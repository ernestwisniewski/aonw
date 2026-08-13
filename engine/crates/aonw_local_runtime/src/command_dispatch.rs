use std::collections::BTreeMap;

use aonw_contracts::ReplayCommandDto;
use aonw_domain::{HexCoord, UnitId};
use aonw_engine::{
    DomainCommand, DomainEvent, ExecutionEvidence, GameEngine, MoveUnitCommand, UnitActionCommand,
};

use crate::persistence::{replay_context, replay_entry};
use crate::player_view::{PlayerUnitView, visible_units};
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
    /// New or changed visible units.
    pub upserted_units: Box<[PlayerUnitView]>,
    /// Units no longer visible.
    pub removed_unit_ids: Box<[UnitId]>,
}

/// Complete local result of one authoritative command dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CommandResult {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStamp,
    /// Stable rejection code, absent when accepted.
    pub rejection: Option<&'static str>,
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
    dispatch_domain(
        session,
        DomainCommand::MoveUnit(MoveUnitCommand::new(
            command.expected_revision,
            &command.unit_id,
            command.target,
        )),
        replay_command,
    )
}

pub(crate) fn dispatch_unit_action(
    session: &mut Session,
    command: &UnitActionRequest,
    kind: RuntimeUnitActionKind,
) -> Result<CommandResult, RuntimeError> {
    let engine_command = UnitActionCommand::new(command.expected_revision, &command.unit_id);
    let (domain_command, replay_command) = match kind {
        RuntimeUnitActionKind::Cancel => (
            DomainCommand::CancelUnitAction(engine_command),
            ReplayCommandDto::CancelUnitAction {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
        RuntimeUnitActionKind::Skip => (
            DomainCommand::SkipUnitTurn(engine_command),
            ReplayCommandDto::SkipUnitTurn {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
        RuntimeUnitActionKind::Fortify => (
            DomainCommand::FortifyUnit(engine_command),
            ReplayCommandDto::FortifyUnit {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
    };
    dispatch_domain(session, domain_command, replay_command)
}

fn dispatch_domain(
    session: &mut Session,
    command: DomainCommand<'_>,
    replay_command: ReplayCommandDto,
) -> Result<CommandResult, RuntimeError> {
    session.prepare_replay_segment();
    let before_context = replay_context(session);
    let before_revision = session.state().revision().get();
    let before_view = visible_units(session.state(), session.actor());
    let state = session.take_state();
    let transition =
        GameEngine::apply_owned(state, session.context(), command).map_err(RuntimeError::Engine)?;
    let parts = transition.into_parts();
    let rejection = parts.rejection.map(aonw_engine::DomainRejection::code);
    let events = parts.events;
    let evidence = parts.evidence;
    session.advance_event_offset(events.len())?;
    session.replace_state(parts.state, parts.digest);
    let after_view = visible_units(session.state(), session.actor());
    let view_patch = diff_view(
        before_revision,
        session.state().revision().get(),
        before_view,
        after_view,
    );
    let result = CommandResult {
        stamp: session.stamp(),
        rejection,
        events,
        evidence,
        view_patch,
    };
    let replay = replay_entry(session, replay_command, before_context, &result);
    session.push_replay(replay);
    Ok(result)
}

fn diff_view(
    from_revision: u64,
    to_revision: u64,
    before: Vec<PlayerUnitView>,
    after: Vec<PlayerUnitView>,
) -> PlayerViewPatch {
    let before = before
        .into_iter()
        .map(|unit| (unit.id().clone(), unit))
        .collect::<BTreeMap<_, _>>();
    let after = after
        .into_iter()
        .map(|unit| (unit.id().clone(), unit))
        .collect::<BTreeMap<_, _>>();
    let upserted_units = after
        .iter()
        .filter(|(id, unit)| before.get(*id) != Some(*unit))
        .map(|(_, unit)| unit.clone())
        .collect::<Vec<_>>()
        .into_boxed_slice();
    let removed_unit_ids = before
        .keys()
        .filter(|id| !after.contains_key(*id))
        .cloned()
        .collect::<Vec<_>>()
        .into_boxed_slice();
    PlayerViewPatch {
        from_revision,
        to_revision,
        upserted_units,
        removed_unit_ids,
    }
}
