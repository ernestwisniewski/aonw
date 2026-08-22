class_name AonwJsonMapRepository
extends AonwMapDocumentReader

const MapDocument := preload("res://game/application/map/read_model/map_document.gd")
const MapSource := preload("res://game/application/map/map_source.gd")
const NativeLocalSession := preload("res://game/infrastructure/engine/native_local_session.gd")

var _client: RefCounted

func _init(client: RefCounted = null) -> void:
	_client = client if client != null else NativeLocalSession.new()

func load_map(source: AonwMapSource) -> Dictionary:
	var absolute_path := resolve_path(source.map_path)
	var file := FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return _failure("cannot open %s" % absolute_path)

	var source_json := file.get_as_text()
	var envelope: Dictionary = _client.call("request", {
		"type": "inspectMap",
		"mapDocument": source_json,
	})
	var outcome: Variant = envelope.get("outcome")
	if not outcome is Dictionary:
		return _failure("Rust returned an invalid map inspection envelope")
	if outcome.get("status", "") == "failure":
		var error: Variant = outcome.get("error")
		return _failure(
			"Rust: %s" % (
				error.get("message", "map inspection failed")
				if error is Dictionary
				else "map inspection failed"
			)
		)
	var response: Variant = outcome.get("response")
	if (
		not response is Dictionary
		or response.size() != 2
		or response.get("type", "") != "mapInspected"
		or not response.has("map")
	):
		return _failure("Rust returned an invalid map inspection response")
	var result := MapDocument.from_map_view(response["map"])
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
	return {
		"ok": true,
		"document": document,
		"content_hash": document.content_hash(),
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
