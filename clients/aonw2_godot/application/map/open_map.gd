class_name AonwOpenMap
extends RefCounted

var _map_repository: Object
var _atlas_repository: Object

func _init(
	map_repository: Object,
	atlas_repository: Object,
) -> void:
	_map_repository = map_repository
	_atlas_repository = atlas_repository

func execute(source_path: String) -> Dictionary:
	var map_result: Dictionary = _map_repository.load_map(source_path)
	if not map_result["ok"]:
		return map_result

	var atlas_result: Dictionary = _atlas_repository.load_atlas(
		map_result["document"],
		map_result["source_directory"],
	)
	if not atlas_result["ok"]:
		return atlas_result
	return {
		"ok": true,
		"document": map_result["document"],
		"texture": atlas_result["texture"],
		"missing_tiles": atlas_result["missing_tiles"],
		"source_path": map_result["source_path"],
	}
