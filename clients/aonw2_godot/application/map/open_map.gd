class_name AonwOpenMap
extends RefCounted

const MapSource := preload("res://application/map/map_source.gd")

var _map_repository: AonwMapDocumentReader
var _atlas_repository: AonwMapTextureAssembler

func _init(
	map_repository: AonwMapDocumentReader,
	atlas_repository: AonwMapTextureAssembler,
) -> void:
	_map_repository = map_repository
	_atlas_repository = atlas_repository

func execute(source: AonwMapSource) -> Dictionary:
	var map_result: Dictionary = _map_repository.load_map(source)
	if not map_result["ok"]:
		return map_result

	var atlas_result: Dictionary = _atlas_repository.load_atlas(
		map_result["document"],
		map_result["visual_directory"],
	)
	if not atlas_result["ok"]:
		return atlas_result
	return {
		"ok": true,
		"document": map_result["document"],
		"texture": atlas_result["texture"],
		"terrain_texture": atlas_result["terrain_texture"],
		"reference_texture": atlas_result["reference_texture"],
		"missing_tiles": atlas_result["missing_tiles"],
		"invalid_tiles": atlas_result["invalid_tiles"],
		"resized_tiles": atlas_result["resized_tiles"],
		"source_path": map_result["source_path"],
		"source": source,
	}
