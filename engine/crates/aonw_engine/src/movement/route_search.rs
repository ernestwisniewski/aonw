use std::cmp::Ordering;
use std::collections::BinaryHeap;

use aonw_content::MapDefinition;
use aonw_domain::{HexCoord, HexTileIndex, MovementStep, MovementUnits, Unit};

use super::compiled_map::neighbor_indices;
use super::cost::{movement_cost_for_index, terrain_entry_cost};
use super::{
    MovementAccess, MovementCost, MovementOccupancy, MovementSearchMetrics, maximum_movement_units,
};
use crate::EngineContext;

pub(super) struct RouteSearchResult {
    pub(super) steps: Option<Vec<MovementStep>>,
    pub(super) metrics: MovementSearchMetrics,
}

#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd)]
struct RouteScore {
    turns: u32,
    total_cost: u32,
    step_count: u16,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct RouteState {
    tile_index: usize,
    remaining: u32,
    started: bool,
}

#[derive(Clone, Copy, Debug)]
struct RouteRecord {
    state: RouteState,
    score: RouteScore,
    parent: Option<usize>,
    enter_cost: MovementUnits,
}

#[derive(Clone, Copy, Debug)]
struct BestRouteRecord {
    score: RouteScore,
    record_index: usize,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct FrontierNode {
    record_index: usize,
    state: RouteState,
    score: RouteScore,
    col: i32,
    row: i32,
}

impl Ord for FrontierNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .score
            .cmp(&self.score)
            .then_with(|| other.col.cmp(&self.col))
            .then_with(|| other.row.cmp(&self.row))
            .then_with(|| self.state.remaining.cmp(&other.state.remaining))
            .then_with(|| other.record_index.cmp(&self.record_index))
    }
}

impl PartialOrd for FrontierNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

struct PreparedRouteSearch {
    target_indices: Box<[usize]>,
    maximum_movement: MovementUnits,
    occupied: MovementOccupancy,
    access: MovementAccess,
    records: Vec<RouteRecord>,
    best_by_state: Vec<Option<BestRouteRecord>>,
    remaining_slots: usize,
    frontier: BinaryHeap<FrontierNode>,
    metrics: MovementSearchMetrics,
    movement_domain: aonw_domain::UnitMovementDomain,
}

pub(super) fn find_route(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    target: HexCoord,
    available_movement: MovementUnits,
    context: EngineContext<'_>,
) -> RouteSearchResult {
    find_route_with_maximum(
        units,
        map,
        unit,
        &[target],
        available_movement,
        context,
        None,
    )
}

pub(super) fn find_route_to_any(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    targets: &[HexCoord],
    available_movement: MovementUnits,
    context: EngineContext<'_>,
) -> RouteSearchResult {
    find_route_with_maximum(units, map, unit, targets, available_movement, context, None)
}

pub(super) fn find_route_ignoring_capacity(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    target: HexCoord,
    available_movement: MovementUnits,
    context: EngineContext<'_>,
) -> RouteSearchResult {
    let Some(definition) = context.ruleset().unit(unit.kind()) else {
        return RouteSearchResult {
            steps: None,
            metrics: MovementSearchMetrics::default(),
        };
    };
    let movement_domain = definition.capabilities().movement_domain.domain();
    let diagnostic_maximum = map
        .tiles()
        .iter()
        .filter_map(|tile| match terrain_entry_cost(tile, movement_domain) {
            MovementCost::Passable(cost) => Some(cost),
            MovementCost::Blocked => None,
        })
        .max()
        .unwrap_or(available_movement);
    find_route_with_maximum(
        units,
        map,
        unit,
        &[target],
        available_movement,
        context,
        Some(diagnostic_maximum),
    )
}

fn find_route_with_maximum(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    targets: &[HexCoord],
    available_movement: MovementUnits,
    context: EngineContext<'_>,
    maximum_override: Option<MovementUnits>,
) -> RouteSearchResult {
    let Some(prepared) = prepare_route_search(
        units,
        map,
        unit,
        targets,
        available_movement,
        context,
        maximum_override,
    ) else {
        return RouteSearchResult {
            steps: None,
            metrics: MovementSearchMetrics::default(),
        };
    };
    run_route_search(prepared, map, unit, context)
}

