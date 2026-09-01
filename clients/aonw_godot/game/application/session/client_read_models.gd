class_name AonwClientReadModels
extends RefCounted

class Stamp:
	extends RefCounted
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
	var worker_build_charges: int
	var worker_job: WorkerJobView
	var has_worker_assignment: bool
	var worker_assignment: Vector2i

class WorkerJobView:
	extends RefCounted
	var kind: StringName
	var target: Vector2i
	var improvement: StringName
	var remaining_turns: int
	var total_turns: int

class TurnLifecycleView:
	extends RefCounted
	var has_own_state: bool
	var own_state: StringName
	var own_submitted: bool
	var required_submission_count: int
	var submitted_count: int

class CityFoundingDraftView:
	extends RefCounted
	var founder_unit_id: String
	var center: Vector2i
	var controlled_hexes: Array[Vector2i]

class OwnedCityPlanningView:
	extends RefCounted
	var population: int
	var worked_hexes: Array[Vector2i]
	var has_preferred_expansion_hex: bool
	var preferred_expansion_hex: Vector2i

class CityView:
	extends RefCounted
	var id: String
	var owner_player_id: String
	var display_name: String
	var center: Vector2i
	var visible_controlled_hexes: Array[Vector2i]
	var owned_planning: OwnedCityPlanningView

class FieldImprovementView:
	extends RefCounted
	var coordinate: Vector2i
	var improvement: StringName

class RoadView:
	extends RefCounted
	var coordinate: Vector2i
	var condition: StringName

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

class PendingActionView:
	extends RefCounted
	var kind: StringName
	var city_id: String
	var unit_id: String
	var improvement: StringName
	var restore_movement_units: int
	var has_defender: bool
	var defender: Vector2i

class SnapshotView:
	extends RefCounted
	var stamp: Stamp
	var turn: int
	var turn_lifecycle: TurnLifecycleView
	var pending_action: PendingActionView
	var city_founding_draft: CityFoundingDraftView
	var units: Array[UnitView]
	var cities: Array[CityView]
	var field_improvements: Array[FieldImprovementView]
	var roads: Array[RoadView]

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
	var turn_lifecycle: TurnLifecycleView
	var upserted_units: Array[UnitView]
	var removed_unit_ids: Array[String]
	var upserted_cities: Array[CityView]
	var removed_city_ids: Array[String]
	var upserted_field_improvements: Array[FieldImprovementView]
	var removed_field_improvement_coordinates: Array[Vector2i]
	var upserted_roads: Array[RoadView]
	var removed_road_coordinates: Array[Vector2i]
	var pending_action: PendingActionView
	var city_founding_draft: CityFoundingDraftView

class MovementEvidence:
	extends RefCounted
	var unit_id: String
	var from: Vector2i
	var steps: Array[MovementStep]

class CommandResult:
	extends RefCounted
	var stamp: Stamp
	var accepted: bool
	var rejection: StringName
	var events: Array[UnitMovedEvent]
	var patch: ViewPatch
	var evidence: MovementEvidence
