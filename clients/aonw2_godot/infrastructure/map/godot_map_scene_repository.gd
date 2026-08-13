@tool
class_name AonwGodotMapSceneRepository
extends RefCounted

const SCENE_ROOT := "res://scenes/maps"
const ASSET_ROOT := "res://assets/generated_maps"

var _scene_root: String
var _asset_root: String

func _init(
	scene_root: String = SCENE_ROOT,
	asset_root: String = ASSET_ROOT,
) -> void:
	_scene_root = scene_root
	_asset_root = asset_root

func scene_path_for(map_id: String) -> String:
	return _scene_root.path_join("%s.tscn" % map_id)

func save(
	source: AonwMapSource,
	document: AonwMapDocument,
	surface: AonwMapSurface,
	terrain_texture: Texture2D,
	reference_texture: Texture2D,
	missing_tiles: Array,
	invalid_tiles: Array,
	resized_tiles: Array,
) -> Dictionary:
	var output_directory := _asset_root.path_join(source.map_id)
	var absolute_output := ProjectSettings.globalize_path(output_directory)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_output)
	if directory_error != OK:
		return _failure("cannot create %s" % output_directory)
	directory_error = DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_scene_root)
	)
	if directory_error != OK:
		return _failure("cannot create %s" % _scene_root)

	var terrain_texture_path := output_directory.path_join("terrain_texture.res")
	var reference_texture_path := output_directory.path_join("reference_texture.res")
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

	var mesh_paths := {
		"terrain": output_directory.path_join("terrain_mesh.res"),
		"reference": output_directory.path_join("reference_mesh.res"),
		"grid": output_directory.path_join("grid_mesh.res"),
	}
	for entry in [
		["terrain", surface.terrain_mesh()],
		["reference", surface.reference_mesh()],
		["grid", surface.grid_mesh()],
	]:
		error = _save_resource(entry[1], mesh_paths[entry[0]])
		if error != OK:
			return _failure("cannot save %s: %s" % [entry[0], error_string(error)])

	var persisted_terrain_mesh := _load_mesh(mesh_paths["terrain"])
	var persisted_reference_mesh := _load_mesh(mesh_paths["reference"])
	var persisted_grid_mesh := _load_mesh(mesh_paths["grid"])
	if persisted_terrain_mesh == null or persisted_reference_mesh == null or persisted_grid_mesh == null:
		return _failure("cannot reload persisted map meshes")
	surface.replace_persisted_resources(
		persisted_terrain_mesh,
		persisted_reference_mesh,
		persisted_grid_mesh,
	)
	surface.assign_layer_owners(surface)
	var snapshot_path := output_directory.path_join("map.json")
	var snapshot_error := _copy_source(source.map_path, snapshot_path)
	if snapshot_error != OK:
		return _failure("cannot save map snapshot: %s" % error_string(snapshot_error))
	surface.source_map_path = snapshot_path
	surface.source_visual_directory = ""

	var scene_path := scene_path_for(source.map_id)
	var packed_scene := PackedScene.new()
	error = packed_scene.pack(surface)
	if error != OK:
		return _failure("cannot pack Godot map scene: %s" % error_string(error))
	error = ResourceSaver.save(packed_scene, scene_path)
	if error != OK:
		return _failure("cannot save Godot map scene: %s" % error_string(error))

	var manifest_error := _write_manifest(
		output_directory.path_join("manifest.json"),
		source,
		document,
		scene_path,
		missing_tiles,
		invalid_tiles,
		resized_tiles,
	)
	if manifest_error != OK:
		return _failure("cannot save map manifest: %s" % error_string(manifest_error))

	return {
		"ok": true,
		"scene_path": scene_path,
		"output_directory": output_directory,
		"missing_tiles": missing_tiles,
		"invalid_tiles": invalid_tiles,
		"resized_tiles": resized_tiles,
	}

func _write_manifest(
	path: String,
	source: AonwMapSource,
	document: AonwMapDocument,
	scene_path: String,
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
		"sourceFormat": "legacy" if source.is_legacy() else "versioned",
		"sourcePath": source.map_path,
		"sourceSha256": FileAccess.get_sha256(absolute_source),
		"scenePath": scene_path,
		"missingTextureCount": missing_tiles.size(),
		"invalidTextureCount": invalid_tiles.size(),
		"resizedTextureCount": resized_tiles.size(),
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(manifest, "  ", false) + "\n")
	return OK

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

func _save_resource(resource: Resource, path: String) -> Error:
	return ResourceSaver.save(resource, path, ResourceSaver.FLAG_COMPRESS)

func _load_mesh(path: String) -> ArrayMesh:
	return ResourceLoader.load(path, "ArrayMesh", ResourceLoader.CACHE_MODE_REPLACE) as ArrayMesh

func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
