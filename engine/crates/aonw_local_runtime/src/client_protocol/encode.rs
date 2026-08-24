use aonw_contract_mapping::{encode_improvement, encode_unit_kind, encode_unit_posture};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CityFoundingDraftViewDto, ClientCommandOutcomeDto, ClientCommandRejectionCodeDto,
    ClientCommandResultDto, ClientFeatureDto, ClientReplayVerificationDto, ClientResponseBodyDto,
    ClientSessionStampDto, OwnedCityPlanningViewDto, PendingActionViewDto, PlayerCityViewDto,
    PlayerTurnLifecycleViewDto, PlayerUnitViewDto, PlayerViewPatchDto, PlayerViewSnapshotDto,
};
use aonw_domain::PlayerTurnState;
use aonw_engine::CommandRejectionCode;

use crate::{
    CityFoundingDraftView, CommandResult, LocalRuntime, PendingActionView, PlayerCityView,
    PlayerTurnLifecycleView, PlayerUnitView, PlayerViewPatch, PlayerViewSnapshot,
    ReplayVerification, SessionStamp,
};

mod evidence;
mod map_view;
mod query;
#[cfg(test)]
mod tests;

use evidence::{event, recipient_evidence};
use map_view::coordinate;
pub(super) use map_view::map;
#[cfg(test)]
use map_view::{objective_type, resource, terrain};
pub(super) use query::query_result;
#[cfg(test)]
use query::{merchant_destination, movement_metrics};

pub(super) fn capabilities() -> ClientResponseBodyDto {
    let capabilities = LocalRuntime::capabilities();
    let mut features = vec![ClientFeatureDto::InspectMap, ClientFeatureDto::Snapshot];
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
    if capabilities.turn_kernel() {
        features.push(ClientFeatureDto::TurnKernel);
    }
    if capabilities.movement_logistics() {
        features.push(ClientFeatureDto::MovementLogistics);
    }
    if capabilities.combat() {
        features.push(ClientFeatureDto::Combat);
    }
    if capabilities.cities() {
        features.push(ClientFeatureDto::Cities);
    }
    if capabilities.save_game() {
        features.push(ClientFeatureDto::SaveGame);
    }
    if capabilities.replay_verification() {
        features.push(ClientFeatureDto::ReplayVerification);
    }
    ClientResponseBodyDto::Capabilities { features }
}

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
        pending_action: value.pending_action.as_ref().map(pending_action),
        city_founding_draft: value.city_founding_draft.as_ref().map(founding_draft),
    }
}

fn pending_action(value: &PendingActionView) -> PendingActionViewDto {
    match value {
        PendingActionView::ResearchSelection => PendingActionViewDto::ResearchSelection,
        PendingActionView::CityWorkedHexSelection { city_id } => {
            PendingActionViewDto::CityWorkedHexSelection {
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingActionView::CityExpansionSelection { city_id } => {
            PendingActionViewDto::CityExpansionSelection {
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingActionView::WorkerActionSelection {
            unit_id,
            improvement,
        } => PendingActionViewDto::WorkerActionSelection {
            unit_id: unit_id.as_str().to_owned(),
            improvement: (*improvement).map(encode_improvement),
        },
        PendingActionView::MerchantTradeRouteSelection { unit_id } => {
            PendingActionViewDto::MerchantTradeRouteSelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
        PendingActionView::MerchantMoveToCitySelection { unit_id } => {
            PendingActionViewDto::MerchantMoveToCitySelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
        PendingActionView::UnitTurnSkip {
            unit_id,
            restore_movement_units,
        } => PendingActionViewDto::UnitTurnSkip {
            unit_id: unit_id.as_str().to_owned(),
            restore_movement_units: *restore_movement_units,
        },
        PendingActionView::AttackTargeting { unit_id, defender } => {
            PendingActionViewDto::AttackTargeting {
                unit_id: unit_id.as_str().to_owned(),
                defender: (*defender).map(coordinate),
            }
        }
        PendingActionView::CommanderMergeSelection { unit_id } => {
            PendingActionViewDto::CommanderMergeSelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
    }
}

fn turn_lifecycle(value: PlayerTurnLifecycleView) -> PlayerTurnLifecycleViewDto {
    PlayerTurnLifecycleViewDto {
        own_state: value.own_state().map(|state| match state {
            PlayerTurnState::Active => aonw_contracts::PlayerTurnStateDto::Active,
            PlayerTurnState::Finished => aonw_contracts::PlayerTurnStateDto::Finished,
        }),
        own_submitted: value.own_submitted(),
        required_submission_count: value.required_submission_count(),
        submitted_count: value.submitted_count(),
    }
}
