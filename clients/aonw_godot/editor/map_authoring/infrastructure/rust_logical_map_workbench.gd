class_name AonwRustLogicalMapWorkbench
extends AonwLogicalMapWorkbench

const API_VERSION := 1
const PACKAGE_FIELDS := [
	"mapDocument",
	"terrainAuthoringDocument",
	"generationDocument",
	"generatedDecorationPlanDocument",
	"mapContentHash",
	"authoringProfileHash",
	"generationSpecHash",
	"generatedDecorationPlanHash",
]

var _bridge: RefCounted

func _init(bridge: RefCounted = null) -> void:
	_bridge = bridge if bridge != null else AonwMapWorkbenchBridge.new()

func generate_map(spec_document: String) -> Dictionary:
	var request := JSON.stringify({
		"apiVersion": API_VERSION,
		"request": {
			"type": "generateMap",
			"specDocument": spec_document,
		},
	})
	var parsed: Variant = JSON.parse_string(str(_bridge.request_json(request)))
	if parsed is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench returned invalid JSON")
	var response: Dictionary = parsed
	if response.get("apiVersion") != API_VERSION or response.get("outcome") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench response is incompatible")
	var outcome: Dictionary = response["outcome"]
	if outcome.get("status") == "failure":
		var error: Variant = outcome.get("error")
		if error is not Dictionary:
			return _failure("invalid_workbench_response", "Rust workbench failure is malformed")
		return {
			"ok": false,
			"code": str(error.get("code", "map_generation_failed")),
			"message": str(error.get("message", "map generation failed")),
			"path": str(error.get("path", "")),
		}
	if outcome.get("status") != "success" or outcome.get("response") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench outcome is malformed")
	var body: Dictionary = outcome["response"]
	if body.get("type") != "mapGenerated" or body.get("package") is not Dictionary:
		return _failure("invalid_workbench_response", "Rust workbench result is unsupported")
	var package: Dictionary = body["package"]
	if not _has_exact_string_fields(package, PACKAGE_FIELDS):
		return _failure("invalid_workbench_response", "generated map package is malformed")
	return {"ok": true, "package": package}

func _has_exact_string_fields(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for field in expected:
		if not value.has(field) or value[field] is not String or value[field].is_empty():
			return false
	return true

func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
