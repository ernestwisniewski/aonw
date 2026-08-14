class_name AonwNativeLocalSession
extends RefCounted

const ClientResponseDecoder := preload(
	"res://infrastructure/engine/client_response_decoder.gd"
)

var _session: Object
var _api_version := 0
var _response_decoder: RefCounted

func _init() -> void:
	if ClassDB.class_exists("AonwLocalSession"):
		_session = ClassDB.instantiate("AonwLocalSession")
		_api_version = int(_session.client_api_version())
		_response_decoder = ClientResponseDecoder.new(_api_version)

func is_available() -> bool:
	return _session != null and _api_version > 0

func client_api_version() -> int:
	return _api_version

func request(body: Dictionary) -> Dictionary:
	if _session == null:
		return _failure(
			"native_engine_unavailable",
			"Build aonw_godot before opening a native session",
		)
	var document := JSON.stringify({
		"apiVersion": _api_version,
		"request": body,
	})
	var response: Dictionary = _response_decoder.call(
		"decode",
		_session.request_json(document),
	)
	return response

func _failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": _api_version,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}
