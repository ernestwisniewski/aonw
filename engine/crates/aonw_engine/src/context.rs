use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{FogVisibility, GameState, HexCoord, PlayerId, Unit};

use crate::movement::{CompiledMovementMap, MovementPlanningView, MovementVisibility};

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
    /// by [`crate::GameEngine::apply`] and [`crate::GameEngine::query`].
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

    #[cfg(test)]
    pub(crate) const fn new(
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

    #[cfg(test)]
    pub(crate) const fn with_action_permission(mut self, can_act: bool) -> Self {
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

    /// Returns whether the application boundary authorizes gameplay actions.
    #[must_use]
    pub const fn can_act(self) -> bool {
        self.can_act
    }

    pub(crate) const fn compiled_movement_map(self) -> Option<&'context CompiledMovementMap> {
        self.compiled_movement_map
    }

    pub(crate) fn with_world<'world>(self, world: &'world GameState) -> EngineContext<'world>
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

    pub(crate) fn observes_occupancy(self, moving_unit: &Unit, candidate: &Unit) -> bool {
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

    pub(crate) fn can_plan_through_tile(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        let Some(world) = self.world else {
            return true;
        };
        if self.visibility(world, coordinate) != FogVisibility::Hidden {
            return true;
        }
        moving_unit.position().distance_to(coordinate) <= 3
    }

    pub(crate) fn city_blocks(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
        self.world
            .and_then(|world| world.city_at(coordinate))
            .is_some_and(|city| city.owner_player_id() != moving_unit.owner_player_id())
    }

    pub(crate) fn city_block_is_known(self, moving_unit: &Unit, coordinate: HexCoord) -> bool {
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
