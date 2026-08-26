mod artifact_events;
mod domain_transition;
mod events;
mod outcome;
mod production_events;

pub use artifact_events::{
    ArtifactCarriedEvent, ArtifactExcavationStartedEvent, ArtifactStoredEvent,
};
pub use domain_transition::{DomainRejection, DomainTransition, DomainTransitionParts};
pub use events::{
    AllPlayersSubmittedEvent, CityFoundedEvent, CombatEvent, DiplomaticScoreChangedEvent,
    PlayerKickedEvent, PlayerTimedOutEvent, TurnEndedEvent, WorkerCompletedJobEvent,
    WorkerJobCompletion,
};
pub use outcome::{DomainEvent, ExecutionEvidence};
pub use production_events::{
    CityBuiltBuildingEvent, CityBuiltWonderEvent, CityProducedUnitEvent, TechnologyResearchedEvent,
    WonderProductionRefundedEvent,
};

/// Stable command rejection shared by every authoritative command family.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum CommandRejectionCode {
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
    /// The requested movement target is outside the map.
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
    /// No visible, passable, unoccupied detachment destination exists.
    DetachmentDestinationUnavailable,
    /// No bounded canonical identifier can be assigned to the detached unit.
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
    /// Trusted player scope is empty, duplicated, or inconsistent.
    TurnScopeInvalid,
    /// A later turn processor was requested from the partial T1 kernel.
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
    /// The attacker position is outside the canonical map.
    AttackerOutOfBounds,
    /// The attacking unit has no positive attack strength.
    AttackerCannotAttack,
    /// The target coordinate is not currently visible to the actor.
    AttackTargetNotVisible,
    /// The target coordinate is outside the canonical map.
    AttackTargetOutOfBounds,
    /// No unit or city occupies the target coordinate.
    AttackTargetNotFound,
    /// The target belongs to the attacking player.
    AttackTargetNotEnemy,
    /// A friendly or truce relation protects the target.
    AttackTargetProtectedByTreaty,
    /// The target exceeds the effective attack range.
    AttackTargetOutOfRange,
    /// A target city has no positive current health.
    AttackCityHasNoHealth,
    /// The requested city founder does not exist.
    CityFounderNotFound,
    /// The actor cannot command the requested founder.
    CityFounderNotControlled,
    /// The founder is already performing authoritative work.
    CityFounderBusy,
    /// The unit cannot found cities.
    CityFounderInvalid,
    /// A commander army has no settler troop to consume.
    CityFounderNoSettlers,
    /// The founder's current tile cannot contain a city center.
    CitySiteInvalid,
    /// Another city already occupies the requested center.
    CityCenterOccupied,
    /// Another city controls the requested center.
    CityCenterClaimed,
    /// The requested center is too close to another city.
    CityCenterTooClose,
    /// Initial controlled territory is incomplete or invalid.
    CityControlledHexesInvalid,
    /// The requested city does not exist.
    CityNotFound,
    /// The actor cannot manage the requested city.
    CityNotControlled,
    /// The coordinate cannot be manually worked by the city.
    WorkedHexUnavailable,
    /// The city already manually works its population-based limit.
    WorkedHexLimitReached,
    /// The coordinate is not a legal current expansion candidate.
    CityExpansionHexUnavailable,
    /// The building is already present, locked, or misses a map requirement.
    BuildingNotAvailable,
    /// A strategic-resource option index does not exist for this unit.
    UnitProductionInvalidResourceOption,
    /// The unit is not producible or is technology-locked.
    UnitProductionNotAvailable,
    /// The empire lacks a visible controlled presence resource.
    UnitProductionRequiresResource,
    /// No strategic-resource alternative can be reserved.
    UnitProductionMissingStrategicResource,
    /// A naval unit requires an ocean-adjacent coastal spawn topology.
    UnitProductionRequiresCoast,
    /// Queuing the unit would exceed canonical supply capacity.
    UnitSupplyLimitReached,
    /// The wonder is completed, locked, blocked, or another wonder is active.
    WonderNotAvailable,
    /// City specialization technology is not unlocked.
    CitySpecializationLocked,
    /// The requested specialization is already selected.
    CitySpecializationUnchanged,
    /// The specialization prerequisite building is missing.
    CitySpecializationMissingBuilding,
    /// The city has no active production queue.
    ProductionQueueEmpty,
    /// Continuous projects cannot be rushed.
    ProjectCannotBeRushed,
    /// No positive affordable rush quote exists.
    RushProductionUnavailable,
    /// The controlled unit already carries an artifact.
    UnitAlreadyCarryingArtifact,
    /// No map artifact occupies the controlled unit's coordinate.
    ArtifactNotFound,
    /// The controlled unit does not carry an artifact.
    UnitNotCarryingArtifact,
    /// The controlled unit does not occupy the requested city center.
    UnitNotInCity,
    /// The requested city already stores an artifact.
    CityArtifactSlotFull,
    /// The authenticated actor cannot select a technology.
    TechnologyPlayerNotControlled,
    /// The technology is unlocked, active, blocked, or misses prerequisites.
    TechnologyNotAvailable,
    /// The authenticated actor cannot initiate an artifact trade.
    ArtifactTradeActorUnavailable,
    /// The artifact trade target is absent or equals the actor.
    ArtifactTradeTargetInvalid,
    /// Offered artifact-trade gold is negative.
    ArtifactTradeGoldInvalid,
    /// Current war policy blocks artifact trade.
    ArtifactTradeBlockedByWar,
    /// The offered gold cannot be transferred atomically.
    ArtifactTradeGoldUnavailable,
    /// The offered artifact is not stored in an actor-owned city.
    OfferedArtifactUnavailable,
    /// The target player has no empty city artifact slot.
    TargetArtifactSlotUnavailable,
    /// The requested worker does not exist or is not a worker.
    WorkerNotFound,
    /// The actor cannot command the requested worker.
    WorkerNotControlled,
    /// Current activity or posture prevents worker automation.
    WorkerUnavailable,
    /// The worker has no movement remaining.
    WorkerNoMovementPoints,
    /// A manual queued route prevents starting worker automation.
    WorkerQueuedPathActive,
    /// Confirmation omitted an explicit and matching pending selection.
    WorkerImprovementNotSelected,
    /// The pending worker selection belongs to another actor.
    WorkerActionNotControlled,
    /// The requested improvement is not currently legal.
    WorkerImprovementUnavailable,
    /// No worker job exists to cancel.
    WorkerJobNotActive,
    /// The current hex cannot receive a worker assignment.
    WorkerAssignmentUnavailable,
    /// No worker assignment exists to cancel.
    WorkerAssignmentNotActive,
    /// Generic road-construction readiness failure.
    WorkerRoadUnavailable,
    /// The coordinate already contains a road.
    RoadConstructionExistingRoad,
    /// City centers cannot receive road-construction jobs.
    RoadConstructionCity,
    /// Diplomacy policy forbids construction in this territory.
    RoadConstructionEnemyTerritory,
    /// Land movement cannot enter the construction coordinate.
    RoadConstructionImpassableTerrain,
    /// Automation continuation was requested for a non-automated worker.
    WorkerAutomationNotActive,
    /// No deterministic legal automation target exists.
    WorkerAutomationNoTarget,
}

