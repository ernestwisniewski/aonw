@tool
class_name AonwGeneratedMapManifestStore
extends RefCounted

const AtomicResourceStore := preload("res://infrastructure/map/atomic_resource_store.gd")

var _atomic_store := AtomicResourceStore.new()

func write(
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
	return _atomic_store.write_text(path, JSON.stringify(manifest, "  ", false) + "\n")

func update_render_settings(path: String, surface: AonwMapSurface) -> Error:
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
	return _atomic_store.write_text(path, JSON.stringify(parsed, "  ", false) + "\n")
