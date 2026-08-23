use aonw_content::ContentHash;
use aonw_domain::{GameState, StateRevision};

use crate::{StateDigest, UnitMovedEvent, UnitMovementExecution};

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
}

impl CommandRejectionCode {
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
            Self::UnitBusy => "unit_busy",
            Self::UnitDefinitionMissing => "unit_definition_missing",
            Self::StateRevisionOverflow => "state_revision_overflow",
            Self::InvalidQueuedMovementPath => "invalid_queued_movement_path",
            Self::InvalidUnit => "invalid_unit",
            Self::MovementUnitUpdateFailed => "movement_unit_update_failed",
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
}

/// Exact evidence used by clients for deterministic presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ExecutionEvidence {
    /// Exact movement steps executed by the engine.
    UnitMovement(UnitMovementExecution),
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
    pub(super) fn accepted(
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

    pub(super) fn rejected(
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