fn prepare_route_search(
    units: &[Unit],
    map: &MapDefinition,
    unit: &Unit,
    targets: &[HexCoord],
    available_movement: MovementUnits,
    context: EngineContext<'_>,
    maximum_override: Option<MovementUnits>,
) -> Option<PreparedRouteSearch> {
    let definition = context.ruleset().unit(unit.kind())?;
    let start_index = map.tile_index(unit.position()).map(HexTileIndex::get)?;
    let target_indices = targets
        .iter()
        .filter_map(|target| map.tile_index(*target).map(HexTileIndex::get))
        .collect::<Vec<_>>();
    if target_indices.is_empty() {
        return None;
    }
    let occupied = MovementOccupancy::for_unit(units, map, unit, context);
    let access = context.prepare_movement_access(unit);
    let maximum_movement = maximum_override.unwrap_or_else(|| {
        maximum_movement_units(
            context.ruleset(),
            unit.kind(),
            unit.carried_artifact_id().is_some(),
        )
    });

    let start_state = RouteState {
        tile_index: start_index,
        remaining: available_movement.get(),
        started: false,
    };
    let start_score = RouteScore {
        turns: 0,
        total_cost: 0,
        step_count: 0,
    };
    let records = vec![RouteRecord {
        state: start_state,
        score: start_score,
        parent: None,
        enter_cost: MovementUnits::ZERO,
    }];
    let remaining_slots = usize::try_from(maximum_movement.get().max(available_movement.get()))
        .ok()?
        .checked_add(1)?;
    let state_slot_count = map
        .bounds()
        .tile_count()
        .checked_mul(remaining_slots)?
        .checked_mul(2)?;
    let mut best_by_state = vec![None; state_slot_count];
    let start_slot = route_state_slot(start_state, remaining_slots)?;
    best_by_state[start_slot] = Some(BestRouteRecord {
        score: start_score,
        record_index: 0,
    });
    let mut frontier = BinaryHeap::new();
    let start_node = frontier_node(map, 0, records[0])?;
    frontier.push(start_node);
    let mut metrics = MovementSearchMetrics::default();
    metrics.retained_record();
    metrics.pushed();
    Some(PreparedRouteSearch {
        target_indices: target_indices.into_boxed_slice(),
        maximum_movement,
        occupied,
        access,
        records,
        best_by_state,
        remaining_slots,
        frontier,
        metrics,
        movement_domain: definition.capabilities().movement_domain.domain(),
    })
}

fn run_route_search(
    mut search: PreparedRouteSearch,
    map: &MapDefinition,
    unit: &Unit,
    context: EngineContext<'_>,
) -> RouteSearchResult {
    while let Some(current_node) = search.frontier.pop() {
        search.metrics.popped();
        if !is_current_best(&search.best_by_state, search.remaining_slots, current_node) {
            continue;
        }
        let current = search.records[current_node.record_index];
        if search.target_indices.contains(&current.state.tile_index) {
            return RouteSearchResult {
                steps: reconstruct_route(map, &search.records, current_node.record_index),
                metrics: search.metrics,
            };
        }
        search.metrics.expanded();
        let (neighbors, neighbor_count) = neighbor_indices(
            map,
            context.compiled_movement_map(),
            current.state.tile_index,
        );
        for &next_index in &neighbors[..neighbor_count] {
            search.metrics.examined_edge();
            let Some(next_coordinate) = map.coordinate_at(HexTileIndex::new(next_index)) else {
                continue;
            };
            if search.occupied.contains(next_index) {
                continue;
            }
            if !context.can_plan_through_tile(unit, next_coordinate)
                || search.access.blocks(next_index)
            {
                continue;
            }
            let MovementCost::Passable(enter_cost) = movement_cost_for_index(
                current.state.tile_index,
                next_coordinate,
                next_index,
                map,
                search.movement_domain,
                context,
                &search.access,
            ) else {
                continue;
            };
            if enter_cost > search.maximum_movement && unit.carried_artifact_id().is_none() {
                continue;
            }
            let Some(next_score) = next_score(current.score, enter_cost) else {
                continue;
            };
            let Some((turns, remaining)) = advance_route(
                current.state,
                current.score.turns,
                enter_cost,
                search.maximum_movement,
            ) else {
                continue;
            };
            let next_state = RouteState {
                tile_index: next_index,
                remaining,
                started: true,
            };
            let next_score = RouteScore {
                turns,
                ..next_score
            };
            if !record_if_better(
                &mut search.best_by_state,
                search.remaining_slots,
                next_state,
                next_score,
                search.records.len(),
            ) {
                continue;
            }
            let record_index = search.records.len();
            let record = RouteRecord {
                state: next_state,
                score: next_score,
                parent: Some(current_node.record_index),
                enter_cost,
            };
            search.records.push(record);
            search.metrics.retained_record();
            if let Some(node) = frontier_node(map, record_index, record) {
                search.frontier.push(node);
                search.metrics.pushed();
            }
        }
    }
    RouteSearchResult {
        steps: None,
        metrics: search.metrics,
    }
}

