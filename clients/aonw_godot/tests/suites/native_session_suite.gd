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
const RustLogicalMapWorkbench := preload(
	"res://editor/map_authoring/infrastructure/rust_logical_map_workbench.gd"
)

var _failures: Array[String]

class ForeignVersionTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 4

	func request(_body: Dictionary) -> Dictionary:
		return {
			"apiVersion": 6,
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
		return 7

	func request(_body: Dictionary) -> Dictionary:
		requested = true
		return {}

class MalformedSnapshotTransport:
	extends RefCounted

	func is_available() -> bool:
		return true

	func client_api_version() -> int:
		return 6

	func request(body: Dictionary) -> Dictionary:
		if body.get("type", "") == "openSession":
			return _success({"type": "sessionOpened", "stamp": _stamp(7)})
		return _success({
			"type": "snapshot",
			"snapshot": {
				"stamp": _stamp(99), "turn": 1, "pendingAction": null, "units": "invalid",
			},
		})

	func _success(response: Dictionary) -> Dictionary:
		return {
			"apiVersion": 6,
			"outcome": {"status": "success", "response": response},
		}

	func _stamp(revision: int) -> Dictionary:
		return {
			"revision": revision,
			"stateDigest": "state",
			"mapHash": "map",
			"rulesetHash": "ruleset",
		}

class TrackingTransport:
	extends RefCounted

	var delegate: RefCounted
	var request_types: Array[String] = []

	func _init(value: RefCounted) -> void:
		delegate = value

	func is_available() -> bool:
		return bool(delegate.call("is_available"))

	func client_api_version() -> int:
		return int(delegate.call("client_api_version"))

	func request(body: Dictionary) -> Dictionary:
		request_types.append(str(body.get("type", "")))
		return delegate.call("request", body)

func run(failures: Array[String]) -> void:
	_failures = failures
	_test_strict_document_boundary()
	_test_native_engine_boundary()
	_test_shared_client_contract()
	_test_logical_map_workbench_boundary()

func _test_logical_map_workbench_boundary() -> void:
	var workbench := RustLogicalMapWorkbench.new()
	var spec := JSON.stringify({
		"generatorId": "blank",
		"generatorVersion": 1,
		"mapId": "godot_generated",
		"cols": 5,
		"rows": 5,
		"defaultZoom": 1.0,
		"hexRadiusMeters": 100.0,
		"maxTerrainHeightMeters": 240.0,
		"seed": "42",
	})
	var first := workbench.generate_map(spec)
	var second := workbench.generate_map(spec)
	_check(first["ok"], "Godot workbench generates logical map documents through Rust")
	if not first["ok"]:
		return
	_check(first["package"] == second.get("package"), "Godot workbench generation is deterministic")
	var direct := workbench.generate_blank_map(
		"godot_generated",
		5,
		5,
		1.0,
		100.0,
		240.0,
		"42",
	)
	_check(
		direct["ok"] and direct["package"] == first["package"],
		"Godot New Map fields are encoded as the same strict Rust generation spec",
	)
	var procedural := workbench.generate_new_map(
		&"continental",
		"godot_continent",
		40,
		30,
		1.0,
		100.0,
		240.0,
		"42",
	)
	_check(procedural["ok"], "Godot can select the deterministic Rust procedural generator")
	if procedural["ok"]:
		var procedural_map: Dictionary = JSON.parse_string(
			procedural["package"]["mapDocument"]
		)
		var procedural_decorations: Dictionary = JSON.parse_string(
			procedural["package"]["generatedDecorationPlanDocument"]
		)
		var terrain_names := {}
		var resource_tiles := 0
		for procedural_tile in procedural_map["tiles"]:
			terrain_names[procedural_tile["terrainTags"][0]] = true
			resource_tiles += 1 if not procedural_tile["resources"].is_empty() else 0
		_check(
			terrain_names.size() >= 5
			and resource_tiles >= 20
			and procedural_decorations["placements"].size() >= 100,
			"procedural Rust output contains varied terrain, resources, and decorations",
		)
	var map: Dictionary = JSON.parse_string(first["package"]["mapDocument"])
	var authoring: Dictionary = JSON.parse_string(
		first["package"]["terrainAuthoringDocument"]
	)
	var decorations: Dictionary = JSON.parse_string(
		first["package"]["generatedDecorationPlanDocument"]
	)
	_check(
		map.get("mapName") == "godot_generated"
		and map.get("tiles", []).size() == 25
		and authoring.get("sourceMapContentHash") == first["package"]["mapContentHash"]
		and decorations.get("placements", [null]).is_empty(),
		"Rust owns canonical map, terrain profile and generated-decoration documents",
	)
	var update := workbench.reconfigure_terrain_height(
		first["package"]["mapDocument"],
		first["package"]["terrainAuthoringDocument"],
		180.0,
	)
	_check(update["ok"], "Godot requests map height-scale changes through Rust")
	if update["ok"]:
		var updated_profile: Dictionary = JSON.parse_string(
			update["update"]["terrainAuthoringDocument"]
		)
		_check(
			updated_profile.get("maxTerrainHeightMeters") == 180.0
			and updated_profile.get("hexRadiusMeters") == 100.0,
			"Rust rebuilds height envelopes and preserves the map spatial scale",
		)
	var tile := workbench.inspect_map_tile(
		first["package"]["mapDocument"],
		Vector2i(2, 3),
	)
	_check(
		tile["ok"]
		and tile["snapshot"]["tile"]["displayTerrain"] == "grassland"
		and tile["snapshot"]["terrainOptions"].size() == 14
		and tile["snapshot"]["resourceOptions"].size() == 29,
		"Godot inspects logical tile state and palettes through Rust",
	)
	var terrain_edit := workbench.set_tile_terrain(
		first["package"]["mapDocument"],
		first["package"]["terrainAuthoringDocument"],
		Vector2i(2, 3),
		&"forest",
	)
	_check(
		terrain_edit["ok"]
		and terrain_edit["update"]["snapshot"]["tile"]["displayTerrain"] == "forest"
		and terrain_edit["update"]["mapContentHash"] != first["package"]["mapContentHash"],
		"Godot sends SetTileTerrain to the Rust workbench",
	)
	if terrain_edit["ok"]:
		var resources_edit := workbench.set_tile_resources(
			terrain_edit["update"]["mapDocument"],
			terrain_edit["update"]["terrainAuthoringDocument"],
			Vector2i(2, 3),
			[&"iron", &"wheat"],
		)
		_check(
			resources_edit["ok"]
			and resources_edit["update"]["snapshot"]["tile"]["resources"]
			== ["wheat", "iron"],
			"Godot sends SetTileResources to the Rust workbench",
		)
		if resources_edit["ok"]:
			var height_edit := workbench.set_tile_height(
				resources_edit["update"]["mapDocument"],
				resources_edit["update"]["terrainAuthoringDocument"],
				Vector2i(2, 3),
				5,
			)
			_check(
				height_edit["ok"]
				and height_edit["update"]["snapshot"]["tile"]["height"] == 5,
				"Godot sends SetTileHeight to the Rust workbench",
			)
	var invalid: Dictionary = JSON.parse_string(spec)
	invalid["cols"] = 4
	_check(
		not workbench.generate_map(JSON.stringify(invalid))["ok"],
		"Rust rejects an invalid authored map specification",
	)

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
		feature_first["tiles"][0]["terrainTags"] = []
		_check(
			_inspect_map(JSON.stringify(feature_first)).get("outcome", {}).get("status", "")
			== "failure",
			"tiles require authored terrain tags",
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

	var transport := TrackingTransport.new(NativeLocalSession.new())
	var session := LocalMatchSessionController.new(transport)
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
			snapshot["ok"]
			and snapshot["value"].turn == 1
			and snapshot["value"].units.size() == 1
		and snapshot["value"].units[0].id == "preview-commander"
		and snapshot["value"].units[0].coordinate == Vector2i(2, 1)
		and snapshot["value"].stamp.map_hash == map_view.get("contentHash", ""),
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
	var stale_envelope := transport.request({
		"type": "dispatch",
		"command": {
			"type": "moveUnit",
			"expectedRevision": 0,
			"unitId": "preview-commander",
			"target": {"col": 2, "row": 1},
		},
	})
	var stale_body: Dictionary = stale_envelope.get("outcome", {}).get("response", {})
	var stale_result := ClientReadModelDecoder.decode_command(stale_body.get("result", {}))
	_check(
		stale_result != null
		and not stale_result.accepted
		and stale_result.rejection == &"stale_revision",
		"native Rust rejection maps to the shared Godot rejection code",
	)
	var skipped: Dictionary = session.skip_unit_turn("preview-commander")
	_check(
		skipped["ok"]
		and skipped["value"].accepted
		and skipped["value"].stamp.revision == 2
		and skipped["value"].patch.upserted_units[0].movement_units == 0
		and skipped["value"].patch.pending_action.kind == &"unitTurnSkip",
		"native session skips a unit turn",
	)
	var cancelled: Dictionary = session.cancel_unit_action("preview-commander")
	_check(
		cancelled["ok"]
		and cancelled["value"].accepted
		and cancelled["value"].stamp.revision == 3
		and cancelled["value"].patch.pending_action == null,
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
		verified["ok"] and verified["value"]["entryCount"] == 5,
		"native session verifies replay results in Rust",
	)
	session.close()
	var restored: Dictionary = session.open_save(map_json, saved["value"])
	_check(
		restored["ok"] and restored["value"]["revision"] == 4,
		"native session restores a canonical save",
	)
	_check(
		session.get("_transport") == transport
		and transport.request_types == [
			"openSession",
			"snapshot",
			"query",
			"query",
			"dispatch",
			"dispatch",
			"dispatch",
			"dispatch",
			"dispatch",
			"exportSave",
			"exportReplay",
			"verifyReplay",
			"closeSession",
			"openSave",
		],
		"one Godot session keeps one Rust transport for its complete lifecycle",
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
			and inspect_request["apiVersion"] == 6
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
			and request["apiVersion"] == 6
			and request["request"]["command"]["type"] == "moveUnit",
			"Godot consumes the shared move request contract",
		)

	var response_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/command_result_response.json",
		FileAccess.READ,
	)
	_check(response_file != null, "shared client response golden opens in Godot")
	if response_file != null:
		var decoder := ClientResponseDecoder.new(6)
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
		var rejected_result: Dictionary = body["result"].duplicate(true)
		rejected_result["outcome"] = {"status": "rejected", "code": "stale_revision"}
		rejected_result["events"] = []
		rejected_result["evidence"] = null
		var rejected := ClientReadModelDecoder.decode_command(rejected_result)
		_check(
			rejected != null and rejected.rejection == &"stale_revision",
			"Godot maps a shared command rejection to a validated code",
		)
		rejected_result["outcome"]["code"] = "future_rejection"
		_check(
			ClientReadModelDecoder.decode_command(rejected_result) == null,
			"Godot rejects an unknown command rejection code",
		)
		var invalid_version := decoder.decode(
			'{"apiVersion":"6","outcome":{"status":"success","response":{}}}'
		)
		_check(
			invalid_version.get("outcome", {}).get("status", "") == "failure",
			"Godot rejects coercible client API versions",
		)

	var rejection_codes_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/command_rejection_codes.json",
		FileAccess.READ,
	)
	_check(rejection_codes_file != null, "shared command rejection-code fixture opens in Godot")
	if rejection_codes_file != null:
		var rejection_codes: Dictionary = JSON.parse_string(rejection_codes_file.get_as_text())
		_check(
			rejection_codes.get("codes")
			== Array(ClientReadModelDecoder.COMMAND_REJECTION_CODES),
			"Godot command rejection codes match the shared contract fixture",
		)

	var map_response_file := FileAccess.open(
		"res://../../test/fixtures/client_protocol/map_inspected_response.json",
		FileAccess.READ,
	)
	_check(map_response_file != null, "shared map response golden opens in Godot")
	if map_response_file != null:
		var decoded_map := ClientResponseDecoder.new(6).decode(map_response_file.get_as_text())
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

	var snapshot_stamp := {
		"revision": 0,
		"stateDigest": "b".repeat(64),
		"mapHash": "a".repeat(64),
		"rulesetHash": "c".repeat(64),
	}
	var unit := {
		"id": "unit-a",
		"ownerPlayerId": "player-1",
		"kind": "commander",
		"name": "Commander",
		"coordinate": {"col": 0, "row": 0},
		"movementUnits": 12,
		"posture": "active",
		"workerBuildCharges": 0,
		"workerJob": null,
		"workerAssignment": null,
	}
	var turn_lifecycle := {
		"ownState": "active",
		"ownSubmitted": false,
		"requiredSubmissionCount": 1,
		"submittedCount": 0,
	}
	var decoded_snapshot := ClientReadModelDecoder.decode_snapshot({
		"stamp": snapshot_stamp,
		"turn": 7,
		"turnLifecycle": turn_lifecycle,
		"pendingAction": {
			"type": "workerActionSelection",
			"unitId": "unit-a",
			"improvement": "farm",
		},
		"cityFoundingDraft": null,
		"units": [unit],
		"cities": [],
		"fieldImprovements": [],
		"roads": [],
	})
	_check(
		decoded_snapshot != null
		and decoded_snapshot.turn == 7
		and decoded_snapshot.pending_action.kind == &"workerActionSelection"
		and decoded_snapshot.pending_action.improvement == &"farm"
		and decoded_snapshot.units[0].kind == "commander",
		"Godot maps the complete recipient-safe snapshot",
	)
	_check(
		ClientReadModelDecoder.decode_snapshot({
			"stamp": snapshot_stamp,
			"turn": 7,
			"turnLifecycle": turn_lifecycle,
			"pendingAction": {
				"type": "workerActionSelection",
				"unitId": "unit-a",
				"improvement": "futureImprovement",
			},
			"cityFoundingDraft": null,
			"units": [unit],
			"cities": [],
			"fieldImprovements": [],
			"roads": [],
		}) == null,
		"Godot rejects an unknown pending-action enum value",
	)
	_check(
		ClientReadModelDecoder.decode_snapshot({
			"stamp": snapshot_stamp,
			"turn": 0,
			"turnLifecycle": turn_lifecycle,
			"pendingAction": null,
			"cityFoundingDraft": null,
			"units": [unit],
			"cities": [],
			"fieldImprovements": [],
			"roads": [],
		}) == null,
		"Godot rejects a non-positive authoritative turn",
	)
	var unknown_unit: Dictionary = unit.duplicate(true)
	unknown_unit["kind"] = "futureUnit"
	_check(
		ClientReadModelDecoder.decode_snapshot({
			"stamp": snapshot_stamp,
			"turn": 7,
			"turnLifecycle": turn_lifecycle,
			"pendingAction": null,
			"cityFoundingDraft": null,
			"units": [unknown_unit],
			"cities": [],
			"fieldImprovements": [],
			"roads": [],
		}) == null,
		"Godot rejects unknown unit enum values",
	)
	var second_unit: Dictionary = unit.duplicate(true)
	second_unit["id"] = "unit-b"
	_check(
		ClientReadModelDecoder.decode_snapshot({
			"stamp": snapshot_stamp,
			"turn": 7,
			"turnLifecycle": turn_lifecycle,
			"pendingAction": null,
			"cityFoundingDraft": null,
			"units": [second_unit, unit],
			"cities": [],
			"fieldImprovements": [],
			"roads": [],
		}) == null,
		"Godot rejects an unstable snapshot unit order",
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
