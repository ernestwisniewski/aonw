mod support;

use std::collections::BTreeSet;

use aonw_content::ContentHash;
use aonw_domain::{GameMode, GameState, PlayerId, PlayerTurnState, UtcTimestamp};

use crate::{
    AllPlayersSubmittedEvent, CanonicalEngineError, CommandRejectionCode, DomainEvent,
    DomainTransition, EngineContext, FinalizeTimedOutTurnCommand, GameEngine,
    KickParticipantCommand, PlayerKickedEvent, PlayerTimedOutEvent, SystemCommand, SystemContext,
    TurnCommand, TurnEndedEvent, TurnProcessor,
};

use self::support::{
    InteractionStateUpdate, accept_identity, apply_update, next_active_player,
    ordered_active_scope, ordered_submission_scope, rebuild_lifecycle, reject, reset_movement,
    system_content_hashes, transition_with_reset_evidence, unsupported_processor_for_scope,
    valid_system_scope, validate_player_command,
};

impl GameEngine {
    /// Applies one host-owned lifecycle command through a boundary that has no player identity.
    ///
    /// # Errors
    ///
    /// Returns an error only when canonical content or an engine-produced state is invalid.
    pub fn apply_system_owned(
        state: GameState,
        context: SystemContext<'_>,
        command: SystemCommand<'_>,
    ) -> Result<DomainTransition, CanonicalEngineError> {
        let hashes = system_content_hashes(context)?;
        match command {
            SystemCommand::FinalizeTimedOutTurn(command) => {
                apply_timeout_finalization(state, context, command, hashes)
            }
            SystemCommand::KickParticipant(command) => {
                apply_kick(state, command, hashes.0, hashes.1)
            }
        }
    }
}

