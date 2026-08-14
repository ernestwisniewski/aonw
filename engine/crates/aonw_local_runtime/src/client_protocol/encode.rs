use aonw_contract_mapping::{encode_unit_kind, encode_unit_posture};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    ClientCommandResultDto, ClientEventDto, ClientEvidenceDto, ClientFeatureDto,
    ClientQueryResultDto, ClientReplayVerificationDto, ClientResponseBodyDto,
    ClientSessionStampDto, MovementStepViewDto, PlayerUnitViewDto, PlayerViewPatchDto,
    PlayerViewSnapshotDto, ReachableTileViewDto,
};
use aonw_domain::HexCoord;
use aonw_engine::{DomainEvent, ExecutionEvidence};

use crate::{
    CommandResult, LocalRuntime, PlayerUnitView, PlayerViewPatch, PlayerViewSnapshot,
    ReplayVerification, RuntimeQueryResult, SessionStamp,
};

pub(super) fn capabilities() -> ClientResponseBodyDto {
    let capabilities = LocalRuntime::capabilities();
    let mut features = vec![ClientFeatureDto::Snapshot];
    if capabilities.reachable() {
        features.push(ClientFeatureDto::Reachable);
    }
    if capabilities.route_plan() {
        features.push(ClientFeatureDto::RoutePlan);
    }
    if capabilities.move_unit() {
        features.push(ClientFeatureDto::MoveUnit);
    }
    if capabilities.unit_actions() {
        features.push(ClientFeatureDto::UnitActions);
    }
    if capabilities.save_game() {
        features.push(ClientFeatureDto::SaveGame);
    }
    if capabilities.replay_verification() {
        features.push(ClientFeatureDto::ReplayVerification);
    }
    ClientResponseBodyDto::Capabilities {
        behavior_version: capabilities.behavior_version,
        features,
    }
}

pub(super) fn stamp(value: SessionStamp) -> ClientSessionStampDto {
    ClientSessionStampDto {
        behavior_version: value.behavior_version,
        revision: value.revision.get(),
        state_digest: value.state_digest.to_string(),
        map_hash: value.map_hash.to_string(),
        ruleset_hash: value.ruleset_hash.to_string(),
    }
}

pub(super) fn snapshot(value: &PlayerViewSnapshot) -> PlayerViewSnapshotDto {
    PlayerViewSnapshotDto {
        stamp: stamp(*value.stamp()),
        units: value.units().iter().map(unit).collect(),
    }
}

pub(super) fn query_result(value: &RuntimeQueryResult) -> ClientQueryResultDto {
    match value {
        RuntimeQueryResult::Reachable(value) => ClientQueryResultDto::Reachable {
            stamp: stamp(value.stamp),
            unit_id: value.unit_id.as_str().to_owned(),
            available_movement_units: value.available_movement.get(),
            tiles: value
                .tiles
                .iter()
                .map(|tile| ReachableTileViewDto {
                    coordinate: coordinate(tile.coordinate),
                    cost_units: tile.cost.get(),
                    exhausts_movement: tile.exhausts_movement,
                })
                .collect(),
        },
        RuntimeQueryResult::RoutePlan(value) => ClientQueryResultDto::RoutePlan {
            stamp: stamp(value.stamp),
            unit_id: value.unit_id.as_str().to_owned(),
            target: coordinate(value.target),
            destination: coordinate(value.destination),
            total_cost_units: value.total_cost.get(),
            available_movement_units: value.available_movement.get(),
            remaining_movement_units: value.remaining_movement.get(),
            steps: value
                .steps
                .iter()
                .map(|step| MovementStepViewDto {
                    coordinate: coordinate(step.coordinate),
                    enter_cost_units: step.enter_cost.get(),
                    cumulative_cost_units: step.cumulative_cost.get(),
                })
                .collect(),
        },
    }
}

pub(super) fn command_result(value: &CommandResult) -> ClientCommandResultDto {
    ClientCommandResultDto {
        stamp: stamp(value.stamp),
        accepted: value.is_accepted(),
        rejection: value.rejection.map(str::to_owned),
        events: value.events.iter().map(event).collect(),
        evidence: value.evidence.as_ref().map(evidence),
        view_patch: patch(&value.view_patch),
    }
}

pub(super) fn replay_verification(value: ReplayVerification) -> ClientReplayVerificationDto {
    ClientReplayVerificationDto {
        entry_count: u64::try_from(value.entry_count).unwrap_or(u64::MAX),
        final_event_offset: value.final_event_offset,
        final_stamp: stamp(value.final_stamp),
    }
}

fn unit(value: &PlayerUnitView) -> PlayerUnitViewDto {
    PlayerUnitViewDto {
        id: value.id().as_str().to_owned(),
        owner_player_id: value.owner_player_id().as_str().to_owned(),
        kind: encode_unit_kind(value.kind()),
        name: value.name().to_owned(),
        coordinate: CoordinateDto {
            col: value.col(),
            row: value.row(),
        },
        movement_units: value.movement_units(),
        posture: encode_unit_posture(value.posture()),
    }
}

fn patch(value: &PlayerViewPatch) -> PlayerViewPatchDto {
    PlayerViewPatchDto {
        from_revision: value.from_revision,
        to_revision: value.to_revision,
        upserted_units: value.upserted_units.iter().map(unit).collect(),
        removed_unit_ids: value
            .removed_unit_ids
            .iter()
            .map(|id| id.as_str().to_owned())
            .collect(),
    }
}

fn event(value: &DomainEvent) -> ClientEventDto {
    match value {
        DomainEvent::UnitMoved(value) => ClientEventDto::UnitMoved {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            to: coordinate(value.to()),
        },
    }
}

fn evidence(value: &ExecutionEvidence) -> ClientEvidenceDto {
    match value {
        ExecutionEvidence::UnitMovement(value) => ClientEvidenceDto::UnitMovement {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            steps: value
                .steps()
                .iter()
                .map(|step| MovementStepViewDto {
                    coordinate: coordinate(step.coordinate()),
                    enter_cost_units: step.enter_cost().get(),
                    cumulative_cost_units: step.cumulative_cost().get(),
                })
                .collect(),
        },
    }
}

const fn coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
