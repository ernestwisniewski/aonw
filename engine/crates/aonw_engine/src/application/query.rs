use aonw_domain::GameState;

use crate::{
    EngineContext, GameEngine, MovementSearchWorkspace, ReachableMovement, ReachableMovementQuery,
    TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError,
};

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
            Self::Rejected(rejection) => rejection.code().as_str(),
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
        let mut workspace = MovementSearchWorkspace::default();
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
        workspace: &mut MovementSearchWorkspace,
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
}
