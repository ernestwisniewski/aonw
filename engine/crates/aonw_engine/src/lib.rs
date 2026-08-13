//! Pure entry point for deterministic game rules and queries.
//!
//! The first committed slice exposes version metadata and allocation-free state
//! inspection. Authoritative transitions are added only with reviewed parity
//! fixtures so an incomplete Rust rule cannot accidentally replace Dart.

#![forbid(unsafe_code)]

mod canonical_engine;
mod movement;
mod state_digest;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{FogVisibility, GameState, HexCoord, MovementState, MovementUnit, PlayerId};

pub use canonical_engine::{
    CanonicalEngineError, CanonicalQueryError, DomainCommand, DomainEvent, DomainRejection,
    DomainTransition, DomainTransitionParts, ExecutionEvidence, GameQuery, QueryResult,
};
pub use movement::{
    CompiledMovementMap, CompiledMovementMapError, MoveUnitCommand, MoveUnitError, MovementCost,
    MovementOccupancy, MovementPlanningView, MovementSearchMetrics, MovementSearchWorkspace,
    MovementTransition, MovementVisibility, ReachableMovement, ReachableMovementQuery,
    ReachableMovementTile, TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError,
    UnitMovedEvent, UnitMovementExecution, maximum_movement_units, terrain_entry_cost,
};
pub use state_digest::StateDigest;

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

    /// Returns reachable hexes while reusing caller-owned search storage.
    ///
    /// # Errors
    ///
    /// Returns [`TerrainMovementQueryError`] when the revision or unit does not
    /// admit a movement query.
    pub fn reachable_movement_with_workspace(
        state: &MovementState,
        context: EngineContext<'_>,
        query: ReachableMovementQuery<'_>,
        workspace: &mut MovementSearchWorkspace,
    ) -> Result<ReachableMovement, TerrainMovementQueryError> {
        movement::find_reachable_tiles_with_workspace(state, context, query, workspace)
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
    ruleset: &'context RulesetDefinition,
    planning_view: MovementPlanningView<'context>,
    can_act: bool,
    world: Option<&'context GameState>,
    compiled_movement_map: Option<&'context CompiledMovementMap>,
    movement_visibility: Option<&'context MovementVisibility>,
}

