@tool
class_name AonwGodotMapSceneRepository
extends RefCounted

const AuthoredMapSceneStore := preload("res://infrastructure/map/authored_map_scene_store.gd")
const GeneratedMapManifestStore := preload(
	"res://infrastructure/map/generated_map_manifest_store.gd"
)
const SCENE_ROOT := "res://scenes/maps"
const GENERATED_SCENE_ROOT := "res://scenes/generated/maps"
const ASSET_ROOT := "res://assets/generated_maps"
const GENERATION_PREFIX := "generation-"

var _scene_root: String
var _generated_scene_root: String
var _asset_root: String
var _authored_scenes := AuthoredMapSceneStore.new()
var _manifests := GeneratedMapManifestStore.new()

func _init(
	scene_root: String = SCENE_ROOT,
	asset_root: String = ASSET_ROOT,
	generated_scene_root: String = GENERATED_SCENE_ROOT,
) -> void:
	_scene_root = scene_root
	_asset_root = asset_root
	_generated_scene_root = generated_scene_root

func scene_path_for(map_id: String) -> String:
	return _scene_root.path_join("%s.tscn" % map_id)

func generated_scene_path_for(map_id: String, generation_id: String) -> String:
	return _generated_scene_root.path_join(map_id).path_join(
		"%s_surface.tscn" % generation_id
	)

