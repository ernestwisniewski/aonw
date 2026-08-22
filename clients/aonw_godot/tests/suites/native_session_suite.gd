extends RefCounted

const MapSource := preload("res://game/application/map/map_source.gd")
const MapViewMapper := preload("res://game/infrastructure/map/map_view_mapper.gd")
const JsonMapRepository := preload("res://game/infrastructure/map/json_map_repository.gd")
const NativeLocalSession := preload("res://game/infrastructure/engine/native_local_session.gd")
const ClientResponseDecoder := preload(
	"res://game/infrastructure/engine/client_response_decoder.gd"
)
const ClientReadModels := preload("res://game/application/session/client_read_models.gd")
const ClientReadModelDecoder := preload(
	"res://game/application/session/client_read_model_decoder.gd"
)
const LocalMatchSessionController := preload(
	"res://game/application/session/local_match_session_controller.gd"
)

var _failures: Array[String]

class ForeignVersionTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 3

	func request(_body: Dictionary) -> Dictionary:
		return {
			"apiVersion": 4,
			"outcome": {
				"status": "success",
				"response": {"type": "capabilities"},
			},
		}

class UnsupportedClientTransport:
	extends RefCounted

	var requested := false

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 4

	func request(_body: Dictionary) -> Dictionary:
		requested = true
		return {}

class MalformedSnapshotTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 3

	func request(body: Dictionary) -> Dictionary:
		if body.get("type", "") == "openSession":
			return _success({"type": "sessionOpened", "stamp": _stamp(7)})
		return _success({
			"type": "snapshot",
			"snapshot": {"stamp": _stamp(99), "units": "invalid"},
		})

	func _success(response: Dictionary) -> Dictionary:
		return {
			"apiVersion": 3,
			"outcome": {"status": "success", "response": response},
		}

	func _stamp(revision: int) -> Dictionary:
		return {
			"behaviorVersion": 1,
			"revision": revision,
			"stateDigest": "state",
			"mapHash": "map",
			"rulesetHash": "ruleset",
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
			var valid_result := _inspect_map(JSON.stringify(valid_map))
			_check(
				valid_result.get("outcome", {}).get("status", "") == "success",
				"lowercase ASCII content identifiers are accepted: %s" % valid_result,
			)
		for invalid_identifier in ["", "Uppercase", "ends_", "żagle"]:
			var invalid_map := fixture.duplicate(true)
			invalid_map["mapName"] = invalid_identifier
			_check(
				_inspect_map(JSON.stringify(invalid_map)).get("outcome", {}).get("status", "")
				== "failure",
				"invalid content identifiers are rejected",
			)
		var feature_first := fixture.duplicate(true)
		feature_first["tiles"][0]["terrains"] = ["forest"]
		_check(
			_inspect_map(JSON.stringify(feature_first)).get("outcome", {}).get("status", "")
			== "failure",
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
	var strict_result := _inspect_map(JSON.stringify(raw))
	_check(
		strict_result.get("outcome", {}).get("status", "") == "failure",
		"strict documents require defaultZoom",
	)

func _test_native_engine_boundary() -> void:
	var client := NativeLocalSession.new()
	_check(client.is_available(), "Rust GDExtension is loaded")
	if not client.is_available():
		return
	var file := FileAccess.open(
		"res://assets/maps/aonw2_starter/map.json",
		FileAccess.READ,
	)
	_check(file != null, "native boundary fixture map opens")
	if file == null:
		return
	var map_json := file.get_as_text()
	var validation := client.request({"type": "inspectMap", "mapDocument": map_json})
	_check(
		validation.get("outcome", {}).get("status", "") == "success",
		"Rust validates the strict map through inspectMap",
	)
	var map_view: Dictionary = validation.get("outcome", {}).get("response", {}).get("map", {})
	_check(
		map_view.get("contentHash", "")
		== "4d5603cc00fa8963a71c23133570f89f43c734598d86579e12e1b1059da8712d",
		"Rust returns the shared logical content hash",
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
	var inspect_request_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/inspect_map_request.json",
		FileAccess.READ,
	)
	_check(inspect_request_file != null, "shared inspectMap request golden opens in Godot")
	if inspect_request_file != null:
		var inspect_request: Variant = JSON.parse_string(inspect_request_file.get_as_text())
		_check(
			inspect_request is Dictionary
			and inspect_request["apiVersion"] == 3
			and inspect_request["request"]["type"] == "inspectMap",
			"Godot consumes the shared inspectMap request contract",
		)

	var request_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/move_unit_request.json",
		FileAccess.READ,
	)
	_check(request_file != null, "shared client request golden opens in Godot")
	if request_file != null:
		var request: Variant = JSON.parse_string(request_file.get_as_text())
		_check(
			request is Dictionary
			and request["apiVersion"] == 3
			and request["request"]["command"]["type"] == "moveUnit",
			"Godot consumes the shared move request contract",
		)

	var response_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/command_result_response.json",
		FileAccess.READ,
	)
	_check(response_file != null, "shared client response golden opens in Godot")
	if response_file != null:
		var decoder := ClientResponseDecoder.new(3)
		var decoded := decoder.decode(response_file.get_as_text())
		_check(
			decoded.get("outcome", {}).get("status", "") == "success",
			"Godot consumes the shared command response contract",
		)
		var body: Dictionary = decoded["outcome"]["response"]
		var command: AonwClientReadModels.CommandResult = (
			ClientReadModelDecoder.decode_command(body.get("result", {}))
		)
		_check(
			command != null
			and command.patch.upserted_units[0].kind == "commander"
			and command.evidence.steps[-1].coordinate == Vector2i(3, 4),
			"Godot maps the shared response into typed client read models",
		)
		var invalid_version := decoder.decode(
			'{"apiVersion":"3","outcome":{"status":"success","response":{}}}'
		)
		_check(
			invalid_version.get("outcome", {}).get("status", "") == "failure",
			"Godot rejects coercible client API versions",
		)

	var map_response_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/map_inspected_response.json",
		FileAccess.READ,
	)
	_check(map_response_file != null, "shared map response golden opens in Godot")
	if map_response_file != null:
		var decoded_map := ClientResponseDecoder.new(3).decode(map_response_file.get_as_text())
		var map_body: Dictionary = decoded_map.get("outcome", {}).get("response", {})
		var mapped := MapViewMapper.new().from_wire(map_body.get("map"))
		_check(
			map_body.get("type", "") == "mapInspected"
			and mapped["ok"]
			and mapped["value"].tile_at(Vector2i.ZERO).display_terrain() == &"forest"
			and mapped["value"].contains(Vector2i.ZERO)
			and not mapped["value"].contains(Vector2i(1, 0)),
			"Godot maps the shared response into its map read model",
		)
		var foreign_map: Dictionary = map_body["map"].duplicate(true)
		foreign_map["tiles"][0]["unknown"] = true
		_check(
			not MapViewMapper.new().from_wire(foreign_map)["ok"],
			"Godot rejects foreign map response fields",
		)
		var duplicate_tiles: Dictionary = map_body["map"].duplicate(true)
		duplicate_tiles["tiles"].append(duplicate_tiles["tiles"][0].duplicate(true))
		_check(
			not MapViewMapper.new().from_wire(duplicate_tiles)["ok"],
			"Godot rejects duplicated map tile coordinates",
		)
		var unknown_terrain: Dictionary = map_body["map"].duplicate(true)
		unknown_terrain["tiles"][0]["displayTerrain"] = "futureTerrain"
		_check(
			not MapViewMapper.new().from_wire(unknown_terrain)["ok"],
			"Godot rejects unknown map enum values",
		)
		var outside_objective: Dictionary = map_body["map"].duplicate(true)
		outside_objective["objectives"][0]["coordinate"]["col"] = 1
		_check(
			not MapViewMapper.new().from_wire(outside_objective)["ok"],
			"Godot rejects objectives outside the validated tile coverage",
		)

	var foreign := LocalMatchSessionController.new(ForeignVersionTransport.new()).capabilities()
	_check(
		not foreign["ok"] and foreign["code"] == "unsupported_client_api",
		"Godot rejects foreign client API responses",
	)

	var unsupported_transport := UnsupportedClientTransport.new()
	var unsupported := LocalMatchSessionController.new(unsupported_transport).capabilities()
	_check(
		not unsupported["ok"]
		and unsupported["code"] == "unsupported_client_api"
		and not unsupported_transport.requested,
		"Godot rejects an incompatible transport before dispatch",
	)

	var malformed_controller := LocalMatchSessionController.new(MalformedSnapshotTransport.new())
	var opened := malformed_controller.open("map", "scenario", "player")
	var malformed := malformed_controller.snapshot()
	_check(
		opened["ok"]
		and not malformed["ok"]
		and malformed_controller.revision() == 7,
		"Godot updates revision only after complete typed response validation",
	)

func _check(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)

func _inspect_map(map_document: String) -> Dictionary:
	return NativeLocalSession.new().request({
		"type": "inspectMap",
		"mapDocument": map_document,
	})
