use aonw_contract_mapping::{
    encode_city_building, encode_city_production_queue, encode_city_specialization,
    encode_city_wonder, encode_improvement, encode_merchant_trade_route, encode_queued_path,
    encode_troop, encode_unit_kind, encode_unit_posture,
};
use aonw_contracts::client::{
    CityFoundingJobViewDto, ClientCommandOutcomeDto, ClientCommandResultDto,
    OwnedCityDetailsViewDto, OwnedUnitDetailsViewDto, PlayerCityViewDto, PlayerUnitViewDto,
    PlayerViewPatchDto, WorkerJobViewDto,
};
use aonw_contracts::{ArmyTroopDto, CoordinateDto};

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

pub(crate) fn command_result(value: &CommandResult) -> ClientCommandResultDto {
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
        hit_points: value.hit_points(),
        carried_artifact_id: value.carried_artifact_id().map(|id| id.as_str().to_owned()),
        owned_details: value.owned_details().map(|details| {
            let activity = details.activity();
            OwnedUnitDetailsViewDto {
                army: details
                    .army()
                    .iter()
                    .map(|troop| ArmyTroopDto {
                        kind: encode_troop(troop.kind()),
                        count: troop.count(),
                    })
                    .collect(),
                queued_path: details.queued_path().map(encode_queued_path),
                merchant_trade_route: details
                    .merchant_trade_route()
                    .map(encode_merchant_trade_route),
                worker_job: activity.worker_job().map(worker_job),
                city_founding_job: activity
                    .city_founding_job()
                    .map(|job| CityFoundingJobViewDto {
                        center: coordinate(job.center()),
                        controlled_hexes: job
                            .controlled_hexes()
                            .iter()
                            .copied()
                            .map(coordinate)
                            .collect(),
                        remaining_turns: job.remaining_turns(),
                        total_turns: job.total_turns(),
                    }),
                worker_assignment: activity.worker_assignment().map(coordinate),
                excavating_artifact_id: activity
                    .excavating_artifact_id()
                    .map(|id| id.as_str().to_owned()),
                worker_build_charges: details.worker_build_charges(),
                experience_points: details.experience_points(),
            }
        }),
    }
}

fn worker_job(job: &aonw_domain::WorkerJob) -> WorkerJobViewDto {
    match job {
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
        hit_points: value.hit_points(),
        owned_details: value
            .owned_details()
            .map(|details| OwnedCityDetailsViewDto {
                population: details.population(),
                stored_food: details.stored_food(),
                max_hexes: details.max_hexes(),
                territory_radius: details.territory_radius(),
                worked_hexes: details
                    .worked_hexes()
                    .iter()
                    .copied()
                    .map(coordinate)
                    .collect(),
                buildings: details
                    .buildings()
                    .iter()
                    .copied()
                    .map(encode_city_building)
                    .collect(),
                wonders: details
                    .wonders()
                    .iter()
                    .copied()
                    .map(encode_city_wonder)
                    .collect(),
                production_queue: details.production_queue().map(encode_city_production_queue),
                production_overflow: details.production_overflow(),
                specialization: details.specialization().map(encode_city_specialization),
                preferred_expansion_hex: details.preferred_expansion_hex().map(coordinate),
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
