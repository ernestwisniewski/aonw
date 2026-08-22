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
