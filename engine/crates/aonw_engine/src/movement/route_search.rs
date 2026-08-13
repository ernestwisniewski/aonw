use std::cmp::Ordering;
use std::collections::BinaryHeap;

use aonw_content::MapDefinition;
use aonw_domain::{
    HexCoord, HexTileIndex, MovementState, MovementStep, MovementUnit, MovementUnits,
};

use super::cost::{movement_cost_for_edge, terrain_entry_cost};
use super::{MovementCost, MovementSearchMetrics, maximum_movement_units};
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
    target_index: usize,
    maximum_movement: MovementUnits,
    occupied: Vec<bool>,
    records: Vec<RouteRecord>,
    best_by_tile: Vec<Vec<(u32, bool, RouteScore, usize)>>,
    frontier: BinaryHeap<FrontierNode>,
    metrics: MovementSearchMetrics,
    movement_domain: aonw_domain::UnitMovementDomain,
}

pub(super) fn find_route(
    state: &MovementState,
    map: &MapDefinition,
    unit: &MovementUnit,
    target: HexCoord,
    available_movement: MovementUnits,
    context: EngineContext<'_>,
) -> RouteSearchResult {
    find_route_with_maximum(state, map, unit, target, available_movement, context, None)
}

pub(super) fn find_route_ignoring_capacity(
    state: &MovementState,
    map: &MapDefinition,
    unit: &MovementUnit,
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
        state,
        map,
        unit,
        target,
        available_movement,
        context,
        Some(diagnostic_maximum),
    )
}

fn find_route_with_maximum(
    state: &MovementState,
    map: &MapDefinition,
    unit: &MovementUnit,
    target: HexCoord,
    available_movement: MovementUnits,
    context: EngineContext<'_>,
    maximum_override: Option<MovementUnits>,
) -> RouteSearchResult {
    let Some(prepared) = prepare_route_search(
        state,
        map,
        unit,
        target,
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
    state: &MovementState,
    map: &MapDefinition,
    unit: &MovementUnit,
    target: HexCoord,
    available_movement: MovementUnits,
    context: EngineContext<'_>,
    maximum_override: Option<MovementUnits>,
) -> Option<PreparedRouteSearch> {
    let definition = context.ruleset().unit(unit.kind())?;
    let start_index = map.tile_index(unit.position()).map(HexTileIndex::get)?;
    let target_index = map.tile_index(target).map(HexTileIndex::get)?;
    let mut occupied = vec![false; map.bounds().tile_count()];
    for candidate in state.units() {
        if candidate.id() == unit.id() || !context.observes_occupancy(unit, candidate) {
            continue;
        }
        if let Some(index) = map.tile_index(candidate.position()) {
            occupied[index.get()] = true;
        }
    }

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
    let mut best_by_tile = vec![Vec::<(u32, bool, RouteScore, usize)>::new(); occupied.len()];
    best_by_tile[start_index].push((start_state.remaining, start_state.started, start_score, 0));
    let mut frontier = BinaryHeap::new();
    let start_node = frontier_node(map, 0, records[0])?;
    frontier.push(start_node);
    let mut metrics = MovementSearchMetrics::default();
    metrics.retained_record();
    metrics.pushed();
    Some(PreparedRouteSearch {
        target_index,
        maximum_movement: maximum_override.unwrap_or_else(|| {
            maximum_movement_units(
                context.ruleset(),
                unit.kind(),
                unit.carried_artifact_id().is_some(),
            )
        }),
        occupied,
        records,
        best_by_tile,
        frontier,
        metrics,
        movement_domain: definition.capabilities().movement_domain.domain(),
    })
}

fn run_route_search(
    mut search: PreparedRouteSearch,
    map: &MapDefinition,
    unit: &MovementUnit,
    context: EngineContext<'_>,
) -> RouteSearchResult {
    while let Some(current_node) = search.frontier.pop() {
        search.metrics.popped();
        if !is_current_best(&search.best_by_tile, current_node) {
            continue;
        }
        let current = search.records[current_node.record_index];
        if current.state.tile_index == search.target_index {
            return RouteSearchResult {
                steps: reconstruct_route(map, &search.records, current_node.record_index),
                metrics: search.metrics,
            };
        }
        let Some(coordinate) = map.coordinate_at(HexTileIndex::new(current.state.tile_index))
        else {
            continue;
        };
        search.metrics.expanded();
        for next_coordinate in map.neighbors(coordinate) {
            search.metrics.examined_edge();
            let Some(next_index) = map.tile_index(next_coordinate).map(HexTileIndex::get) else {
                continue;
            };
            if search.occupied[next_index] {
                continue;
            }
            if !context.can_plan_through_tile(unit, next_coordinate)
                || context.city_block_is_known(unit, next_coordinate)
            {
                continue;
            }
            let Some(tile) = map.tile_at(next_coordinate) else {
                continue;
            };
            let MovementCost::Passable(enter_cost) = movement_cost_for_edge(
                coordinate,
                next_coordinate,
                tile,
                search.movement_domain,
                context,
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
                &mut search.best_by_tile[next_index],
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
    best_by_tile: &[Vec<(u32, bool, RouteScore, usize)>],
    node: FrontierNode,
) -> bool {
    best_by_tile[node.state.tile_index]
        .iter()
        .any(|(remaining, started, score, record_index)| {
            *remaining == node.state.remaining
                && *started == node.state.started
                && *score == node.score
                && *record_index == node.record_index
        })
}

fn record_if_better(
    best: &mut Vec<(u32, bool, RouteScore, usize)>,
    state: RouteState,
    score: RouteScore,
    record_index: usize,
) -> bool {
    if let Some(existing) = best.iter_mut().find(|(remaining, started, _, _)| {
        *remaining == state.remaining && *started == state.started
    }) {
        if existing.2 <= score {
            return false;
        }
        *existing = (state.remaining, state.started, score, record_index);
        return true;
    }
    best.push((state.remaining, state.started, score, record_index));
    true
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
