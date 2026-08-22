@tool
class_name AonwGenerateTerrainAuthoringMap
extends RefCounted

var _open_map: AonwOpenMap
var _artifact_repository: AonwTerrainCompiledArtifactRepository
var _scene_repository: AonwTerrainAuthoringSceneRepository

func _init(
	open_map: AonwOpenMap,
	artifact_repository: AonwTerrainCompiledArtifactRepository,
	scene_repository: AonwTerrainAuthoringSceneRepository,
) -> void:
	_open_map = open_map
	_artifact_repository = artifact_repository
	_scene_repository = scene_repository

func execute(source: AonwMapSource) -> Dictionary:
	var opened := _open_map.execute(source)
	if not opened["ok"]:
		return opened
	var artifact_result := _artifact_repository.load_artifact(
		_scene_repository.compiled_artifact_directory_for(source.map_id),
		source.map_id,
	)
	if not artifact_result["ok"]:
		return artifact_result
	var artifact: AonwTerrainCompiledArtifact = artifact_result["artifact"]
	if artifact.map_content_hash != opened["content_hash"]:
		return {
			"ok": false,
			"message": "compiled terrain profile does not match the current map content hash",
		}
	return _scene_repository.prepare_scene(source.map_id, opened["reference_texture"])
