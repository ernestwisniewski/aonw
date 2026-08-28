class_name AonwNativeLocalSession
extends RefCounted

const ClientResponseDecoder := preload(
	"res://game/infrastructure/engine/client_response_decoder.gd"
)
const ClientProtocol := preload("res://game/application/session/client_protocol.gd")

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
	var precondition := _request_precondition()
	if not precondition.is_empty():
		return precondition
	var document := _request_document(body)
	var response: Dictionary = _response_decoder.call(
		"decode",
		_session.request_json(document),
	)
	return response

## Executes engine work on its serial native worker without blocking Godot's main thread.
## Callers must use `await session.request_async(body)`.
func request_async(body: Dictionary) -> Dictionary:
	var precondition := _request_precondition()
	if not precondition.is_empty():
		return precondition
	var job_id := int(_session.request_json_async(_request_document(body)))
	if job_id < 0:
		return _failure("engine_worker_unavailable", "The native engine worker is unavailable")
	while not bool(_session.is_response_ready(job_id)):
		await Engine.get_main_loop().process_frame
	var response_json := str(_session.poll_response_json(job_id))
	if response_json.is_empty():
		return _failure("engine_worker_unavailable", "The native engine response was lost")
	return _response_decoder.call("decode", response_json)

func _request_precondition() -> Dictionary:
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
	return {}

func _request_document(body: Dictionary) -> String:
	return JSON.stringify({
		"apiVersion": ClientProtocol.API_VERSION,
		"request": body,
	})

func _failure(code: String, message: String) -> Dictionary:
	return {
		"apiVersion": ClientProtocol.API_VERSION,
		"outcome": {
			"status": "failure",
			"error": {"code": code, "message": message},
		},
	}
