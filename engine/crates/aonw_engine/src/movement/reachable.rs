use std::cmp::Ordering;
use std::collections::BinaryHeap;

use aonw_content::MapDefinition;
use aonw_domain::{
    HexCoord, HexTileIndex, MovementState, MovementUnit, MovementUnits, UnitId, UnitPosture,
};

use super::cost::movement_cost_for_edge;
use super::query::{validate_revision, validate_unit};
use super::{
    MovementCost, MovementSearchMetrics, TerrainMovementQueryError, maximum_movement_units,
};
use crate::EngineContext;

/// Input for a revision-bound reachable-hex query.
#[derive(Clone, Copy, Debug)]
pub struct ReachableMovementQuery<'query> {
    expected_revision: u64,
    unit_id: &'query UnitId,
}

impl<'query> ReachableMovementQuery<'query> {
    /// Creates a query for every hex reachable during the current turn.
    #[must_use]
    pub const fn new(expected_revision: u64, unit_id: &'query UnitId) -> Self {
        Self {
            expected_revision,
            unit_id,
        }
    }
}

/// One row-major reachable coordinate and its minimum current-turn cost.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ReachableMovementTile {
    coordinate: HexCoord,
    cost: MovementUnits,
    exhausts_movement: bool,
}

impl ReachableMovementTile {
    /// Returns the reachable coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    /// Returns the minimum fixed-point cost from the unit origin.
    #[must_use]
    pub const fn cost(self) -> MovementUnits {
        self.cost
    }

    /// Returns whether entering this boundary tile consumes the remaining turn.
    #[must_use]
    pub const fn exhausts_movement(self) -> bool {
        self.exhausts_movement
    }
}

/// Deterministic row-major result for a reachable-hex query.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReachableMovement {
    revision: u64,
    unit_id: UnitId,
    available_movement: MovementUnits,
    tiles: Box<[ReachableMovementTile]>,
    search_metrics: MovementSearchMetrics,
}

impl ReachableMovement {
    /// Returns the state revision used by the query.
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }

    /// Returns the queried unit.
    #[must_use]
    pub const fn unit_id(&self) -> &UnitId {
        &self.unit_id
    }

    /// Returns movement available at query time.
    #[must_use]
    pub const fn available_movement(&self) -> MovementUnits {
        self.available_movement
    }

    /// Returns reachable tiles in stable row-major order.
    #[must_use]
    pub const fn tiles(&self) -> &[ReachableMovementTile] {
        &self.tiles
    }

    /// Returns deterministic search work counters.
    #[must_use]
    pub const fn search_metrics(&self) -> MovementSearchMetrics {
        self.search_metrics
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct FrontierNode {
    cost: u32,
    index: usize,
    col: i32,
    row: i32,
}

impl Ord for FrontierNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .cmp(&self.cost)
            .then_with(|| other.col.cmp(&self.col))
            .then_with(|| other.row.cmp(&self.row))
    }
}

impl PartialOrd for FrontierNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

pub(crate) fn find_reachable_tiles(
    state: &MovementState,
    context: EngineContext<'_>,
    query: ReachableMovementQuery<'_>,
) -> Result<ReachableMovement, TerrainMovementQueryError> {
    validate_revision(state, query.expected_revision)?;
    let unit = validate_unit(state, context, query.unit_id)?;
    let available = movement_available_for_query(unit, context.ruleset());
    let (costs, search_metrics) = reachable_costs(state, context.map(), unit, available, context);
    let tiles = costs
        .into_iter()
        .enumerate()
        .filter_map(|(index, cost)| {
            let cost = cost?;
            if index == context.map().tile_index(unit.position())?.get() {
                return None;
            }
            Some(ReachableMovementTile {
                coordinate: context.map().coordinate_at(HexTileIndex::new(index))?,
                cost,
                exhausts_movement: cost > available,
            })
        })
        .collect::<Vec<_>>()
        .into_boxed_slice();
    Ok(ReachableMovement {
        revision: state.revision(),
        unit_id: unit.id().clone(),
        available_movement: available,
        tiles,
        search_metrics,
    })
}

pub(super) fn movement_available_for_query(
    unit: &MovementUnit,
    ruleset: &aonw_content::RulesetDefinition,
) -> MovementUnits {
    if unit.posture() == UnitPosture::Fortified {
        maximum_movement_units(ruleset, unit.kind(), unit.carried_artifact_id().is_some())
    } else {
        unit.movement_units()
    }
}

fn reachable_costs(
    state: &MovementState,
    map: &MapDefinition,
    unit: &MovementUnit,
    available: MovementUnits,
    context: EngineContext<'_>,
) -> (Vec<Option<MovementUnits>>, MovementSearchMetrics) {
    let Some(definition) = context.ruleset().unit(unit.kind()) else {
        return (
            vec![None; map.bounds().tile_count()],
            MovementSearchMetrics::default(),
        );
    };
    let mut metrics = MovementSearchMetrics::default();
    let Some(start) = map.tile_index(unit.position()).map(HexTileIndex::get) else {
        return (vec![None; map.bounds().tile_count()], metrics);
    };
    let mut occupied = vec![false; map.bounds().tile_count()];
    for candidate in state.units() {
        if candidate.id() == unit.id() || !context.observes_occupancy(unit, candidate) {
            continue;
        }
        if let Some(index) = map.tile_index(candidate.position()) {
            occupied[index.get()] = true;
        }
    }
    let mut costs = vec![None; map.bounds().tile_count()];
    costs[start] = Some(MovementUnits::ZERO);
    let mut frontier = BinaryHeap::new();
    let start_coord = unit.position();
    frontier.push(FrontierNode {
        cost: 0,
        index: start,
        col: start_coord.col(),
        row: start_coord.row(),
    });
    metrics.pushed();
    let maximum = maximum_movement_units(
        context.ruleset(),
        unit.kind(),
        unit.carried_artifact_id().is_some(),
    );

    while let Some(current) = frontier.pop() {
        metrics.popped();
        if costs[current.index].is_none_or(|known| known.get() != current.cost) {
            continue;
        }
        if current.cost >= available.get() {
            continue;
        }
        let Some(coordinate) = map.coordinate_at(HexTileIndex::new(current.index)) else {
            continue;
        };
        metrics.expanded();
        for next in map.neighbors(coordinate) {
            metrics.examined_edge();
            let Some(next_index) = map.tile_index(next).map(HexTileIndex::get) else {
                continue;
            };
            if occupied[next_index] {
                continue;
            }
            if !context.can_plan_through_tile(unit, next) || context.city_block_is_known(unit, next)
            {
                continue;
            }
            let Some(tile) = map.tile_at(next) else {
                continue;
            };
            let MovementCost::Passable(enter_cost) = movement_cost_for_edge(
                coordinate,
                next,
                tile,
                definition.capabilities().movement_domain.domain(),
                context,
            ) else {
                continue;
            };
            if enter_cost > maximum && unit.carried_artifact_id().is_none() {
                continue;
            }
            let Some(next_cost) = current.cost.checked_add(enter_cost.get()) else {
                continue;
            };
            if costs[next_index].is_some_and(|known| known.get() <= next_cost) {
                continue;
            }
            let movement_cost = MovementUnits::new(next_cost);
            costs[next_index] = Some(movement_cost);
            frontier.push(FrontierNode {
                cost: next_cost,
                index: next_index,
                col: next.col(),
                row: next.row(),
            });
            metrics.pushed();
        }
    }
    (costs, metrics)
}
