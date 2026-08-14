class_name AonwNativeLocalSession
extends RefCounted

const CLIENT_API_VERSION := 1

var _session: Object

func _init() -> void:
	if ClassDB.class_exists("AonwLocalSession"):
		_session = ClassDB.instantiate("AonwLocalSession")

func is_available() -> bool:
	return _session != null

func request(body: Dictionary) -> Dictionary:
	if _session == null:
		return _failure(
			"native_engine_unavailable",
			"Build aonw_godot before opening a native session",
		)
	var document := JSON.stringify({
		"apiVersion": CLIENT_API_VERSION,
		"request": body,
	})
	var value: Variant = JSON.parse_string(_session.request_json(document))
	if value is Dictionary:
		return value
	return _failure("invalid_native_response", "Rust session returned invalid JSON")

func _failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": CLIENT_API_VERSION,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}
