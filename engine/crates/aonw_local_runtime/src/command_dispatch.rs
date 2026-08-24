use core::cmp::Ordering;

use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::{HexCoord, UnitId};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, ExecutionEvidence, GameEngine, MoveUnitCommand,
    PlayerCommand, UnitActionCommand,
};

use crate::persistence::{replay_context, replay_entry};
use crate::player_view::{
    PendingActionView, PlayerTurnLifecycleView, PlayerUnitView, pending_action, visible_units,
};
use crate::session::Session;
use crate::{RuntimeError, SessionStamp};

/// Current revision-bound manual-movement command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MoveUnitRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to move.
    pub unit_id: UnitId,
    /// Requested target.
    pub target: HexCoord,
}

/// Current revision-bound map-independent unit action.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitActionRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit receiving the action.
    pub unit_id: UnitId,
}

#[derive(Clone, Copy, Debug)]
pub(crate) enum RuntimeUnitActionKind {
    Cancel,
    Skip,
    Fortify,
}

/// Recipient-safe view delta produced by one dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerViewPatch {
    /// Revision the patch applies to.
    pub from_revision: u64,
    /// Revision after the patch.
    pub to_revision: u64,
    /// Replacement turn projection when lifecycle state changed.
    pub turn_lifecycle: Option<PlayerTurnLifecycleView>,
    /// New or changed visible units.
    pub upserted_units: Box<[PlayerUnitView]>,
    /// Units no longer visible.
    pub removed_unit_ids: Box<[UnitId]>,
    /// Current action awaiting input from this recipient.
    pub pending_action: Option<PendingActionView>,
}

/// Complete local result of one authoritative command dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CommandResult {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStamp,
    /// Stable rejection code, absent when accepted.
    pub rejection: Option<CommandRejectionCode>,
    /// Ordered authoritative events.
    pub events: Box<[DomainEvent]>,
    /// Exact execution evidence.
    pub evidence: Option<ExecutionEvidence>,
    /// Recipient-safe presentation delta.
    pub view_patch: PlayerViewPatch,
}

impl CommandResult {
    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn is_accepted(&self) -> bool {
        self.rejection.is_none()
    }
}

pub(crate) fn dispatch_move(
    session: &mut Session,
    command: &MoveUnitRequest,
) -> Result<CommandResult, RuntimeError> {
    let replay_command = ReplayCommandDto::MoveUnit {
        expected_revision: command.expected_revision,
        unit_id: command.unit_id.as_str().to_owned(),
        target: aonw_contracts::CoordinateDto {
            col: command.target.col(),
            row: command.target.row(),
        },
    };
    dispatch_player(
        session,
        PlayerCommand::MoveUnit(MoveUnitCommand::new(
            command.expected_revision,
            &command.unit_id,
            command.target,
        )),
        ReplayRecordDto::Player {
            command: replay_command,
        },
    )
}

