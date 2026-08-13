use std::cmp::Ordering;
use std::collections::BinaryHeap;

use aonw_content::MapDefinition;
use aonw_domain::{
    HexCoord, HexTileIndex, MovementState, MovementStep, MovementUnit, MovementUnits,
};

use super::{MovementCost, MovementPlanningView, maximum_movement_units, terrain_entry_cost};

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

pub(super) fn find_route(
    state: &MovementState,
    map: &MapDefinition,
    unit: &MovementUnit,
    target: HexCoord,
    available_movement: MovementUnits,
    planning_view: MovementPlanningView<'_>,
) -> Option<Vec<MovementStep>> {
    let start_index = map.tile_index(unit.position())?.get();
    let target_index = map.tile_index(target)?.get();
    let maximum_movement =
        maximum_movement_units(unit.kind(), unit.carried_artifact_id().is_some());
    let mut occupied = vec![false; map.bounds().tile_count()];
    for candidate in state.units() {
        if candidate.id() == unit.id() || !planning_view.observes_occupancy(unit, candidate) {
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
    let mut records = vec![RouteRecord {
        state: start_state,
        score: start_score,
        parent: None,
        enter_cost: MovementUnits::ZERO,
    }];
    let mut best_by_tile = vec![Vec::<(u32, bool, RouteScore, usize)>::new(); occupied.len()];
    best_by_tile[start_index].push((start_state.remaining, start_state.started, start_score, 0));
    let mut frontier = BinaryHeap::new();
    frontier.push(frontier_node(map, 0, records[0])?);

    while let Some(current_node) = frontier.pop() {
        if !is_current_best(&best_by_tile, current_node) {
            continue;
        }
        let current = records[current_node.record_index];
        if current.state.tile_index == target_index {
            return reconstruct_route(map, &records, current_node.record_index);
        }
        let coordinate = map.coordinate_at(HexTileIndex::new(current.state.tile_index))?;
        for next_coordinate in map.neighbors(coordinate) {
            let next_index = map.tile_index(next_coordinate)?.get();
            if occupied[next_index] {
                continue;
            }
            let MovementCost::Passable(enter_cost) =
                terrain_entry_cost(map.tile_at(next_coordinate)?, unit.kind().movement_domain())
            else {
                continue;
            };
            if enter_cost > maximum_movement && unit.carried_artifact_id().is_none() {
                continue;
            }
            let Some(next_score) = next_score(current.score, enter_cost) else {
                continue;
            };
            let Some((turns, remaining)) = advance_route(
                current.state,
                current.score.turns,
                enter_cost,
                maximum_movement,
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
                &mut best_by_tile[next_index],
                next_state,
                next_score,
                records.len(),
            ) {
                continue;
            }
            let record_index = records.len();
            let record = RouteRecord {
                state: next_state,
                score: next_score,
                parent: Some(current_node.record_index),
                enter_cost,
            };
            records.push(record);
            if let Some(node) = frontier_node(map, record_index, record) {
                frontier.push(node);
            }
        }
    }
    None
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
