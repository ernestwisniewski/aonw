mod balance;
mod cost;
mod query;
#[cfg(test)]
mod query_tests;
mod route_search;
mod terrain_profile;

pub use balance::maximum_movement_units;
pub use cost::{MovementCost, terrain_entry_cost};
pub use query::{TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError};

pub(crate) use query::plan_terrain_route;
