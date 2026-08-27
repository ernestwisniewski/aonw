use core::cmp::Ordering;

use aonw_domain::{HexCoord, MovementUnits};
use aonw_local_runtime::{
    LocalRuntime, MoveUnitRequest, PlayerViewSnapshot, ReachableRequest, RuntimeError,
    RuntimeQuery, RuntimeQueryResult,
};

use crate::PlannedCommand;

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct MoveCandidate {
    pub(crate) command: PlannedCommand,
    distance_to_known_opponent: Option<u64>,
    cost: MovementUnits,
}

pub(crate) fn legal_move_candidates(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Vec<MoveCandidate>, RuntimeError> {
    let mut candidates = Vec::new();
    visit_legal_move_candidates(runtime, snapshot, |candidate| candidates.push(candidate))?;
    candidates.sort_by(compare_candidates);
    Ok(candidates)
}

pub(crate) fn bounded_move_candidates(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
    limit: usize,
) -> Result<Vec<MoveCandidate>, RuntimeError> {
    let mut candidates = Vec::with_capacity(limit);
    visit_legal_move_candidates(runtime, snapshot, |candidate| {
        let index = candidates
            .binary_search_by(|current| compare_candidates(current, &candidate))
            .unwrap_or_else(core::convert::identity);
        if index < limit {
            candidates.insert(index, candidate);
            if candidates.len() > limit {
                candidates.pop();
            }
        }
    })?;
    Ok(candidates)
}

pub(crate) fn best_move_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let mut selected: Option<MoveCandidate> = None;
    visit_legal_move_candidates(runtime, snapshot, |candidate| {
        if selected
            .as_ref()
            .is_none_or(|current| compare_candidates(&candidate, current).is_lt())
        {
            selected = Some(candidate);
        }
    })?;
    Ok(selected.map(|candidate| candidate.command))
}

fn visit_legal_move_candidates(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
    mut visit: impl FnMut(MoveCandidate),
) -> Result<(), RuntimeError> {
    let recipient = snapshot.recipient_player_id();
    let known_opponents = snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() != recipient)
        .map(|unit| HexCoord::new(unit.col(), unit.row()))
        .chain(
            snapshot
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() != recipient)
                .map(aonw_local_runtime::PlayerCityView::center),
        )
        .collect::<Vec<_>>();
    let revision = snapshot.stamp().revision.get();
    for unit in snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() == recipient && unit.movement_units() > 0)
    {
        let origin = HexCoord::new(unit.col(), unit.row());
        let response = runtime.query(&RuntimeQuery::Reachable(ReachableRequest {
            expected_revision: revision,
            unit_id: unit.id().clone(),
        }))?;
        let RuntimeQueryResult::Reachable(reachable) = response else {
            unreachable!("reachable query returns reachable response")
        };
        for tile in reachable
            .tiles
            .iter()
            .filter(|tile| tile.coordinate != origin)
        {
            visit(MoveCandidate {
                command: PlannedCommand::MoveUnit(MoveUnitRequest {
                    expected_revision: revision,
                    unit_id: unit.id().clone(),
                    target: tile.coordinate,
                }),
                distance_to_known_opponent: known_opponents
                    .iter()
                    .map(|target| tile.coordinate.distance_to(*target))
                    .min(),
                cost: tile.cost,
            });
        }
    }
    Ok(())
}

pub(crate) fn compare_commands(left: &PlannedCommand, right: &PlannedCommand) -> Ordering {
    match (left, right) {
        (PlannedCommand::MoveUnit(left), PlannedCommand::MoveUnit(right)) => left
            .unit_id
            .cmp(&right.unit_id)
            .then_with(|| left.target.cmp(&right.target)),
    }
}

fn compare_candidates(left: &MoveCandidate, right: &MoveCandidate) -> Ordering {
    left.distance_to_known_opponent
        .unwrap_or(u64::MAX)
        .cmp(&right.distance_to_known_opponent.unwrap_or(u64::MAX))
        .then_with(|| left.cost.cmp(&right.cost))
        .then_with(|| compare_commands(&left.command, &right.command))
}
