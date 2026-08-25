use aonw_contract_mapping::{encode_improvement, encode_troop};
use aonw_contracts::client::{
    AutoExploreOptionDto, CityExpansionCandidateDto, ClientQueryResultDto, DetachmentOptionDto,
    MerchantDestinationOptionDto, MovementSearchMetricsDto, MovementStepViewDto,
    ReachableTileViewDto, WorkerImprovementOptionDto,
};
use aonw_engine::{CityExpansionOptions, CityFoundingOptions, CityWorkedHexOptions};

use crate::{RuntimeQueryResult, SessionStamp};

use super::evidence::combat_preview;
use super::map_view::coordinate;
use super::stamp;
use super::worker::automation_option;

pub(crate) fn query_result(value: &RuntimeQueryResult) -> ClientQueryResultDto {
    match value {
        RuntimeQueryResult::CityFoundingOptions {
            stamp: value_stamp,
            options,
        } => city_founding_options(*value_stamp, options),
        RuntimeQueryResult::CityWorkedHexOptions {
            stamp: value_stamp,
            options,
        } => city_worked_hex_options(*value_stamp, options),
        RuntimeQueryResult::CityExpansionOptions {
            stamp: value_stamp,
            options,
        } => city_expansion_options(*value_stamp, options),
        RuntimeQueryResult::CombatPreview {
            stamp: value_stamp,
            preview,
        } => ClientQueryResultDto::CombatPreview {
            stamp: stamp(*value_stamp),
            preview: combat_preview(preview),
        },
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
        RuntimeQueryResult::UnitLogisticsOptions(value) => {
            ClientQueryResultDto::UnitLogisticsOptions {
                stamp: stamp(value.stamp),
                unit_id: value.unit_id.as_str().to_owned(),
                auto_explore: value.auto_explore.map(|option| AutoExploreOptionDto {
                    target: coordinate(option.target),
                    total_cost_units: option.total_cost.get(),
                    search_metrics: movement_metrics(option.search_metrics),
                }),
                merchant_route_destinations: value
                    .merchant_route_destinations
                    .iter()
                    .map(merchant_destination)
                    .collect(),
                merchant_travel_destinations: value
                    .merchant_travel_destinations
                    .iter()
                    .map(merchant_destination)
                    .collect(),
                detachments: value
                    .detachments
                    .iter()
                    .map(|option| DetachmentOptionDto {
                        troop_kind: encode_troop(option.troop_kind),
                        destination: coordinate(option.destination),
                    })
                    .collect(),
            }
        }
        RuntimeQueryResult::WorkerOptions {
            stamp: value_stamp,
            options,
        } => worker_options(*value_stamp, options),
    }
}

fn worker_options(
    value_stamp: SessionStamp,
    options: &aonw_engine::WorkerOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::WorkerOptions {
        stamp: stamp(value_stamp),
        unit_id: options.unit_id().as_str().to_owned(),
        coordinate: coordinate(options.coordinate()),
        improvements: options
            .improvements()
            .iter()
            .map(|option| WorkerImprovementOptionDto {
                improvement: encode_improvement(option.kind()),
                build_turns: option.build_turns(),
            })
            .collect(),
        can_assign: options.can_assign(),
        can_build_road: options.can_build_road(),
        automation: options.automation().map(automation_option),
    }
}

fn city_founding_options(
    value_stamp: SessionStamp,
    options: &CityFoundingOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityFoundingOptions {
        stamp: stamp(value_stamp),
        founder_unit_id: options.founder_unit_id().as_str().to_owned(),
        center: coordinate(options.center()),
        selected_controlled_hexes: options
            .selected_controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        available_controlled_hexes: options
            .available_controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        required_controlled_hexes: options.required_controlled_hexes(),
        maximum_radius: options.maximum_radius(),
    }
}

fn city_worked_hex_options(
    value_stamp: SessionStamp,
    options: &CityWorkedHexOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityWorkedHexOptions {
        stamp: stamp(value_stamp),
        city_id: options.city_id().as_str().to_owned(),
        center: coordinate(options.center()),
        controlled_hexes: options
            .controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        available_hexes: options
            .available_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        selected_hexes: options
            .selected_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        effective_hexes: options
            .effective_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        limit: options.limit(),
    }
}

fn city_expansion_options(
    value_stamp: SessionStamp,
    options: &CityExpansionOptions,
) -> ClientQueryResultDto {
    ClientQueryResultDto::CityExpansionOptions {
        stamp: stamp(value_stamp),
        city_id: options.city_id().as_str().to_owned(),
        controlled_hexes: options
            .controlled_hexes()
            .iter()
            .copied()
            .map(coordinate)
            .collect(),
        preferred_hex: options.preferred_hex().map(coordinate),
        candidates: options
            .candidates()
            .iter()
            .map(|candidate| CityExpansionCandidateDto {
                coordinate: coordinate(candidate.coordinate()),
                score: candidate.score(),
                distance: candidate.distance(),
            })
            .collect(),
    }
}

pub(super) fn movement_metrics(
    value: aonw_engine::MovementSearchMetrics,
) -> MovementSearchMetricsDto {
    MovementSearchMetricsDto {
        frontier_pops: value.frontier_pops(),
        expanded_tiles: value.expanded_tiles(),
        examined_edges: value.examined_edges(),
        heap_pushes: value.heap_pushes(),
        route_records: value.route_records(),
    }
}

pub(super) fn merchant_destination(
    value: &crate::MerchantDestinationView,
) -> MerchantDestinationOptionDto {
    MerchantDestinationOptionDto {
        city_id: value.city_id.as_str().to_owned(),
        total_cost_units: value.total_cost.get(),
    }
}
