class_name AonwClientReadModelDecoder
extends RefCounted

const ReadModels := preload("res://game/application/session/client_read_models.gd")
const UNIT_KINDS := [
	"commander", "warrior", "archer", "settler", "worker", "merchant", "scout",
	"spearman", "cavalry", "catapult", "heavyInfantry", "fieldCannon", "rifleman",
	"tank", "scoutShip", "warship", "reconPlane",
]
const UNIT_POSTURES := ["active", "fortified", "autoExploring", "autoWorking"]
const COMMAND_REJECTION_CODES := [
	"stale_revision",
	"unit_not_found",
	"unit_not_controlled",
	"unit_unavailable",
	"unit_uses_trade_routes",
	"unit_out_of_bounds",
	"move_target_out_of_bounds",
	"move_target_is_current_tile",
	"move_target_is_foreign_city_center",
	"move_target_occupied",
	"unit_movement_capacity_insufficient",
	"move_path_not_found",
	"unit_busy",
	"unit_definition_missing",
	"state_revision_overflow",
	"invalid_queued_movement_path",
	"invalid_unit",
	"movement_unit_update_failed",
]

static func decode_stamp(raw: Variant) -> AonwClientReadModels.Stamp:
	if not _has_exact_fields(raw, [
		"behaviorVersion", "revision", "stateDigest", "mapHash", "rulesetHash",
	]):
		return null
	if not _strings(raw, ["stateDigest", "mapHash", "rulesetHash"]):
		return null
	if not _integers(raw, ["behaviorVersion", "revision"], true):
		return null
	var result := ReadModels.Stamp.new()
	result.behavior_version = int(raw["behaviorVersion"])
	result.revision = int(raw["revision"])
	result.state_digest = raw["stateDigest"]
	result.map_hash = raw["mapHash"]
	result.ruleset_hash = raw["rulesetHash"]
	return result

static func decode_snapshot(raw: Variant) -> AonwClientReadModels.SnapshotView:
	if not _has_exact_fields(raw, ["stamp", "turn", "units"]) or not raw["units"] is Array:
		return null
	if not _integers(raw, ["turn"], true) or int(raw["turn"]) < 1:
		return null
	var stamp := decode_stamp(raw["stamp"])
	if stamp == null:
		return null
	var units: Array[AonwClientReadModels.UnitView] = []
	var previous_id := ""
	for value in raw["units"]:
		var unit := _decode_unit(value)
		if unit == null or (not previous_id.is_empty() and unit.id <= previous_id):
			return null
		units.append(unit)
		previous_id = unit.id
	units.make_read_only()
	var result := ReadModels.SnapshotView.new()
	result.stamp = stamp
	result.turn = int(raw["turn"])
	result.units = units
	return result

static func decode_reachable(raw: Variant) -> AonwClientReadModels.ReachableView:
	if not _has_exact_fields(raw, [
		"type", "stamp", "unitId", "availableMovementUnits", "tiles",
	]) or raw["type"] != "reachable" or not raw["tiles"] is Array:
		return null
	if not raw["unitId"] is String or raw["unitId"].is_empty():
		return null
	if not _integers(raw, ["availableMovementUnits"], true):
		return null
	var stamp := decode_stamp(raw["stamp"])
	if stamp == null:
		return null
	var tiles: Array[AonwClientReadModels.ReachableTile] = []
	for tile in raw["tiles"]:
		if not _has_exact_fields(tile, ["coordinate", "costUnits", "exhaustsMovement"]):
			return null
		if not tile["exhaustsMovement"] is bool:
			return null
		if not _integers(tile, ["costUnits"], true):
			return null
		var coordinate: Variant = _decode_coordinate(tile["coordinate"])
		if coordinate == null:
			return null
		var tile_view := ReadModels.ReachableTile.new()
		tile_view.coordinate = coordinate
		tile_view.cost_units = int(tile["costUnits"])
		tile_view.exhausts_movement = tile["exhaustsMovement"]
		tiles.append(tile_view)
	tiles.make_read_only()
	var result := ReadModels.ReachableView.new()
	result.stamp = stamp
	result.unit_id = raw["unitId"]
	result.available_movement_units = int(raw["availableMovementUnits"])
	result.tiles = tiles
	return result

