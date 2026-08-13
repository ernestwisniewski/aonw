class_name AonwNativeLocalSession
extends RefCounted

var _session: Object

func _init() -> void:
	if ClassDB.class_exists("AonwLocalSession"):
		_session = ClassDB.instantiate("AonwLocalSession")

func is_available() -> bool:
	return _session != null

func capabilities() -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.capabilities_json())

func open(map_json: String, scenario_json: String, actor_player_id: String) -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.open(map_json, scenario_json, actor_player_id))

func close() -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.close())

func snapshot() -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.snapshot_json())

func reachable(unit_id: String, expected_revision: int) -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.reachable_json(unit_id, expected_revision))

func route_plan(
	unit_id: String,
	target: Vector2i,
	expected_revision: int,
) -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.route_plan_json(
		unit_id,
		target.x,
		target.y,
		expected_revision,
	))

func move_unit(
	unit_id: String,
	target: Vector2i,
	expected_revision: int,
) -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.move_unit_json(
		unit_id,
		target.x,
		target.y,
		expected_revision,
	))

func _decode(response: String) -> Dictionary:
	var value: Variant = JSON.parse_string(response)
	if value is Dictionary:
		return value
	return {
		"ok": false,
		"code": "invalid_native_response",
		"message": "Rust session returned invalid JSON",
	}

func _unavailable() -> Dictionary:
	return {
		"ok": false,
		"code": "native_engine_unavailable",
		"message": "Build aonw_godot before opening a native session",
	}
