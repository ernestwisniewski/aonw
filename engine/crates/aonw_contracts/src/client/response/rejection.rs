use serde::{Deserialize, Serialize};

/// Closed set of stable authoritative command rejection codes.
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ClientCommandRejectionCodeDto {
    /// Command was planned against another canonical revision.
    StaleRevision,
    /// The requested unit does not exist.
    UnitNotFound,
    /// The actor cannot command the requested unit.
    UnitNotControlled,
    /// Current activity prevents manual movement.
    UnitUnavailable,
    /// The unit is controlled by the trade-route subsystem.
    UnitUsesTradeRoutes,
    /// The canonical unit position is outside the map.
    UnitOutOfBounds,
    /// The movement target is outside the map.
    MoveTargetOutOfBounds,
    /// The movement target equals the current unit position.
    MoveTargetIsCurrentTile,
    /// A known foreign city blocks the target.
    MoveTargetIsForeignCityCenter,
    /// A known foreign unit blocks the target.
    MoveTargetOccupied,
    /// The unit cannot pay the minimum movement cost.
    UnitMovementCapacityInsufficient,
    /// No valid route reaches the target.
    MovePathNotFound,
    /// Auto-exploration requires a scout.
    UnitNotScout,
    /// The unit has no movement left for auto-exploration.
    UnitExhausted,
    /// Auto-exploration cannot replace an existing queued path.
    UnitHasPath,
    /// No deterministic exploration target remains.
    AutoExploreNoTarget,
    /// Merchant routing requires a merchant unit.
    UnitNotMerchant,
    /// A cyclic route can only start in an owned city center.
    MerchantNotInCity,
    /// The requested destination city does not exist.
    DestinationCityNotFound,
    /// The requested destination city is not controlled by the actor.
    DestinationCityNotControlled,
    /// A cyclic merchant destination equals its origin.
    DestinationCityIsOrigin,
    /// Explicit merchant travel already starts in the destination city.
    DestinationCityIsCurrent,
    /// No cyclic merchant route reaches the destination.
    MerchantRouteNotFound,
    /// No explicit merchant path reaches the destination city.
    MerchantCityPathNotFound,
    /// The requested troop is absent from the source army.
    TroopNotAvailable,
    /// The detachment source is outside immutable map content.
    DetachmentSourceOutOfBounds,
    /// No legal detachment destination exists.
    DetachmentDestinationUnavailable,
    /// No bounded canonical detached-unit identifier is available.
    DetachedUnitIdUnavailable,
    /// The unit has an activity that prevents the requested action.
    UnitBusy,
    /// The ruleset lacks the requested unit definition.
    UnitDefinitionMissing,
    /// The next canonical revision cannot be represented.
    StateRevisionOverflow,
    /// A queued movement path violates its invariants.
    InvalidQueuedMovementPath,
    /// An engine-produced unit violates its invariants.
    InvalidUnit,
    /// The validated movement unit disappeared during transition construction.
    MovementUnitUpdateFailed,
    /// Player payload identity conflicts with authenticated actor identity.
    TurnPlayerNotControlled,
    /// Participant cannot act in the current turn scope.
    TurnPlayerNotActive,
    /// Trusted lifecycle scope is invalid.
    TurnScopeInvalid,
    /// A later turn processor was requested from the partial kernel.
    TurnProcessorUnsupported,
    /// The next turn number cannot be represented.
    TurnNumberOverflow,
    /// The requested attacking unit does not exist.
    AttackerNotFound,
    /// The actor cannot command the requested attacker.
    AttackerNotControlled,
    /// Current activity prevents the attacker from acting.
    AttackerUnavailable,
    /// The attacker has no movement remaining.
    AttackerExhausted,
    /// The attacker position is outside the map.
    AttackerOutOfBounds,
    /// The attacker has no positive attack strength.
    AttackerCannotAttack,
    /// The target is not visible.
    AttackTargetNotVisible,
    /// The target coordinate is outside the map.
    AttackTargetOutOfBounds,
    /// No target occupies the coordinate.
    AttackTargetNotFound,
    /// The target belongs to the actor.
    AttackTargetNotEnemy,
    /// A treaty protects the target.
    AttackTargetProtectedByTreaty,
    /// The target exceeds attack range.
    AttackTargetOutOfRange,
    /// The target city has no health.
    AttackCityHasNoHealth,
    /// The requested city founder does not exist.
    CityFounderNotFound,
    /// The actor cannot command the requested founder.
    CityFounderNotControlled,
    /// The founder is already performing work.
    CityFounderBusy,
    /// The unit cannot found cities.
    CityFounderInvalid,
    /// A commander has no settler troop.
    CityFounderNoSettlers,
    /// The center tile cannot host a city.
    CitySiteInvalid,
    /// Another city occupies the center.
    CityCenterOccupied,
    /// Another city controls the center.
    CityCenterClaimed,
    /// The center is too close to another city.
    CityCenterTooClose,
    /// Initial territory is invalid.
    CityControlledHexesInvalid,
    /// The requested city does not exist.
    CityNotFound,
    /// The actor cannot manage the city.
    CityNotControlled,
    /// The requested worked hex is unavailable.
    WorkedHexUnavailable,
    /// The manual worked-hex limit was reached.
    WorkedHexLimitReached,
    /// The expansion coordinate is unavailable.
    CityExpansionHexUnavailable,
    /// The requested worker does not exist or is not a worker.
    WorkerNotFound,
    /// The actor cannot command the requested worker.
    WorkerNotControlled,
    /// Current activity prevents automation.
    WorkerUnavailable,
    /// The worker has no movement remaining.
    WorkerNoMovementPoints,
    /// A queued path prevents starting automation.
    WorkerQueuedPathActive,
    /// No improvement was supplied or pending.
    WorkerImprovementNotSelected,
    /// A pending action belongs to another actor.
    WorkerActionNotControlled,
    /// The requested improvement is unavailable.
    WorkerImprovementUnavailable,
    /// No worker job is active.
    WorkerJobNotActive,
    /// The current assignment is unavailable.
    WorkerAssignmentUnavailable,
    /// No worker assignment is active.
    WorkerAssignmentNotActive,
    /// Generic road readiness failure.
    WorkerRoadUnavailable,
    /// A road already occupies the coordinate.
    #[serde(rename = "road_construction_existingRoad")]
    RoadConstructionExistingRoad,
    /// A city occupies the coordinate.
    RoadConstructionCity,
    /// Diplomacy policy forbids construction.
    #[serde(rename = "road_construction_enemyTerritory")]
    RoadConstructionEnemyTerritory,
    /// Land movement cannot enter the coordinate.
    #[serde(rename = "road_construction_impassableTerrain")]
    RoadConstructionImpassableTerrain,
    /// Worker automation is not active.
    WorkerAutomationNotActive,
    /// No deterministic worker target exists.
    WorkerAutomationNoTarget,
}

