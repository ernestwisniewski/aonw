//! Pure entry point for deterministic game rules and queries.
//!
//! The first committed slice exposes version metadata and allocation-free state
//! inspection. Authoritative transitions are added only with reviewed parity
//! fixtures so an incomplete Rust rule cannot accidentally replace Dart.

#![forbid(unsafe_code)]

mod movement;

use aonw_content::MapDefinition;
use aonw_domain::{MovementState, PlayerId};

pub use movement::{
    MoveUnitCommand, MoveUnitError, MovementCost, MovementPlanningView, MovementSearchMetrics,
    MovementTransition, ReachableMovement, ReachableMovementQuery, ReachableMovementTile,
    TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError, UnitMovedEvent,
    UnitMovementExecution, maximum_movement_units, terrain_entry_cost,
};

/// Engine behavior version implemented by this workspace.
///
/// This axis is independent of save, wire, and native ABI versions.
pub const ENGINE_BEHAVIOR_VERSION: u16 = 1;

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

    /// Inspects the movement projection without allocation or mutation.
    #[must_use]
    pub const fn summarize_movement_state(state: &MovementState) -> MovementStateSummary {
        MovementStateSummary {
            revision: state.revision(),
            turn: state.turn(),
            unit_count: state.units().len(),
        }
    }

    /// Plans a deterministic route using terrain and known unit occupancy.
    ///
    /// This query intentionally excludes fog, cities, diplomacy, and roads
    /// until those authoritative state slices are ported.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainMovementQueryError`] when the revision, unit, target,
    /// occupancy, or terrain does not admit a route.
    pub fn plan_terrain_route(
        state: &MovementState,
        context: EngineContext<'_>,
        query: TerrainMovementQuery<'_>,
    ) -> Result<TerrainMovementPlan, TerrainMovementQueryError> {
        movement::plan_terrain_route(state, context, query)
    }

    /// Returns every actor-visible hex reachable during the current turn.
    ///
    /// The engine performs one bounded search and returns stable row-major
    /// output suitable for selection overlays.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainMovementQueryError`] when the revision or unit does not
    /// admit a movement query.
    pub fn reachable_movement(
        state: &MovementState,
        context: EngineContext<'_>,
        query: ReachableMovementQuery<'_>,
    ) -> Result<ReachableMovement, TerrainMovementQueryError> {
        movement::find_reachable_tiles(state, context, query)
    }

    /// Applies one revision-bound authoritative manual movement command.
    ///
    /// # Errors
    ///
    /// Returns [`MoveUnitError`] when validation, planning, or projection update
    /// fails. Rejected commands do not mutate the borrowed input state.
    pub fn apply_move_unit(
        state: &MovementState,
        context: EngineContext<'_>,
        command: MoveUnitCommand<'_>,
    ) -> Result<MovementTransition, MoveUnitError> {
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

/// Movement-projection summary for health checks and early adapters.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MovementStateSummary {
    /// Projection revision.
    pub revision: u64,
    /// Current turn.
    pub turn: u32,
    /// Number of projected units.
    pub unit_count: usize,
}

/// Immutable inputs that are authoritative for one command or query.
#[derive(Clone, Copy, Debug)]
pub struct EngineContext<'context> {
    actor_player_id: &'context PlayerId,
    map: &'context MapDefinition,
    planning_view: MovementPlanningView<'context>,
    can_act: bool,
}

impl<'context> EngineContext<'context> {
    /// Constructs an explicit context without ambient actor or map state.
    #[must_use]
    pub const fn new(
        actor_player_id: &'context PlayerId,
        map: &'context MapDefinition,
        planning_view: MovementPlanningView<'context>,
    ) -> Self {
        Self {
            actor_player_id,
            map,
            planning_view,
            can_act: true,
        }
    }

    /// Replaces the application-level permission result for this operation.
    #[must_use]
    pub const fn with_action_permission(mut self, can_act: bool) -> Self {
        self.can_act = can_act;
        self
    }

    /// Returns the player issuing the command or query.
    #[must_use]
    pub const fn actor_player_id(self) -> &'context PlayerId {
        self.actor_player_id
    }

    /// Returns the validated logical map used by the rules engine.
    #[must_use]
    pub const fn map(self) -> &'context MapDefinition {
        self.map
    }

    /// Returns actor-visible occupancy used by movement planning.
    #[must_use]
    pub const fn planning_view(self) -> MovementPlanningView<'context> {
        self.planning_view
    }

    /// Returns whether the application boundary authorizes gameplay actions.
    #[must_use]
    pub const fn can_act(self) -> bool {
        self.can_act
    }
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
    use aonw_domain::{
        HexCoord, MovementState, MovementUnit, MovementUnits, PlayerId, UnitId, UnitKind,
    };

    use super::{ENGINE_BEHAVIOR_VERSION, EngineContext, GameEngine, MovementPlanningView};

    #[test]
    fn engine_summary_reports_movement_projection() {
        let player_id = PlayerId::new("player-1").expect("valid player id");
        let state = MovementState::try_new(
            12,
            4,
            [MovementUnit::new(
                UnitId::new("unit-1").expect("valid unit id"),
                player_id,
                UnitKind::Commander,
                HexCoord::new(3, -2),
                MovementUnits::new(10),
            )],
        )
        .expect("valid state");

        let summary = GameEngine::summarize_movement_state(&state);
        assert_eq!(summary.revision, 12);
        assert_eq!(summary.turn, 4);
        assert_eq!(summary.unit_count, 1);
    }

    #[test]
    fn engine_version_axes_are_explicit() {
        let version = GameEngine::version();

        assert_eq!(version.crate_version, env!("CARGO_PKG_VERSION"));
        assert_eq!(version.behavior_version, ENGINE_BEHAVIOR_VERSION);
    }

    #[test]
    fn engine_context_carries_actor_and_map_explicitly() {
        let actor = PlayerId::new("player-1").expect("valid player id");
        let tile = TileDefinition::try_new(
            HexCoord::new(0, 0),
            vec![TerrainType::Plains],
            Vec::new(),
            0,
        )
        .expect("valid tile");
        let map = MapDefinition::try_new(
            "fixture",
            GridLayout::OddQFlatTop,
            1,
            1,
            vec![tile],
            Vec::new(),
        )
        .expect("valid logical map");

        let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

        assert_eq!(context.actor_player_id(), &actor);
        assert_eq!(context.map().map_id(), "fixture");
    }
}
