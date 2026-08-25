use aonw_contract_mapping::{encode_improvement, encode_unit_kind, encode_unit_posture};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CityFoundingDraftViewDto, ClientCommandOutcomeDto, ClientCommandRejectionCodeDto,
    ClientCommandResultDto, ClientSessionStampDto, OwnedCityPlanningViewDto, PlayerCityViewDto,
    PlayerUnitViewDto, PlayerViewPatchDto, PlayerViewSnapshotDto, WorkerJobViewDto,
};
use aonw_engine::CommandRejectionCode;

use crate::{
    CityFoundingDraftView, CommandResult, PlayerCityView, PlayerUnitView, PlayerViewPatch,
    PlayerViewSnapshot, SessionStamp,
};

mod capability;
mod evidence;
mod map_view;
mod presentation;
mod query;
mod simple;
#[cfg(test)]
mod tests;
mod worker;

pub(super) use capability::capabilities;
use evidence::{event, recipient_evidence};
use map_view::coordinate;
pub(super) use map_view::map;
#[cfg(test)]
use map_view::{objective_type, resource, terrain};
use presentation::{pending_action, turn_lifecycle};
pub(super) use query::query_result;
#[cfg(test)]
use query::{merchant_destination, movement_metrics};
pub(super) use simple::replay_verification;
use simple::{field_improvement, road};

pub(super) fn stamp(value: SessionStamp) -> ClientSessionStampDto {
    ClientSessionStampDto {
        revision: value.revision.get(),
        state_digest: value.state_digest.to_string(),
        map_hash: value.map_hash.to_string(),
        ruleset_hash: value.ruleset_hash.to_string(),
    }
}

pub(super) fn snapshot(value: &PlayerViewSnapshot) -> PlayerViewSnapshotDto {
    PlayerViewSnapshotDto {
        stamp: stamp(*value.stamp()),
        turn: value.turn(),
        turn_lifecycle: turn_lifecycle(*value.turn_lifecycle()),
        pending_action: value.pending_action().map(pending_action),
        city_founding_draft: value.city_founding_draft().map(founding_draft),
        units: value.units().iter().map(unit).collect(),
        cities: value.cities().iter().map(city).collect(),
        field_improvements: value
            .field_improvements()
            .iter()
            .copied()
            .map(field_improvement)
            .collect(),
        roads: value.roads().iter().copied().map(road).collect(),
    }
}

pub(super) fn command_result(value: &CommandResult) -> ClientCommandResultDto {
    ClientCommandResultDto {
        stamp: stamp(value.stamp),
        outcome: value
            .rejection
            .map_or(ClientCommandOutcomeDto::Accepted, |code| {
                ClientCommandOutcomeDto::Rejected {
                    code: rejection(code),
                }
            }),
        events: value
            .events
            .iter()
            .filter(|event| value.recipient_disclosure.allows_event(event))
            .map(event)
            .collect(),
        evidence: value
            .evidence
            .as_ref()
            .and_then(|evidence| recipient_evidence(evidence, &value.recipient_disclosure)),
        view_patch: patch(&value.view_patch),
    }
}

