use std::collections::{BTreeMap, BTreeSet};

use aonw_content::{ContentHash, RulesetDefinition};
use aonw_domain::{
    GameState, InteractionState, MatchLifecycle, PlayerId, PlayerTurnState, TurnLifecycle,
    UnitPosture, UtcTimestamp,
};

use crate::{
    CanonicalEngineError, CommandRejectionCode, DomainEvent, DomainTransition, EngineContext,
    ExecutionEvidence, SystemContext, TurnCommand, TurnKernelExecution, TurnProcessor,
    maximum_movement_units,
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
        if unit.queued_path().is_some() {
            return Some(TurnProcessor::QueuedMovement);
        }
        if unit.merchant_trade_route().is_some() {
            return Some(TurnProcessor::TradeRoutes);
        }
        match unit.posture() {
            UnitPosture::AutoWorking => return Some(TurnProcessor::WorkerAutomation),
            UnitPosture::AutoExploring => return Some(TurnProcessor::AutoExplore),
            UnitPosture::Active | UnitPosture::Fortified => {}
        }
    }
    if !state.combat().intended_attacks().is_empty() {
        return Some(TurnProcessor::Combat);
    }
    None
}

pub(super) struct MovementReset {
    pub(super) units: Vec<aonw_domain::Unit>,
    pub(super) interaction: InteractionState,
    pub(super) reset_unit_ids: Vec<aonw_domain::UnitId>,
}

pub(super) fn reset_movement(
    state: &GameState,
    ruleset: &RulesetDefinition,
    player_ids: &[PlayerId],
) -> Result<MovementReset, CommandRejectionCode> {
    let scope = player_ids.iter().cloned().collect::<BTreeSet<_>>();
    if state
        .units()
        .iter()
        .filter(|unit| scope.contains(unit.owner_player_id()))
        .any(|unit| ruleset.unit(unit.kind()).is_none())
    {
        return Err(CommandRejectionCode::UnitDefinitionMissing);
    }
    let mut reset_unit_ids = Vec::new();
    let units = state
        .units()
        .iter()
        .map(|unit| {
            if !scope.contains(unit.owner_player_id()) {
                return unit.clone();
            }
            reset_unit_ids.push(unit.id().clone());
            let maximum =
                maximum_movement_units(ruleset, unit.kind(), unit.carried_artifact_id().is_some());
            unit.after_turn_movement_reset(maximum)
        })
        .collect();
    let interaction = state.interaction().clone().expire_turn_skip_for(&scope);
    Ok(MovementReset {
        units,
        interaction,
        reset_unit_ids,
    })
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
    let interaction = match interaction {
        InteractionStateUpdate::Preserve => state.interaction().clone(),
        InteractionStateUpdate::Replace(value) => value,
    };
    let state = state
        .into_after_turn_kernel(revision, turn, lifecycle, units, interaction)
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

pub(super) fn transition_with_reset_evidence(
    transition: DomainTransition,
    reset_unit_ids: Vec<aonw_domain::UnitId>,
) -> DomainTransition {
    let parts = transition.into_parts();
    let processors = match parts.evidence {
        Some(ExecutionEvidence::TurnKernel(value)) => value.processors().to_vec(),
        _ => Vec::new(),
    };
    DomainTransition::accepted(
        parts.state,
        parts.events,
        Some(ExecutionEvidence::TurnKernel(TurnKernelExecution::new(
            processors,
            reset_unit_ids,
        ))),
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
