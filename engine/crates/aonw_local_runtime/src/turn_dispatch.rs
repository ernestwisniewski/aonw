use aonw_contracts::{ReplayCommandDto, ReplayRecordDto, ReplaySystemCommandDto};
use aonw_domain::{PlayerId, UtcTimestamp};
use aonw_engine::{
    FinalizeTimedOutTurnCommand, GameEngine, KickParticipantCommand, PlayerCommand, SystemCommand,
    TurnCommand,
};

use crate::RuntimeError;
use crate::command_dispatch::{
    CommandResult, ProjectedView, RecipientDisclosure, diff_view, dispatch_player, visible_city_ids,
};
use crate::persistence::{replay_context, replay_entry};
use crate::player_view::{
    PlayerTurnLifecycleView, city_founding_draft, pending_action, visible_cities, visible_units,
};
use crate::session::Session;

/// Revision-bound `EndTurn` or `SubmitTurn` request from the local authenticated actor.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct TurnCommandRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
}

/// Host-owned timeout finalization unavailable through the client protocol.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FinalizeTimedOutTurnRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Ordered participant scope selected by the host.
    pub player_ids: Box<[PlayerId]>,
    /// Ordered timed-out participants.
    pub skipped_player_ids: Box<[PlayerId]>,
    /// Explicit next-turn UTC time when it is rule-relevant.
    pub next_turn_started_at: Option<UtcTimestamp>,
}

/// Host-owned participant removal unavailable through the client protocol.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct KickParticipantRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Participant selected by the host.
    pub player_id: PlayerId,
    /// Stable host-owned reason.
    pub reason: Box<str>,
    /// Timeout streak observed by the host.
    pub timeout_streak: i64,
}

#[derive(Clone, Copy, Debug)]
pub(crate) enum RuntimeTurnKind {
    End,
    Submit,
}

pub(crate) fn dispatch_turn(
    session: &mut Session,
    request: TurnCommandRequest,
    kind: RuntimeTurnKind,
) -> Result<CommandResult, RuntimeError> {
    let actor = session.actor().clone();
    let command = TurnCommand::new(request.expected_revision, &actor);
    let (command, replay) = match kind {
        RuntimeTurnKind::End => (
            PlayerCommand::EndTurn(command),
            ReplayCommandDto::EndTurn {
                expected_revision: request.expected_revision,
            },
        ),
        RuntimeTurnKind::Submit => (
            PlayerCommand::SubmitTurn(command),
            ReplayCommandDto::SubmitTurn {
                expected_revision: request.expected_revision,
            },
        ),
    };
    dispatch_player(
        session,
        command,
        ReplayRecordDto::Player { command: replay },
    )
}

pub(crate) fn dispatch_timeout(
    session: &mut Session,
    request: &FinalizeTimedOutTurnRequest,
) -> Result<CommandResult, RuntimeError> {
    let command = FinalizeTimedOutTurnCommand::new(
        request.expected_revision,
        &request.player_ids,
        &request.skipped_player_ids,
        request.next_turn_started_at.as_ref(),
    );
    dispatch_system(
        session,
        SystemCommand::FinalizeTimedOutTurn(command),
        ReplaySystemCommandDto::FinalizeTimedOutTurn {
            expected_revision: request.expected_revision,
            player_ids: player_ids(&request.player_ids),
            skipped_player_ids: player_ids(&request.skipped_player_ids),
            next_turn_started_at: request
                .next_turn_started_at
                .as_ref()
                .map(|time| time.as_str().to_owned()),
        },
    )
}

pub(crate) fn dispatch_kick(
    session: &mut Session,
    request: &KickParticipantRequest,
) -> Result<CommandResult, RuntimeError> {
    let command = KickParticipantCommand::new(
        request.expected_revision,
        &request.player_id,
        &request.reason,
        request.timeout_streak,
    );
    dispatch_system(
        session,
        SystemCommand::KickParticipant(command),
        ReplaySystemCommandDto::KickParticipant {
            expected_revision: request.expected_revision,
            player_id: request.player_id.as_str().to_owned(),
            reason: request.reason.to_string(),
            timeout_streak: request.timeout_streak,
        },
    )
}

fn dispatch_system(
    session: &mut Session,
    command: SystemCommand<'_>,
    replay_command: ReplaySystemCommandDto,
) -> Result<CommandResult, RuntimeError> {
    let event_reservation =
        session.reserve_event_capacity(command.event_budget(session.state()))?;
    session.prepare_replay_segment();
    let before_context = replay_context(session, None);
    let before_revision = session.state().revision().get();
    let before_turn = PlayerTurnLifecycleView::new(session.state(), session.actor());
    let before_view = visible_units(session.state(), session.actor());
    let before_city_view = visible_cities(session.state(), session.actor());
    let before_visible_city_ids = visible_city_ids(session.state(), session.actor());
    let state = session.take_state();
    let transition = GameEngine::apply_system_owned(state, session.system_context(), command)
        .map_err(RuntimeError::Engine)?;
    let parts = transition.into_parts();
    let rejection = parts.rejection.map(aonw_engine::DomainRejection::code);
    let events = parts.events;
    let evidence = parts.evidence;
    session.commit_event_reservation(event_reservation, events.len())?;
    session.replace_state(parts.state, parts.digest);
    let after_view = visible_units(session.state(), session.actor());
    let after_city_view = visible_cities(session.state(), session.actor());
    let after_turn = PlayerTurnLifecycleView::new(session.state(), session.actor());
    let after_pending = pending_action(session.state(), session.actor());
    let recipient_disclosure = RecipientDisclosure::new(
        session.actor().clone(),
        &before_view,
        &before_visible_city_ids,
        evidence.as_ref(),
    );
    let result = CommandResult {
        stamp: session.stamp(),
        rejection,
        events,
        evidence,
        view_patch: diff_view(
            before_revision,
            session.state().revision().get(),
            ProjectedView::new(before_turn, before_view, before_city_view),
            ProjectedView::new(after_turn, after_view, after_city_view),
            after_pending,
            city_founding_draft(session.state(), session.actor()),
        ),
        recipient_disclosure,
    };
    let replay = replay_entry(
        session,
        ReplayRecordDto::System {
            command: replay_command,
        },
        before_context,
        &result,
    );
    session.push_replay(replay);
    Ok(result)
}

fn player_ids(values: &[PlayerId]) -> Vec<String> {
    values
        .iter()
        .map(|player| player.as_str().to_owned())
        .collect()
}
