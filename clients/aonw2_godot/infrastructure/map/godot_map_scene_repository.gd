@tool
class_name AonwGodotMapSceneRepository
extends RefCounted

const SCENE_ROOT := "res://scenes/maps"
const GENERATED_SCENE_ROOT := "res://scenes/generated/maps"
const ASSET_ROOT := "res://assets/generated_maps"
const GENERATION_PREFIX := "generation-"
const GENERATED_LAYER_NAMES := [&"BaseTerrain", &"ReferenceTexture", &"HexGrid"]

var _scene_root: String
var _generated_scene_root: String
var _asset_root: String

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
		error = _create_authored_scene(scene_path, source.map_id, generated_scene_path)
		if error != OK:
			return _failure("cannot create authored Godot map scene: %s" % error_string(error))
		authored_scene_created = true
	else:
		error = _refresh_authored_surface(scene_path, generated_scene_path)
		if error != OK:
			return _failure("cannot refresh authored Godot map scene: %s" % error_string(error))

	var manifest_error := _write_manifest(
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
	var manifest_error := _update_manifest_render_settings(
		output_directory.path_join("manifest.json"),
		surface,
	)
	if manifest_error != OK:
		return _failure("cannot update map manifest: %s" % error_string(manifest_error))
	return {"ok": true}

func _create_authored_scene(path: String, map_id: String, generated_scene_path: String) -> Error:
	var generated_scene := ResourceLoader.load(
		generated_scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as PackedScene
	if generated_scene == null:
		return ERR_CANT_OPEN
	var surface := generated_scene.instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE
	) as AonwMapSurface
	if surface == null:
		return ERR_CANT_CREATE
	var root := Node3D.new()
	root.name = map_id
	root.add_child(surface)
	surface.owner = root
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		error = _save_packed_scene_atomically(packed, path)
	root.free()
	return error

func _refresh_authored_surface(path: String, generated_scene_path: String) -> Error:
	var authored_scene := ResourceLoader.load(
		path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	var generated_scene := ResourceLoader.load(
		generated_scene_path,
		"PackedScene",
		ResourceLoader.CACHE_MODE_REPLACE_DEEP,
	) as PackedScene
	if authored_scene == null or generated_scene == null:
		return ERR_CANT_OPEN
	var root := authored_scene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var previous_surface := root.get_node_or_null("AonwMap3D")
	if previous_surface == null:
		root.free()
		return ERR_DOES_NOT_EXIST
	var surface_index := previous_surface.get_index()
	var authored_children: Array[Node] = []
	for child in previous_surface.get_children():
		if child.name in GENERATED_LAYER_NAMES:
			continue
		previous_surface.remove_child(child)
		child.owner = null
		authored_children.append(child)
	root.remove_child(previous_surface)
	previous_surface.free()
	var surface := generated_scene.instantiate(
		PackedScene.GEN_EDIT_STATE_INSTANCE
	) as AonwMapSurface
	if surface == null:
		root.free()
		return ERR_CANT_CREATE
	root.add_child(surface)
	root.move_child(surface, surface_index)
	surface.owner = root
	for child in authored_children:
		surface.add_child(child)
		child.owner = root
	var packed := PackedScene.new()
	var error := packed.pack(root)
	if error == OK:
		error = _save_packed_scene_atomically(packed, path)
	root.free()
	return error

func _write_manifest(
	path: String,
	source: AonwMapSource,
	document: AonwMapDocument,
	surface: AonwMapSurface,
	content_hash: String,
	source_tile_size: Vector2i,
	scene_path: String,
	generated_scene_path: String,
	generation_id: String,
	missing_tiles: Array,
	invalid_tiles: Array,
	resized_tiles: Array,
) -> Error:
	var absolute_source := AonwJsonMapRepository.resolve_path(source.map_path)
	var manifest := {
		"formatVersion": 1,
		"mapId": document.map_id(),
		"cols": document.cols(),
		"rows": document.rows(),
		"mapSchemaVersion": 1,
		"sourcePath": source.map_path,
		"sourceSha256": FileAccess.get_sha256(absolute_source),
		"contentHash": content_hash,
		"sourceTileSize": {"width": source_tile_size.x, "height": source_tile_size.y},
		"scenePath": scene_path,
		"generatedScenePath": generated_scene_path,
		"activeGeneration": generation_id,
		"renderSettings": surface.render_settings.to_dictionary(),
		"missingTextureCount": missing_tiles.size(),
		"invalidTextureCount": invalid_tiles.size(),
		"resizedTextureCount": resized_tiles.size(),
	}
	return _write_text_atomically(path, JSON.stringify(manifest, "  ", false) + "\n")

func _update_manifest_render_settings(path: String, surface: AonwMapSurface) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR
	parsed["renderSettings"] = surface.render_settings.to_dictionary()
	var settings_path := surface.render_settings.resource_path
	if not settings_path.is_empty():
		parsed["activeGeneration"] = settings_path.get_base_dir().get_file()
	return _write_text_atomically(path, JSON.stringify(parsed, "  ", false) + "\n")

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

func _save_packed_scene_atomically(scene: PackedScene, path: String) -> Error:
	var pending_path := _pending_path(path)
	var error := ResourceSaver.save(scene, pending_path)
	if error != OK:
		return error
	return _replace_file(pending_path, path)

func _write_text_atomically(path: String, content: String) -> Error:
	var pending_path := _pending_path(path)
	var file := FileAccess.open(pending_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	file = null
	return _replace_file(pending_path, path)

func _replace_file(pending_path: String, target_path: String) -> Error:
	var pending_absolute := ProjectSettings.globalize_path(pending_path)
	var target_absolute := ProjectSettings.globalize_path(target_path)
	var error := DirAccess.rename_absolute(pending_absolute, target_absolute)
	if error == OK:
		return OK
	if not FileAccess.file_exists(target_path):
		return error
	var backup_path := "%s.backup" % target_path
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	error = DirAccess.rename_absolute(target_absolute, backup_absolute)
	if error != OK:
		return error
	error = DirAccess.rename_absolute(pending_absolute, target_absolute)
	if error != OK:
		DirAccess.rename_absolute(backup_absolute, target_absolute)
		return error
	DirAccess.remove_absolute(backup_absolute)
	return OK

func _pending_path(path: String) -> String:
	return "%s.pending.%s" % [path.get_basename(), path.get_extension()]

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
