class_name AonwClientReadModels
extends RefCounted

class Stamp:
	extends RefCounted
	var behavior_version: int
	var revision: int
	var state_digest: String
	var map_hash: String
	var ruleset_hash: String

class UnitView:
	extends RefCounted
	var id: String
	var owner_player_id: String
	var kind: String
	var display_name: String
	var coordinate: Vector2i
	var movement_units: int
	var posture: String

class MovementStep:
	extends RefCounted
	var coordinate: Vector2i
	var enter_cost_units: int
	var cumulative_cost_units: int

class ReachableTile:
	extends RefCounted
	var coordinate: Vector2i
	var cost_units: int
	var exhausts_movement: bool

class UnitMovedEvent:
	extends RefCounted
	var unit_id: String
	var from: Vector2i
	var to: Vector2i

class SnapshotView:
	extends RefCounted
	var stamp: Stamp
	var units: Array[UnitView]

class ReachableView:
	extends RefCounted
	var stamp: Stamp
	var unit_id: String
	var available_movement_units: int
	var tiles: Array[ReachableTile]

class RoutePlanView:
	extends RefCounted
	var stamp: Stamp
	var unit_id: String
	var target: Vector2i
	var destination: Vector2i
	var total_cost_units: int
	var available_movement_units: int
	var remaining_movement_units: int
	var steps: Array[MovementStep]

class ViewPatch:
	extends RefCounted
	var from_revision: int
	var to_revision: int
	var upserted_units: Array[UnitView]
	var removed_unit_ids: Array[String]

class MovementEvidence:
	extends RefCounted
	var unit_id: String
	var from: Vector2i
	var steps: Array[MovementStep]

class CommandResult:
	extends RefCounted
	var stamp: Stamp
	var accepted: bool
	var rejection: String
	var events: Array[UnitMovedEvent]
	var patch: ViewPatch
	var evidence: MovementEvidence

static func decode_stamp(raw: Variant) -> Stamp:
	if not _has_exact_fields(raw, [
		"behaviorVersion", "revision", "stateDigest", "mapHash", "rulesetHash",
	]):
		return null
	var result := Stamp.new()
	result.behavior_version = int(raw["behaviorVersion"])
	result.revision = int(raw["revision"])
	result.state_digest = str(raw["stateDigest"])
	result.map_hash = str(raw["mapHash"])
	result.ruleset_hash = str(raw["rulesetHash"])
	return result

static func decode_snapshot(raw: Variant) -> SnapshotView:
	if not _has_exact_fields(raw, ["stamp", "units"]) or not raw["units"] is Array:
		return null
	var stamp := decode_stamp(raw["stamp"])
	if stamp == null:
		return null
	var units: Array[UnitView] = []
	for value in raw["units"]:
		var unit := _decode_unit(value)
		if unit == null:
			return null
		units.append(unit)
	units.make_read_only()
	var result := SnapshotView.new()
	result.stamp = stamp
	result.units = units
	return result

static func decode_reachable(raw: Variant) -> ReachableView:
	if not _has_exact_fields(raw, [
		"type", "stamp", "unitId", "availableMovementUnits", "tiles",
	]) or raw["type"] != "reachable" or not raw["tiles"] is Array:
		return null
	var stamp := decode_stamp(raw["stamp"])
	if stamp == null:
		return null
	var tiles: Array[ReachableTile] = []
	for tile in raw["tiles"]:
		if not _has_exact_fields(tile, ["coordinate", "costUnits", "exhaustsMovement"]):
			return null
		var coordinate: Variant = _decode_coordinate(tile["coordinate"])
		if coordinate == null:
			return null
		var tile_view := ReachableTile.new()
		tile_view.coordinate = coordinate
		tile_view.cost_units = int(tile["costUnits"])
		tile_view.exhausts_movement = bool(tile["exhaustsMovement"])
		tiles.append(tile_view)
	tiles.make_read_only()
	var result := ReachableView.new()
	result.stamp = stamp
	result.unit_id = str(raw["unitId"])
	result.available_movement_units = int(raw["availableMovementUnits"])
	result.tiles = tiles
	return result

static func decode_route_plan(raw: Variant) -> RoutePlanView:
	if not _has_exact_fields(raw, [
		"type", "stamp", "unitId", "target", "destination", "totalCostUnits",
		"availableMovementUnits", "remainingMovementUnits", "steps",
	]) or raw["type"] != "routePlan" or not raw["steps"] is Array:
		return null
	var stamp := decode_stamp(raw["stamp"])
	var target: Variant = _decode_coordinate(raw["target"])
	var destination: Variant = _decode_coordinate(raw["destination"])
	if stamp == null or target == null or destination == null:
		return null
	var steps: Variant = _decode_steps(raw["steps"])
	if steps == null:
		return null
	var result := RoutePlanView.new()
	result.stamp = stamp
	result.unit_id = str(raw["unitId"])
	result.target = target
	result.destination = destination
	result.total_cost_units = int(raw["totalCostUnits"])
	result.available_movement_units = int(raw["availableMovementUnits"])
	result.remaining_movement_units = int(raw["remainingMovementUnits"])
	result.steps = steps
	return result

