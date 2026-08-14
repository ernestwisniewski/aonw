class_name AonwJsonMapRepository
extends AonwMapDocumentReader

const MapDocument := preload("res://application/map/read_model/map_document.gd")
const MapSource := preload("res://application/map/map_source.gd")
const NativeEngineBridge := preload("res://infrastructure/engine/native_engine_bridge.gd")

var _native_engine := NativeEngineBridge.new()

func load_map(source: AonwMapSource) -> Dictionary:
	var absolute_path := resolve_path(source.map_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return _failure("cannot open %s" % absolute_path)

	var source_json := file.get_as_text()
	var native_result := _native_engine.validate_map_json(source_json)
	if not bool(native_result.get("ok", false)):
		return _failure(
			"Rust: %s" % native_result.get("message", "map validator failed")
		)

	var native_value: Dictionary = native_result.get("value", {})
	var result := MapDocument.from_native_snapshot(native_value.get("document"))
	if not result["ok"]:
		return result
	var document: AonwMapDocument = result["value"]
	if source.map_id != document.map_id():
		return _failure(
			"source id %s does not match mapName %s" % [
				source.map_id,
				document.map_id(),
			]
		)
	if native_value.get("mapId", "") != document.map_id():
		return _failure("Rust validator returned a mismatched map identity")
	return {
		"ok": true,
		"document": document,
		"content_hash": native_value.get("contentHash", ""),
		"source_path": absolute_path,
		"visual_directory": source.visual_directory,
		"source": source,
	}

static func resolve_path(source_path: String) -> String:
	if source_path.begins_with("res://") or source_path.begins_with("user://"):
		return ProjectSettings.globalize_path(source_path)
	return source_path

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
