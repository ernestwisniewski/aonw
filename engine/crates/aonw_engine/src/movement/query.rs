use aonw_content::MapDefinition;
use aonw_domain::{HexCoord, MovementStep, MovementUnits, Unit, UnitId, UnitPosture, WorldState};

use super::maximum_movement_units;
use super::route_search::find_route;
use crate::EngineContext;

/// Input for deterministic terrain-only movement planning.
#[derive(Clone, Copy, Debug)]
pub struct TerrainMovementQuery<'query> {
    expected_revision: u64,
    unit_id: &'query UnitId,
    target: HexCoord,
}

impl<'query> TerrainMovementQuery<'query> {
    /// Creates a revision-bound route query.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'query UnitId, target: HexCoord) -> Self {
        Self {
            expected_revision,
            unit_id,
            target,
        }
    }
}

/// Deterministic route and the prefix executable during the current turn.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TerrainMovementPlan {
    revision: u64,
    unit_id: UnitId,
    target: HexCoord,
    total_cost: MovementUnits,
    available_movement: MovementUnits,
    remaining_movement: MovementUnits,
    furthest_reachable_step_index: usize,
    steps: Box<[MovementStep]>,
}

impl TerrainMovementPlan {
    /// Returns the state revision used to compute the plan.
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }

    /// Returns the moving unit identifier.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns the requested destination.
    #[must_use]
    pub const fn target(&self) -> HexCoord {
        self.target
    }

    /// Returns the complete multi-turn route cost.
    #[must_use]
    pub const fn total_cost(&self) -> MovementUnits {
        self.total_cost
    }

    /// Returns movement available before executing the current-turn prefix.
    #[must_use]
    pub const fn available_movement(&self) -> MovementUnits {
        self.available_movement
    }

    /// Returns movement remaining after executing the current-turn prefix.
    #[must_use]
    pub const fn remaining_movement(&self) -> MovementUnits {
        self.remaining_movement
    }

    /// Returns the route including its zero-cost origin.
    #[must_use]
    pub const fn steps(&self) -> &[MovementStep] {
        &self.steps
    }

    /// Returns the route prefix executable during the current turn.
    #[must_use]
    pub fn reachable_steps(&self) -> &[MovementStep] {
        &self.steps[..=self.furthest_reachable_step_index]
    }

    /// Returns whether the complete target can be reached this turn.
    #[must_use]
    pub fn target_reachable_this_turn(&self) -> bool {
        self.furthest_reachable_step_index + 1 == self.steps.len()
    }
}

/// Rejection from the terrain-only movement query.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum TerrainMovementQueryError {
    StaleRevision {
        expected: u64,
        actual: u64,
    },
    UnitNotFound,
    UnitNotControlled,
    UnitUnavailable,
    UnitUsesTradeRoutes,
    UnitOutOfBounds,
    InvalidMovementBalance {
        actual: MovementUnits,
        maximum: MovementUnits,
    },
    TargetOutOfBounds,
    TargetIsCurrentTile,
    TargetOccupied,
    PathNotFound,
}

impl core::fmt::Display for TerrainMovementQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::StaleRevision { expected, actual } => {
                write!(
                    formatter,
                    "stale revision {expected}; current revision is {actual}"
                )
            }
            Self::UnitNotFound => formatter.write_str("unit not found"),
            Self::UnitNotControlled => formatter.write_str("unit is not controlled by the actor"),
            Self::UnitUnavailable => formatter.write_str("unit is unavailable for manual movement"),
            Self::UnitUsesTradeRoutes => formatter.write_str("unit uses trade routes"),
            Self::UnitOutOfBounds => formatter.write_str("unit is outside map bounds"),
            Self::InvalidMovementBalance { actual, maximum } => write!(
                formatter,
                "unit movement balance {} exceeds maximum {}",
                actual.get(),
                maximum.get()
            ),
            Self::TargetOutOfBounds => formatter.write_str("target is outside map bounds"),
            Self::TargetIsCurrentTile => formatter.write_str("target is the current tile"),
            Self::TargetOccupied => formatter.write_str("target is occupied"),
            Self::PathNotFound => formatter.write_str("movement path not found"),
        }
    }
}