pub(crate) fn apply_submit_turn(
    state: GameState,
    context: EngineContext<'_>,
    command: TurnCommand<'_>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    if let Some(code) = validate_player_command(&state, context, command) {
        return Ok(reject(state, code, map_hash, ruleset_hash));
    }
    let turn = state.match_lifecycle().turn();
    if turn.submitted_player_ids().contains(command.player_id()) {
        return Ok(accept_identity(
            state,
            [TurnProcessor::Submission, TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        ));
    }
    let scope = ordered_submission_scope(&state);
    let mut submitted = turn.submitted_player_ids().clone();
    submitted.insert(command.player_id().clone());
    let mut states = turn.turn_states_by_player_id().clone();
    states.insert(command.player_id().clone(), PlayerTurnState::Finished);
    if !scope.iter().all(|player| submitted.contains(player)) {
        let lifecycle = rebuild_lifecycle(
            &state,
            states,
            turn.required_submission_player_ids().clone(),
            submitted,
            turn.timeout_streaks_by_player_id().clone(),
            turn.afk_player_ids().clone(),
            turn.kicked_player_ids().clone(),
            turn.turn_started_at().cloned(),
        )?;
        return apply_update(
            state,
            lifecycle,
            None,
            Vec::new(),
            InteractionStateUpdate::Preserve,
            Box::new([]),
            [TurnProcessor::Submission, TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        );
    }
    finalize_simultaneous(
        state,
        context.ruleset(),
        &scope,
        &[],
        None,
        false,
        map_hash,
        ruleset_hash,
    )
}

pub(crate) fn apply_end_turn(
    state: GameState,
    context: EngineContext<'_>,
    command: TurnCommand<'_>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    if let Some(code) = validate_player_command(&state, context, command) {
        return Ok(reject(state, code, map_hash, ruleset_hash));
    }
    let identity = state.match_lifecycle().identity();
    if identity.game_mode() == GameMode::Multiplayer {
        return apply_submit_turn(state, context, command, map_hash, ruleset_hash);
    }
    let lifecycle = state.match_lifecycle().turn();
    let mut states = lifecycle.turn_states_by_player_id().clone();
    states.insert(command.player_id().clone(), PlayerTurnState::Finished);
    let active_scope = ordered_active_scope(&state);
    let round_complete = active_scope
        .iter()
        .all(|player| states.get(player) == Some(&PlayerTurnState::Finished));
    let next_turn = if round_complete {
        match state.turn().checked_add(1) {
            Some(turn) => turn,
            None => {
                return Ok(reject(
                    state,
                    CommandRejectionCode::TurnNumberOverflow,
                    map_hash,
                    ruleset_hash,
                ));
            }
        }
    } else {
        state.turn()
    };
    if round_complete {
        for player in &active_scope {
            states.insert(player.clone(), PlayerTurnState::Active);
        }
    }
    let next_player = next_active_player(&active_scope, command.player_id(), &states);
    let reset_scope = next_player.into_iter().collect::<Vec<_>>();
    if unsupported_processor_for_scope(&state, &reset_scope).is_some() {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnProcessorUnsupported,
            map_hash,
            ruleset_hash,
        ));
    }
    let movement = match reset_movement(&state, context.ruleset(), &reset_scope) {
        Ok(movement) => movement,
        Err(code) => return Ok(reject(state, code, map_hash, ruleset_hash)),
    };
    let required = lifecycle.required_submission_player_ids().clone();
    let submitted = if round_complete {
        BTreeSet::new()
    } else {
        lifecycle.submitted_player_ids().clone()
    };
    let next_lifecycle = rebuild_lifecycle(
        &state,
        states,
        required,
        submitted,
        lifecycle.timeout_streaks_by_player_id().clone(),
        lifecycle.afk_player_ids().clone(),
        lifecycle.kicked_player_ids().clone(),
        lifecycle.turn_started_at().cloned(),
    )?;
    apply_update(
        state,
        next_lifecycle,
        Some(next_turn),
        movement.units,
        InteractionStateUpdate::Replace(movement.interaction),
        vec![DomainEvent::TurnEnded(TurnEndedEvent::new(
            command.player_id().clone(),
        ))]
        .into_boxed_slice(),
        [
            TurnProcessor::Lifecycle,
            TurnProcessor::MovementReset,
            TurnProcessor::ReversibleSkipCleanup,
        ],
        map_hash,
        ruleset_hash,
    )
    .map(|transition| transition_with_reset_evidence(transition, movement.reset_unit_ids))
}

fn apply_timeout_finalization(
    state: GameState,
    context: SystemContext<'_>,
    command: FinalizeTimedOutTurnCommand<'_>,
    hashes: (ContentHash, ContentHash),
) -> Result<DomainTransition, CanonicalEngineError> {
    if state.revision().get() != command.expected_revision() {
        return Ok(reject(
            state,
            CommandRejectionCode::StaleRevision,
            hashes.0,
            hashes.1,
        ));
    }
    if !valid_system_scope(&state, command.player_ids(), command.skipped_player_ids()) {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnScopeInvalid,
            hashes.0,
            hashes.1,
        ));
    }
    finalize_simultaneous(
        state,
        context.ruleset(),
        command.player_ids(),
        command.skipped_player_ids(),
        command.next_turn_started_at().cloned(),
        true,
        hashes.0,
        hashes.1,
    )
}

