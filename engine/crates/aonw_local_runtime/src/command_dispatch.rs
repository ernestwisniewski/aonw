use std::collections::BTreeMap;

use aonw_domain::{HexCoord, UnitId};
use aonw_engine::{DomainCommand, DomainEvent, ExecutionEvidence, GameEngine, MoveUnitCommand};

use crate::persistence::{replay_context, replay_entry};
use crate::player_view::{PlayerUnitViewV1, visible_units};
use crate::session::Session;
use crate::{RuntimeError, SessionStampV1};

/// Current revision-bound manual-movement command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MoveUnitV1 {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to move.
    pub unit_id: UnitId,
    /// Requested target.
    pub target: HexCoord,
}

/// Recipient-safe view delta produced by one dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerViewPatchV1 {
    /// Revision the patch applies to.
    pub from_revision: u64,
    /// Revision after the patch.
    pub to_revision: u64,
    /// New or changed visible units.
    pub upserted_units: Box<[PlayerUnitViewV1]>,
    /// Units no longer visible.
    pub removed_unit_ids: Box<[UnitId]>,
}

/// Complete local result of one manual movement dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MoveUnitResultV1 {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStampV1,
    /// Stable rejection code, absent when accepted.
    pub rejection: Option<&'static str>,
    /// Ordered authoritative events.
    pub events: Box<[DomainEvent]>,
    /// Exact execution evidence.
    pub evidence: Option<ExecutionEvidence>,
    /// Recipient-safe presentation delta.
    pub view_patch: PlayerViewPatchV1,
}

impl MoveUnitResultV1 {
    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn is_accepted(&self) -> bool {
        self.rejection.is_none()
    }
}

pub(crate) fn dispatch_move(
    session: &mut Session,
    command: &MoveUnitV1,
) -> Result<MoveUnitResultV1, RuntimeError> {
    session.prepare_replay_segment();
    let before_context = replay_context(session);
    let before_revision = session.state().revision().get();
    let before_view = visible_units(session.state(), session.actor());
    let state = session.take_state();
    let transition = GameEngine::apply_owned(
        state,
        session.context(),
        DomainCommand::MoveUnit(MoveUnitCommand::new(
            command.expected_revision,
            &command.unit_id,
            command.target,
        )),
    )
    .map_err(RuntimeError::Engine)?;
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
    let result = MoveUnitResultV1 {
        stamp: session.stamp(),
        rejection,
        events,
        evidence,
        view_patch,
    };
    let replay = replay_entry(session, command, before_context, &result);
    session.push_replay(replay);
    Ok(result)
}

fn diff_view(
    from_revision: u64,
    to_revision: u64,
    before: Vec<PlayerUnitViewV1>,
    after: Vec<PlayerUnitViewV1>,
) -> PlayerViewPatchV1 {
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
    PlayerViewPatchV1 {
        from_revision,
        to_revision,
        upserted_units,
        removed_unit_ids,
    }
}