impl std::error::Error for TerrainMovementQueryError {}

pub(crate) fn plan_terrain_route(
    state: &WorldState,
    context: EngineContext<'_>,
    query: TerrainMovementQuery<'_>,
) -> Result<TerrainMovementPlan, TerrainMovementQueryError> {
    validate_revision(state, query.expected_revision)?;
    let unit = validate_unit(state, context, query.unit_id)?;
    validate_target(state, context.map(), unit, query.target)?;

    let available_movement = if unit.posture() == UnitPosture::Fortified {
        maximum_movement_units(unit.kind(), unit.carried_artifact_id().is_some())
    } else {
        unit.movement_units()
    };
    let steps = find_route(state, context.map(), unit, query.target, available_movement)
        .ok_or(TerrainMovementQueryError::PathNotFound)?;
    let total_cost = steps
        .last()
        .map_or(MovementUnits::ZERO, |step| step.cumulative_cost());
    let furthest_reachable_step_index = reachable_step_index(&steps, available_movement);
    let reachable_cost = steps
        .get(furthest_reachable_step_index)
        .ok_or(TerrainMovementQueryError::PathNotFound)?
        .cumulative_cost();
    let remaining_movement = available_movement
        .checked_sub(reachable_cost)
        .unwrap_or(MovementUnits::ZERO);

    Ok(TerrainMovementPlan {
        revision: state.revision(),
        unit_id: unit.id().clone(),
        target: query.target,
        total_cost,
        available_movement,
        remaining_movement,
        furthest_reachable_step_index,
        steps: steps.into_boxed_slice(),
    })
}

fn validate_revision(
    state: &WorldState,
    expected_revision: u64,
) -> Result<(), TerrainMovementQueryError> {
    if state.revision() == expected_revision {
        return Ok(());
    }
    Err(TerrainMovementQueryError::StaleRevision {
        expected: expected_revision,
        actual: state.revision(),
    })
}

fn validate_unit<'state>(
    state: &'state WorldState,
    context: EngineContext<'_>,
    unit_id: &UnitId,
) -> Result<&'state Unit, TerrainMovementQueryError> {
    let unit = state
        .unit(unit_id)
        .ok_or(TerrainMovementQueryError::UnitNotFound)?;
    if unit.owner_player_id() != context.actor_player_id() {
        return Err(TerrainMovementQueryError::UnitNotControlled);
    }
    if unit.is_working() {
        return Err(TerrainMovementQueryError::UnitUnavailable);
    }
    if unit.kind().uses_trade_routes() {
        return Err(TerrainMovementQueryError::UnitUsesTradeRoutes);
    }
    if context.map().tile_at(unit.position()).is_none() {
        return Err(TerrainMovementQueryError::UnitOutOfBounds);
    }
    let maximum = maximum_movement_units(unit.kind(), unit.carried_artifact_id().is_some());
    if unit.posture() != UnitPosture::Fortified && unit.movement_units() > maximum {
        return Err(TerrainMovementQueryError::InvalidMovementBalance {
            actual: unit.movement_units(),
            maximum,
        });
    }
    Ok(unit)
}

fn validate_target(
    state: &WorldState,
    map: &MapDefinition,
    unit: &Unit,
    target: HexCoord,
) -> Result<(), TerrainMovementQueryError> {
    if map.tile_at(target).is_none() {
        return Err(TerrainMovementQueryError::TargetOutOfBounds);
    }
    if target == unit.position() {
        return Err(TerrainMovementQueryError::TargetIsCurrentTile);
    }
    if state
        .units()
        .iter()
        .any(|candidate| candidate.id() != unit.id() && candidate.position() == target)
    {
        return Err(TerrainMovementQueryError::TargetOccupied);
    }
    Ok(())
}

fn reachable_step_index(steps: &[MovementStep], available: MovementUnits) -> usize {
    let mut reachable_index = 0;
    for (index, step) in steps.iter().enumerate().skip(1) {
        let before_step = step
            .cumulative_cost()
            .checked_sub(step.enter_cost())
            .unwrap_or(MovementUnits::ZERO);
        if step.cumulative_cost() <= available || before_step < available {
            reachable_index = index;
        } else {
            break;
        }
    }
    reachable_index
}
