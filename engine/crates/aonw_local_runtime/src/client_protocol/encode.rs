use aonw_contract_mapping::{encode_improvement, encode_unit_kind, encode_unit_posture};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    ClientCommandOutcomeDto, ClientCommandResultDto, OwnedCityPlanningViewDto, PlayerCityViewDto,
    PlayerUnitViewDto, PlayerViewPatchDto, WorkerJobViewDto,
};

use crate::{CommandResult, PlayerCityView, PlayerUnitView, PlayerViewPatch};

mod artifact;
mod capability;
mod diplomacy;
mod evidence;
mod map_view;
mod presentation;
mod query;
mod rejection;
mod research;
mod simple;
mod snapshot;
#[cfg(test)]
mod tests;
mod worker;

pub(super) use capability::capabilities;
use diplomacy::diplomacy;
use evidence::{event, recipient_evidence};
use map_view::coordinate;
pub(super) use map_view::map;
#[cfg(test)]
use map_view::{objective_type, resource, terrain};
use presentation::{pending_action, turn_lifecycle};
pub(super) use query::query_result;
#[cfg(test)]
use query::{merchant_destination, movement_metrics};
use rejection::rejection;
use simple::founding_draft;
pub(super) use simple::replay_verification;
use simple::{field_improvement, road};
pub(super) use snapshot::{snapshot, stamp};

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

fn patch(value: &PlayerViewPatch) -> PlayerViewPatchDto {
    PlayerViewPatchDto {
        from_revision: value.from_revision,
        to_revision: value.to_revision,
        turn: value.turn,
        turn_lifecycle: value.turn_lifecycle.map(turn_lifecycle),
        outcome: value
            .outcome
            .as_ref()
            .map(aonw_contract_mapping::encode_game_outcome),
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
        upserted_artifacts: value.upserted_artifacts.iter().map(artifact).collect(),
        removed_artifact_ids: value
            .removed_artifact_ids
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
        diplomacy: value.diplomacy.as_ref().map(diplomacy),
    }
}
use artifact::artifact;
