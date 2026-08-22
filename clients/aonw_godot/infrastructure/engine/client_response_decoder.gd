class_name AonwClientResponseDecoder
extends RefCounted

var _api_version: int

func _init(api_version: int) -> void:
	_api_version = api_version

func decode(document: String) -> Dictionary:
	var value: Variant = JSON.parse_string(document)
	if not value is Dictionary or not _has_exact_fields(value, ["apiVersion", "outcome"]):
		return _failure("invalid_native_response", "Rust session returned invalid JSON")
	if not _matches_api_version(value["apiVersion"]):
		return _failure(
			"unsupported_client_api",
			"Rust session returned an unsupported client API version",
		)
	var outcome: Variant = value.get("outcome")
	if not outcome is Dictionary:
		return _failure("invalid_native_response", "Rust session returned an invalid envelope")
	match outcome.get("status", ""):
		"success":
			if not _has_exact_fields(outcome, ["status", "response"]):
				return _failure("invalid_native_response", "Rust session returned an invalid envelope")
		"failure":
			if not _has_exact_fields(outcome, ["status", "error"]):
				return _failure("invalid_native_response", "Rust session returned an invalid envelope")
		_:
			return _failure("invalid_native_response", "Rust session returned an invalid envelope")
	return value

func _matches_api_version(value: Variant) -> bool:
	if not value is int and not value is float:
		return false
	return float(value) == float(_api_version)

func _has_exact_fields(value: Dictionary, fields: Array) -> bool:
	if value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

func _failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": _api_version,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}
