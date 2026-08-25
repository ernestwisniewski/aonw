use aonw_contract_mapping::{decode_improvement, decode_troop};
use aonw_contracts::ReplayCommandDto;
use aonw_domain::{CityConquestAction, UnitId};

use super::{
    PersistenceError, ReplayRuntimeCommand, decode_found_city, decode_merchant_city,
    decode_select_city_expansion_hex, decode_toggle_worked_hex, decode_unit_action,
    decode_worker_unit,
};
use crate::TurnCommandRequest;
use crate::{AttackHexRequest, AutoExploreUnitRequest, DetachTroopRequest, MoveUnitRequest};

pub(super) fn decode_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match command {
        ReplayCommandDto::FoundCity {
            expected_revision,
            founder_unit_id,
            controlled_hexes,
        } => decode_found_city(*expected_revision, founder_unit_id, controlled_hexes)
            .map(ReplayRuntimeCommand::FoundCity),
        ReplayCommandDto::ToggleWorkedHex {
            expected_revision,
            city_id,
            target,
        } => decode_toggle_worked_hex(*expected_revision, city_id, *target)
            .map(ReplayRuntimeCommand::ToggleWorkedHex),
        ReplayCommandDto::SelectCityExpansionHex {
            expected_revision,
            city_id,
            target,
        } => decode_select_city_expansion_hex(*expected_revision, city_id, *target)
            .map(ReplayRuntimeCommand::SelectCityExpansionHex),
        command @ (ReplayCommandDto::SelectWorkerImprovement { .. }
        | ReplayCommandDto::ConfirmWorkerImprovement { .. }
        | ReplayCommandDto::CancelWorkerJob { .. }
        | ReplayCommandDto::AssignWorkerToHex { .. }
        | ReplayCommandDto::CancelWorkerAssignment { .. }
        | ReplayCommandDto::BuildRoad { .. }
        | ReplayCommandDto::AutomateWorker { .. }) => decode_worker_command(command),
        ReplayCommandDto::AttackHex {
            expected_revision,
            attacker_unit_id,
            defender,
            city_conquest_action,
        } => Ok(ReplayRuntimeCommand::Attack(AttackHexRequest {
            expected_revision: *expected_revision,
            attacker_unit_id: UnitId::new(attacker_unit_id.clone())
                .map_err(PersistenceError::InvalidUnit)?,
            defender: aonw_domain::HexCoord::new(defender.col, defender.row),
            city_conquest_action: match city_conquest_action {
                aonw_contracts::CityConquestActionDto::Capture => CityConquestAction::Capture,
                aonw_contracts::CityConquestActionDto::Destroy => CityConquestAction::Destroy,
            },
        })),
        ReplayCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => Ok(ReplayRuntimeCommand::Move(MoveUnitRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            target: aonw_domain::HexCoord::new(target.col, target.row),
        })),
        ReplayCommandDto::AutoExploreUnit {
            expected_revision,
            unit_id,
        } => Ok(ReplayRuntimeCommand::AutoExplore(AutoExploreUnitRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
        })),
        ReplayCommandDto::AssignMerchantTradeRoute {
            expected_revision,
            unit_id,
            destination_city_id,
        } => decode_merchant_city(*expected_revision, unit_id, destination_city_id)
            .map(ReplayRuntimeCommand::AssignMerchantRoute),
        ReplayCommandDto::MoveMerchantToCity {
            expected_revision,
            unit_id,
            destination_city_id,
        } => decode_merchant_city(*expected_revision, unit_id, destination_city_id)
            .map(ReplayRuntimeCommand::MoveMerchantToCity),
        ReplayCommandDto::DetachTroop {
            expected_revision,
            unit_id,
            troop_kind,
        } => Ok(ReplayRuntimeCommand::DetachTroop(DetachTroopRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            troop_kind: decode_troop(*troop_kind),
        })),
        ReplayCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Cancel),
        ReplayCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Skip),
        ReplayCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Fortify),
        command @ (ReplayCommandDto::EndTurn { .. } | ReplayCommandDto::SubmitTurn { .. }) => {
            Ok(decode_turn_command(command))
        }
    }
}

fn decode_turn_command(command: &ReplayCommandDto) -> ReplayRuntimeCommand {
    match command {
        ReplayCommandDto::EndTurn { expected_revision } => {
            ReplayRuntimeCommand::EndTurn(TurnCommandRequest {
                expected_revision: *expected_revision,
            })
        }
        ReplayCommandDto::SubmitTurn { expected_revision } => {
            ReplayRuntimeCommand::SubmitTurn(TurnCommandRequest {
                expected_revision: *expected_revision,
            })
        }
        _ => unreachable!("turn decoder received another command family"),
    }
}

fn decode_worker_command(
    command: &ReplayCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match command {
        ReplayCommandDto::SelectWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => Ok(ReplayRuntimeCommand::SelectWorkerImprovement(
            crate::WorkerImprovementRequest {
                expected_revision: *expected_revision,
                unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
                improvement: Some(decode_improvement(*improvement)),
            },
        )),
        ReplayCommandDto::ConfirmWorkerImprovement {
            expected_revision,
            unit_id,
            improvement,
        } => Ok(ReplayRuntimeCommand::ConfirmWorkerImprovement(
            crate::WorkerImprovementRequest {
                expected_revision: *expected_revision,
                unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
                improvement: improvement.map(decode_improvement),
            },
        )),
        ReplayCommandDto::CancelWorkerJob {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::CancelWorkerJob),
        ReplayCommandDto::AssignWorkerToHex {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::AssignWorkerToHex),
        ReplayCommandDto::CancelWorkerAssignment {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::CancelWorkerAssignment),
        ReplayCommandDto::BuildRoad {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id).map(ReplayRuntimeCommand::BuildRoad),
        ReplayCommandDto::AutomateWorker {
            expected_revision,
            unit_id,
        } => decode_worker_unit(*expected_revision, unit_id)
            .map(ReplayRuntimeCommand::AutomateWorker),
        _ => unreachable!("worker decoder received another command family"),
    }
}
