class_name AonwLocalMatchSessionController
extends RefCounted

const NativeLocalSession := preload("res://infrastructure/engine/native_local_session.gd")

var _transport: RefCounted
var _stamp: Dictionary = {}

func _init(transport: RefCounted = null) -> void:
	_transport = transport if transport != null else NativeLocalSession.new()

func is_available() -> bool:
	return bool(_transport.call("is_available"))

func revision() -> int:
	return int(_stamp.get("revision", 0))

func capabilities() -> Dictionary:
	return _execute({"type": "capabilities"}, "capabilities")

func open(map_document: String, scenario_document: String, actor_player_id: String) -> Dictionary:
	var result := _execute({
		"type": "openSession",
		"mapDocument": map_document,
		"scenarioDocument": scenario_document,
		"actorPlayerId": actor_player_id,
	}, "sessionOpened")
	return _extract(result, "stamp")

func close() -> Dictionary:
	var result := _execute({"type": "closeSession"}, "sessionClosed")
	if result["ok"]:
		_stamp.clear()
	return result

func snapshot() -> Dictionary:
	return _extract(_execute({"type": "snapshot"}, "snapshot"), "snapshot")

func reachable(unit_id: String) -> Dictionary:
	return _query({
		"type": "reachable",
		"expectedRevision": revision(),
		"unitId": unit_id,
	}, "reachable")

func route_plan(unit_id: String, target: Vector2i) -> Dictionary:
	return _query({
		"type": "routePlan",
		"expectedRevision": revision(),
		"unitId": unit_id,
		"target": _coordinate(target),
	}, "routePlan")

func move_unit(unit_id: String, target: Vector2i) -> Dictionary:
	return _command({
		"type": "moveUnit",
		"expectedRevision": revision(),
		"unitId": unit_id,
		"target": _coordinate(target),
	})

func cancel_unit_action(unit_id: String) -> Dictionary:
	return _unit_action("cancelUnitAction", unit_id)

func skip_unit_turn(unit_id: String) -> Dictionary:
	return _unit_action("skipUnitTurn", unit_id)

func fortify_unit(unit_id: String) -> Dictionary:
	return _unit_action("fortifyUnit", unit_id)

func save_game() -> Dictionary:
	return _extract(_execute({"type": "exportSave"}, "saveExported"), "document")

func open_save(map_document: String, save_document: String) -> Dictionary:
	var result := _execute({
		"type": "openSave",
		"mapDocument": map_document,
		"saveDocument": save_document,
	}, "saveOpened")
	return _extract(result, "stamp")

func replay_log() -> Dictionary:
	return _extract(_execute({"type": "exportReplay"}, "replayExported"), "document")

func verify_replay(map_document: String, replay_document: String) -> Dictionary:
	var result := _execute({
		"type": "verifyReplay",
		"mapDocument": map_document,
		"replayDocument": replay_document,
	}, "replayVerified")
	return _extract(result, "verification")

func _query(query: Dictionary, result_type: String) -> Dictionary:
	var result := _execute({"type": "query", "query": query}, "query")
	if not result["ok"]:
		return result
	var value: Variant = result["value"].get("result")
	if not value is Dictionary or value.get("type", "") != result_type:
		return _failure("invalid_client_response", "Rust returned an unexpected query result")
	return {"ok": true, "value": value}

func _command(command: Dictionary) -> Dictionary:
	return _extract(
		_execute({"type": "dispatch", "command": command}, "command"),
		"result",
	)

func _unit_action(action_type: String, unit_id: String) -> Dictionary:
	return _command({
		"type": action_type,
		"expectedRevision": revision(),
		"unitId": unit_id,
	})

func _execute(request: Dictionary, response_type: String) -> Dictionary:
	var envelope: Dictionary = _transport.call("request", request)
	if int(envelope.get("apiVersion", -1)) != int(
		_transport.call("client_api_version")
	):
		return _failure(
			"unsupported_client_api",
			"Rust returned an unsupported client API version",
		)
	var outcome: Variant = envelope.get("outcome")
	if not outcome is Dictionary:
		return _failure("invalid_client_response", "Rust returned an invalid response envelope")
	if outcome.get("status", "") == "failure":
		var error: Variant = outcome.get("error")
		if error is Dictionary:
			return _failure(str(error.get("code", "client_failure")), str(error.get("message", "")))
		return _failure("invalid_client_response", "Rust returned an invalid failure response")
	var response: Variant = outcome.get("response")
	if not response is Dictionary or response.get("type", "") != response_type:
		return _failure("invalid_client_response", "Rust returned an unexpected response type")
	_capture_stamp(response)
	return {"ok": true, "value": response}

func _extract(result: Dictionary, field: String) -> Dictionary:
	if not result["ok"]:
		return result
	var body: Dictionary = result["value"]
	if not body.has(field):
		return _failure("invalid_client_response", "Rust response is missing %s" % field)
	return {"ok": true, "value": body[field]}

func _capture_stamp(response: Dictionary) -> void:
	if response.get("stamp") is Dictionary:
		_stamp = response["stamp"].duplicate(true)
		return
	for field in ["snapshot", "result", "verification"]:
		var value: Variant = response.get(field)
		if value is Dictionary and value.get("stamp") is Dictionary:
			_stamp = value["stamp"].duplicate(true)
			return

func _coordinate(value: Vector2i) -> Dictionary:
	return {"col": value.x, "row": value.y}

func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
