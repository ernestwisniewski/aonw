class_name AonwJsonMapRepository
extends AonwMapViewReader

const MapSource := preload("res://game/application/map/map_source.gd")
const MapViewMapper := preload("res://game/infrastructure/map/map_view_mapper.gd")

var _client: RefCounted
var _documents: RefCounted
var _mapper := MapViewMapper.new()

func _init(client: RefCounted, documents: RefCounted) -> void:
	assert(client != null, "Map inspection client is required")
	assert(documents != null, "Map document reader is required")
	_client = client
	_documents = documents

func load_map(source: AonwMapSource) -> Dictionary:
	var loaded: Dictionary = _documents.call("read", source.map_path)
	if not loaded.get("ok", false):
		return _failure(str(loaded.get("message", "cannot read map document")))
	var envelope: Dictionary = _client.call("request", {
		"type": "inspectMap",
		"mapDocument": loaded.get("document", ""),
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

static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
