class_name AonwJsonMapRepository
extends AonwMapViewReader

const MapSource := preload("res://game/application/map/map_source.gd")
const MapViewMapper := preload("res://game/infrastructure/map/map_view_mapper.gd")
const NativeLocalSession := preload("res://game/infrastructure/engine/native_local_session.gd")

var _client: RefCounted
var _mapper := MapViewMapper.new()

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
	var result := _mapper.from_wire(response["map"])
	if not result["ok"]:
		return result
	var map: AonwMapView = result["value"]
	if source.map_id != map.map_id():
		return _failure(
			"source id %s does not match mapId %s" % [
				source.map_id,
				map.map_id(),
			]
		)
	return {
		"ok": true,
		"map": map,
		"visual_directory": source.visual_directory,
	}

static func resolve_path(source_path: String) -> String:
	if source_path.begins_with("res://") or source_path.begins_with("user://"):
		return ProjectSettings.globalize_path(source_path)
	return source_path

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