impl<'context> EngineContext<'context> {
    /// Constructs canonical context. Visibility is derived from [`GameState`]
    /// by [`GameEngine::apply`] and [`GameEngine::query`].
    #[must_use]
    pub const fn canonical(
        actor_player_id: &'context PlayerId,
        map: &'context MapDefinition,
        ruleset: &'context RulesetDefinition,
    ) -> Self {
        Self {
            actor_player_id,
            map,
            ruleset,
            planning_view: MovementPlanningView::fog_disabled(),
            can_act: true,
            world: None,
            compiled_movement_map: None,
            movement_visibility: None,
        }
    }

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
            ruleset: RulesetDefinition::standard(),
            planning_view,
            can_act: true,
            world: None,
            compiled_movement_map: None,
            movement_visibility: None,
        }
    }

    /// Replaces the standard ruleset with an explicit validated definition.
    #[must_use]
    pub const fn with_ruleset(mut self, ruleset: &'context RulesetDefinition) -> Self {
        self.ruleset = ruleset;
        self
    }

    /// Replaces the application-level permission result for this operation.
    #[must_use]
    pub const fn with_action_permission(mut self, can_act: bool) -> Self {
        self.can_act = can_act;
        self
    }

    /// Uses movement topology and terrain costs compiled for this map and ruleset.
    #[must_use]
    pub const fn with_compiled_movement_map(
        mut self,
        compiled: &'context CompiledMovementMap,
    ) -> Self {
        self.map = compiled.map();
        self.ruleset = compiled.ruleset();
        self.compiled_movement_map = Some(compiled);
        self
    }

    /// Uses tile-indexed visibility prepared for the actor and state revision.
    #[must_use]
    pub const fn with_movement_visibility(
        mut self,
        visibility: &'context MovementVisibility,
    ) -> Self {
        self.movement_visibility = Some(visibility);
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

    /// Returns the immutable ruleset used by the operation.
    #[must_use]
    pub const fn ruleset(self) -> &'context RulesetDefinition {
        self.ruleset
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

    pub(crate) const fn compiled_movement_map(self) -> Option<&'context CompiledMovementMap> {
        self.compiled_movement_map
    }

    fn with_world<'world>(self, world: &'world GameState) -> EngineContext<'world>
    where
        'context: 'world,
    {
        EngineContext {
            actor_player_id: self.actor_player_id,
            map: self.map,
            ruleset: self.ruleset,
            planning_view: self.planning_view,
            can_act: self.can_act,
            world: Some(world),
            compiled_movement_map: self.compiled_movement_map,
            movement_visibility: self.movement_visibility,
        }
    }

    pub(crate) fn observes_occupancy(
        self,
        moving_unit: &MovementUnit,
        candidate: &MovementUnit,
    ) -> bool {
        if candidate.owner_player_id() == moving_unit.owner_player_id() {
            return true;
        }
        self.world.map_or_else(
            || {
                self.planning_view
                    .observes_occupancy(moving_unit, candidate)
            },
            |world| self.visibility(world, candidate.position()) == FogVisibility::Visible,
        )
    }

    pub(crate) fn can_plan_through_tile(
        self,
        moving_unit: &MovementUnit,
        coordinate: HexCoord,
    ) -> bool {
        let Some(world) = self.world else {
            return true;
        };
        if self.visibility(world, coordinate) != FogVisibility::Hidden {
            return true;
        }
        moving_unit.position().distance_to(coordinate) <= 3
    }

    pub(crate) fn city_blocks(self, moving_unit: &MovementUnit, coordinate: HexCoord) -> bool {
        self.world
            .and_then(|world| world.city_at(coordinate))
            .is_some_and(|city| city.owner_player_id() != moving_unit.owner_player_id())
    }

    pub(crate) fn city_block_is_known(
        self,
        moving_unit: &MovementUnit,
        coordinate: HexCoord,
    ) -> bool {
        if !self.city_blocks(moving_unit, coordinate) {
            return false;
        }
        self.world
            .is_none_or(|world| self.visibility(world, coordinate) != FogVisibility::Hidden)
    }

    pub(crate) fn has_known_operational_road(self, coordinate: HexCoord) -> bool {
        let Some(world) = self.world else {
            return false;
        };
        let Some(segment) = world.transport_network().at(coordinate) else {
            return false;
        };
        if !segment.is_operational() {
            return false;
        }
        segment.built_by_player_id() == self.actor_player_id
            || segment
                .built_by_city_id()
                .and_then(|city_id| world.city(city_id))
                .is_some_and(|city| city.owner_player_id() == self.actor_player_id)
            || self.visibility(world, coordinate) != FogVisibility::Hidden
    }

    pub(crate) fn is_known_city_center(self, coordinate: HexCoord) -> bool {
        let Some(world) = self.world else {
            return false;
        };
        world.city_at(coordinate).is_some_and(|city| {
            city.owner_player_id() == self.actor_player_id
                || self.visibility(world, coordinate) != FogVisibility::Hidden
        })
    }

    fn visibility(self, world: &GameState, coordinate: HexCoord) -> FogVisibility {
        self.movement_visibility.map_or_else(
            || {
                world
                    .fog_of_war()
                    .visibility(self.actor_player_id, coordinate)
            },
            |visibility| visibility.at(self.map, coordinate),
        )
    }
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
    use aonw_domain::{
        HexCoord, MovementState, MovementUnit, MovementUnits, PlayerId, UnitId, UnitKind,
    };

    use super::{
        CompiledMovementMap, ENGINE_BEHAVIOR_VERSION, EngineContext, GameEngine,
        MovementPlanningView,
    };

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

    #[test]
    fn compiled_context_uses_the_content_it_was_compiled_from() {
        let actor = PlayerId::new("player-1").expect("valid player id");
        let map = single_tile_map("source");
        let other_map = single_tile_map("other");
        let compiled =
            CompiledMovementMap::compile(&map, RulesetDefinition::standard()).expect("compiled");

        let context = EngineContext::new(&actor, &other_map, MovementPlanningView::fog_disabled())
            .with_compiled_movement_map(&compiled);

        assert_eq!(context.map().map_id(), "source");
        assert_eq!(context.ruleset(), RulesetDefinition::standard());
    }

    fn single_tile_map(map_id: &str) -> MapDefinition {
        MapDefinition::try_new(
            map_id,
            GridLayout::OddQFlatTop,
            1,
            1,
            vec![
                TileDefinition::try_new(
                    HexCoord::new(0, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("valid tile"),
            ],
            Vec::new(),
        )
        .expect("valid logical map")
    }
}
