use aonw_content::ContentHash;
use aonw_domain::{GameState, GameStateBuildError};

use super::{DomainEvent, DomainTransition, ExecutionEvidence};
use crate::movement::{merge_discovered_contacts, recompute_after_move};
use crate::unit_action::{UnitActionKind, apply_unit_action};
use crate::{EngineContext, GameEngine, MoveUnitCommand, StateDigest, UnitActionCommand};

/// Authoritative simulation command family.
#[derive(Clone, Copy, Debug)]
pub enum DomainCommand<'command> {
    /// Revision-bound manual unit movement.
    MoveUnit(MoveUnitCommand<'command>),
    /// Clears every cancellable order owned by one unit.
    CancelUnitAction(UnitActionCommand<'command>),
    /// Consumes one unit's remaining movement for the current turn.
    SkipUnitTurn(UnitActionCommand<'command>),
    /// Places one idle unit in persistent fortification.
    FortifyUnit(UnitActionCommand<'command>),
}

/// Failure indicating corrupt internal state rather than a rejected command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CanonicalEngineError {
    /// A referenced content identity could not be computed.
    ContentHash(Box<str>),
    /// Applying the result violates an aggregate invariant.
    State(GameStateBuildError),
}

impl core::fmt::Display for CanonicalEngineError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::ContentHash(source) => write!(formatter, "content hash failed: {source}"),
            Self::State(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for CanonicalEngineError {}

impl GameEngine {
    /// Applies a command while reusing owned canonical-state storage.
    ///
    /// # Errors
    ///
    /// Returns an error only when canonical state or an engine-produced update
    /// violates internal invariants.
    pub fn apply_owned(
        state: GameState,
        context: EngineContext<'_>,
        command: DomainCommand<'_>,
    ) -> Result<DomainTransition, CanonicalEngineError> {
        let (map_hash, ruleset_hash) = content_hashes(context)?;
        let map = context.map();
        match command {
            DomainCommand::MoveUnit(command) => {
                let movement =
                    GameEngine::apply_move_unit(&state, context.with_world(&state), command);
                apply_move(state, map, movement, map_hash, ruleset_hash)
            }
            DomainCommand::CancelUnitAction(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Cancel,
                map_hash,
                ruleset_hash,
            ),
            DomainCommand::SkipUnitTurn(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Skip,
                map_hash,
                ruleset_hash,
            ),
            DomainCommand::FortifyUnit(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Fortify,
                map_hash,
                ruleset_hash,
            ),
        }
    }

    /// Computes canonical state identity.
    #[must_use]
    pub fn state_digest(state: &GameState) -> StateDigest {
        crate::state_digest::digest_state(state)
    }
}

fn content_hashes(
    context: EngineContext<'_>,
) -> Result<(ContentHash, ContentHash), CanonicalEngineError> {
    if let Some(compiled) = context.compiled_movement_map() {
        return Ok((compiled.map_hash(), compiled.ruleset_hash()));
    }
    let map_hash = context
        .map()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    let ruleset_hash = context
        .ruleset()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    Ok((map_hash, ruleset_hash))
}

fn apply_canonical_unit_action(
    state: GameState,
    context: EngineContext<'_>,
    command: UnitActionCommand<'_>,
    kind: UnitActionKind,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let update = match apply_unit_action(&state, context, command, kind) {
        Ok(update) => update,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let next_state = state
        .into_after_unit_action(
            update.revision,
            update.unit,
            update.interaction,
            update.cancelled_excavation,
        )
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next_state,
        Box::new([]),
        None,
        map_hash,
        ruleset_hash,
    ))
}

fn apply_move(
    state: GameState,
    map: &aonw_content::MapDefinition,
    movement: Result<crate::movement::MovementTransition, crate::MoveUnitError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let movement = match movement {
        Ok(value) => value,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let updated_unit = movement.unit().clone();
    let unit_id = updated_unit.id().clone();
    let next_revision = movement.revision();
    let mut fog = state.fog_of_war().clone();
    let mut diplomacy = state.diplomacy().clone();
    if movement.event().is_some() {
        let updated_index = state
            .units()
            .iter()
            .position(|unit| unit.id() == &unit_id)
            .expect("canonical unit exists");
        let units = state
            .units()
            .iter()
            .enumerate()
            .map(|(index, unit)| {
                if index == updated_index {
                    &updated_unit
                } else {
                    unit
                }
            })
            .collect::<Vec<_>>();
        fog = recompute_after_move(
            &fog,
            map,
            updated_unit.owner_player_id(),
            &units,
            state.cities(),
        );
        diplomacy = merge_discovered_contacts(&diplomacy, &fog, &units, state.cities());
    }
    let next_state = state
        .into_after_movement(next_revision, updated_unit, fog, diplomacy)
        .map_err(CanonicalEngineError::State)?;
    let events = movement
        .event()
        .cloned()
        .map(DomainEvent::UnitMoved)
        .into_iter()
        .collect::<Vec<_>>()
        .into_boxed_slice();
    let evidence = movement
        .execution()
        .cloned()
        .map(ExecutionEvidence::UnitMovement);
    Ok(DomainTransition::accepted(
        next_state,
        events,
        evidence,
        map_hash,
        ruleset_hash,
    ))
}
