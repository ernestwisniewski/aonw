class_name AonwNativeEngineBridge
extends RefCounted

func is_available() -> bool:
	return ClassDB.class_exists("AonwEngineBridge")

func validate_map_json(source: String) -> Dictionary:
	var bridge: Object = ClassDB.instantiate("AonwEngineBridge") if is_available() else null
	if bridge == null:
		return {
			"ok": false,
			"code": "native_engine_unavailable",
			"message": "Rust map validator is unavailable",
		}
	var response: Variant = bridge.call("validate_map_json", source)
	if not response is String:
		return {
			"ok": false,
			"code": "invalid_native_response",
			"message": "Rust map validator returned a non-string response",
		}
	var result: Variant = JSON.parse_string(response)
	if not result is Dictionary:
		return {
			"ok": false,
			"code": "invalid_native_response",
			"message": "Rust map validator returned invalid JSON",
		}
	result["native"] = true
	return result
