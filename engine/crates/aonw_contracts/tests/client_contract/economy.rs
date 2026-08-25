//! Current economy query response fixtures.

use aonw_contracts::client::{
    CityYieldContributionDto, CityYieldContributionKindDto, ClientQueryResultDto,
    ClientResponseBodyDto, StrategicResourceAmountDto, StrategicResourceSourceDto, YieldValueDto,
};
use aonw_contracts::{FieldImprovementKindDto, ResourceTypeDto};

use super::{coordinate, stamp};

pub(super) fn responses() -> Vec<ClientResponseBodyDto> {
    vec![city_yield(), strategic_resource_projection()]
}

fn city_yield() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::CityYield {
            stamp: stamp(),
            city_id: "city-1".to_owned(),
            contributions: vec![CityYieldContributionDto {
                kind: CityYieldContributionKindDto::Center,
                coordinate: coordinate(3, 4),
                value: YieldValueDto {
                    food: 2,
                    production: 1,
                    gold: 0,
                    defense: 0,
                },
            }],
            total: YieldValueDto {
                food: 2,
                production: 1,
                gold: 0,
                defense: 0,
            },
        },
    }
}

fn strategic_resource_projection() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::StrategicResourceProjection {
            stamp: stamp(),
            player_id: "player-1".to_owned(),
            output: vec![StrategicResourceAmountDto {
                resource: ResourceTypeDto::Oil,
                amount: 1,
            }],
            sources: vec![StrategicResourceSourceDto {
                city_id: "city-1".to_owned(),
                coordinate: coordinate(4, 4),
                resource: ResourceTypeDto::Oil,
                improvement: FieldImprovementKindDto::OilWell,
                amount_per_turn: 1,
            }],
        },
    }
}