#[allow(clippy::too_many_lines)]
const fn rejection(value: CommandRejectionCode) -> ClientCommandRejectionCodeDto {
    match value {
        CommandRejectionCode::StaleRevision => ClientCommandRejectionCodeDto::StaleRevision,
        CommandRejectionCode::UnitNotFound => ClientCommandRejectionCodeDto::UnitNotFound,
        CommandRejectionCode::UnitNotControlled => ClientCommandRejectionCodeDto::UnitNotControlled,
        CommandRejectionCode::UnitUnavailable => ClientCommandRejectionCodeDto::UnitUnavailable,
        CommandRejectionCode::UnitUsesTradeRoutes => {
            ClientCommandRejectionCodeDto::UnitUsesTradeRoutes
        }
        CommandRejectionCode::UnitOutOfBounds => ClientCommandRejectionCodeDto::UnitOutOfBounds,
        CommandRejectionCode::MoveTargetOutOfBounds => {
            ClientCommandRejectionCodeDto::MoveTargetOutOfBounds
        }
        CommandRejectionCode::MoveTargetIsCurrentTile => {
            ClientCommandRejectionCodeDto::MoveTargetIsCurrentTile
        }
        CommandRejectionCode::MoveTargetIsForeignCityCenter => {
            ClientCommandRejectionCodeDto::MoveTargetIsForeignCityCenter
        }
        CommandRejectionCode::MoveTargetOccupied => {
            ClientCommandRejectionCodeDto::MoveTargetOccupied
        }
        CommandRejectionCode::UnitMovementCapacityInsufficient => {
            ClientCommandRejectionCodeDto::UnitMovementCapacityInsufficient
        }
        CommandRejectionCode::MovePathNotFound => ClientCommandRejectionCodeDto::MovePathNotFound,
        CommandRejectionCode::UnitNotScout => ClientCommandRejectionCodeDto::UnitNotScout,
        CommandRejectionCode::UnitExhausted => ClientCommandRejectionCodeDto::UnitExhausted,
        CommandRejectionCode::UnitHasPath => ClientCommandRejectionCodeDto::UnitHasPath,
        CommandRejectionCode::AutoExploreNoTarget => {
            ClientCommandRejectionCodeDto::AutoExploreNoTarget
        }
        CommandRejectionCode::UnitNotMerchant => ClientCommandRejectionCodeDto::UnitNotMerchant,
        CommandRejectionCode::MerchantNotInCity => ClientCommandRejectionCodeDto::MerchantNotInCity,
        CommandRejectionCode::DestinationCityNotFound => {
            ClientCommandRejectionCodeDto::DestinationCityNotFound
        }
        CommandRejectionCode::DestinationCityNotControlled => {
            ClientCommandRejectionCodeDto::DestinationCityNotControlled
        }
        CommandRejectionCode::DestinationCityIsOrigin => {
            ClientCommandRejectionCodeDto::DestinationCityIsOrigin
        }
        CommandRejectionCode::DestinationCityIsCurrent => {
            ClientCommandRejectionCodeDto::DestinationCityIsCurrent
        }
        CommandRejectionCode::MerchantRouteNotFound => {
            ClientCommandRejectionCodeDto::MerchantRouteNotFound
        }
        CommandRejectionCode::MerchantCityPathNotFound => {
            ClientCommandRejectionCodeDto::MerchantCityPathNotFound
        }
        CommandRejectionCode::TroopNotAvailable => ClientCommandRejectionCodeDto::TroopNotAvailable,
        CommandRejectionCode::DetachmentSourceOutOfBounds => {
            ClientCommandRejectionCodeDto::DetachmentSourceOutOfBounds
        }
        CommandRejectionCode::DetachmentDestinationUnavailable => {
            ClientCommandRejectionCodeDto::DetachmentDestinationUnavailable
        }
        CommandRejectionCode::DetachedUnitIdUnavailable => {
            ClientCommandRejectionCodeDto::DetachedUnitIdUnavailable
        }
        CommandRejectionCode::UnitBusy => ClientCommandRejectionCodeDto::UnitBusy,
        CommandRejectionCode::UnitDefinitionMissing => {
            ClientCommandRejectionCodeDto::UnitDefinitionMissing
        }
        CommandRejectionCode::StateRevisionOverflow => {
            ClientCommandRejectionCodeDto::StateRevisionOverflow
        }
        CommandRejectionCode::InvalidQueuedMovementPath => {
            ClientCommandRejectionCodeDto::InvalidQueuedMovementPath
        }
        CommandRejectionCode::InvalidUnit => ClientCommandRejectionCodeDto::InvalidUnit,
        CommandRejectionCode::MovementUnitUpdateFailed => {
            ClientCommandRejectionCodeDto::MovementUnitUpdateFailed
        }
        CommandRejectionCode::TurnPlayerNotControlled => {
            ClientCommandRejectionCodeDto::TurnPlayerNotControlled
        }
        CommandRejectionCode::TurnPlayerNotActive => {
            ClientCommandRejectionCodeDto::TurnPlayerNotActive
        }
        CommandRejectionCode::TurnScopeInvalid => ClientCommandRejectionCodeDto::TurnScopeInvalid,
        CommandRejectionCode::TurnProcessorUnsupported => {
            ClientCommandRejectionCodeDto::TurnProcessorUnsupported
        }
        CommandRejectionCode::TurnNumberOverflow => {
            ClientCommandRejectionCodeDto::TurnNumberOverflow
        }
        CommandRejectionCode::AttackerNotFound => ClientCommandRejectionCodeDto::AttackerNotFound,
        CommandRejectionCode::AttackerNotControlled => {
            ClientCommandRejectionCodeDto::AttackerNotControlled
        }
        CommandRejectionCode::AttackerUnavailable => {
            ClientCommandRejectionCodeDto::AttackerUnavailable
        }
        CommandRejectionCode::AttackerExhausted => ClientCommandRejectionCodeDto::AttackerExhausted,
        CommandRejectionCode::AttackerOutOfBounds => {
            ClientCommandRejectionCodeDto::AttackerOutOfBounds
        }
        CommandRejectionCode::AttackerCannotAttack => {
            ClientCommandRejectionCodeDto::AttackerCannotAttack
        }
        CommandRejectionCode::AttackTargetNotVisible => {
            ClientCommandRejectionCodeDto::AttackTargetNotVisible
        }
        CommandRejectionCode::AttackTargetOutOfBounds => {
            ClientCommandRejectionCodeDto::AttackTargetOutOfBounds
        }
        CommandRejectionCode::AttackTargetNotFound => {
            ClientCommandRejectionCodeDto::AttackTargetNotFound
        }
        CommandRejectionCode::AttackTargetNotEnemy => {
            ClientCommandRejectionCodeDto::AttackTargetNotEnemy
        }
        CommandRejectionCode::AttackTargetProtectedByTreaty => {
            ClientCommandRejectionCodeDto::AttackTargetProtectedByTreaty
        }
        CommandRejectionCode::AttackTargetOutOfRange => {
            ClientCommandRejectionCodeDto::AttackTargetOutOfRange
        }
        CommandRejectionCode::AttackCityHasNoHealth => {
            ClientCommandRejectionCodeDto::AttackCityHasNoHealth
        }
        CommandRejectionCode::CityFounderNotFound => {
            ClientCommandRejectionCodeDto::CityFounderNotFound
        }
        CommandRejectionCode::CityFounderNotControlled => {
            ClientCommandRejectionCodeDto::CityFounderNotControlled
        }
        CommandRejectionCode::CityFounderBusy => ClientCommandRejectionCodeDto::CityFounderBusy,
        CommandRejectionCode::CityFounderInvalid => {
            ClientCommandRejectionCodeDto::CityFounderInvalid
        }
        CommandRejectionCode::CityFounderNoSettlers => {
            ClientCommandRejectionCodeDto::CityFounderNoSettlers
        }
        CommandRejectionCode::CitySiteInvalid => ClientCommandRejectionCodeDto::CitySiteInvalid,
        CommandRejectionCode::CityCenterOccupied => {
            ClientCommandRejectionCodeDto::CityCenterOccupied
        }
        CommandRejectionCode::CityCenterClaimed => ClientCommandRejectionCodeDto::CityCenterClaimed,
        CommandRejectionCode::CityCenterTooClose => {
            ClientCommandRejectionCodeDto::CityCenterTooClose
        }
        CommandRejectionCode::CityControlledHexesInvalid => {
            ClientCommandRejectionCodeDto::CityControlledHexesInvalid
        }
        CommandRejectionCode::CityNotFound => ClientCommandRejectionCodeDto::CityNotFound,
        CommandRejectionCode::CityNotControlled => ClientCommandRejectionCodeDto::CityNotControlled,
        CommandRejectionCode::WorkedHexUnavailable => {
            ClientCommandRejectionCodeDto::WorkedHexUnavailable
        }
        CommandRejectionCode::WorkedHexLimitReached => {
            ClientCommandRejectionCodeDto::WorkedHexLimitReached
        }
        CommandRejectionCode::CityExpansionHexUnavailable => {
            ClientCommandRejectionCodeDto::CityExpansionHexUnavailable
        }
        CommandRejectionCode::BuildingNotAvailable => {
            ClientCommandRejectionCodeDto::BuildingNotAvailable
        }
        CommandRejectionCode::UnitProductionInvalidResourceOption => {
            ClientCommandRejectionCodeDto::UnitProductionInvalidResourceOption
        }
        CommandRejectionCode::UnitProductionNotAvailable => {
            ClientCommandRejectionCodeDto::UnitProductionNotAvailable
        }
        CommandRejectionCode::UnitProductionRequiresResource => {
            ClientCommandRejectionCodeDto::UnitProductionRequiresResource
        }
        CommandRejectionCode::UnitProductionMissingStrategicResource => {
            ClientCommandRejectionCodeDto::UnitProductionMissingStrategicResource
        }
        CommandRejectionCode::UnitProductionRequiresCoast => {
            ClientCommandRejectionCodeDto::UnitProductionRequiresCoast
        }
        CommandRejectionCode::UnitSupplyLimitReached => {
            ClientCommandRejectionCodeDto::UnitSupplyLimitReached
        }
        CommandRejectionCode::WonderNotAvailable => {
            ClientCommandRejectionCodeDto::WonderNotAvailable
        }
        CommandRejectionCode::CitySpecializationLocked => {
            ClientCommandRejectionCodeDto::CitySpecializationLocked
        }
        CommandRejectionCode::CitySpecializationUnchanged => {
            ClientCommandRejectionCodeDto::CitySpecializationUnchanged
        }
        CommandRejectionCode::CitySpecializationMissingBuilding => {
            ClientCommandRejectionCodeDto::CitySpecializationMissingBuilding
        }
        CommandRejectionCode::ProductionQueueEmpty => {
            ClientCommandRejectionCodeDto::ProductionQueueEmpty
        }
        CommandRejectionCode::ProjectCannotBeRushed => {
            ClientCommandRejectionCodeDto::ProjectCannotBeRushed
        }
        CommandRejectionCode::RushProductionUnavailable => {
            ClientCommandRejectionCodeDto::RushProductionUnavailable
        }
        CommandRejectionCode::UnitAlreadyCarryingArtifact => {
            ClientCommandRejectionCodeDto::UnitAlreadyCarryingArtifact
        }
        CommandRejectionCode::ArtifactNotFound => ClientCommandRejectionCodeDto::ArtifactNotFound,
        CommandRejectionCode::UnitNotCarryingArtifact => {
            ClientCommandRejectionCodeDto::UnitNotCarryingArtifact
        }
        CommandRejectionCode::UnitNotInCity => ClientCommandRejectionCodeDto::UnitNotInCity,
        CommandRejectionCode::CityArtifactSlotFull => {
            ClientCommandRejectionCodeDto::CityArtifactSlotFull
        }
        CommandRejectionCode::ArtifactTradeActorUnavailable => {
            ClientCommandRejectionCodeDto::ArtifactTradeActorUnavailable
        }
        CommandRejectionCode::ArtifactTradeTargetInvalid => {
            ClientCommandRejectionCodeDto::ArtifactTradeTargetInvalid
        }
        CommandRejectionCode::ArtifactTradeGoldInvalid => {
            ClientCommandRejectionCodeDto::ArtifactTradeGoldInvalid
        }
        CommandRejectionCode::ArtifactTradeBlockedByWar => {
            ClientCommandRejectionCodeDto::ArtifactTradeBlockedByWar
        }
        CommandRejectionCode::ArtifactTradeGoldUnavailable => {
            ClientCommandRejectionCodeDto::ArtifactTradeGoldUnavailable
        }
        CommandRejectionCode::OfferedArtifactUnavailable => {
            ClientCommandRejectionCodeDto::OfferedArtifactUnavailable
        }
        CommandRejectionCode::TargetArtifactSlotUnavailable => {
            ClientCommandRejectionCodeDto::TargetArtifactSlotUnavailable
        }
        CommandRejectionCode::WorkerNotFound => ClientCommandRejectionCodeDto::WorkerNotFound,
        CommandRejectionCode::WorkerNotControlled => {
            ClientCommandRejectionCodeDto::WorkerNotControlled
        }
        CommandRejectionCode::WorkerUnavailable => ClientCommandRejectionCodeDto::WorkerUnavailable,
        CommandRejectionCode::WorkerNoMovementPoints => {
            ClientCommandRejectionCodeDto::WorkerNoMovementPoints
        }
        CommandRejectionCode::WorkerQueuedPathActive => {
            ClientCommandRejectionCodeDto::WorkerQueuedPathActive
        }
        CommandRejectionCode::WorkerImprovementNotSelected => {
            ClientCommandRejectionCodeDto::WorkerImprovementNotSelected
        }
        CommandRejectionCode::WorkerActionNotControlled => {
            ClientCommandRejectionCodeDto::WorkerActionNotControlled
        }
        CommandRejectionCode::WorkerImprovementUnavailable => {
            ClientCommandRejectionCodeDto::WorkerImprovementUnavailable
        }
        CommandRejectionCode::WorkerJobNotActive => {
            ClientCommandRejectionCodeDto::WorkerJobNotActive
        }
        CommandRejectionCode::WorkerAssignmentUnavailable => {
            ClientCommandRejectionCodeDto::WorkerAssignmentUnavailable
        }
        CommandRejectionCode::WorkerAssignmentNotActive => {
            ClientCommandRejectionCodeDto::WorkerAssignmentNotActive
        }
        CommandRejectionCode::WorkerRoadUnavailable => {
            ClientCommandRejectionCodeDto::WorkerRoadUnavailable
        }
        CommandRejectionCode::RoadConstructionExistingRoad => {
            ClientCommandRejectionCodeDto::RoadConstructionExistingRoad
        }
        CommandRejectionCode::RoadConstructionCity => {
            ClientCommandRejectionCodeDto::RoadConstructionCity
        }
        CommandRejectionCode::RoadConstructionEnemyTerritory => {
            ClientCommandRejectionCodeDto::RoadConstructionEnemyTerritory
        }
        CommandRejectionCode::RoadConstructionImpassableTerrain => {
            ClientCommandRejectionCodeDto::RoadConstructionImpassableTerrain
        }
        CommandRejectionCode::WorkerAutomationNotActive => {
            ClientCommandRejectionCodeDto::WorkerAutomationNotActive
        }
        CommandRejectionCode::WorkerAutomationNoTarget => {
            ClientCommandRejectionCodeDto::WorkerAutomationNoTarget
        }
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
        worker_build_charges: value.worker_build_charges(),
        worker_job: value.worker_job().map(|job| match job {
            aonw_domain::WorkerJob::FieldImprovement {
                target,
                improvement,
                remaining_turns,
                total_turns,
            } => WorkerJobViewDto::FieldImprovement {
                target: coordinate(*target),
                improvement: encode_improvement(*improvement),
                remaining_turns: *remaining_turns,
                total_turns: *total_turns,
            },
            aonw_domain::WorkerJob::RoadConstruction {
                target,
                remaining_turns,
                total_turns,
            } => WorkerJobViewDto::RoadConstruction {
                target: coordinate(*target),
                remaining_turns: *remaining_turns,
                total_turns: *total_turns,
            },
        }),
        worker_assignment: value.worker_assignment().map(coordinate),
    }
}

