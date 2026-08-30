class_name AonwOpenLocalMatch
extends RefCounted

var _session: AonwLocalMatchSessionController
var _documents: RefCounted

func _init(
	session: AonwLocalMatchSessionController,
	documents: RefCounted,
) -> void:
	assert(session != null, "Local match session is required")
	assert(documents != null, "Text document reader port is required")
	_session = session
	_documents = documents

func execute(
	map_path: String,
	scenario_path: String,
	actor_player_id: String,
) -> Dictionary:
	var map_document := _read(map_path, "map_document_unavailable")
	if not map_document["ok"]:
		return map_document
	var scenario_document := _read(scenario_path, "scenario_document_unavailable")
	if not scenario_document["ok"]:
		return scenario_document
	return _session.open(
		map_document["document"],
		scenario_document["document"],
		actor_player_id,
	)

func _read(path: String, error_code: String) -> Dictionary:
	var loaded: Dictionary = _documents.call("read", path)
	if loaded.get("ok", false):
		return {
			"ok": true,
			"document": str(loaded.get("document", "")),
		}
	return {
		"ok": false,
		"code": error_code,
		"message": str(loaded.get("message", "cannot read document")),
	}