fn apply_kick(
    state: GameState,
    command: KickParticipantCommand<'_>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    if state.revision().get() != command.expected_revision() {
        return Ok(reject(
            state,
            CommandRejectionCode::StaleRevision,
            map_hash,
            ruleset_hash,
        ));
    }
    if !state
        .match_lifecycle()
        .identity()
        .contains(command.player_id())
    {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnPlayerNotActive,
            map_hash,
            ruleset_hash,
        ));
    }
    let turn = state.match_lifecycle().turn();
    if turn.kicked_player_ids().contains(command.player_id()) {
        return Ok(accept_identity(
            state,
            [TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        ));
    }
    let mut states = turn.turn_states_by_player_id().clone();
    states.insert(command.player_id().clone(), PlayerTurnState::Finished);
    let mut required = turn.required_submission_player_ids().clone();
    required.remove(command.player_id());
    let mut submitted = turn.submitted_player_ids().clone();
    submitted.remove(command.player_id());
    let mut afk = turn.afk_player_ids().clone();
    afk.insert(command.player_id().clone());
    let mut kicked = turn.kicked_player_ids().clone();
    kicked.insert(command.player_id().clone());
    let lifecycle = rebuild_lifecycle(
        &state,
        states,
        required,
        submitted,
        turn.timeout_streaks_by_player_id().clone(),
        afk,
        kicked,
        turn.turn_started_at().cloned(),
    )?;
    let event = DomainEvent::PlayerKicked(PlayerKickedEvent::new(
        state.turn(),
        command.player_id().clone(),
        command.reason(),
        command.timeout_streak(),
    ));
    apply_update(
        state,
        lifecycle,
        None,
        Vec::new(),
        InteractionStateUpdate::Preserve,
        vec![event].into_boxed_slice(),
        [TurnProcessor::Lifecycle],
        map_hash,
        ruleset_hash,
    )
}

#[allow(clippy::too_many_arguments)]
fn finalize_simultaneous(
    state: GameState,
    ruleset: &aonw_content::RulesetDefinition,
    scope: &[PlayerId],
    skipped: &[PlayerId],
    next_turn_started_at: Option<UtcTimestamp>,
    track_timeout_streaks: bool,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    if unsupported_processor_for_scope(&state, scope).is_some() {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnProcessorUnsupported,
            map_hash,
            ruleset_hash,
        ));
    }
    let Some(next_turn) = state.turn().checked_add(1) else {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnNumberOverflow,
            map_hash,
            ruleset_hash,
        ));
    };
    let current = state.match_lifecycle().turn();
    let mut states = current.turn_states_by_player_id().clone();
    for player in scope {
        states.insert(player.clone(), PlayerTurnState::Active);
    }
    for player in current.kicked_player_ids() {
        states.insert(player.clone(), PlayerTurnState::Finished);
    }
    let timeouts = if track_timeout_streaks {
        skipped
            .iter()
            .map(|player| {
                (
                    player.clone(),
                    current
                        .timeout_streaks_by_player_id()
                        .get(player)
                        .copied()
                        .unwrap_or_default()
                        .saturating_add(1),
                )
            })
            .collect()
    } else {
        current.timeout_streaks_by_player_id().clone()
    };
    let lifecycle = rebuild_lifecycle(
        &state,
        states,
        current.required_submission_player_ids().clone(),
        BTreeSet::new(),
        timeouts,
        current.afk_player_ids().clone(),
        current.kicked_player_ids().clone(),
        next_turn_started_at.or_else(|| current.turn_started_at().cloned()),
    )?;
    let movement = match reset_movement(&state, ruleset, scope) {
        Ok(movement) => movement,
        Err(code) => return Ok(reject(state, code, map_hash, ruleset_hash)),
    };
    let mut events = skipped
        .iter()
        .cloned()
        .map(|player| DomainEvent::PlayerTimedOut(PlayerTimedOutEvent::new(state.turn(), player)))
        .collect::<Vec<_>>();
    events.push(DomainEvent::AllPlayersSubmitted(
        AllPlayersSubmittedEvent::new(state.turn(), scope.to_vec()),
    ));
    events.extend(
        scope
            .iter()
            .cloned()
            .map(TurnEndedEvent::new)
            .map(DomainEvent::TurnEnded),
    );
    apply_update(
        state,
        lifecycle,
        Some(next_turn),
        movement.units,
        InteractionStateUpdate::Replace(movement.interaction),
        events.into_boxed_slice(),
        [
            TurnProcessor::Submission,
            TurnProcessor::Lifecycle,
            TurnProcessor::MovementReset,
            TurnProcessor::ReversibleSkipCleanup,
        ],
        map_hash,
        ruleset_hash,
    )
    .map(|transition| transition_with_reset_evidence(transition, movement.reset_unit_ids))
}