static func decode_route_plan(raw: Variant) -> AonwClientReadModels.RoutePlanView:
	if not _has_exact_fields(raw, [
		"type", "stamp", "unitId", "target", "destination", "totalCostUnits",
		"availableMovementUnits", "remainingMovementUnits", "steps",
	]) or raw["type"] != "routePlan" or not raw["steps"] is Array:
		return null
	if not raw["unitId"] is String or raw["unitId"].is_empty():
		return null
	if not _integers(raw, [
		"totalCostUnits", "availableMovementUnits", "remainingMovementUnits",
	], true):
		return null
	var stamp := decode_stamp(raw["stamp"])
	var target: Variant = _decode_coordinate(raw["target"])
	var destination: Variant = _decode_coordinate(raw["destination"])
	if stamp == null or target == null or destination == null:
		return null
	var steps: Variant = _decode_steps(raw["steps"])
	if (
		steps == null
		or steps.is_empty()
		or steps[0].enter_cost_units != 0
		or steps[0].cumulative_cost_units != 0
		or steps[-1].coordinate != destination
		or steps[-1].cumulative_cost_units != int(raw["totalCostUnits"])
		or int(raw["remainingMovementUnits"]) > int(raw["availableMovementUnits"])
	):
		return null
	var result := ReadModels.RoutePlanView.new()
	result.stamp = stamp
	result.unit_id = raw["unitId"]
	result.target = target
	result.destination = destination
	result.total_cost_units = int(raw["totalCostUnits"])
	result.available_movement_units = int(raw["availableMovementUnits"])
	result.remaining_movement_units = int(raw["remainingMovementUnits"])
	result.steps = steps
	return result

static func decode_command(raw: Variant) -> AonwClientReadModels.CommandResult:
	if not _has_exact_fields(raw, [
		"stamp", "outcome", "events", "evidence", "viewPatch",
	]):
		return null
	var stamp := decode_stamp(raw["stamp"])
	var patch := _decode_patch(raw["viewPatch"])
	if not raw["events"] is Array:
		return null
	var events: Variant = _decode_events(raw["events"])
	var evidence := _decode_evidence(raw["evidence"])
	if stamp == null or patch == null or (raw["evidence"] != null and evidence == null):
		return null
	if events == null:
		return null
	var outcome: Variant = raw["outcome"]
	if not outcome is Dictionary:
		return null
	var accepted := false
	var rejection := &""
	match outcome.get("status", ""):
		"accepted":
			if not _has_exact_fields(outcome, ["status"]):
				return null
			accepted = true
		"rejected":
			if (
				not _has_exact_fields(outcome, ["status", "code"])
				or not outcome["code"] is String
				or not COMMAND_REJECTION_CODES.has(outcome["code"])
			):
				return null
			rejection = StringName(outcome["code"])
		_:
			return null
	var result := ReadModels.CommandResult.new()
	result.stamp = stamp
	result.accepted = accepted
	result.rejection = rejection
	result.events = events
	result.patch = patch
	result.evidence = evidence
	return result

static func _decode_unit(raw: Variant) -> AonwClientReadModels.UnitView:
	if not _has_exact_fields(raw, [
		"id", "ownerPlayerId", "kind", "name", "coordinate", "movementUnits", "posture",
	]):
		return null
	if not _strings(raw, ["id", "ownerPlayerId", "kind", "name", "posture"]):
		return null
	if (
		raw["id"].is_empty()
		or raw["ownerPlayerId"].is_empty()
		or raw["name"].is_empty()
		or not UNIT_KINDS.has(raw["kind"])
		or not UNIT_POSTURES.has(raw["posture"])
	):
		return null
	if not _integers(raw, ["movementUnits"], true):
		return null
	var coordinate: Variant = _decode_coordinate(raw["coordinate"])
	if coordinate == null:
		return null
	var result := ReadModels.UnitView.new()
	result.id = raw["id"]
	result.owner_player_id = raw["ownerPlayerId"]
	result.kind = raw["kind"]
	result.display_name = raw["name"]
	result.coordinate = coordinate
	result.movement_units = int(raw["movementUnits"])
	result.posture = raw["posture"]
	return result