fn city(value: &PlayerCityView) -> PlayerCityViewDto {
    PlayerCityViewDto {
        id: value.id().as_str().to_owned(),
        owner_player_id: value.owner_player_id().as_str().to_owned(),
        name: value.name().to_owned(),
        center: coordinate(value.center()),
        visible_controlled_hexes: value
            .visible_controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        owned_planning: value
            .owned_planning()
            .map(|planning| OwnedCityPlanningViewDto {
                population: planning.population(),
                worked_hexes: planning
                    .worked_hexes()
                    .iter()
                    .copied()
                    .map(coordinate)
                    .collect(),
                preferred_expansion_hex: planning.preferred_expansion_hex().map(coordinate),
            }),
    }
}

fn founding_draft(value: &CityFoundingDraftView) -> CityFoundingDraftViewDto {
    CityFoundingDraftViewDto {
        founder_unit_id: value.founder_unit_id().as_str().to_owned(),
        center: coordinate(value.center()),
        controlled_hexes: value
            .controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
    }
}

fn patch(value: &PlayerViewPatch) -> PlayerViewPatchDto {
    PlayerViewPatchDto {
        from_revision: value.from_revision,
        to_revision: value.to_revision,
        turn_lifecycle: value.turn_lifecycle.map(turn_lifecycle),
        upserted_units: value.upserted_units.iter().map(unit).collect(),
        removed_unit_ids: value
            .removed_unit_ids
            .iter()
            .map(|id| id.as_str().to_owned())
            .collect(),
        upserted_cities: value.upserted_cities.iter().map(city).collect(),
        removed_city_ids: value
            .removed_city_ids
            .iter()
            .map(|id| id.as_str().to_owned())
            .collect(),
        upserted_field_improvements: value
            .upserted_field_improvements
            .iter()
            .copied()
            .map(field_improvement)
            .collect(),
        removed_field_improvement_coordinates: value
            .removed_field_improvement_coordinates
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        upserted_roads: value.upserted_roads.iter().copied().map(road).collect(),
        removed_road_coordinates: value
            .removed_road_coordinates
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        pending_action: value.pending_action.as_ref().map(pending_action),
        city_founding_draft: value.city_founding_draft.as_ref().map(founding_draft),
    }
}
