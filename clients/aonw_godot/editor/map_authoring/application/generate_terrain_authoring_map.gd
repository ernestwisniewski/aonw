@tool
class_name AonwGenerateTerrainAuthoringMap
extends RefCounted

var _open_map: AonwOpenMap
var _scene_writer: AonwTerrainAuthoringSceneWriter

func _init(
	open_map: AonwOpenMap,
	scene_writer: AonwTerrainAuthoringSceneWriter,
) -> void:
	_open_map = open_map
	_scene_writer = scene_writer

func execute(source: AonwMapSource) -> Dictionary:
	var opened := _open_map.execute(source)
	if not opened["ok"]:
		return opened
	return _scene_writer.prepare_scene(source.map_id)
