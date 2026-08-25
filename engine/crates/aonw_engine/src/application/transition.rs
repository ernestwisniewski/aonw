use aonw_content::ContentHash;
use aonw_domain::GameState;

use crate::{
    AutoExplorePlannedEvent, CombatExecution, LogisticsExecution, MerchantRouteAssignedEvent,
    MerchantTravelQueuedEvent, StateDigest, TroopDetachedEvent, TurnKernelExecution,
    UnitMovedEvent, UnitMovementExecution, WorkerAutomationExecution,
};

mod domain_transition;
mod events;

pub use events::{
    AllPlayersSubmittedEvent, CityFoundedEvent, CombatEvent, DiplomaticScoreChangedEvent,
    PlayerKickedEvent, PlayerTimedOutEvent, TurnEndedEvent, WorkerCompletedJobEvent,
    WorkerJobCompletion,
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

    /// Returns the stable language-neutral wire value.
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

impl core::fmt::Display for CommandRejectionCode {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str(self.as_str())
    }
}

/// Stable command rejection independent of presentation language.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DomainRejection {
    code: CommandRejectionCode,
}

impl DomainRejection {
    /// Returns the stable wire code.
    #[must_use]
    pub const fn code(self) -> CommandRejectionCode {
        self.code
    }
}

/// Ordered event emitted by an accepted transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DomainEvent {
    /// One city-founding job completed.
    CityFounded(CityFoundedEvent),
    /// One unit changed map position.
    UnitMoved(UnitMovedEvent),
    /// Auto-exploration selected an engine-owned target.
    AutoExplorePlanned(AutoExplorePlannedEvent),
    /// A cyclic merchant route was assigned.
    MerchantRouteAssigned(MerchantRouteAssignedEvent),
    /// Explicit merchant travel was queued.
    MerchantTravelQueued(MerchantTravelQueuedEvent),
    /// One army troop became an independent unit.
    TroopDetached(TroopDetachedEvent),
    /// One participant completed its sequential turn.
    TurnEnded(TurnEndedEvent),
    /// Every required participant became ready for simultaneous finalization.
    AllPlayersSubmitted(AllPlayersSubmittedEvent),
    /// The trusted host finalized one participant on timeout.
    PlayerTimedOut(PlayerTimedOutEvent),
    /// The trusted host removed one participant from active lifecycle.
    PlayerKicked(PlayerKickedEvent),
    /// A visible attacker engaged a visible target.
    UnitAttacked(CombatEvent),
    /// A visible attacker engaged a visible city.
    CityAttacked(CombatEvent),
    /// Exact authoritative combat resolution occurred.
    CombatResolved(CombatEvent),
    /// A known observer applied a city-attack reputation penalty.
    DiplomaticScoreChanged(DiplomaticScoreChangedEvent),
    /// A surviving unit gained combat experience.
    UnitGainedExperience(CombatEvent),
    /// A defeated unit was removed.
    UnitKilled(CombatEvent),
    /// A surviving defender changed position.
    UnitRetreated(CombatEvent),
    /// A defeated city changed owner.
    CityCaptured(CombatEvent),
    /// A defeated city was removed.
    CityDestroyed(CombatEvent),
    /// One worker job completed successfully.
    WorkerCompletedJob(WorkerCompletedJobEvent),
}

/// Exact evidence used by clients for deterministic presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ExecutionEvidence {
    /// Exact movement steps executed by the engine.
    UnitMovement(UnitMovementExecution),
    /// Exact result of one movement-logistics command.
    Logistics(LogisticsExecution),
    /// Exact capability-gated processors executed by the T1 turn kernel.
    TurnKernel(TurnKernelExecution),
    /// Exact seed, rolls, modifiers, damage and retreat result for one attack.
    Combat(CombatExecution),
    /// Exact target, bounded counters, and movement selected by worker automation.
    WorkerAutomation(WorkerAutomationExecution),
}

/// Complete authoritative outcome of one command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DomainTransition {
    state: GameState,
    rejection: Option<DomainRejection>,
    events: Box<[DomainEvent]>,
    evidence: Option<ExecutionEvidence>,
    digest: StateDigest,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
}

/// Owned components of one authoritative transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DomainTransitionParts {
    /// Unchanged or next canonical state.
    pub state: GameState,
    /// Stable rejection code, absent when accepted.
    pub rejection: Option<DomainRejection>,
    /// Ordered authoritative events.
    pub events: Box<[DomainEvent]>,
    /// Exact presentation evidence.
    pub evidence: Option<ExecutionEvidence>,
    /// Canonical identity of `state`.
    pub digest: StateDigest,
    /// Exact logical map identity.
    pub map_hash: ContentHash,
    /// Exact immutable ruleset identity.
    pub ruleset_hash: ContentHash,
}
