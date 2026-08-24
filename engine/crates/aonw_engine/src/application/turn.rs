use aonw_domain::{PlayerId, UnitId, UtcTimestamp};

use super::EventBudget;
use crate::movement::UnitMovementExecution;

/// Revision-bound player command that targets one participant lifecycle.
#[derive(Clone, Copy, Debug)]
pub struct TurnCommand<'command> {
    expected_revision: u64,
    player_id: &'command PlayerId,
}

impl<'command> TurnCommand<'command> {
    /// Constructs a player turn command from authenticated envelope data.
    #[must_use]
    pub const fn new(expected_revision: u64, player_id: &'command PlayerId) -> Self {
        Self {
            expected_revision,
            player_id,
        }
    }

    /// Returns the revision observed by the caller.
    #[must_use]
    pub const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    /// Returns the participant targeted by the authenticated command.
    #[must_use]
    pub const fn player_id(self) -> &'command PlayerId {
        self.player_id
    }
}

/// Trusted timeout finalization selected by the host lifecycle boundary.
#[derive(Clone, Copy, Debug)]
pub struct FinalizeTimedOutTurnCommand<'command> {
    expected_revision: u64,
    player_ids: &'command [PlayerId],
    skipped_player_ids: &'command [PlayerId],
    next_turn_started_at: Option<&'command UtcTimestamp>,
}

impl<'command> FinalizeTimedOutTurnCommand<'command> {
    /// Constructs a trusted, fully explicit timeout transition.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        player_ids: &'command [PlayerId],
        skipped_player_ids: &'command [PlayerId],
        next_turn_started_at: Option<&'command UtcTimestamp>,
    ) -> Self {
        Self {
            expected_revision,
            player_ids,
            skipped_player_ids,
            next_turn_started_at,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn player_ids(self) -> &'command [PlayerId] {
        self.player_ids
    }

    pub(crate) const fn skipped_player_ids(self) -> &'command [PlayerId] {
        self.skipped_player_ids
    }

    pub(crate) const fn next_turn_started_at(self) -> Option<&'command UtcTimestamp> {
        self.next_turn_started_at
    }
}

/// Trusted participant-removal transition.
#[derive(Clone, Copy, Debug)]
pub struct KickParticipantCommand<'command> {
    expected_revision: u64,
    player_id: &'command PlayerId,
    reason: &'command str,
    timeout_streak: i64,
}

impl<'command> KickParticipantCommand<'command> {
    /// Constructs a trusted kick transition.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        player_id: &'command PlayerId,
        reason: &'command str,
        timeout_streak: i64,
    ) -> Self {
        Self {
            expected_revision,
            player_id,
            reason,
            timeout_streak,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }

    pub(crate) const fn player_id(self) -> &'command PlayerId {
        self.player_id
    }

    pub(crate) const fn reason(self) -> &'command str {
        self.reason
    }

    pub(crate) const fn timeout_streak(self) -> i64 {
        self.timeout_streak
    }
}

/// Commands accepted only from a trusted host or scheduler boundary.
#[derive(Clone, Copy, Debug)]
pub enum SystemCommand<'command> {
    /// Finalizes one expired simultaneous turn.
    FinalizeTimedOutTurn(FinalizeTimedOutTurnCommand<'command>),
    /// Marks one participant unavailable and removes it from submission scope.
    KickParticipant(KickParticipantCommand<'command>),
}

impl SystemCommand<'_> {
    /// Returns the reviewed upper event bound for this trusted command.
    #[must_use]
    pub fn event_budget(self, state: &aonw_domain::GameState) -> EventBudget {
        match self {
            Self::FinalizeTimedOutTurn(command) => {
                let player_count = u64::try_from(command.player_ids().len()).unwrap_or(u64::MAX);
                let skipped_count =
                    u64::try_from(command.skipped_player_ids().len()).unwrap_or(u64::MAX);
                let unit_count = u64::try_from(state.units().len()).unwrap_or(u64::MAX);
                EventBudget::new(
                    player_count
                        .saturating_add(skipped_count)
                        .saturating_add(unit_count)
                        .saturating_add(1),
                )
            }
            Self::KickParticipant(_) => EventBudget::new(1),
        }
    }
}

/// Named processor in the current capability-gated turn kernel.
#[derive(Clone, Copy, Debug, Eq, Hash, Ord, PartialEq, PartialOrd)]
pub enum TurnProcessor {
    /// Submission and readiness bookkeeping.
    Submission,
    /// Sequential/simultaneous lifecycle progression.
    Lifecycle,
    /// Per-turn movement allowance reset.
    MovementReset,
    /// Expiry of the reversible skip interaction.
    ReversibleSkipCleanup,
    /// Continuation of queued routes.
    QueuedMovement,
    /// Merchant route advancement.
    TradeRoutes,
    /// Worker automation continuation.
    WorkerAutomation,
    /// Scout auto-exploration continuation.
    AutoExplore,
    /// Simultaneous combat resolution.
    Combat,
    /// Economy and production progression.
    Economy,
    /// Diplomacy/contact progression.
    Diplomacy,
    /// Research progression.
    Research,
    /// Agreement progression.
    Agreements,
    /// Victory and map-objective progression.
    Objectives,
}

