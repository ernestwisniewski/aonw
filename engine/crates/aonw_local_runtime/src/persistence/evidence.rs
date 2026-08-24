use aonw_contract_mapping::encode_troop;
use aonw_contracts::{
    CoordinateDto, MovementStepDto, ReplayEventDto, ReplayEvidenceDto, ReplayLogisticsEvidenceDto,
    ReplayUnitMovementExecutionDto,
};
use aonw_engine::{DomainEvent, ExecutionEvidence, LogisticsExecution, UnitMovementExecution};

pub(super) fn encode_event(event: &DomainEvent) -> ReplayEventDto {
    match event {
        DomainEvent::UnitMoved(event) => ReplayEventDto::UnitMoved {
            unit_id: event.unit_id().as_str().to_owned(),
            from: coordinate(event.from()),
            to: coordinate(event.to()),
        },
        DomainEvent::AutoExplorePlanned(event) => ReplayEventDto::AutoExplorePlanned {
            unit_id: event.unit_id().as_str().to_owned(),
            target: coordinate(event.target()),
        },
        DomainEvent::MerchantRouteAssigned(event) => ReplayEventDto::MerchantRouteAssigned {
            unit_id: event.unit_id().as_str().to_owned(),
            origin_city_id: event.origin_city_id().as_str().to_owned(),
            destination_city_id: event.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::MerchantTravelQueued(event) => ReplayEventDto::MerchantTravelQueued {
            unit_id: event.unit_id().as_str().to_owned(),
            destination_city_id: event.destination_city_id().as_str().to_owned(),
        },
        DomainEvent::TroopDetached(event) => ReplayEventDto::TroopDetached {
            source_unit_id: event.source_unit_id().as_str().to_owned(),
            detached_unit_id: event.detached_unit_id().as_str().to_owned(),
            troop_kind: encode_troop(event.troop_kind()),
            destination: coordinate(event.destination()),
        },
        DomainEvent::TurnEnded(event) => ReplayEventDto::TurnEnded {
            player_id: event.player_id().as_str().to_owned(),
        },
        DomainEvent::AllPlayersSubmitted(event) => ReplayEventDto::AllPlayersSubmitted {
            turn: event.turn(),
            player_ids: event
                .player_ids()
                .iter()
                .map(|player| player.as_str().to_owned())
                .collect(),
        },
        DomainEvent::PlayerTimedOut(event) => ReplayEventDto::PlayerTimedOut {
            turn: event.turn(),
            player_id: event.player_id().as_str().to_owned(),
        },
        DomainEvent::PlayerKicked(event) => ReplayEventDto::PlayerKicked {
            turn: event.turn(),
            player_id: event.player_id().as_str().to_owned(),
            reason: event.reason().to_owned(),
            timeout_streak: event.timeout_streak(),
        },
    }
}

pub(super) fn encode_evidence(evidence: &ExecutionEvidence) -> ReplayEvidenceDto {
    match evidence {
        ExecutionEvidence::UnitMovement(execution) => ReplayEvidenceDto::UnitMovement {
            unit_id: execution.unit_id().as_str().to_owned(),
            from: coordinate(execution.from()),
            steps: execution.steps().iter().map(encode_step).collect(),
        },
        ExecutionEvidence::Logistics(execution) => ReplayEvidenceDto::Logistics {
            execution: encode_logistics_evidence(execution),
        },
        ExecutionEvidence::TurnKernel(execution) => ReplayEvidenceDto::TurnKernel {
            processors: execution
                .processors()
                .iter()
                .map(|processor| processor.as_str().to_owned())
                .collect(),
            reset_unit_ids: execution
                .reset_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            movement_executions: execution
                .movement_executions()
                .iter()
                .map(encode_movement_execution)
                .collect(),
            invalidated_order_unit_ids: execution
                .invalidated_order_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
            finished_auto_explore_unit_ids: execution
                .finished_auto_explore_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
        },
    }
}

fn encode_logistics_evidence(execution: &LogisticsExecution) -> ReplayLogisticsEvidenceDto {
    match execution {
        LogisticsExecution::AutoExplore {
            unit_id,
            target,
            movement,
        } => ReplayLogisticsEvidenceDto::AutoExplore {
            unit_id: unit_id.as_str().to_owned(),
            target: coordinate(*target),
            movement: movement.as_ref().map(encode_movement_execution),
        },
        LogisticsExecution::MerchantRouteAssigned {
            unit_id,
            origin_city_id,
            destination_city_id,
            steps,
            transport_network_fingerprint,
        } => ReplayLogisticsEvidenceDto::MerchantRouteAssigned {
            unit_id: unit_id.as_str().to_owned(),
            origin_city_id: origin_city_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(encode_step).collect(),
            transport_network_fingerprint: transport_network_fingerprint.to_string(),
        },
        LogisticsExecution::MerchantTravelQueued {
            unit_id,
            destination_city_id,
            steps,
        } => ReplayLogisticsEvidenceDto::MerchantTravelQueued {
            unit_id: unit_id.as_str().to_owned(),
            destination_city_id: destination_city_id.as_str().to_owned(),
            steps: steps.iter().map(encode_step).collect(),
        },
        LogisticsExecution::TroopDetached {
            source_unit_id,
            detached_unit_id,
            troop_kind,
            destination,
        } => ReplayLogisticsEvidenceDto::TroopDetached {
            source_unit_id: source_unit_id.as_str().to_owned(),
            detached_unit_id: detached_unit_id.as_str().to_owned(),
            troop_kind: encode_troop(*troop_kind),
            destination: coordinate(*destination),
        },
    }
}

fn encode_movement_execution(execution: &UnitMovementExecution) -> ReplayUnitMovementExecutionDto {
    ReplayUnitMovementExecutionDto {
        unit_id: execution.unit_id().as_str().to_owned(),
        from: coordinate(execution.from()),
        steps: execution.steps().iter().map(encode_step).collect(),
    }
}

fn encode_step(step: &aonw_domain::MovementStep) -> MovementStepDto {
    MovementStepDto {
        col: step.coordinate().col(),
        row: step.coordinate().row(),
        enter_cost_units: step.enter_cost().get(),
        cumulative_cost_units: step.cumulative_cost().get(),
    }
}

const fn coordinate(value: aonw_domain::HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