static func _decode_patch(raw: Variant) -> AonwClientReadModels.ViewPatch:
	if not _has_exact_fields(raw, [
		"fromRevision", "toRevision", "upsertedUnits", "removedUnitIds",
	]) or not raw["upsertedUnits"] is Array or not raw["removedUnitIds"] is Array:
		return null
	if not _integers(raw, ["fromRevision", "toRevision"], true):
		return null
	var units: Array[AonwClientReadModels.UnitView] = []
	for value in raw["upsertedUnits"]:
		var unit := _decode_unit(value)
		if unit == null:
			return null
		units.append(unit)
	units.make_read_only()
	var removed: Array[String] = []
	for value in raw["removedUnitIds"]:
		if not value is String:
			return null
		removed.append(value)
	removed.make_read_only()
	var result := ReadModels.ViewPatch.new()
	result.from_revision = int(raw["fromRevision"])
	result.to_revision = int(raw["toRevision"])
	result.upserted_units = units
	result.removed_unit_ids = removed
	return result

static func _decode_evidence(raw: Variant) -> AonwClientReadModels.MovementEvidence:
	if raw == null:
		return null
	if not _has_exact_fields(raw, ["type", "unitId", "from", "steps"]):
		return null
	if raw["type"] != "unitMovement" or not raw["unitId"] is String or not raw["steps"] is Array:
		return null
	var from: Variant = _decode_coordinate(raw["from"])
	var steps: Variant = _decode_steps(raw["steps"])
	if from == null or steps == null:
		return null
	var result := ReadModels.MovementEvidence.new()
	result.unit_id = raw["unitId"]
	result.from = from
	result.steps = steps
	return result

static func _decode_steps(raw: Array) -> Variant:
	var steps: Array[AonwClientReadModels.MovementStep] = []
	for value in raw:
		if not _has_exact_fields(value, [
			"coordinate", "enterCostUnits", "cumulativeCostUnits",
		]):
			return null
		if not _integers(value, ["enterCostUnits", "cumulativeCostUnits"], true):
			return null
		var coordinate: Variant = _decode_coordinate(value["coordinate"])
		if coordinate == null:
			return null
		var step := ReadModels.MovementStep.new()
		step.coordinate = coordinate
		step.enter_cost_units = int(value["enterCostUnits"])
		step.cumulative_cost_units = int(value["cumulativeCostUnits"])
		steps.append(step)
	steps.make_read_only()
	return steps

static func _decode_events(raw: Array) -> Variant:
	var events: Array[AonwClientReadModels.UnitMovedEvent] = []
	for value in raw:
		if not _has_exact_fields(value, ["type", "unitId", "from", "to"]):
			return null
		if value["type"] != "unitMoved" or not value["unitId"] is String:
			return null
		var from: Variant = _decode_coordinate(value["from"])
		var to: Variant = _decode_coordinate(value["to"])
		if from == null or to == null:
			return null
		var event := ReadModels.UnitMovedEvent.new()
		event.unit_id = value["unitId"]
		event.from = from
		event.to = to
		events.append(event)
	events.make_read_only()
	return events

static func _decode_coordinate(raw: Variant) -> Variant:
	if not _has_exact_fields(raw, ["col", "row"]):
		return null
	if not _integers(raw, ["col", "row"], false):
		return null
	return Vector2i(int(raw["col"]), int(raw["row"]))

static func _integers(raw: Dictionary, fields: Array, non_negative: bool) -> bool:
	for field in fields:
		var value: Variant = raw[field]
		if not value is int and not value is float:
			return false
		var integer := int(value)
		if float(integer) != float(value) or (non_negative and integer < 0):
			return false
	return true

static func _strings(raw: Dictionary, fields: Array) -> bool:
	for field in fields:
		if not raw[field] is String:
			return false
	return true

static func _has_exact_fields(raw: Variant, fields: Array) -> bool:
	if not raw is Dictionary or raw.size() != fields.size():
		return false
	for field in fields:
		if not raw.has(field):
			return false
	return true
