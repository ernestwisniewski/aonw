@tool
class_name AonwGodotMapSceneRepository
extends RefCounted

const SCENE_ROOT := "res://scenes/maps"
const GENERATED_SCENE_ROOT := "res://scenes/generated/maps"
const ASSET_ROOT := "res://assets/generated_maps"
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

func generated_scene_path_for(map_id: String) -> String:
	return _generated_scene_root.path_join("%s_surface.tscn" % map_id)

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
	var absolute_output := ProjectSettings.globalize_path(output_directory)
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_output)
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

	var generated_scene_path := generated_scene_path_for(source.map_id)
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
		var error := _save_resource(entry[1], mesh_paths[entry[0]])
		if error != OK:
			return _failure("cannot save %s: %s" % [entry[0], error_string(error)])
	var persisted_terrain := _load_mesh(mesh_paths["terrain"])
	var persisted_reference := _load_mesh(mesh_paths["reference"])
	var persisted_grid := _load_mesh(mesh_paths["grid"])
	if persisted_terrain == null or persisted_reference == null or persisted_grid == null:
		return _failure("cannot reload persisted map meshes")
	surface.replace_persisted_resources(
		persisted_terrain,
		persisted_reference,
		persisted_grid,
	)
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
		error = ResourceSaver.save(packed, path)
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
		error = ResourceSaver.save(packed, path)
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
		"renderSettings": _render_settings(surface),
		"missingTextureCount": missing_tiles.size(),
		"invalidTextureCount": invalid_tiles.size(),
		"resizedTextureCount": resized_tiles.size(),
	}
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(manifest, "  ", false) + "\n")
	return OK

func _update_manifest_render_settings(path: String, surface: AonwMapSurface) -> Error:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return FileAccess.get_open_error()
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return ERR_PARSE_ERROR
	parsed["renderSettings"] = _render_settings(surface)
	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(parsed, "  ", false) + "\n")
	return OK

func _render_settings(surface: AonwMapSurface) -> Dictionary:
	return {
		"hexRadius": surface.hex_radius,
		"heightStep": surface.height_step,
		"referenceVisible": surface.reference_visible,
		"referenceOpacity": surface.reference_opacity,
		"gridVisible": surface.grid_visible,
		"gridOpacity": surface.grid_opacity,
		"gridWidth": surface.grid_width,
	}

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