impl TurnProcessor {
    /// Stable manifest value.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Submission => "submission",
            Self::Lifecycle => "lifecycle",
            Self::MovementReset => "movementReset",
            Self::ReversibleSkipCleanup => "reversibleSkipCleanup",
            Self::QueuedMovement => "queuedMovement",
            Self::TradeRoutes => "tradeRoutes",
            Self::WorkerAutomation => "workerAutomation",
            Self::AutoExplore => "autoExplore",
            Self::Combat => "combat",
            Self::Economy => "economy",
            Self::Diplomacy => "diplomacy",
            Self::Research => "research",
            Self::Agreements => "agreements",
            Self::Objectives => "objectives",
        }
    }
}

/// Explicit processor set implemented by the T1 kernel.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct TurnKernelCapabilities;

impl TurnKernelCapabilities {
    /// Capability label used by current fixtures and runtime clients.
    pub const LABEL: &'static str = "turn-kernel-ready";
    /// Processors executed by the current kernel.
    pub const ENABLED: [TurnProcessor; 7] = [
        TurnProcessor::Submission,
        TurnProcessor::Lifecycle,
        TurnProcessor::MovementReset,
        TurnProcessor::QueuedMovement,
        TurnProcessor::TradeRoutes,
        TurnProcessor::AutoExplore,
        TurnProcessor::ReversibleSkipCleanup,
    ];
    /// Later turn processors that are intentionally unavailable.
    pub const DISABLED: [TurnProcessor; 7] = [
        TurnProcessor::WorkerAutomation,
        TurnProcessor::Combat,
        TurnProcessor::Economy,
        TurnProcessor::Diplomacy,
        TurnProcessor::Research,
        TurnProcessor::Agreements,
        TurnProcessor::Objectives,
    ];

    /// Returns whether a named processor is implemented by this kernel.
    #[must_use]
    pub const fn supports(processor: TurnProcessor) -> bool {
        matches!(
            processor,
            TurnProcessor::Submission
                | TurnProcessor::Lifecycle
                | TurnProcessor::MovementReset
                | TurnProcessor::QueuedMovement
                | TurnProcessor::TradeRoutes
                | TurnProcessor::AutoExplore
                | TurnProcessor::ReversibleSkipCleanup
        )
    }
}

/// Ordered evidence of the exact partial turn pipeline that executed.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TurnKernelExecution {
    processors: Box<[TurnProcessor]>,
    reset_unit_ids: Box<[UnitId]>,
    movement_executions: Box<[UnitMovementExecution]>,
    invalidated_order_unit_ids: Box<[UnitId]>,
    finished_auto_explore_unit_ids: Box<[UnitId]>,
}

impl TurnKernelExecution {
    pub(crate) fn new(
        processors: impl Into<Box<[TurnProcessor]>>,
        reset_unit_ids: impl Into<Box<[UnitId]>>,
    ) -> Self {
        Self {
            processors: processors.into(),
            reset_unit_ids: reset_unit_ids.into(),
            movement_executions: Box::new([]),
            invalidated_order_unit_ids: Box::new([]),
            finished_auto_explore_unit_ids: Box::new([]),
        }
    }

    pub(crate) fn with_movement(
        processors: impl Into<Box<[TurnProcessor]>>,
        reset_unit_ids: impl Into<Box<[UnitId]>>,
        movement_executions: impl Into<Box<[UnitMovementExecution]>>,
        invalidated_order_unit_ids: impl Into<Box<[UnitId]>>,
        finished_auto_explore_unit_ids: impl Into<Box<[UnitId]>>,
    ) -> Self {
        Self {
            processors: processors.into(),
            reset_unit_ids: reset_unit_ids.into(),
            movement_executions: movement_executions.into(),
            invalidated_order_unit_ids: invalidated_order_unit_ids.into(),
            finished_auto_explore_unit_ids: finished_auto_explore_unit_ids.into(),
        }
    }

    /// Returns processors in execution order.
    #[must_use]
    pub const fn processors(&self) -> &[TurnProcessor] {
        &self.processors
    }

    /// Returns units whose movement phase began, in canonical unit order.
    #[must_use]
    pub const fn reset_unit_ids(&self) -> &[UnitId] {
        &self.reset_unit_ids
    }

    /// Returns exact movement steps executed by turn processors.
    #[must_use]
    pub const fn movement_executions(&self) -> &[UnitMovementExecution] {
        &self.movement_executions
    }

    /// Returns units whose queued or merchant order became invalid.
    #[must_use]
    pub const fn invalidated_order_unit_ids(&self) -> &[UnitId] {
        &self.invalidated_order_unit_ids
    }

    /// Returns scouts whose auto-exploration ended without another target.
    #[must_use]
    pub const fn finished_auto_explore_unit_ids(&self) -> &[UnitId] {
        &self.finished_auto_explore_unit_ids
    }
}
