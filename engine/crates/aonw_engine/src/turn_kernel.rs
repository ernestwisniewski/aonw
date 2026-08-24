mod support;

use std::collections::BTreeSet;

use aonw_content::{ContentHash, MapDefinition, RulesetDefinition};
use aonw_domain::{GameMode, GameState, MatchLifecycle, PlayerId, PlayerTurnState, UtcTimestamp};

use crate::movement::{TurnMovementUpdate, advance_turn_movement};
use crate::{
    AllPlayersSubmittedEvent, CanonicalEngineError, CommandRejectionCode, DomainEvent,
    DomainTransition, EngineContext, FinalizeTimedOutTurnCommand, GameEngine,
    KickParticipantCommand, PlayerKickedEvent, PlayerTimedOutEvent, SystemCommand, SystemContext,
    TurnCommand, TurnEndedEvent, TurnProcessor,
};

use self::support::{
    InteractionStateUpdate, accept_identity, apply_update, ordered_submission_scope,
    rebuild_lifecycle, reject, sequential_progress, system_content_hashes,
    transition_with_phase_evidence, unsupported_processor_for_scope, valid_system_scope,
    validate_player_command,
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
            None,
            None,
            InteractionStateUpdate::Preserve,
            Box::new([]),
            [TurnProcessor::Submission, TurnProcessor::Lifecycle],
            map_hash,
            ruleset_hash,
        );
    }
    finalize_simultaneous(
        state,
        context.map(),
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
    let progress = match sequential_progress(&state, command.player_id()) {
        Ok(progress) => progress,
        Err(code) => return Ok(reject(state, code, map_hash, ruleset_hash)),
    };
    if unsupported_processor_for_scope(&state, &progress.reset_scope).is_some() {
        return Ok(reject(
            state,
            CommandRejectionCode::TurnProcessorUnsupported,
            map_hash,
            ruleset_hash,
        ));
    }
    let movement = match advance_turn_movement(
        &state,
        context.map(),
        context.ruleset(),
        &progress.reset_scope,
    ) {
        Ok(movement) => movement,
        Err(code) => return Ok(reject(state, code, map_hash, ruleset_hash)),
    };
    let lifecycle = state.match_lifecycle().turn();
    let required = lifecycle.required_submission_player_ids().clone();
    let submitted = if progress.round_complete {
        BTreeSet::new()
    } else {
        lifecycle.submitted_player_ids().clone()
    };
    let next_lifecycle = rebuild_lifecycle(
        &state,
        progress.states,
        required,
        submitted,
        lifecycle.timeout_streaks_by_player_id().clone(),
        lifecycle.afk_player_ids().clone(),
        lifecycle.kicked_player_ids().clone(),
        lifecycle.turn_started_at().cloned(),
    )?;
    let TurnMovementUpdate {
        units,
        fog_of_war,
        diplomacy,
        interaction,
        events: movement_events,
        executions,
        reset_unit_ids,
        invalidated_order_unit_ids,
        finished_auto_explore_unit_ids,
    } = movement;
    let mut events = vec![DomainEvent::TurnEnded(TurnEndedEvent::new(
        command.player_id().clone(),
    ))];
    events.extend(movement_events);
    apply_update(
        state,
        next_lifecycle,
        Some(progress.next_turn),
        units,
        Some(fog_of_war),
        Some(diplomacy),
        InteractionStateUpdate::Replace(interaction),
        events.into_boxed_slice(),
        [
            TurnProcessor::Lifecycle,
            TurnProcessor::MovementReset,
            TurnProcessor::QueuedMovement,
            TurnProcessor::TradeRoutes,
            TurnProcessor::AutoExplore,
            TurnProcessor::ReversibleSkipCleanup,
        ],
        map_hash,
        ruleset_hash,
    )
    .map(|transition| {
        transition_with_phase_evidence(
            transition,
            Vec::new(),
            reset_unit_ids,
            executions,
            invalidated_order_unit_ids,
            finished_auto_explore_unit_ids,
        )
    })
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
        context.map(),
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
        None,
        None,
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
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
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
    let lifecycle = simultaneous_lifecycle(
        &state,
        scope,
        skipped,
        next_turn_started_at,
        track_timeout_streaks,
    )?;
    let current_turn = state.turn();
    let combat =
        crate::combat::resolve_intended_attacks(state, map, ruleset).map_err(
            |error| match error {
                crate::combat::CombatPhaseError::Diplomacy(source) => {
                    CanonicalEngineError::Diplomacy(source)
                }
                crate::combat::CombatPhaseError::State(source) => {
                    CanonicalEngineError::State(source)
                }
            },
        )?;
    let movement = match advance_turn_movement(&combat.state, map, ruleset, scope) {
        Ok(movement) => movement,
        Err(code) => return Ok(reject(combat.state, code, map_hash, ruleset_hash)),
    };
    let mut events = skipped
        .iter()
        .cloned()
        .map(|player| DomainEvent::PlayerTimedOut(PlayerTimedOutEvent::new(current_turn, player)))
        .collect::<Vec<_>>();
    events.push(DomainEvent::AllPlayersSubmitted(
        AllPlayersSubmittedEvent::new(current_turn, scope.to_vec()),
    ));
    events.extend(combat.events.iter().cloned());
    events.extend(
        scope
            .iter()
            .cloned()
            .map(TurnEndedEvent::new)
            .map(DomainEvent::TurnEnded),
    );
    let TurnMovementUpdate {
        units,
        fog_of_war,
        diplomacy,
        interaction,
        events: movement_events,
        executions,
        reset_unit_ids,
        invalidated_order_unit_ids,
        finished_auto_explore_unit_ids,
    } = movement;
    events.extend(movement_events);
    apply_update(
        combat.state,
        lifecycle,
        Some(next_turn),
        units,
        Some(fog_of_war),
        Some(diplomacy),
        InteractionStateUpdate::Replace(interaction),
        events.into_boxed_slice(),
        [
            TurnProcessor::Submission,
            TurnProcessor::Lifecycle,
            TurnProcessor::Combat,
            TurnProcessor::MovementReset,
            TurnProcessor::QueuedMovement,
            TurnProcessor::TradeRoutes,
            TurnProcessor::AutoExplore,
            TurnProcessor::ReversibleSkipCleanup,
        ],
        map_hash,
        ruleset_hash,
    )
    .map(|transition| {
        transition_with_phase_evidence(
            transition,
            combat.executions.into_vec(),
            reset_unit_ids,
            executions,
            invalidated_order_unit_ids,
            finished_auto_explore_unit_ids,
        )
    })
}

fn simultaneous_lifecycle(
    state: &GameState,
    scope: &[PlayerId],
    skipped: &[PlayerId],
    next_turn_started_at: Option<UtcTimestamp>,
    track_timeout_streaks: bool,
) -> Result<MatchLifecycle, CanonicalEngineError> {
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
                let previous = current
                    .timeout_streaks_by_player_id()
                    .get(player)
                    .copied()
                    .unwrap_or_default();
                (player.clone(), previous.saturating_add(1))
            })
            .collect()
    } else {
        current.timeout_streaks_by_player_id().clone()
    };
    rebuild_lifecycle(
        state,
        states,
        current.required_submission_player_ids().clone(),
        BTreeSet::new(),
        timeouts,
        current.afk_player_ids().clone(),
        current.kicked_player_ids().clone(),
        next_turn_started_at.or_else(|| current.turn_started_at().cloned()),
    )
}
