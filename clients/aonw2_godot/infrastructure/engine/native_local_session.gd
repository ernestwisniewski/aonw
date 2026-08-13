class_name AonwNativeLocalSession
extends RefCounted

var _session: Object

func _init() -> void:
	if ClassDB.class_exists("AonwLocalSession"):
		_session = ClassDB.instantiate("AonwLocalSession")

func is_available() -> bool:
	return _session != null

func open(
	map_json: String,
	movement_state: Dictionary,
	actor_player_id: String,
	visibility_mode: String,
	known_unit_ids: Array[String],
) -> Dictionary:
	if _session == null:
		return _unavailable()
	var known_json := "" if visibility_mode == "unrestricted" else JSON.stringify(known_unit_ids)
	return _decode(_session.open(
		map_json,
		JSON.stringify(movement_state),
		actor_player_id,
		visibility_mode,
		known_json,
	))

func reachable(unit_id: String, expected_revision: int) -> Dictionary:
	if _session == null:
		return _unavailable()
	return _decode(_session.reachable_json(unit_id, expected_revision))

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
