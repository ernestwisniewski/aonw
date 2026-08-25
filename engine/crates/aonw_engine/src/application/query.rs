use aonw_domain::GameState;

use crate::{
    CityExpansionOptions, CityExpansionOptionsQuery, CityFoundingOptions, CityFoundingOptionsQuery,
    CityWorkedHexOptions, CityWorkedHexOptionsQuery, CombatPreview, CombatPreviewQuery,
    EngineContext, GameEngine, MovementSearchWorkspace, ReachableMovement, ReachableMovementQuery,
    TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError, UnitLogisticsOptions,
    UnitLogisticsOptionsQuery, WorkerOptions, WorkerOptionsQuery,
};

/// Read-only game query family.
#[derive(Clone, Copy, Debug)]
pub enum GameQuery<'query> {
    /// Returns founding legality and engine-owned initial territory choices.
    CityFoundingOptions(CityFoundingOptionsQuery<'query>),
    /// Returns controlled/manual/effective worked coordinates.
    CityWorkedHexOptions(CityWorkedHexOptionsQuery<'query>),
    /// Returns deterministically ranked expansion candidates.
    CityExpansionOptions(CityExpansionOptionsQuery<'query>),
    /// Recipient-safe combat preview without seed or rolls.
    CombatPreview(CombatPreviewQuery<'query>),
    /// Route preview for one target.
    PlanRoute(TerrainMovementQuery<'query>),
    /// Current-turn reachable overlay.
    Reachable(ReachableMovementQuery<'query>),
    /// Complete engine-owned logistics options for one unit.
    UnitLogisticsOptions(UnitLogisticsOptionsQuery<'query>),
    /// Complete legal worker options and deterministic automation target.
    WorkerOptions(WorkerOptionsQuery<'query>),
}

/// Typed query result.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum QueryResult {
    /// Legal initial territory for one founder.
    CityFoundingOptions(CityFoundingOptions),
    /// Legal worked-hex state for one city.
    CityWorkedHexOptions(CityWorkedHexOptions),
    /// Legal preferred-expansion candidates for one city.
    CityExpansionOptions(CityExpansionOptions),
    /// Effective combat statistics and damage bounds.
    CombatPreview(CombatPreview),
    /// Planned route.
    Route(TerrainMovementPlan),
    /// Reachable coordinates.
    Reachable(ReachableMovement),
    /// Auto-explore, merchant, and detachment options.
    UnitLogisticsOptions(UnitLogisticsOptions),
    /// Improvement, assignment, road, and automation options.
    WorkerOptions(WorkerOptions),
}

/// Failure from a canonical read-only query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CanonicalQueryError {
    /// City query was rejected by deterministic city rules.
    City(crate::CommandRejectionCode),
    /// City query referenced incomplete technology content.
    Technology(crate::TechnologyQueryError),
    /// Combat preview was rejected without disclosing hidden target state.
    Combat(crate::CommandRejectionCode),
    /// Query was rejected by deterministic rules.
    Rejected(TerrainMovementQueryError),
    /// Logistics options were rejected by deterministic rules.
    Logistics(crate::MovementLogisticsError),
    /// Worker options were rejected by deterministic rules.
    Worker(crate::CommandRejectionCode),
}

impl CanonicalQueryError {
    /// Returns the stable rejection or internal error code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::Technology(_) => "technology_query_invalid",
            Self::City(rejection) | Self::Combat(rejection) | Self::Worker(rejection) => {
                rejection.as_str()
            }
            Self::Rejected(rejection) => rejection.code().as_str(),
            Self::Logistics(rejection) => rejection.code().as_str(),
        }
    }
}

impl core::fmt::Display for CanonicalQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Technology(source) => source.fmt(formatter),
            Self::City(source) | Self::Combat(source) | Self::Worker(source) => {
                source.fmt(formatter)
            }
            Self::Rejected(source) => source.fmt(formatter),
            Self::Logistics(source) => source.fmt(formatter),
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
            GameQuery::CityFoundingOptions(query) => {
                crate::city::query_founding(state, context, query)
                    .map(QueryResult::CityFoundingOptions)
                    .map_err(city_query_error)
            }
            GameQuery::CityWorkedHexOptions(query) => {
                crate::city::query_worked_hexes(state, context, query)
                    .map(QueryResult::CityWorkedHexOptions)
                    .map_err(city_query_error)
            }
            GameQuery::CityExpansionOptions(query) => {
                crate::city::query_expansion(state, context, query)
                    .map(QueryResult::CityExpansionOptions)
                    .map_err(city_query_error)
            }
            GameQuery::CombatPreview(query) => crate::combat::preview(state, context, query)
                .map(QueryResult::CombatPreview)
                .map_err(CanonicalQueryError::Combat),
            GameQuery::PlanRoute(query) => Self::plan_terrain_route(state, context, query)
                .map(QueryResult::Route)
                .map_err(CanonicalQueryError::Rejected),
            GameQuery::Reachable(query) => {
                Self::reachable_movement_with_workspace(state, context, query, workspace)
                    .map(QueryResult::Reachable)
                    .map_err(CanonicalQueryError::Rejected)
            }
            GameQuery::UnitLogisticsOptions(query) => {
                crate::movement::query_logistics_options(state, context, query, workspace)
                    .map(QueryResult::UnitLogisticsOptions)
                    .map_err(CanonicalQueryError::Logistics)
            }
            GameQuery::WorkerOptions(query) => crate::worker::query_options(state, context, query)
                .map(QueryResult::WorkerOptions)
                .map_err(worker_query_error),
        }
    }
}

fn worker_query_error(error: crate::worker::WorkerRuleError) -> CanonicalQueryError {
    match error {
        crate::worker::WorkerRuleError::Rejected(code) => CanonicalQueryError::Worker(code),
    }
}

fn city_query_error(error: crate::city::CityRuleError) -> CanonicalQueryError {
    match error {
        crate::city::CityRuleError::Rejected(code) => CanonicalQueryError::City(code),
        crate::city::CityRuleError::Technology(error) => CanonicalQueryError::Technology(error),
    }
}

#[cfg(test)]
mod tests;
