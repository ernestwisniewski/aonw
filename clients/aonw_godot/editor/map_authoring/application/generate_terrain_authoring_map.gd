@tool
class_name AonwGenerateTerrainAuthoringMap
extends RefCounted

var _open_map: AonwOpenMap
var _scene_repository: AonwTerrainAuthoringSceneRepository

func _init(
	open_map: AonwOpenMap,
	scene_repository: AonwTerrainAuthoringSceneRepository,
) -> void:
	_open_map = open_map
	_scene_repository = scene_repository

func execute(source: AonwMapSource) -> Dictionary:
	var opened := _open_map.execute(source)
	if not opened["ok"]:
		return opened
	return _scene_repository.prepare_scene(source.map_id, opened["reference_texture"])
