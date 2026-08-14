extends RefCounted

const MapSource := preload("res://application/map/map_source.gd")
const JsonMapRepository := preload("res://infrastructure/map/json_map_repository.gd")
const NativeEngineBridge := preload("res://infrastructure/engine/native_engine_bridge.gd")
const ClientResponseDecoder := preload(
	"res://infrastructure/engine/client_response_decoder.gd"
)
const ClientReadModels := preload("res://application/session/client_read_models.gd")
const LocalMatchSessionController := preload(
	"res://application/session/local_match_session_controller.gd"
)

var _failures: Array[String]

class ForeignVersionTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 1

	func request(_body: Dictionary) -> Dictionary:
		return {
			"apiVersion": 2,
			"outcome": {
				"status": "success",
				"response": {"type": "capabilities"},
			},
		}

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_strict_document_boundary()
	_test_native_engine_boundary()
	_test_shared_client_contract()

func _test_strict_document_boundary() -> void:
	var file := FileAccess.open(
		"res://assets/maps/aonw2_starter/map.json",
		FileAccess.READ,
	)
	_check(file != null, "content identifier fixture map opens")
	if file != null:
		var fixture: Dictionary = JSON.parse_string(file.get_as_text())
		for valid_identifier in ["a", "a_b-1", "aonw2_starter"]:
			var valid_map := fixture.duplicate(true)
			valid_map["mapName"] = valid_identifier
			var valid_result := NativeEngineBridge.new().validate_map_json(
				JSON.stringify(valid_map)
			)
			_check(
				valid_result["ok"],
				"lowercase ASCII content identifiers are accepted: %s" % valid_result,
			)
		for invalid_identifier in ["", "Uppercase", "ends_", "żagle"]:
			var invalid_map := fixture.duplicate(true)
			invalid_map["mapName"] = invalid_identifier
			_check(
				not NativeEngineBridge.new().validate_map_json(JSON.stringify(invalid_map))["ok"],
				"invalid content identifiers are rejected",
			)
		var feature_first := fixture.duplicate(true)
		feature_first["tiles"][0]["terrains"] = ["forest"]
		_check(
			not NativeEngineBridge.new().validate_map_json(JSON.stringify(feature_first))["ok"],
			"tiles require an explicit primary terrain",
		)
		var mismatched_source := MapSource.new(
			"wrong_map_id",
			"res://assets/maps/aonw2_starter/map.json",
			"res://assets/maps/aonw2_starter",
			"test",
		)
		_check(
			not JsonMapRepository.new().load_map(mismatched_source)["ok"],
			"source directory id must match mapName",
		)
	var raw := {
		"schemaVersion": 1,
		"gridLayout": "oddQFlatTop",
		"cols": 5,
		"rows": 5,
		"mapName": "strict_test",
		"objectives": [],
		"tiles": [],
	}
	var strict_result := NativeEngineBridge.new().validate_map_json(JSON.stringify(raw))
	_check(not strict_result["ok"], "strict documents require defaultZoom")