func save(
	source: AonwMapSource,
	document: AonwMapDocument,
	surface: AonwMapSurface,
	terrain_texture: Texture2D,
	reference_texture: Texture2D,
	content_hash: String,
	source_tile_size: Vector2i,
	missing_tiles: Array,
	invalid_tiles: Array,
	resized_tiles: Array,
) -> Dictionary:
	var output_directory := _asset_root.path_join(source.map_id)
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(output_directory)
	)
	if directory_error != OK:
		return _failure("cannot create %s" % output_directory)
	directory_error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_scene_root)
	)
	if directory_error != OK:
		return _failure("cannot create %s" % _scene_root)
	directory_error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_generated_scene_root)
	)
	if directory_error != OK:
		return _failure("cannot create %s" % _generated_scene_root)
	var generation := _create_generation(output_directory)
	if not generation["ok"]:
		return generation
	var generation_id: String = generation["generation_id"]
	var generation_directory: String = generation["directory"]
	var generated_scene_directory := _generated_scene_root.path_join(source.map_id)
	directory_error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(generated_scene_directory)
	)
	if directory_error != OK:
		return _failure("cannot create %s" % generated_scene_directory)

	var terrain_texture_path := generation_directory.path_join("terrain_texture.res")
	var reference_texture_path := generation_directory.path_join("reference_texture.res")
	var error := _save_resource(terrain_texture, terrain_texture_path)
	if error != OK:
		return _failure("cannot save terrain texture: %s" % error_string(error))
	error = _save_resource(reference_texture, reference_texture_path)
	if error != OK:
		return _failure("cannot save reference texture: %s" % error_string(error))

	var persisted_terrain := ResourceLoader.load(
		terrain_texture_path,
		"Texture2D",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as Texture2D
	var persisted_reference := ResourceLoader.load(
		reference_texture_path,
		"Texture2D",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as Texture2D
	if persisted_terrain == null or persisted_reference == null:
		return _failure("cannot reload persisted map textures")
	surface.present(document, persisted_terrain, persisted_reference)

	var mesh_paths := _mesh_paths(generation_directory)
	for entry in [
		["terrain", surface.terrain_mesh()],
		["reference", surface.reference_mesh()],
		["grid", surface.grid_mesh()],
	]:
		error = _save_resource(entry[1], mesh_paths[entry[0]])
		if error != OK:
			return _failure("cannot save %s: %s" % [entry[0], error_string(error)])

	var settings_path := generation_directory.path_join("render_settings.tres")
	error = _save_resource(surface.render_settings.snapshot(), settings_path)
	if error != OK:
		return _failure("cannot save render settings: %s" % error_string(error))
	var persisted_settings := _load_settings(settings_path)
	var persisted_terrain_mesh := _load_mesh(mesh_paths["terrain"])
	var persisted_reference_mesh := _load_mesh(mesh_paths["reference"])
	var persisted_grid_mesh := _load_mesh(mesh_paths["grid"])
	if (
		persisted_settings == null
		or persisted_terrain_mesh == null
		or persisted_reference_mesh == null
		or persisted_grid_mesh == null
	):
		return _failure("cannot reload persisted map meshes")
	surface.replace_persisted_resources(
		persisted_terrain_mesh,
		persisted_reference_mesh,
		persisted_grid_mesh,
		persisted_settings,
	)
	surface.assign_layer_owners(surface)
	var snapshot_path := generation_directory.path_join("map.json")
	var snapshot_error := _copy_source(source.map_path, snapshot_path)
	if snapshot_error != OK:
		return _failure("cannot save map snapshot: %s" % error_string(snapshot_error))
	surface.source_map_path = snapshot_path
	surface.source_visual_directory = ""

	var generated_scene_path := generated_scene_path_for(source.map_id, generation_id)
	var packed_scene := PackedScene.new()
	error = packed_scene.pack(surface)
	if error != OK:
		return _failure("cannot pack generated Godot map surface: %s" % error_string(error))
	error = ResourceSaver.save(packed_scene, generated_scene_path)
	if error != OK:
		return _failure("cannot save generated Godot map surface: %s" % error_string(error))

	var scene_path := scene_path_for(source.map_id)
	var authored_scene_created := false
	if not FileAccess.file_exists(scene_path):
		error = _authored_scenes.create(scene_path, source.map_id, generated_scene_path)
		if error != OK:
			return _failure("cannot create authored Godot map scene: %s" % error_string(error))
		authored_scene_created = true
	else:
		error = _authored_scenes.refresh(scene_path, generated_scene_path)
		if error != OK:
			return _failure("cannot refresh authored Godot map scene: %s" % error_string(error))

	var manifest_error := _manifests.write(
		output_directory.path_join("manifest.json"),
		source,
		document,
		surface,
		content_hash,
		source_tile_size,
		scene_path,
		generated_scene_path,
		generation_id,
		missing_tiles,
		invalid_tiles,
		resized_tiles,
	)
	if manifest_error != OK:
		return _failure("cannot save map manifest: %s" % error_string(manifest_error))

	return {
		"ok": true,
		"scene_path": scene_path,
		"generated_scene_path": generated_scene_path,
		"generation_id": generation_id,
		"terrain_texture_path": terrain_texture_path,
		"reference_texture_path": reference_texture_path,
		"authored_scene_created": authored_scene_created,
		"output_directory": output_directory,
		"missing_tiles": missing_tiles,
		"invalid_tiles": invalid_tiles,
		"resized_tiles": resized_tiles,
	}

func persist_surface_geometry(surface: AonwMapSurface) -> Dictionary:
	if surface.source_map_id.is_empty():
		return _failure("map surface has no source id")
	if not surface.has_editing_context():
		return _failure("map surface has no editing context")
	var output_directory := _asset_root.path_join(surface.source_map_id)
	var generation := _create_generation(output_directory)
	if not generation["ok"]:
		return generation
	var generation_directory: String = generation["directory"]
	var mesh_paths := _mesh_paths(generation_directory)
	for entry in [
		["terrain", surface.terrain_mesh()],
		["reference", surface.reference_mesh()],
		["grid", surface.grid_mesh()],
	]:
		var error := _save_resource(entry[1], mesh_paths[entry[0]])
		if error != OK:
			return _failure("cannot save %s: %s" % [entry[0], error_string(error)])
	var settings_path := generation_directory.path_join("render_settings.tres")
	var settings_error := _save_resource(surface.render_settings.snapshot(), settings_path)
	if settings_error != OK:
		return _failure("cannot save render settings: %s" % error_string(settings_error))
	var persisted_terrain := _load_mesh(mesh_paths["terrain"])
	var persisted_reference := _load_mesh(mesh_paths["reference"])
	var persisted_grid := _load_mesh(mesh_paths["grid"])
	var persisted_settings := _load_settings(settings_path)
	if (
		persisted_terrain == null
		or persisted_reference == null
		or persisted_grid == null
		or persisted_settings == null
	):
		return _failure("cannot reload persisted map meshes")
	surface.replace_persisted_resources(
		persisted_terrain,
		persisted_reference,
		persisted_grid,
		persisted_settings,
	)
	return {
		"ok": true,
		"generation_id": generation["generation_id"],
		"generation_directory": generation_directory,
	}

func publish_surface_geometry(surface: AonwMapSurface) -> Dictionary:
	if surface.source_map_id.is_empty():
		return _failure("map surface has no source id")
	var output_directory := _asset_root.path_join(surface.source_map_id)
	var manifest_error := _manifests.update_render_settings(
		output_directory.path_join("manifest.json"),
		surface,
	)
	if manifest_error != OK:
		return _failure("cannot update map manifest: %s" % error_string(manifest_error))
	return {"ok": true}

func _copy_source(source_path: String, target_path: String) -> Error:
	var absolute_source := AonwJsonMapRepository.resolve_path(source_path)
	var source_file := FileAccess.open(absolute_source, FileAccess.READ)
	if source_file == null:
		return FileAccess.get_open_error()
	var target_file := FileAccess.open(target_path, FileAccess.WRITE)
	if target_file == null:
		return FileAccess.get_open_error()
	target_file.store_buffer(source_file.get_buffer(source_file.get_length()))
	return OK

func _create_generation(output_directory: String) -> Dictionary:
	var generations_directory := output_directory.path_join("generations")
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(generations_directory)
	)
	if directory_error != OK:
		return _failure("cannot create %s" % generations_directory)
	var directory := DirAccess.open(ProjectSettings.globalize_path(generations_directory))
	if directory == null:
		return _failure("cannot open %s" % generations_directory)
	var next_index := 1
	for name in directory.get_directories():
		if not name.begins_with(GENERATION_PREFIX):
			continue
		var suffix := name.trim_prefix(GENERATION_PREFIX)
		if suffix.is_valid_int():
			next_index = maxi(next_index, int(suffix) + 1)
	var generation_id := "%s%06d" % [GENERATION_PREFIX, next_index]
	var generation_directory := generations_directory.path_join(generation_id)
	directory_error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(generation_directory)
	)
	if directory_error != OK:
		return _failure("cannot create %s" % generation_directory)
	return {
		"ok": true,
		"generation_id": generation_id,
		"directory": generation_directory,
	}

func _mesh_paths(generation_directory: String) -> Dictionary:
	return {
		"terrain": generation_directory.path_join("terrain_mesh.res"),
		"reference": generation_directory.path_join("reference_mesh.res"),
		"grid": generation_directory.path_join("grid_mesh.res"),
	}

func _save_resource(resource: Resource, path: String) -> Error:
	return ResourceSaver.save(resource, path, ResourceSaver.FLAG_COMPRESS)

func _load_mesh(path: String) -> ArrayMesh:
	return ResourceLoader.load(path, "ArrayMesh", ResourceLoader.CACHE_MODE_REPLACE) as ArrayMesh

func _load_settings(path: String) -> Resource:
	return ResourceLoader.load(
		path,
		"AonwMapRenderSettings",
		ResourceLoader.CACHE_MODE_REPLACE,
	)

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
