use std::collections::{BTreeMap, BTreeSet};

use aonw_content::ContentHash;
use aonw_domain::{
    Diplomacy, FogOfWar, GameState, InteractionState, MatchLifecycle, PlayerId, PlayerTurnState,
    TurnLifecycle, UnitPosture, UtcTimestamp,
};

use crate::{
    CanonicalEngineError, CommandRejectionCode, DomainEvent, DomainTransition, EngineContext,
    ExecutionEvidence, SystemContext, TurnCommand, TurnKernelExecution, TurnProcessor,
    UnitMovementExecution,
};

pub(super) fn validate_player_command(
    state: &GameState,
    context: EngineContext<'_>,
    command: TurnCommand<'_>,
) -> Option<CommandRejectionCode> {
    if state.revision().get() != command.expected_revision() {
        return Some(CommandRejectionCode::StaleRevision);
    }
    if context.actor_player_id() != command.player_id() {
        return Some(CommandRejectionCode::TurnPlayerNotControlled);
    }
    let lifecycle = state.match_lifecycle();
    if !lifecycle.identity().contains(command.player_id())
        || lifecycle
            .turn()
            .kicked_player_ids()
            .contains(command.player_id())
        || lifecycle
            .turn()
            .turn_states_by_player_id()
            .get(command.player_id())
            == Some(&PlayerTurnState::Finished)
            && !lifecycle
                .turn()
                .submitted_player_ids()
                .contains(command.player_id())
    {
        return Some(CommandRejectionCode::TurnPlayerNotActive);
    }
    None
}

pub(super) fn ordered_submission_scope(state: &GameState) -> Vec<PlayerId> {
    let lifecycle = state.match_lifecycle().turn();
    let required = lifecycle.required_submission_player_ids();
    state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| {
            !lifecycle.kicked_player_ids().contains(*player)
                && (required.is_empty() || required.contains(*player))
        })
        .cloned()
        .collect()
}

pub(super) fn ordered_active_scope(state: &GameState) -> Vec<PlayerId> {
    let kicked = state.match_lifecycle().turn().kicked_player_ids();
    state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(aonw_domain::Participant::id)
        .filter(|player| !kicked.contains(*player))
        .cloned()
        .collect()
}

pub(super) fn next_active_player(
    scope: &[PlayerId],
    after: &PlayerId,
    states: &BTreeMap<PlayerId, PlayerTurnState>,
) -> Option<PlayerId> {
    if scope.is_empty() {
        return None;
    }
    let start = scope.iter().position(|player| player == after).unwrap_or(0);
    (1..=scope.len())
        .map(|offset| &scope[(start + offset) % scope.len()])
        .find(|player| states.get(*player) != Some(&PlayerTurnState::Finished))
        .cloned()
}

pub(super) struct SequentialProgress {
    pub(super) states: BTreeMap<PlayerId, PlayerTurnState>,
    pub(super) next_turn: u32,
    pub(super) reset_scope: Vec<PlayerId>,
    pub(super) round_complete: bool,
}

pub(super) fn sequential_progress(
    state: &GameState,
    player_id: &PlayerId,
) -> Result<SequentialProgress, CommandRejectionCode> {
    let mut states = state
        .match_lifecycle()
        .turn()
        .turn_states_by_player_id()
        .clone();
    states.insert(player_id.clone(), PlayerTurnState::Finished);
    let active_scope = ordered_active_scope(state);
    let round_complete = active_scope
        .iter()
        .all(|player| states.get(player) == Some(&PlayerTurnState::Finished));
    let next_turn = if round_complete {
        state
            .turn()
            .checked_add(1)
            .ok_or(CommandRejectionCode::TurnNumberOverflow)?
    } else {
        state.turn()
    };
    if round_complete {
        for player in &active_scope {
            states.insert(player.clone(), PlayerTurnState::Active);
        }
    }
    let reset_scope = next_active_player(&active_scope, player_id, &states)
        .into_iter()
        .collect();
    Ok(SequentialProgress {
        states,
        next_turn,
        reset_scope,
        round_complete,
    })
}

pub(super) fn unsupported_processor_for_scope(
    state: &GameState,
    player_ids: &[PlayerId],
) -> Option<TurnProcessor> {
    let scope = player_ids.iter().collect::<BTreeSet<_>>();
    for unit in state
        .units()
        .iter()
        .filter(|unit| scope.contains(unit.owner_player_id()))
    {
        match unit.posture() {
            UnitPosture::AutoWorking => return Some(TurnProcessor::WorkerAutomation),
            UnitPosture::Active | UnitPosture::Fortified | UnitPosture::AutoExploring => {}
        }
    }
    if state.match_lifecycle().identity().game_mode() != aonw_domain::GameMode::Multiplayer
        && !state.combat().intended_attacks().is_empty()
    {
        return Some(TurnProcessor::Combat);
    }
    None
}

