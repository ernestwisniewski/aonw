class_name AonwClientResponseDecoder
extends RefCounted

var _api_version: int

func _init(api_version: int) -> void:
	_api_version = api_version

func decode(document: String) -> Dictionary:
	var value: Variant = JSON.parse_string(document)
	if not value is Dictionary:
		return _failure("invalid_native_response", "Rust session returned invalid JSON")
	if int(value.get("apiVersion", -1)) != _api_version:
		return _failure(
			"unsupported_client_api",
			"Rust session returned an unsupported client API version",
		)
	var outcome: Variant = value.get("outcome")
	if not outcome is Dictionary:
		return _failure("invalid_native_response", "Rust session returned an invalid envelope")
	return value

func _failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": _api_version,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}