pub(crate) fn dispatch_unit_action(
    session: &mut Session,
    command: &UnitActionRequest,
    kind: RuntimeUnitActionKind,
) -> Result<CommandResult, RuntimeError> {
    let engine_command = UnitActionCommand::new(command.expected_revision, &command.unit_id);
    let (player_command, replay_command) = match kind {
        RuntimeUnitActionKind::Cancel => (
            PlayerCommand::CancelUnitAction(engine_command),
            ReplayCommandDto::CancelUnitAction {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
        RuntimeUnitActionKind::Skip => (
            PlayerCommand::SkipUnitTurn(engine_command),
            ReplayCommandDto::SkipUnitTurn {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
        RuntimeUnitActionKind::Fortify => (
            PlayerCommand::FortifyUnit(engine_command),
            ReplayCommandDto::FortifyUnit {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
    };
    dispatch_player(
        session,
        player_command,
        ReplayRecordDto::Player {
            command: replay_command,
        },
    )
}

pub(crate) fn dispatch_player(
    session: &mut Session,
    command: PlayerCommand<'_>,
    replay_record: ReplayRecordDto,
) -> Result<CommandResult, RuntimeError> {
    let event_reservation =
        session.reserve_event_capacity(command.event_budget(session.state()))?;
    session.prepare_replay_segment();
    let before_context = replay_context(session, Some(session.actor()));
    let before_revision = session.state().revision().get();
    let before_turn = PlayerTurnLifecycleView::new(session.state(), session.actor());
    let before_view = visible_units(session.state(), session.actor());
    let state = session.take_state();
    let transition = GameEngine::apply_player_owned(state, session.context(), command)
        .map_err(RuntimeError::Engine)?;
    let parts = transition.into_parts();
    let rejection = parts.rejection.map(aonw_engine::DomainRejection::code);
    let events = parts.events;
    let evidence = parts.evidence;
    session.commit_event_reservation(event_reservation, events.len())?;
    session.replace_state(parts.state, parts.digest);
    let after_view = visible_units(session.state(), session.actor());
    let after_turn = PlayerTurnLifecycleView::new(session.state(), session.actor());
    let after_pending = pending_action(session.state(), session.actor());
    let view_patch = diff_view(
        before_revision,
        session.state().revision().get(),
        before_turn,
        after_turn,
        before_view,
        after_view,
        after_pending,
    );
    let result = CommandResult {
        stamp: session.stamp(),
        rejection,
        events,
        evidence,
        view_patch,
    };
    let replay = replay_entry(session, replay_record, before_context, &result);
    session.push_replay(replay);
    Ok(result)
}

pub(crate) fn diff_view(
    from_revision: u64,
    to_revision: u64,
    before_turn: PlayerTurnLifecycleView,
    after_turn: PlayerTurnLifecycleView,
    before: Vec<PlayerUnitView>,
    after: Vec<PlayerUnitView>,
    pending_action: Option<PendingActionView>,
) -> PlayerViewPatch {
    debug_assert!(before.windows(2).all(|pair| pair[0].id() < pair[1].id()));
    debug_assert!(after.windows(2).all(|pair| pair[0].id() < pair[1].id()));
    let mut before = before.into_iter().peekable();
    let mut after = after.into_iter().peekable();
    let mut upserted_units = Vec::new();
    let mut removed_unit_ids = Vec::new();
    while let (Some(previous), Some(current)) = (before.peek(), after.peek()) {
        match previous.id().cmp(current.id()) {
            Ordering::Less => {
                if let Some(previous) = before.next() {
                    removed_unit_ids.push(previous.id().clone());
                }
            }
            Ordering::Equal => {
                if let (Some(previous), Some(current)) = (before.next(), after.next())
                    && previous != current
                {
                    upserted_units.push(current);
                }
            }
            Ordering::Greater => {
                if let Some(current) = after.next() {
                    upserted_units.push(current);
                }
            }
        }
    }
    removed_unit_ids.extend(before.map(|unit| unit.id().clone()));
    upserted_units.extend(after);
    PlayerViewPatch {
        from_revision,
        to_revision,
        turn_lifecycle: (before_turn != after_turn).then_some(after_turn),
        upserted_units: upserted_units.into_boxed_slice(),
        removed_unit_ids: removed_unit_ids.into_boxed_slice(),
        pending_action,
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{HexCoord, MovementUnits, PlayerId, Unit, UnitId, UnitKind};

    use super::diff_view;
    use crate::player_view::PlayerUnitView;

    #[test]
    fn sorted_view_diff_reports_updates_insertions_and_removals() {
        let before = vec![view("unit-a", 0), view("unit-b", 1)];
        let after = vec![view("unit-b", 2), view("unit-c", 3)];

        let turn = super::PlayerTurnLifecycleView::default();
        let patch = diff_view(4, 5, turn, turn, before, after, None);

        assert_eq!(patch.from_revision, 4);
        assert_eq!(patch.to_revision, 5);
        assert_eq!(
            patch
                .upserted_units
                .iter()
                .map(|unit| unit.id().as_str())
                .collect::<Vec<_>>(),
            ["unit-b", "unit-c"]
        );
        assert_eq!(
            patch
                .removed_unit_ids
                .iter()
                .map(UnitId::as_str)
                .collect::<Vec<_>>(),
            ["unit-a"]
        );
        assert_eq!(patch.pending_action, None);
    }

    fn view(id: &str, col: i32) -> PlayerUnitView {
        let unit = Unit::builder(
            UnitId::new(id).expect("unit id"),
            PlayerId::new("player-1").expect("player id"),
            UnitKind::Commander,
            "Commander",
            HexCoord::new(col, 0),
            MovementUnits::new(10),
        )
        .build()
        .expect("unit");
        PlayerUnitView::from_unit(&unit)
    }
}
