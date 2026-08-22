class_name AonwNativeLocalSession
extends RefCounted

const ClientResponseDecoder := preload(
	"res://infrastructure/engine/client_response_decoder.gd"
)
const ClientProtocol := preload("res://application/session/client_protocol.gd")

var _session: Object
var _native_api_version := 0
var _response_decoder: RefCounted

func _init() -> void:
	if ClassDB.class_exists("AonwLocalSession"):
		_session = ClassDB.instantiate("AonwLocalSession")
		_native_api_version = int(_session.client_api_version())
	_response_decoder = ClientResponseDecoder.new(ClientProtocol.API_VERSION)

func is_available() -> bool:
	return _session != null and _native_api_version == ClientProtocol.API_VERSION

func client_api_version() -> int:
	return ClientProtocol.API_VERSION

func request(body: Dictionary) -> Dictionary:
	if _session == null:
		return _failure(
			"native_engine_unavailable",
			"Build aonw_godot before opening a native session",
		)
	if _native_api_version != ClientProtocol.API_VERSION:
		return _failure(
			"unsupported_client_api",
			"The native engine uses an unsupported client API version",
		)
	var document := JSON.stringify({
		"apiVersion": ClientProtocol.API_VERSION,
		"request": body,
	})
	var response: Dictionary = _response_decoder.call(
		"decode",
		_session.request_json(document),
	)
	return response

func _failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": ClientProtocol.API_VERSION,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}
