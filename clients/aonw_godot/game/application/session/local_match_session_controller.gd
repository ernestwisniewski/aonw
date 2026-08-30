class_name AonwLocalMatchSessionController
extends RefCounted

var _gateway: RefCounted
var _stamp: AonwClientReadModels.Stamp

func _init(gateway: RefCounted) -> void:
	assert(gateway != null, "Local match gateway port is required")
	_gateway = gateway

func is_available() -> bool:
	return bool(_gateway.call("is_available"))

func revision() -> int:
	return 0 if _stamp == null else _stamp.revision

func capabilities() -> Dictionary:
	return _gateway.call("capabilities")

func open(map_document: String, scenario_document: String, actor_player_id: String) -> Dictionary:
	return _track_stamp(_gateway.call(
		"open_session",
		map_document,
		scenario_document,
		actor_player_id,
	))

func start_match(
	map_document: String,
	scenario_document: String,
	actor_player_id: String,
	match_identity: Dictionary,
	fog_enabled: bool,
) -> Dictionary:
	return _track_stamp(_gateway.call(
		"start_match",
		map_document,
		scenario_document,
		actor_player_id,
		match_identity,
		fog_enabled,
	))

func handoff_actor(actor_player_id: String) -> Dictionary:
	return _track_stamp(_gateway.call("handoff_actor", actor_player_id))

func advance_ai_turn(actor_player_id: String, command_budget: int) -> Dictionary:
	return _track_value_stamp(_gateway.call(
		"advance_ai_turn",
		actor_player_id,
		command_budget,
	))

func advance_ai_turn_async(actor_player_id: String, command_budget: int) -> Dictionary:
	var result: Dictionary = await _gateway.call(
		"advance_ai_turn_async",
		actor_player_id,
		command_budget,
	)
	return _track_value_stamp(result)

func close() -> Dictionary:
	var result: Dictionary = _gateway.call("close_session")
	if result["ok"]:
		_stamp = null
	return result

func snapshot() -> Dictionary:
	return _track_value_stamp(_gateway.call("snapshot"))

func reachable(unit_id: String) -> Dictionary:
	return _track_value_stamp(_gateway.call("reachable", revision(), unit_id))

func route_plan(unit_id: String, target: Vector2i) -> Dictionary:
	return _track_value_stamp(_gateway.call("route_plan", revision(), unit_id, target))

func move_unit(unit_id: String, target: Vector2i) -> Dictionary:
	return _track_value_stamp(_gateway.call("move_unit", revision(), unit_id, target))

func cancel_unit_action(unit_id: String) -> Dictionary:
	return _track_value_stamp(_gateway.call(
		"cancel_unit_action",
		revision(),
		unit_id,
	))

func skip_unit_turn(unit_id: String) -> Dictionary:
	return _track_value_stamp(_gateway.call("skip_unit_turn", revision(), unit_id))

func fortify_unit(unit_id: String) -> Dictionary:
	return _track_value_stamp(_gateway.call("fortify_unit", revision(), unit_id))

func end_turn() -> Dictionary:
	return _track_value_stamp(_gateway.call("end_turn", revision()))

func save_game() -> Dictionary:
	return _gateway.call("save_game")

func open_save(map_document: String, save_document: String) -> Dictionary:
	return _track_stamp(_gateway.call("open_save", map_document, save_document))

func replay_log() -> Dictionary:
	return _gateway.call("replay_log")

func verify_replay(map_document: String, replay_document: String) -> Dictionary:
	return _gateway.call("verify_replay", map_document, replay_document)

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