pub(super) fn valid_system_scope(
    state: &GameState,
    scope: &[PlayerId],
    skipped: &[PlayerId],
) -> bool {
    let unique_scope = scope.iter().collect::<BTreeSet<_>>();
    let unique_skipped = skipped.iter().collect::<BTreeSet<_>>();
    !scope.is_empty()
        && unique_scope.len() == scope.len()
        && unique_skipped.len() == skipped.len()
        && scope.iter().all(|player| {
            state.match_lifecycle().identity().contains(player)
                && !state
                    .match_lifecycle()
                    .turn()
                    .kicked_player_ids()
                    .contains(player)
        })
        && skipped.iter().all(|player| unique_scope.contains(player))
}

#[allow(clippy::too_many_arguments)]
pub(super) fn rebuild_lifecycle(
    state: &GameState,
    states: BTreeMap<PlayerId, PlayerTurnState>,
    required: BTreeSet<PlayerId>,
    submitted: BTreeSet<PlayerId>,
    timeouts: BTreeMap<PlayerId, i64>,
    afk: BTreeSet<PlayerId>,
    kicked: BTreeSet<PlayerId>,
    started: Option<UtcTimestamp>,
) -> Result<MatchLifecycle, CanonicalEngineError> {
    let identity = state.match_lifecycle().identity().clone();
    let turn = TurnLifecycle::try_new(
        &identity, states, required, submitted, timeouts, afk, kicked, started,
    )
    .map_err(CanonicalEngineError::TurnLifecycle)?;
    Ok(MatchLifecycle::new(identity, turn))
}

pub(super) enum InteractionStateUpdate {
    Preserve,
    Replace(InteractionState),
}

#[allow(clippy::too_many_arguments)]
pub(super) fn apply_update<const PROCESSORS: usize>(
    state: GameState,
    lifecycle: MatchLifecycle,
    turn: Option<u32>,
    units: Vec<aonw_domain::Unit>,
    fog_of_war: Option<FogOfWar>,
    diplomacy: Option<Diplomacy>,
    interaction: InteractionStateUpdate,
    events: Box<[DomainEvent]>,
    processors: [TurnProcessor; PROCESSORS],
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let Some(revision) = state.revision().checked_next() else {
        return Ok(reject(
            state,
            CommandRejectionCode::StateRevisionOverflow,
            map_hash,
            ruleset_hash,
        ));
    };
    let turn = turn.unwrap_or_else(|| state.turn());
    let units = if units.is_empty() {
        state.units().to_vec()
    } else {
        units
    };
    let fog_of_war = fog_of_war.unwrap_or_else(|| state.fog_of_war().clone());
    let diplomacy = diplomacy.unwrap_or_else(|| state.diplomacy().clone());
    let interaction = match interaction {
        InteractionStateUpdate::Preserve => state.interaction().clone(),
        InteractionStateUpdate::Replace(value) => value,
    };
    let state = state
        .into_after_turn_kernel(
            revision,
            aonw_domain::TurnAdvance::new(turn, lifecycle),
            units,
            fog_of_war,
            diplomacy,
            interaction,
        )
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        state,
        events,
        Some(ExecutionEvidence::TurnKernel(TurnKernelExecution::new(
            processors,
            Vec::<aonw_domain::UnitId>::new(),
        ))),
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn transition_with_phase_evidence(
    transition: DomainTransition,
    combat_executions: Vec<crate::CombatExecution>,
    reset_unit_ids: Vec<aonw_domain::UnitId>,
    movement_executions: Vec<UnitMovementExecution>,
    invalidated_order_unit_ids: Vec<aonw_domain::UnitId>,
    finished_auto_explore_unit_ids: Vec<aonw_domain::UnitId>,
    founded_city_ids: Vec<aonw_domain::CityId>,
) -> DomainTransition {
    let parts = transition.into_parts();
    let processors = match parts.evidence {
        Some(ExecutionEvidence::TurnKernel(value)) => value.processors().to_vec(),
        _ => Vec::new(),
    };
    DomainTransition::accepted(
        parts.state,
        parts.events,
        Some(ExecutionEvidence::TurnKernel(
            TurnKernelExecution::with_phases(
                processors,
                combat_executions,
                reset_unit_ids,
                movement_executions,
                invalidated_order_unit_ids,
                finished_auto_explore_unit_ids,
                founded_city_ids,
            ),
        )),
        parts.map_hash,
        parts.ruleset_hash,
    )
}

pub(super) fn accept_identity<const PROCESSORS: usize>(
    state: GameState,
    processors: [TurnProcessor; PROCESSORS],
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> DomainTransition {
    DomainTransition::accepted(
        state,
        Box::new([]),
        Some(ExecutionEvidence::TurnKernel(TurnKernelExecution::new(
            processors,
            Vec::<aonw_domain::UnitId>::new(),
        ))),
        map_hash,
        ruleset_hash,
    )
}

pub(super) fn reject(
    state: GameState,
    code: CommandRejectionCode,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> DomainTransition {
    DomainTransition::rejected(state, code, map_hash, ruleset_hash)
}

pub(super) fn system_content_hashes(
    context: SystemContext<'_>,
) -> Result<(ContentHash, ContentHash), CanonicalEngineError> {
    let map = context
        .map()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    let ruleset = context
        .ruleset()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    Ok((map, ruleset))
}