func _test_native_engine_boundary() -> void:
	var bridge := NativeEngineBridge.new()
	_check(bridge.is_available(), "Rust GDExtension is loaded")
	if not bridge.is_available():
		return
	var file := FileAccess.open(
		"res://assets/maps/aonw2_starter/map.json",
		FileAccess.READ,
	)
	_check(file != null, "native boundary fixture map opens")
	if file == null:
		return
	var map_json := file.get_as_text()
	var validation := bridge.validate_map_json(map_json)
	_check(validation["ok"] and validation["native"], "Rust validates the strict map")
	_check(
		validation.get("value", {}).get("contentHash", "").length() == 64,
		"Rust returns the logical content hash",
	)

	var session := LocalMatchSessionController.new()
	_check(session.is_available(), "native local session is registered")
	if not session.is_available():
		return
	var scenario_file := FileAccess.open(
		"res://assets/scenarios/aonw2_starter.json",
		FileAccess.READ,
	)
	_check(scenario_file != null, "native boundary scenario opens")
	if scenario_file == null:
		return
	var opened: Dictionary = session.open(
		map_json,
		scenario_file.get_as_text(),
		"preview-player",
	)
	_check(opened["ok"], "native local scenario session opens")
	var snapshot: Dictionary = session.snapshot()
	_check(
		snapshot["ok"] and snapshot["value"].units.size() == 1,
		"native snapshot owns the scenario unit view",
	)
	var reachable: Dictionary = session.reachable("preview-commander")
	_check(
		reachable["ok"] and not reachable["value"].tiles.is_empty(),
		"native session returns reachable hexes",
	)
	var route: Dictionary = session.route_plan("preview-commander", Vector2i(2, 2))
	_check(route["ok"] and route["value"].steps.size() > 1, "native route is planned")
	var moved: Dictionary = session.move_unit("preview-commander", Vector2i(2, 2))
	_check(
		moved["ok"]
		and moved["value"].accepted
		and moved["value"].stamp.revision == 1
		and moved["value"].evidence.steps[-1].coordinate.y == 2,
		"native session applies a revision-bound move",
	)
	var skipped: Dictionary = session.skip_unit_turn("preview-commander")
	_check(
		skipped["ok"]
		and skipped["value"].accepted
		and skipped["value"].stamp.revision == 2
		and skipped["value"].patch.upserted_units[0].movement_units == 0,
		"native session skips a unit turn",
	)
	var cancelled: Dictionary = session.cancel_unit_action("preview-commander")
	_check(
		cancelled["ok"]
		and cancelled["value"].accepted
		and cancelled["value"].stamp.revision == 3,
		"native session cancels a unit action",
	)
	var fortified: Dictionary = session.fortify_unit("preview-commander")
	_check(
		fortified["ok"]
		and fortified["value"].accepted
		and fortified["value"].stamp.revision == 4
		and fortified["value"].patch.upserted_units[0].posture == "fortified",
		"native session fortifies an idle unit",
	)
	var saved: Dictionary = session.save_game()
	_check(
		saved["ok"] and not saved["value"].is_empty(),
		"native session exports a canonical save",
	)
	var replay: Dictionary = session.replay_log()
	_check(
		replay["ok"] and not replay["value"].is_empty(),
		"native session exports a deterministic replay",
	)
	var verified: Dictionary = session.verify_replay(map_json, replay["value"])
	_check(
		verified["ok"] and verified["value"]["entryCount"] == 4,
		"native session verifies replay results in Rust",
	)
	session.close()
	var restored: Dictionary = session.open_save(map_json, saved["value"])
	_check(
		restored["ok"] and restored["value"]["revision"] == 4,
		"native session restores a canonical save",
	)

func _test_shared_client_contract() -> void:
	var request_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/move_unit_request.json",
		FileAccess.READ,
	)
	_check(request_file != null, "shared client request golden opens in Godot")
	if request_file != null:
		var request: Variant = JSON.parse_string(request_file.get_as_text())
		_check(
			request is Dictionary
			and request["apiVersion"] == 1
			and request["request"]["command"]["type"] == "moveUnit",
			"Godot consumes the shared move request contract",
		)

	var response_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/command_result_response.json",
		FileAccess.READ,
	)
	_check(response_file != null, "shared client response golden opens in Godot")
	if response_file != null:
		var decoded := ClientResponseDecoder.new(1).decode(response_file.get_as_text())
		_check(
			decoded.get("outcome", {}).get("status", "") == "success",
			"Godot consumes the shared command response contract",
		)
		var body: Dictionary = decoded["outcome"]["response"]
		var command: AonwClientReadModels.CommandResult = (
			ClientReadModels.decode_command(body.get("result", {}))
		)
		_check(
			command != null
			and command.patch.upserted_units[0].kind == "commander"
			and command.evidence.steps[-1].coordinate == Vector2i(3, 4),
			"Godot maps the shared response into typed client read models",
		)

	var foreign := LocalMatchSessionController.new(ForeignVersionTransport.new()).capabilities()
	_check(
		not foreign["ok"] and foreign["code"] == "unsupported_client_api",
		"Godot rejects foreign client API responses",
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