impl CommandRejectionCode {
    /// Complete stable rejection surface exposed to current clients.
    pub const ALL: [Self; 113] = [
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
        Self::BuildingNotAvailable,
        Self::UnitProductionInvalidResourceOption,
        Self::UnitProductionNotAvailable,
        Self::UnitProductionRequiresResource,
        Self::UnitProductionMissingStrategicResource,
        Self::UnitProductionRequiresCoast,
        Self::UnitSupplyLimitReached,
        Self::WonderNotAvailable,
        Self::CitySpecializationLocked,
        Self::CitySpecializationUnchanged,
        Self::CitySpecializationMissingBuilding,
        Self::ProductionQueueEmpty,
        Self::ProjectCannotBeRushed,
        Self::RushProductionUnavailable,
        Self::UnitAlreadyCarryingArtifact,
        Self::ArtifactNotFound,
        Self::UnitNotCarryingArtifact,
        Self::UnitNotInCity,
        Self::CityArtifactSlotFull,
        Self::TechnologyPlayerNotControlled,
        Self::TechnologyNotAvailable,
        Self::ArtifactTradeActorUnavailable,
        Self::ArtifactTradeTargetInvalid,
        Self::ArtifactTradeGoldInvalid,
        Self::ArtifactTradeBlockedByWar,
        Self::ArtifactTradeGoldUnavailable,
        Self::OfferedArtifactUnavailable,
        Self::TargetArtifactSlotUnavailable,
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

    /// Returns the stable language-neutral wire value.
    #[must_use]
    #[allow(clippy::too_many_lines)]
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
            Self::BuildingNotAvailable => "building_not_available",
            Self::UnitProductionInvalidResourceOption => "unit_production_invalid_resource_option",
            Self::UnitProductionNotAvailable => "unit_production_not_available",
            Self::UnitProductionRequiresResource => "unit_production_requires_resource",
            Self::UnitProductionMissingStrategicResource => {
                "unit_production_missing_strategic_resource"
            }
            Self::UnitProductionRequiresCoast => "unit_production_requires_coast",
            Self::UnitSupplyLimitReached => "unit_supply_limit_reached",
            Self::WonderNotAvailable => "wonder_not_available",
            Self::CitySpecializationLocked => "city_specialization_locked",
            Self::CitySpecializationUnchanged => "city_specialization_unchanged",
            Self::CitySpecializationMissingBuilding => "city_specialization_missing_building",
            Self::ProductionQueueEmpty => "production_queue_empty",
            Self::ProjectCannotBeRushed => "project_cannot_be_rushed",
            Self::RushProductionUnavailable => "rush_production_unavailable",
            Self::UnitAlreadyCarryingArtifact => "unit_already_carrying_artifact",
            Self::ArtifactNotFound => "artifact_not_found",
            Self::UnitNotCarryingArtifact => "unit_not_carrying_artifact",
            Self::UnitNotInCity => "unit_not_in_city",
            Self::CityArtifactSlotFull => "city_artifact_slot_full",
            Self::TechnologyPlayerNotControlled => "technology_player_not_controlled",
            Self::TechnologyNotAvailable => "technology_not_available",
            Self::ArtifactTradeActorUnavailable => "artifact_trade_actor_unavailable",
            Self::ArtifactTradeTargetInvalid => "artifact_trade_target_invalid",
            Self::ArtifactTradeGoldInvalid => "artifact_trade_gold_invalid",
            Self::ArtifactTradeBlockedByWar => "artifact_trade_blocked_by_war",
            Self::ArtifactTradeGoldUnavailable => "artifact_trade_gold_unavailable",
            Self::OfferedArtifactUnavailable => "offered_artifact_unavailable",
            Self::TargetArtifactSlotUnavailable => "target_artifact_slot_unavailable",
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

impl core::fmt::Display for CommandRejectionCode {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(self.as_str())
    }
}
