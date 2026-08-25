use std::collections::BTreeMap;

use aonw_contracts::client::{
    CitySpecializationOptionDto, ClientCommandDto, ClientQueryDto, ClientQueryResultDto,
    ClientRequestBodyDto, ClientResponseBodyDto, ProductionOptionDto, UnitProductionOptionDto,
};
use aonw_contracts::{
    CityBuildingTypeDto, CityProductionTargetDto, CityProjectTypeDto, CitySpecializationTypeDto,
    ResourceTypeDto, StrategicResourceStockpileDto, UnitKindDto, WonderTypeDto,
};

use super::stamp;

pub(super) fn requests() -> Vec<ClientRequestBodyDto> {
    vec![
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionOptions {
                expected_revision: 8,
                city_id: "city-1".to_owned(),
            },
        },
        dispatch(ClientCommandDto::StartBuilding {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            building: CityBuildingTypeDto::Workshop,
        }),
        dispatch(ClientCommandDto::StartUnitProduction {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            unit: UnitKindDto::Tank,
            resource_option_index: Some(0),
        }),
        dispatch(ClientCommandDto::StartCityProject {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            project: CityProjectTypeDto::Research,
        }),
        dispatch(ClientCommandDto::StartWonder {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            wonder: WonderTypeDto::GreatLibrary,
        }),
        dispatch(ClientCommandDto::SetCitySpecialization {
            expected_revision: 8,
            city_id: "city-1".to_owned(),
            specialization: CitySpecializationTypeDto::Industry,
        }),
    ]
}

pub(super) fn response() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::ProductionOptions {
            stamp: stamp(),
            city_id: "city-1".to_owned(),
            current_target: Some(CityProductionTargetDto::Project {
                project_type: CityProjectTypeDto::Research,
            }),
            invested_production: 4,
            production_overflow: 1,
            buildings: vec![ProductionOptionDto {
                target: CityProductionTargetDto::Building {
                    building_type: CityBuildingTypeDto::Workshop,
                },
                cost: 15,
                rejection: None,
            }],
            units: vec![UnitProductionOptionDto {
                option: ProductionOptionDto {
                    target: CityProductionTargetDto::Unit {
                        unit_type: UnitKindDto::Tank,
                    },
                    cost: 32,
                    rejection: None,
                },
                resource_options: vec![StrategicResourceStockpileDto(BTreeMap::from([(
                    ResourceTypeDto::Oil,
                    2,
                )]))],
                affordable_resource_option_indices: vec![0],
            }],
            projects: vec![ProductionOptionDto {
                target: CityProductionTargetDto::Project {
                    project_type: CityProjectTypeDto::Research,
                },
                cost: 0,
                rejection: None,
            }],
            wonders: vec![ProductionOptionDto {
                target: CityProductionTargetDto::Wonder {
                    wonder_type: WonderTypeDto::GreatLibrary,
                },
                cost: 25,
                rejection: None,
            }],
            specializations: vec![CitySpecializationOptionDto {
                specialization: CitySpecializationTypeDto::Industry,
                required_building: CityBuildingTypeDto::Workshop,
                rejection: None,
            }],
        },
    }
}

fn dispatch(command: ClientCommandDto) -> ClientRequestBodyDto {
    ClientRequestBodyDto::Dispatch { command }
}
