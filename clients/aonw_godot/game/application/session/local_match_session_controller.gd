class_name AonwLocalMatchSessionController
extends RefCounted

enum Lifecycle { CLOSED, OPENING, OPEN, CLOSING }

var _gateway: RefCounted
var _stamp: AonwClientReadModels.Stamp
var _lifecycle := Lifecycle.CLOSED
var _generation := 0

func _init(gateway: RefCounted) -> void:
	assert(gateway != null, "Local match gateway port is required")
	_gateway = gateway

func is_available() -> bool:
	return bool(_gateway.call("is_available"))

func revision() -> int:
	return 0 if _stamp == null else _stamp.revision

func lifecycle() -> int:
	return _lifecycle

func generation() -> int:
	return _generation

func is_open() -> bool:
	return _lifecycle == Lifecycle.OPEN

func capabilities() -> Dictionary:
	return _gateway.call("capabilities")

func open(map_document: String, scenario_document: String, actor_player_id: String) -> Dictionary:
	return _open_with(&"open_session", [
		map_document,
		scenario_document,
		actor_player_id,
	])

func start_match(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
	match_identity: Dictionary,
	fog_enabled: bool,
) -> Dictionary:
	return _open_with(&"start_match", [
		map_document,
		scenario_document,
		actor_player_id,
		match_identity,
		fog_enabled,
	])

func handoff_actor(actor_player_id: String) -> Dictionary:
	return _call_stamp(&"handoff_actor", [actor_player_id])

func advance_ai_turn(actor_player_id: String, command_budget: int) -> Dictionary:
	return _call_value(&"advance_ai_turn", [actor_player_id, command_budget])

func advance_ai_turn_async(actor_player_id: String, command_budget: int) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	var request_generation := _generation
	var result: Dictionary = await _gateway.call(
		"advance_ai_turn_async",
		actor_player_id,
		command_budget,
	)
	if request_generation != _generation or _lifecycle != Lifecycle.OPEN:
		return _failure(
			"stale_session_response",
			"The session changed before the engine response arrived",
		)
	return _track_value_stamp(result)

func close() -> Dictionary:
	if _lifecycle in [Lifecycle.CLOSED, Lifecycle.CLOSING]:
		return {"ok": true}
	_generation += 1
	_lifecycle = Lifecycle.CLOSING
	var result: Dictionary = _gateway.call("close_session")
	if result["ok"]:
		_stamp = null
		_lifecycle = Lifecycle.CLOSED
	else:
		_lifecycle = Lifecycle.OPEN
	return result

func snapshot() -> Dictionary:
	return _call_value(&"snapshot")

func reachable(unit_id: String) -> Dictionary:
	return _call_value(&"reachable", [revision(), unit_id])

func route_plan(unit_id: String, target: Vector2i) -> Dictionary:
	return _call_value(&"route_plan", [revision(), unit_id, target])

func move_unit(unit_id: String, target: Vector2i) -> Dictionary:
	return _call_value(&"move_unit", [revision(), unit_id, target])

func cancel_unit_action(unit_id: String) -> Dictionary:
	return _call_value(&"cancel_unit_action", [revision(), unit_id])

func skip_unit_turn(unit_id: String) -> Dictionary:
	return _call_value(&"skip_unit_turn", [revision(), unit_id])

func fortify_unit(unit_id: String) -> Dictionary:
	return _call_value(&"fortify_unit", [revision(), unit_id])

func end_turn() -> Dictionary:
	return _call_value(&"end_turn", [revision()])

func save_game() -> Dictionary:
	return _call_plain(&"save_game")

func open_save(map_document: String, save_document: String) -> Dictionary:
	return _open_with(&"open_save", [map_document, save_document])

func replay_log() -> Dictionary:
	return _call_plain(&"replay_log")

func verify_replay(map_document: String, replay_document: String) -> Dictionary:
	return _gateway.call("verify_replay", map_document, replay_document)

func _open_with(method: StringName, arguments: Array) -> Dictionary:
	if _lifecycle != Lifecycle.CLOSED:
		return _failure("session_already_open", "Close the active session before opening another")
	_generation += 1
	_lifecycle = Lifecycle.OPENING
	_stamp = null
	var result: Dictionary = _gateway.callv(method, arguments)
	if result["ok"]:
		_stamp = result["value"]
		_lifecycle = Lifecycle.OPEN
	else:
		_lifecycle = Lifecycle.CLOSED
	return result

func _call_stamp(method: StringName, arguments: Array = []) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	return _track_stamp(_gateway.callv(method, arguments))

func _call_value(method: StringName, arguments: Array = []) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	return _track_value_stamp(_gateway.callv(method, arguments))

func _call_plain(method: StringName, arguments: Array = []) -> Dictionary:
	var precondition := _require_open()
	if not precondition.is_empty():
		return precondition
	return _gateway.callv(method, arguments)

func _require_open() -> Dictionary:
	if _lifecycle == Lifecycle.OPEN:
		return {}
	return _failure("session_not_open", "Open a session before using session operations")

func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}

func _track_stamp(result: Dictionary) -> Dictionary:
	if result["ok"]:
		_stamp = result["value"]
	return result

func _track_value_stamp(result: Dictionary) -> Dictionary:
	if not result["ok"]:
		return result
	var value: RefCounted = result["value"]
	var stamp: Variant = value.get("stamp")
	assert(stamp is AonwClientReadModels.Stamp, "Gateway result must carry a typed stamp")
	_stamp = stamp
	return result
