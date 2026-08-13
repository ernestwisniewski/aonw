mod balance;
mod cost;
mod metrics;
mod planning_view;
mod query;
#[cfg(test)]
mod query_tests;
mod reachable;
mod route_search;
mod terrain_profile;
mod transition;
#[cfg(test)]
mod transition_tests;

pub use balance::maximum_movement_units;
pub use cost::{MovementCost, terrain_entry_cost};
pub use metrics::MovementSearchMetrics;
pub use planning_view::MovementPlanningView;
pub use query::{TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError};
pub use reachable::{ReachableMovement, ReachableMovementQuery, ReachableMovementTile};
pub use transition::{
    MoveUnitCommand, MoveUnitError, MovementTransition, UnitMovedEvent, UnitMovementExecution,
};

pub(crate) use query::plan_terrain_route;
pub(crate) use reachable::find_reachable_tiles;
pub(crate) use transition::apply_move_unit;