static func decode_command(raw: Variant) -> CommandResult:
	if not _has_exact_fields(raw, [
		"stamp", "accepted", "rejection", "events", "evidence", "viewPatch",
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
	var accepted := bool(raw["accepted"])
	if accepted == (raw["rejection"] != null):
		return null
	var result := CommandResult.new()
	result.stamp = stamp
	result.accepted = accepted
	result.rejection = "" if raw["rejection"] == null else str(raw["rejection"])
	result.events = events
	result.patch = patch
	result.evidence = evidence
	return result

static func _decode_unit(raw: Variant) -> UnitView:
	if not _has_exact_fields(raw, [
		"id", "ownerPlayerId", "kind", "name", "coordinate", "movementUnits", "posture",
	]):
		return null
	var coordinate: Variant = _decode_coordinate(raw["coordinate"])
	if coordinate == null:
		return null
	var result := UnitView.new()
	result.id = str(raw["id"])
	result.owner_player_id = str(raw["ownerPlayerId"])
	result.kind = str(raw["kind"])
	result.display_name = str(raw["name"])
	result.coordinate = coordinate
	result.movement_units = int(raw["movementUnits"])
	result.posture = str(raw["posture"])
	return result

static func _decode_patch(raw: Variant) -> ViewPatch:
	if not _has_exact_fields(raw, [
		"fromRevision", "toRevision", "upsertedUnits", "removedUnitIds",
	]) or not raw["upsertedUnits"] is Array or not raw["removedUnitIds"] is Array:
		return null
	var units: Array[UnitView] = []
	for value in raw["upsertedUnits"]:
		var unit := _decode_unit(value)
		if unit == null:
			return null
		units.append(unit)
	units.make_read_only()
	var removed: Array[String] = []
	for value in raw["removedUnitIds"]:
		removed.append(str(value))
	removed.make_read_only()
	var result := ViewPatch.new()
	result.from_revision = int(raw["fromRevision"])
	result.to_revision = int(raw["toRevision"])
	result.upserted_units = units
	result.removed_unit_ids = removed
	return result

static func _decode_evidence(raw: Variant) -> MovementEvidence:
	if raw == null:
		return null
	if not _has_exact_fields(raw, ["type", "unitId", "from", "steps"]):
		return null
	if raw["type"] != "unitMovement" or not raw["steps"] is Array:
		return null
	var from: Variant = _decode_coordinate(raw["from"])
	var steps: Variant = _decode_steps(raw["steps"])
	if from == null or steps == null:
		return null
	var result := MovementEvidence.new()
	result.unit_id = str(raw["unitId"])
	result.from = from
	result.steps = steps
	return result

static func _decode_steps(raw: Array) -> Variant:
	var steps: Array[MovementStep] = []
	for value in raw:
		if not _has_exact_fields(value, [
			"coordinate", "enterCostUnits", "cumulativeCostUnits",
		]):
			return null
		var coordinate: Variant = _decode_coordinate(value["coordinate"])
		if coordinate == null:
			return null
		var step := MovementStep.new()
		step.coordinate = coordinate
		step.enter_cost_units = int(value["enterCostUnits"])
		step.cumulative_cost_units = int(value["cumulativeCostUnits"])
		steps.append(step)
	steps.make_read_only()
	return steps

static func _decode_events(raw: Array) -> Variant:
	var events: Array[UnitMovedEvent] = []
	for value in raw:
		if not _has_exact_fields(value, ["type", "unitId", "from", "to"]):
			return null
		if value["type"] != "unitMoved":
			return null
		var from: Variant = _decode_coordinate(value["from"])
		var to: Variant = _decode_coordinate(value["to"])
		if from == null or to == null:
			return null
		var event := UnitMovedEvent.new()
		event.unit_id = str(value["unitId"])
		event.from = from
		event.to = to
		events.append(event)
	events.make_read_only()
	return events

static func _decode_coordinate(raw: Variant) -> Variant:
	if not _has_exact_fields(raw, ["col", "row"]):
		return null
	return Vector2i(int(raw["col"]), int(raw["row"]))

static func _has_exact_fields(raw: Variant, fields: Array) -> bool:
	if not raw is Dictionary or raw.size() != fields.size():
		return false
	for field in fields:
		if not raw.has(field):
			return false
	return true
