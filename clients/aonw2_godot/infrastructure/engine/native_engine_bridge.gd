class_name AonwNativeEngineBridge
extends RefCounted

var _bridge: Object

func _init() -> void:
	if ClassDB.class_exists("AonwEngineBridge"):
		_bridge = ClassDB.instantiate("AonwEngineBridge")

func is_available() -> bool:
	return _bridge != null

func validate_map_json(source: String, legacy: bool) -> Dictionary:
	if _bridge == null:
		return {"ok": true, "native": false}
	var result: Variant = JSON.parse_string(_bridge.validate_map_json(source, legacy))
	if not result is Dictionary:
		return {
			"ok": false,
			"code": "invalid_native_response",
			"message": "Rust map validator returned invalid JSON",
		}
	result["native"] = true
	return result
