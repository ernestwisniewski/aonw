mod balance;
mod compiled_map;
mod cost;
mod fog;
mod metrics;
mod occupancy;
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
mod visibility;
mod workspace;

pub use balance::maximum_movement_units;
pub use compiled_map::{CompiledMovementMap, CompiledMovementMapError};
pub use cost::{MovementCost, terrain_entry_cost};
pub use metrics::MovementSearchMetrics;
pub(crate) use occupancy::MovementOccupancy;
pub(crate) use planning_view::MovementPlanningView;
pub use query::{TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError};
pub use reachable::{ReachableMovement, ReachableMovementQuery, ReachableMovementTile};
pub use transition::{MoveUnitCommand, MoveUnitError, UnitMovedEvent, UnitMovementExecution};
pub use visibility::MovementVisibility;
pub use workspace::MovementSearchWorkspace;

pub(crate) use fog::{merge_discovered_contacts, recompute_after_move};
pub(crate) use query::plan_terrain_route;
#[cfg(test)]
pub(crate) use reachable::find_reachable_tiles;
pub(crate) use reachable::find_reachable_tiles_with_workspace;
pub(crate) use transition::MovementTransition;
pub(crate) use transition::apply_move_unit;