impl ClientCommandRejectionCodeDto {
    /// Every code supported by the current client protocol.
    pub const ALL: [Self; 85] = [
        Self::StaleRevision,
        Self::UnitNotFound,
        Self::UnitNotControlled,
        Self::UnitUnavailable,
        Self::UnitUsesTradeRoutes,
        Self::UnitOutOfBounds,
        Self::MoveTargetOutOfBounds,
        Self::MoveTargetIsCurrentTile,
        Self::MoveTargetIsForeignCityCenter,
        Self::MoveTargetOccupied,
        Self::UnitMovementCapacityInsufficient,
        Self::MovePathNotFound,
        Self::UnitNotScout,
        Self::UnitExhausted,
        Self::UnitHasPath,
        Self::AutoExploreNoTarget,
        Self::UnitNotMerchant,
        Self::MerchantNotInCity,
        Self::DestinationCityNotFound,
        Self::DestinationCityNotControlled,
        Self::DestinationCityIsOrigin,
        Self::DestinationCityIsCurrent,
        Self::MerchantRouteNotFound,
        Self::MerchantCityPathNotFound,
        Self::TroopNotAvailable,
        Self::DetachmentSourceOutOfBounds,
        Self::DetachmentDestinationUnavailable,
        Self::DetachedUnitIdUnavailable,
        Self::UnitBusy,
        Self::UnitDefinitionMissing,
        Self::StateRevisionOverflow,
        Self::InvalidQueuedMovementPath,
        Self::InvalidUnit,
        Self::MovementUnitUpdateFailed,
        Self::TurnPlayerNotControlled,
        Self::TurnPlayerNotActive,
        Self::TurnScopeInvalid,
        Self::TurnProcessorUnsupported,
        Self::TurnNumberOverflow,
        Self::AttackerNotFound,
        Self::AttackerNotControlled,
        Self::AttackerUnavailable,
        Self::AttackerExhausted,
        Self::AttackerOutOfBounds,
        Self::AttackerCannotAttack,
        Self::AttackTargetNotVisible,
        Self::AttackTargetOutOfBounds,
        Self::AttackTargetNotFound,
        Self::AttackTargetNotEnemy,
        Self::AttackTargetProtectedByTreaty,
        Self::AttackTargetOutOfRange,
        Self::AttackCityHasNoHealth,
        Self::CityFounderNotFound,
        Self::CityFounderNotControlled,
        Self::CityFounderBusy,
        Self::CityFounderInvalid,
        Self::CityFounderNoSettlers,
        Self::CitySiteInvalid,
        Self::CityCenterOccupied,
        Self::CityCenterClaimed,
        Self::CityCenterTooClose,
        Self::CityControlledHexesInvalid,
        Self::CityNotFound,
        Self::CityNotControlled,
        Self::WorkedHexUnavailable,
        Self::WorkedHexLimitReached,
        Self::CityExpansionHexUnavailable,
        Self::WorkerNotFound,
        Self::WorkerNotControlled,
        Self::WorkerUnavailable,
        Self::WorkerNoMovementPoints,
        Self::WorkerQueuedPathActive,
        Self::WorkerImprovementNotSelected,
        Self::WorkerActionNotControlled,
        Self::WorkerImprovementUnavailable,
        Self::WorkerJobNotActive,
        Self::WorkerAssignmentUnavailable,
        Self::WorkerAssignmentNotActive,
        Self::WorkerRoadUnavailable,
        Self::RoadConstructionExistingRoad,
        Self::RoadConstructionCity,
        Self::RoadConstructionEnemyTerritory,
        Self::RoadConstructionImpassableTerrain,
        Self::WorkerAutomationNotActive,
        Self::WorkerAutomationNoTarget,
    ];