fn frontier_node(
    map: &MapDefinition,
    record_index: usize,
    record: RouteRecord,
) -> Option<FrontierNode> {
    let coordinate = map.coordinate_at(HexTileIndex::new(record.state.tile_index))?;
    Some(FrontierNode {
        record_index,
        state: record.state,
        score: record.score,
        col: coordinate.col(),
        row: coordinate.row(),
    })
}

fn is_current_best(
    best_by_state: &[Option<BestRouteRecord>],
    remaining_slots: usize,
    node: FrontierNode,
) -> bool {
    route_state_slot(node.state, remaining_slots)
        .and_then(|slot| best_by_state.get(slot).copied().flatten())
        .is_some_and(|best| best.score == node.score && best.record_index == node.record_index)
}

fn record_if_better(
    best_by_state: &mut [Option<BestRouteRecord>],
    remaining_slots: usize,
    state: RouteState,
    score: RouteScore,
    record_index: usize,
) -> bool {
    let Some(slot) = route_state_slot(state, remaining_slots) else {
        return false;
    };
    let Some(best) = best_by_state.get_mut(slot) else {
        return false;
    };
    if best.is_some_and(|existing| existing.score <= score) {
        return false;
    }
    *best = Some(BestRouteRecord {
        score,
        record_index,
    });
    true
}

fn route_state_slot(state: RouteState, remaining_slots: usize) -> Option<usize> {
    let remaining = usize::try_from(state.remaining).ok()?;
    if remaining >= remaining_slots {
        return None;
    }
    state
        .tile_index
        .checked_mul(remaining_slots)?
        .checked_add(remaining)?
        .checked_mul(2)?
        .checked_add(usize::from(state.started))
}

fn next_score(score: RouteScore, enter_cost: MovementUnits) -> Option<RouteScore> {
    Some(RouteScore {
        turns: score.turns,
        total_cost: score.total_cost.checked_add(enter_cost.get())?,
        step_count: score.step_count.checked_add(1)?,
    })
}

fn advance_route(
    state: RouteState,
    current_turns: u32,
    enter_cost: MovementUnits,
    maximum_movement: MovementUnits,
) -> Option<(u32, u32)> {
    let mut turns = current_turns;
    if !state.started {
        turns = turns.checked_add(1)?;
    }
    let remaining = if enter_cost.get() <= state.remaining {
        state.remaining - enter_cost.get()
    } else if state.remaining > 0 {
        0
    } else {
        turns = turns.checked_add(1)?;
        maximum_movement.get().saturating_sub(enter_cost.get())
    };
    Some((turns, remaining))
}

fn reconstruct_route(
    map: &MapDefinition,
    records: &[RouteRecord],
    target_record_index: usize,
) -> Option<Vec<MovementStep>> {
    let mut record_indices = Vec::new();
    let mut cursor = Some(target_record_index);
    while let Some(index) = cursor {
        record_indices.push(index);
        cursor = records[index].parent;
    }
    record_indices.reverse();
    record_indices
        .into_iter()
        .map(|index| {
            let record = records[index];
            let coordinate = map.coordinate_at(HexTileIndex::new(record.state.tile_index))?;
            Some(MovementStep::new(
                coordinate,
                record.enter_cost,
                MovementUnits::new(record.score.total_cost),
            ))
        })
        .collect()
}
