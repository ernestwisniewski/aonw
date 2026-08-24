use aonw_content::ContentHash;
use aonw_domain::{GameState, StateRevision};

use crate::{
    AutoExplorePlannedEvent, CombatExecution, LogisticsExecution, MerchantRouteAssignedEvent,
    MerchantTravelQueuedEvent, StateDigest, TroopDetachedEvent, TurnKernelExecution,
    UnitMovedEvent, UnitMovementExecution,
};

mod events;

pub use events::{
    AllPlayersSubmittedEvent, CombatEvent, DiplomaticScoreChangedEvent, PlayerKickedEvent,
    PlayerTimedOutEvent, TurnEndedEvent,
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
}

impl CommandRejectionCode {
    /// Complete stable rejection surface exposed to current clients.
    pub const ALL: [Self; 52] = [
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

impl DomainTransition {
    pub(crate) fn accepted(
        state: GameState,
        events: Box<[DomainEvent]>,
        evidence: Option<ExecutionEvidence>,
        map_hash: ContentHash,
        ruleset_hash: ContentHash,
    ) -> Self {
        Self {
            digest: crate::state_digest::digest_state(&state),
            state,
            rejection: None,
            events,
            evidence,
            map_hash,
            ruleset_hash,
        }
    }

    pub(crate) fn rejected(
        state: GameState,
        code: CommandRejectionCode,
        map_hash: ContentHash,
        ruleset_hash: ContentHash,
    ) -> Self {
        Self {
            digest: crate::state_digest::digest_state(&state),
            state,
            rejection: Some(DomainRejection { code }),
            events: Box::new([]),
            evidence: None,
            map_hash,
            ruleset_hash,
        }
    }

    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn is_accepted(&self) -> bool {
        self.rejection.is_none()
    }

    /// Returns the unchanged or next canonical state.
    #[must_use]
    pub const fn state(&self) -> &GameState {
        &self.state
    }

    /// Returns a stable rejection when the command was not accepted.
    #[must_use]
    pub const fn rejection(&self) -> Option<DomainRejection> {
        self.rejection
    }

    /// Returns ordered domain events.
    #[must_use]
    pub const fn events(&self) -> &[DomainEvent] {
        &self.events
    }

    /// Returns exact command execution evidence.
    #[must_use]
    pub const fn evidence(&self) -> Option<&ExecutionEvidence> {
        self.evidence.as_ref()
    }

    /// Returns the revision of the returned state.
    #[must_use]
    pub const fn revision(&self) -> StateRevision {
        self.state.revision()
    }

    /// Returns canonical state identity.
    #[must_use]
    pub const fn digest(&self) -> StateDigest {
        self.digest
    }

    /// Returns the exact map identity used by the transition.
    #[must_use]
    pub const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }

    /// Returns the exact ruleset identity used by the transition.
    #[must_use]
    pub const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }

    /// Consumes the transition without cloning its canonical state.
    #[must_use]
    pub fn into_parts(self) -> DomainTransitionParts {
        DomainTransitionParts {
            state: self.state,
            rejection: self.rejection,
            events: self.events,
            evidence: self.evidence,
            digest: self.digest,
            map_hash: self.map_hash,
            ruleset_hash: self.ruleset_hash,
        }
    }
}
