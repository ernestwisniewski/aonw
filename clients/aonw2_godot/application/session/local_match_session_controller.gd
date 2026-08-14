class_name AonwLocalMatchSessionController
extends RefCounted

const NativeLocalSession := preload("res://infrastructure/engine/native_local_session.gd")
const ReadModelDecoder := preload(
	"res://application/session/client_read_model_decoder.gd"
)
const ClientProtocol := preload("res://application/session/client_protocol.gd")

var _transport: RefCounted
var _stamp: RefCounted

func _init(transport: RefCounted = null) -> void:
	_transport = transport if transport != null else NativeLocalSession.new()

func is_available() -> bool:
	return bool(_transport.call("is_available"))

func revision() -> int:
	return 0 if _stamp == null else int(_stamp.get("revision"))

func capabilities() -> Dictionary:
	return _execute({"type": "capabilities"}, "capabilities")

func open(map_document: String, scenario_document: String, actor_player_id: String) -> Dictionary:
	var result := _execute({
		"type": "openSession",
		"mapDocument": map_document,
		"scenarioDocument": scenario_document,
		"actorPlayerId": actor_player_id,
	}, "sessionOpened")
	return _extract_stamp(result, "stamp")

func close() -> Dictionary:
	var result := _execute({"type": "closeSession"}, "sessionClosed")
	if result["ok"]:
		_stamp = null
	return result

func snapshot() -> Dictionary:
	var result := _extract(_execute({"type": "snapshot"}, "snapshot"), "snapshot")
	if not result["ok"]:
		return result
	var snapshot := ReadModelDecoder.decode_snapshot(result["value"])
	if snapshot == null:
		return _failure("invalid_client_response", "Rust returned an invalid snapshot")
	_stamp = snapshot.stamp
	return {"ok": true, "value": snapshot}

func reachable(unit_id: String) -> Dictionary:
	var result := _query({
		"type": "reachable",
		"expectedRevision": revision(),
		"unitId": unit_id,
	}, "reachable")
	if not result["ok"]:
		return result
	var reachable_view := ReadModelDecoder.decode_reachable(result["value"])
	if reachable_view == null:
		return _failure("invalid_client_response", "Rust returned invalid reachable tiles")
	_stamp = reachable_view.stamp
	return {"ok": true, "value": reachable_view}

func route_plan(unit_id: String, target: Vector2i) -> Dictionary:
	var result := _query({
		"type": "routePlan",
		"expectedRevision": revision(),
		"unitId": unit_id,
		"target": _coordinate(target),
	}, "routePlan")
	if not result["ok"]:
		return result
	var route := ReadModelDecoder.decode_route_plan(result["value"])
	if route == null:
		return _failure("invalid_client_response", "Rust returned an invalid route plan")
	_stamp = route.stamp
	return {"ok": true, "value": route}

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
	return _extract_stamp(result, "stamp")

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
	var result := _extract(
		_execute({"type": "dispatch", "command": command}, "command"),
		"result",
	)
	if not result["ok"]:
		return result
	var command_result := ReadModelDecoder.decode_command(result["value"])
	if command_result == null:
		return _failure("invalid_client_response", "Rust returned an invalid command result")
	_stamp = command_result.stamp
	return {"ok": true, "value": command_result}

func _unit_action(action_type: String, unit_id: String) -> Dictionary:
	return _command({
		"type": action_type,
		"expectedRevision": revision(),
		"unitId": unit_id,
	})

func _execute(request: Dictionary, response_type: String) -> Dictionary:
	if int(_transport.call("client_api_version")) != ClientProtocol.API_VERSION:
		return _failure(
			"unsupported_client_api",
			"The client transport uses an unsupported API version",
		)
	var envelope: Dictionary = _transport.call("request", request)
	if int(envelope.get("apiVersion", -1)) != ClientProtocol.API_VERSION:
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
	return {"ok": true, "value": response}

func _extract(result: Dictionary, field: String) -> Dictionary:
	if not result["ok"]:
		return result
	var body: Dictionary = result["value"]
	if not body.has(field):
		return _failure("invalid_client_response", "Rust response is missing %s" % field)
	return {"ok": true, "value": body[field]}

func _extract_stamp(result: Dictionary, field: String) -> Dictionary:
	var extracted := _extract(result, field)
	if not extracted["ok"]:
		return extracted
	var stamp := ReadModelDecoder.decode_stamp(extracted["value"])
	if stamp == null:
		return _failure("invalid_client_response", "Rust returned an invalid session stamp")
	_stamp = stamp
	return extracted

func _coordinate(value: Vector2i) -> Dictionary:
	return {"col": value.x, "row": value.y}

func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
