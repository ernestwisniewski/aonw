//! Pure entry point for deterministic game rules and queries.
//!
//! Authoritative transitions are added only with reviewed parity fixtures so
//! an incomplete Rust rule cannot accidentally replace Dart.

#![forbid(unsafe_code)]

mod application;
mod context;
mod movement;
mod state_digest;
mod unit_action;

use aonw_domain::GameState;

pub use application::{
    CanonicalEngineError, CanonicalQueryError, DomainCommand, DomainEvent, DomainRejection,
    DomainTransition, DomainTransitionParts, ExecutionEvidence, GameQuery, QueryResult,
};
pub use context::EngineContext;
pub use movement::{
    CompiledMovementMap, CompiledMovementMapError, MoveUnitCommand, MoveUnitError, MovementCost,
    MovementSearchMetrics, MovementSearchWorkspace, MovementVisibility, ReachableMovement,
    ReachableMovementQuery, ReachableMovementTile, TerrainMovementPlan, TerrainMovementQuery,
    TerrainMovementQueryError, UnitMovedEvent, UnitMovementExecution, maximum_movement_units,
    terrain_entry_cost,
};
pub use state_digest::StateDigest;
pub use unit_action::{UnitActionCommand, UnitActionError};

/// Engine behavior version implemented by this workspace.
///
/// This axis is independent of save, wire, and native ABI versions.
pub const ENGINE_BEHAVIOR_VERSION: u16 = 2;

/// Stateless deterministic engine facade.
#[derive(Clone, Copy, Debug, Default)]
pub struct GameEngine;

impl GameEngine {
    /// Returns compile-time crate version metadata.
    #[must_use]
    pub const fn version() -> EngineVersion {
        EngineVersion {
            crate_version: env!("CARGO_PKG_VERSION"),
            behavior_version: ENGINE_BEHAVIOR_VERSION,
        }
    }

    /// Inspects canonical state without allocation or mutation.
    #[must_use]
    pub const fn summarize_state(state: &GameState) -> GameStateSummary {
        GameStateSummary {
            revision: state.revision().get(),
            turn: state.turn(),
            unit_count: state.units().len(),
        }
    }

    pub(crate) fn plan_terrain_route(
        state: &GameState,
        context: EngineContext<'_>,
        query: TerrainMovementQuery<'_>,
    ) -> Result<TerrainMovementPlan, TerrainMovementQueryError> {
        movement::plan_terrain_route(state, context, query)
    }

    pub(crate) fn reachable_movement_with_workspace(
        state: &GameState,
        context: EngineContext<'_>,
        query: ReachableMovementQuery<'_>,
        workspace: &mut MovementSearchWorkspace,
    ) -> Result<ReachableMovement, TerrainMovementQueryError> {
        movement::find_reachable_tiles_with_workspace(state, context, query, workspace)
    }

    pub(crate) fn apply_move_unit(
        state: &GameState,
        context: EngineContext<'_>,
        command: MoveUnitCommand<'_>,
    ) -> Result<movement::MovementTransition, MoveUnitError> {
        movement::apply_move_unit(state, context, command)
    }
}

/// Compile-time engine version metadata.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct EngineVersion {
    /// Cargo crate version.
    pub crate_version: &'static str,
    /// Deterministic behavior compatibility version.
    pub behavior_version: u16,
}

/// Canonical-state summary for health checks and adapters.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct GameStateSummary {
    /// State revision.
    pub revision: u64,
    /// Current turn.
    pub turn: u32,
    /// Number of projected units.
    pub unit_count: usize,
}

#[cfg(test)]
mod tests;
