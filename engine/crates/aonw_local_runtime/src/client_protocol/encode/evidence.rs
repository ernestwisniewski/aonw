use aonw_contract_mapping::encode_troop;
use aonw_contracts::client::{
    ClientEventDto, ClientEvidenceDto, ClientLogisticsEvidenceDto, MovementStepViewDto,
    UnitMovementExecutionDto,
};
use aonw_engine::{DomainEvent, ExecutionEvidence, LogisticsExecution, UnitMovementExecution};

use super::coordinate;

pub(super) fn event(value: &DomainEvent) -> ClientEventDto {
    match value {
        DomainEvent::UnitMoved(value) => ClientEventDto::UnitMoved {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            to: coordinate(value.to()),
        },
        DomainEvent::AutoExplorePlanned(value) => ClientEventDto::AutoExplorePlanned {
            unit_id: value.unit_id().as_str().to_owned(),
            target: coordinate(value.target()),
        },
        DomainEvent::MerchantRouteAssigned(value) => ClientEventDto::MerchantRouteAssigned {
            unit_id: value.unit_id().as_str().to_owned(),
            origin_city_id: value.origin_city_id().as_str().to_owned(),
            destination_city_id: value.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::MerchantTravelQueued(value) => ClientEventDto::MerchantTravelQueued {
            unit_id: value.unit_id().as_str().to_owned(),
            destination_city_id: value.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::TroopDetached(value) => ClientEventDto::TroopDetached {
            source_unit_id: value.source_unit_id().as_str().to_owned(),
            detached_unit_id: value.detached_unit_id().as_str().to_owned(),
            troop_kind: encode_troop(value.troop_kind()),
            destination: coordinate(value.destination()),
        },
        DomainEvent::TurnEnded(value) => ClientEventDto::TurnEnded {
            player_id: value.player_id().as_str().to_owned(),
        },
        DomainEvent::AllPlayersSubmitted(value) => ClientEventDto::AllPlayersSubmitted {
            turn: value.turn(),
            player_ids: value
                .player_ids()
                .iter()
                .map(|player| player.as_str().to_owned())
                .collect(),
        },
        DomainEvent::PlayerTimedOut(value) => ClientEventDto::PlayerTimedOut {
            turn: value.turn(),
            player_id: value.player_id().as_str().to_owned(),
        },
        DomainEvent::PlayerKicked(value) => ClientEventDto::PlayerKicked {
            turn: value.turn(),
            player_id: value.player_id().as_str().to_owned(),
            reason: value.reason().to_owned(),
            timeout_streak: value.timeout_streak(),
        },
    }
}

pub(super) fn evidence(value: &ExecutionEvidence) -> ClientEvidenceDto {
    match value {
        ExecutionEvidence::UnitMovement(value) => ClientEvidenceDto::UnitMovement {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            steps: value.steps().iter().map(movement_step).collect(),
        },
        ExecutionEvidence::Logistics(value) => ClientEvidenceDto::Logistics {
            execution: logistics_evidence(value),
        },
        ExecutionEvidence::TurnKernel(value) => ClientEvidenceDto::TurnKernel {
            processors: value
                .processors()
                .iter()
                .map(|processor| processor.as_str().to_owned())
                .collect(),
            reset_unit_ids: value
                .reset_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            movement_executions: value
                .movement_executions()
                .iter()
                .map(movement_execution)
                .collect(),
            invalidated_order_unit_ids: value
                .invalidated_order_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            finished_auto_explore_unit_ids: value
                .finished_auto_explore_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
        },
    }
}

fn logistics_evidence(value: &LogisticsExecution) -> ClientLogisticsEvidenceDto {
    match value {
        LogisticsExecution::AutoExplore {
            unit_id,
            target,
            movement,
        } => ClientLogisticsEvidenceDto::AutoExplore {
            unit_id: unit_id.as_str().to_owned(),
            target: coordinate(*target),
            movement: movement.as_ref().map(movement_execution),
        },
        LogisticsExecution::MerchantRouteAssigned {
            unit_id,
            origin_city_id,
            destination_city_id,
            steps,
            transport_network_fingerprint,
        } => ClientLogisticsEvidenceDto::MerchantRouteAssigned {
            unit_id: unit_id.as_str().to_owned(),
            origin_city_id: origin_city_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(movement_step).collect(),
            transport_network_fingerprint: transport_network_fingerprint.to_string(),
        },
        LogisticsExecution::MerchantTravelQueued {
            unit_id,
            destination_city_id,
            steps,
        } => ClientLogisticsEvidenceDto::MerchantTravelQueued {
            unit_id: unit_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(movement_step).collect(),
        },
        LogisticsExecution::TroopDetached {
            source_unit_id,
            detached_unit_id,
            troop_kind,
            destination,
        } => ClientLogisticsEvidenceDto::TroopDetached {
            source_unit_id: source_unit_id.as_str().to_owned(),
            detached_unit_id: detached_unit_id.as_str().to_owned(),
            troop_kind: encode_troop(*troop_kind),
            destination: coordinate(*destination),
        },
    }
}

fn movement_execution(value: &UnitMovementExecution) -> UnitMovementExecutionDto {
    UnitMovementExecutionDto {
        unit_id: value.unit_id().as_str().to_owned(),
        from: coordinate(value.from()),
        steps: value.steps().iter().map(movement_step).collect(),
    }
}

fn movement_step(value: &aonw_domain::MovementStep) -> MovementStepViewDto {
    MovementStepViewDto {
        coordinate: coordinate(value.coordinate()),
        enter_cost_units: value.enter_cost().get(),
        cumulative_cost_units: value.cumulative_cost().get(),
    }
}
