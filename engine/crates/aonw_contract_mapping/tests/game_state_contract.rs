//! Canonical state contract and domain round-trip tests.

use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::{
    ArmyTroopDto, CURRENT_GAME_STATE_VERSION, CityDto, CoordinateDto, GameStateDto,
    MovementStepDto, PlayerFogDto, PlayerPairDto, QueuedMovePathDto, TransportConditionDto,
    TransportSegmentDto, TroopKindDto, UnitActivityDto, UnitDto, UnitKindDto,
    UnitOccupancyPolicyDto, UnitPostureDto, WorkerJobDto,
};
use aonw_domain::{FogVisibility, HexCoord, UnitId};

fn contract() -> GameStateDto {
    GameStateDto {
        schema_version: CURRENT_GAME_STATE_VERSION,
        revision: 9,
        turn: 3,
        cols: 5,
        rows: 5,
        occupancy_policy: UnitOccupancyPolicyDto::FriendlyStacking,
        units: vec![UnitDto {
            id: "unit-1".to_owned(),
            owner_player_id: "player-1".to_owned(),
            kind: UnitKindDto::Worker,
            name: "unit.worker".to_owned(),
            col: 1,
            row: 1,
            movement_units: 4,
            army: vec![ArmyTroopDto {
                kind: TroopKindDto::Settler,
                count: 2,
            }],
            queued_path: Some(QueuedMovePathDto {
                target_col: 2,
                target_row: 1,
                steps: vec![
                    MovementStepDto {
                        col: 1,
                        row: 1,
                        enter_cost_units: 0,
                        cumulative_cost_units: 0,
                    },
                    MovementStepDto {
                        col: 2,
                        row: 1,
                        enter_cost_units: 2,
                        cumulative_cost_units: 2,
                    },
                ],
            }),
            merchant_trade_route: None,
            activity: UnitActivityDto {
                worker_job: Some(WorkerJobDto::RoadConstruction {
                    target: CoordinateDto { col: 1, row: 1 },
                    remaining_turns: 1,
                    total_turns: 2,
                }),
                city_founding_job: None,
                worker_assignment: None,
                excavating_artifact_id: Some("artifact-1".to_owned()),
            },
            worker_build_charges: 4,
            hit_points: Some(7),
            experience_points: 11,
            posture: UnitPostureDto::AutoWorking,
            carried_artifact_id: Some("artifact-2".to_owned()),
        }],
        cities: vec![CityDto {
            id: "city-1".to_owned(),
            owner_player_id: "player-1".to_owned(),
            center: CoordinateDto { col: 0, row: 0 },
            controlled_hexes: vec![CoordinateDto { col: 0, row: 1 }],
        }],
        fog_of_war: vec![PlayerFogDto {
            player_id: "player-1".to_owned(),
            discovered_hexes: vec![
                CoordinateDto { col: 0, row: 0 },
                CoordinateDto { col: 1, row: 1 },
            ],
            visible_hexes: vec![CoordinateDto { col: 1, row: 1 }],
        }],
        diplomatic_contacts: vec![PlayerPairDto {
            first_player_id: "player-1".to_owned(),
            second_player_id: "player-2".to_owned(),
        }],
        transport_network: vec![TransportSegmentDto {
            coordinate: CoordinateDto { col: 1, row: 1 },
            condition: TransportConditionDto::Operational,
            built_by_player_id: "player-1".to_owned(),
            built_by_city_id: Some("city-1".to_owned()),
        }],
    }
}

#[test]
fn complete_state_round_trip_preserves_every_movement_slice() {
    let source = contract();
    let state = decode_game_state(source.clone()).expect("decode");
    let encoded = encode_game_state(&state);

    assert_eq!(encoded, source);
    assert_eq!(decode_game_state(encoded), Ok(state));
}

#[test]
fn json_round_trip_remains_strict_and_domain_validated() {
    let source = contract();
    let json = source.to_json().expect("encode json");
    let decoded_dto = GameStateDto::from_json(&json, json.len()).expect("decode json");
    let state = decode_game_state(decoded_dto).expect("map domain");
    let unit = state
        .unit(&UnitId::new("unit-1").expect("unit id"))
        .expect("unit");

    assert_eq!(unit.hit_points(), Some(7));
    assert_eq!(unit.experience_points(), 11);
    assert_eq!(
        state
            .fog_of_war()
            .visibility(unit.owner_player_id(), HexCoord::new(1, 1)),
        FogVisibility::Visible
    );
}

#[test]
fn contract_version_and_map_bounds_fail_closed() {
    let mut version = contract();
    version.schema_version += 1;
    assert_eq!(
        decode_game_state(version).expect_err("version").path(),
        "$.schemaVersion"
    );

    let mut bounds = contract();
    bounds.cols = 0;
    assert_eq!(decode_game_state(bounds).expect_err("bounds").path(), "$");
}
