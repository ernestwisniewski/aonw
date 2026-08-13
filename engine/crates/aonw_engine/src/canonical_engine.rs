use aonw_content::ContentHash;
use aonw_domain::{GameState, GameStateBuildError, StateRevision};

use crate::movement::{merge_discovered_contacts, recompute_after_move};
use crate::unit_action::{UnitActionKind, apply_unit_action};
use crate::{
    EngineContext, GameEngine, MoveUnitCommand, ReachableMovement, ReachableMovementQuery,
    StateDigest, TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError,
    UnitActionCommand, UnitMovedEvent, UnitMovementExecution,
};

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

/// Read-only game query family.
#[derive(Clone, Copy, Debug)]
pub enum GameQuery<'query> {
    /// Route preview for one target.
    PlanRoute(TerrainMovementQuery<'query>),
    /// Current-turn reachable overlay.
    Reachable(ReachableMovementQuery<'query>),
}

/// Typed query result.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum QueryResult {
    /// Planned route.
    Route(TerrainMovementPlan),
    /// Reachable coordinates.
    Reachable(ReachableMovement),
}

/// Stable command rejection independent of presentation language.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DomainRejection {
    code: &'static str,
}

impl DomainRejection {
    /// Returns the stable wire code.
    #[must_use]
    pub const fn code(self) -> &'static str {
        self.code
    }
}

/// Ordered event emitted by an accepted transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DomainEvent {
    /// One unit changed map position.
    UnitMoved(UnitMovedEvent),
}

/// Exact evidence used by clients for deterministic presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ExecutionEvidence {
    /// Exact movement steps executed by the engine.
    UnitMovement(UnitMovementExecution),
}

/// Complete authoritative outcome of one command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DomainTransition {
    state: GameState,
    rejection: Option<DomainRejection>,
    events: Box<[DomainEvent]>,
    evidence: Option<ExecutionEvidence>,
    digest: StateDigest,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
}

/// Owned components of one authoritative transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DomainTransitionParts {
    /// Unchanged or next canonical state.
    pub state: GameState,
    /// Stable rejection code, absent when accepted.
    pub rejection: Option<DomainRejection>,
    /// Ordered authoritative events.
    pub events: Box<[DomainEvent]>,
    /// Exact presentation evidence.
    pub evidence: Option<ExecutionEvidence>,
    /// Canonical identity of `state`.
    pub digest: StateDigest,
    /// Exact logical map identity.
    pub map_hash: ContentHash,
    /// Exact immutable ruleset identity.
    pub ruleset_hash: ContentHash,
}

impl DomainTransition {
    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn is_accepted(&self) -> bool {
        self.rejection.is_none()
    }
    /// Returns the unchanged or next canonical state.
    #[must_use]
    pub const fn state(&self) -> &GameState {
        &self.state
    }
    /// Returns a stable rejection when the command was not accepted.
    #[must_use]
    pub const fn rejection(&self) -> Option<DomainRejection> {
        self.rejection
    }
    /// Returns ordered domain events.
    #[must_use]
    pub const fn events(&self) -> &[DomainEvent] {
        &self.events
    }
    /// Returns exact command execution evidence.
    #[must_use]
    pub const fn evidence(&self) -> Option<&ExecutionEvidence> {
        self.evidence.as_ref()
    }
    /// Returns the revision of the returned state.
    #[must_use]
    pub const fn revision(&self) -> StateRevision {
        self.state.revision()
    }
    /// Returns canonical state identity.
    #[must_use]
    pub const fn digest(&self) -> StateDigest {
        self.digest
    }
    /// Returns the exact map identity used by the transition.
    #[must_use]
    pub const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }
    /// Returns the exact ruleset identity used by the transition.
    #[must_use]
    pub const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }

    /// Consumes the transition without cloning its canonical state.
    #[must_use]
    pub fn into_parts(self) -> DomainTransitionParts {
        DomainTransitionParts {
            state: self.state,
            rejection: self.rejection,
            events: self.events,
            evidence: self.evidence,
            digest: self.digest,
            map_hash: self.map_hash,
            ruleset_hash: self.ruleset_hash,
        }
    }
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
    /// Executes a query without accepting client-owned visibility.
    ///
    /// # Errors
    ///
    /// Returns a deterministic query rejection or an invalid-state error.
    pub fn query(
        state: &GameState,
        context: EngineContext<'_>,
        query: GameQuery<'_>,
    ) -> Result<QueryResult, CanonicalQueryError> {
        let mut workspace = crate::MovementSearchWorkspace::default();
        Self::query_with_workspace(state, context, query, &mut workspace)
    }

    /// Executes a query while reusing caller-owned search storage.
    ///
    /// # Errors
    ///
    /// Returns a deterministic query rejection or an invalid-state error.
    pub fn query_with_workspace(
        state: &GameState,
        context: EngineContext<'_>,
        query: GameQuery<'_>,
        workspace: &mut crate::MovementSearchWorkspace,
    ) -> Result<QueryResult, CanonicalQueryError> {
        let context = context.with_world(state);
        match query {
            GameQuery::PlanRoute(query) => Self::plan_terrain_route(state, context, query)
                .map(QueryResult::Route)
                .map_err(CanonicalQueryError::Rejected),
            GameQuery::Reachable(query) => {
                Self::reachable_movement_with_workspace(state, context, query, workspace)
                    .map(QueryResult::Reachable)
                    .map_err(CanonicalQueryError::Rejected)
            }
        }
    }

    /// Applies one authoritative command to canonical state.
    ///
    /// Rejections return the identical state value, revision, and digest.
    ///
    /// # Errors
    ///
    /// Returns an error only when canonical state or an engine-produced update
    /// violates internal invariants.
    pub fn apply(
        state: &GameState,
        context: EngineContext<'_>,
        command: DomainCommand<'_>,
    ) -> Result<DomainTransition, CanonicalEngineError> {
        Self::apply_owned(state.clone(), context, command)
    }

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
        let map_hash = context
            .map()
            .content_hash()
            .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
        let ruleset_hash = context
            .ruleset()
            .content_hash()
            .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
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
            return Ok(rejected_transition(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let next_state = state
        .into_replacing_unit(update.revision, update.unit)
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition {
        digest: crate::state_digest::digest_state(&next_state),
        state: next_state,
        rejection: None,
        events: Box::new([]),
        evidence: None,
        map_hash,
        ruleset_hash,
    })
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
            return Ok(rejected_transition(
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
    Ok(DomainTransition {
        digest: crate::state_digest::digest_state(&next_state),
        state: next_state,
        rejection: None,
        events,
        evidence,
        map_hash,
        ruleset_hash,
    })
}

/// Failure from a canonical read-only query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CanonicalQueryError {
    /// Query was rejected by deterministic rules.
    Rejected(TerrainMovementQueryError),
}

impl CanonicalQueryError {
    /// Returns the stable rejection or internal error code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Rejected(rejection) => rejection.code(),
        }
    }
}

impl core::fmt::Display for CanonicalQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Rejected(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for CanonicalQueryError {}

fn rejected_transition(
    state: GameState,
    rejection_code: &'static str,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> DomainTransition {
    DomainTransition {
        digest: crate::state_digest::digest_state(&state),
        state,
        rejection: Some(DomainRejection {
            code: rejection_code,
        }),
        events: Box::new([]),
        evidence: None,
        map_hash,
        ruleset_hash,
    }
}