    /// Returns the stable snake-case wire value.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::StaleRevision => "stale_revision",
            Self::UnitNotFound => "unit_not_found",
            Self::UnitNotControlled => "unit_not_controlled",
            Self::UnitUnavailable => "unit_unavailable",
            Self::UnitUsesTradeRoutes => "unit_uses_trade_routes",
            Self::UnitOutOfBounds => "unit_out_of_bounds",
            Self::MoveTargetOutOfBounds => "move_target_out_of_bounds",
            Self::MoveTargetIsCurrentTile => "move_target_is_current_tile",
            Self::MoveTargetIsForeignCityCenter => "move_target_is_foreign_city_center",
            Self::MoveTargetOccupied => "move_target_occupied",
            Self::UnitMovementCapacityInsufficient => "unit_movement_capacity_insufficient",
            Self::MovePathNotFound => "move_path_not_found",
            Self::UnitNotScout => "unit_not_scout",
            Self::UnitExhausted => "unit_exhausted",
            Self::UnitHasPath => "unit_has_path",
            Self::AutoExploreNoTarget => "auto_explore_no_target",
            Self::UnitNotMerchant => "unit_not_merchant",
            Self::MerchantNotInCity => "merchant_not_in_city",
            Self::DestinationCityNotFound => "destination_city_not_found",
            Self::DestinationCityNotControlled => "destination_city_not_controlled",
            Self::DestinationCityIsOrigin => "destination_city_is_origin",
            Self::DestinationCityIsCurrent => "destination_city_is_current",
            Self::MerchantRouteNotFound => "merchant_route_not_found",
            Self::MerchantCityPathNotFound => "merchant_city_path_not_found",
            Self::TroopNotAvailable => "troop_not_available",
            Self::DetachmentSourceOutOfBounds => "detachment_source_out_of_bounds",
            Self::DetachmentDestinationUnavailable => "detachment_destination_unavailable",
            Self::DetachedUnitIdUnavailable => "detached_unit_id_unavailable",
            Self::UnitBusy => "unit_busy",
            Self::UnitDefinitionMissing => "unit_definition_missing",
            Self::StateRevisionOverflow => "state_revision_overflow",
            Self::InvalidQueuedMovementPath => "invalid_queued_movement_path",
            Self::InvalidUnit => "invalid_unit",
            Self::MovementUnitUpdateFailed => "movement_unit_update_failed",
            Self::TurnPlayerNotControlled => "turn_player_not_controlled",
            Self::TurnPlayerNotActive => "turn_player_not_active",
            Self::TurnScopeInvalid => "turn_scope_invalid",
            Self::TurnProcessorUnsupported => "turn_processor_unsupported",
            Self::TurnNumberOverflow => "turn_number_overflow",
            Self::AttackerNotFound => "attacker_not_found",
            Self::AttackerNotControlled => "attacker_not_controlled",
            Self::AttackerUnavailable => "attacker_unavailable",
            Self::AttackerExhausted => "attacker_exhausted",
            Self::AttackerOutOfBounds => "attacker_out_of_bounds",
            Self::AttackerCannotAttack => "attacker_cannot_attack",
            Self::AttackTargetNotVisible => "attack_target_not_visible",
            Self::AttackTargetOutOfBounds => "attack_target_out_of_bounds",
            Self::AttackTargetNotFound => "attack_target_not_found",
            Self::AttackTargetNotEnemy => "attack_target_not_enemy",
            Self::AttackTargetProtectedByTreaty => "attack_target_protected_by_treaty",
            Self::AttackTargetOutOfRange => "attack_target_out_of_range",
            Self::AttackCityHasNoHealth => "attack_city_has_no_health",
            Self::CityFounderNotFound => "city_founder_not_found",
            Self::CityFounderNotControlled => "city_founder_not_controlled",
            Self::CityFounderBusy => "city_founder_busy",
            Self::CityFounderInvalid => "city_founder_invalid",
            Self::CityFounderNoSettlers => "city_founder_no_settlers",
            Self::CitySiteInvalid => "city_site_invalid",
            Self::CityCenterOccupied => "city_center_occupied",
            Self::CityCenterClaimed => "city_center_claimed",
            Self::CityCenterTooClose => "city_center_too_close",
            Self::CityControlledHexesInvalid => "city_controlled_hexes_invalid",
            Self::CityNotFound => "city_not_found",
            Self::CityNotControlled => "city_not_controlled",
            Self::WorkedHexUnavailable => "worked_hex_unavailable",
            Self::WorkedHexLimitReached => "worked_hex_limit_reached",
            Self::CityExpansionHexUnavailable => "city_expansion_hex_unavailable",
            Self::WorkerNotFound => "worker_not_found",
            Self::WorkerNotControlled => "worker_not_controlled",
            Self::WorkerUnavailable => "worker_unavailable",
            Self::WorkerNoMovementPoints => "worker_no_movement_points",
            Self::WorkerQueuedPathActive => "worker_queued_path_active",
            Self::WorkerImprovementNotSelected => "worker_improvement_not_selected",
            Self::WorkerActionNotControlled => "worker_action_not_controlled",
            Self::WorkerImprovementUnavailable => "worker_improvement_unavailable",
            Self::WorkerJobNotActive => "worker_job_not_active",
            Self::WorkerAssignmentUnavailable => "worker_assignment_unavailable",
            Self::WorkerAssignmentNotActive => "worker_assignment_not_active",
            Self::WorkerRoadUnavailable => "worker_road_unavailable",
            Self::RoadConstructionExistingRoad => "road_construction_existingRoad",
            Self::RoadConstructionCity => "road_construction_city",
            Self::RoadConstructionEnemyTerritory => "road_construction_enemyTerritory",
            Self::RoadConstructionImpassableTerrain => "road_construction_impassableTerrain",
            Self::WorkerAutomationNotActive => "worker_automation_not_active",
            Self::WorkerAutomationNoTarget => "worker_automation_no_target",
        }
    }
}
