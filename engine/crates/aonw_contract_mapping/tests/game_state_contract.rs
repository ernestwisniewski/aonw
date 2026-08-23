//! Canonical state contract and domain round-trip tests.

use std::collections::BTreeMap;

use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::{
    AiDifficultyDto, AiPersonaDto, AiPlayerDto, AiStrategyIdDto, ArmyTroopDto, CityDto,
    CoordinateDto, GameLengthConfigDto, GameLengthKindDto, GameModeDto, GameStateDto,
    InteractionStateDto, MatchIdentityDto, MatchRulesDto, MovementStepDto, PaceProfileDto,
    ParticipantDto, PendingInteractionDto, PlayerCountryDto, PlayerFogDto, PlayerKindDto,
    PlayerPairDto, PlayerTurnStateDto, QueuedMovePathDto, RuleValueDto, TransportConditionDto,
    TransportSegmentDto, TroopKindDto, TurnLifecycleDto, UnitActivityDto, UnitDto, UnitKindDto,
    UnitOccupancyPolicyDto, UnitPostureDto, VictoryRulesDto, WorkerJobDto, WorldArtifactDto,
    WorldArtifactLocationDto, WorldArtifactTypeDto,
};
use aonw_domain::{FogVisibility, HexCoord, UnitId};

fn contract() -> GameStateDto {
    GameStateDto {
        revision: 9,
        turn: 3,
        match_identity: match_identity(),
        turn_lifecycle: turn_lifecycle(),
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
        artifacts: vec![
            WorldArtifactDto {
                id: "artifact-1".to_owned(),
                artifact_type: WorldArtifactTypeDto::AstronomersTablets,
                location: WorldArtifactLocationDto::Excavation {
                    unit_id: "unit-1".to_owned(),
                    coordinate: CoordinateDto { col: 1, row: 1 },
                    remaining_turns: 2,
                },
            },
            WorldArtifactDto {
                id: "artifact-2".to_owned(),
                artifact_type: WorldArtifactTypeDto::HeroSword,
                location: WorldArtifactLocationDto::Carried {
                    unit_id: "unit-1".to_owned(),
                },
            },
        ],
        interaction: InteractionStateDto::default(),
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

fn match_identity() -> MatchIdentityDto {
    MatchIdentityDto {
        match_rules: MatchRulesDto {
            game_length: GameLengthConfigDto {
                kind: GameLengthKindDto::TargetMinutes,
                target_minutes: Some(90),
                turn_limit: Some(180),
                pace_profile: PaceProfileDto::Normal90,
                score_fallback_enabled: true,
            },
            victory: VictoryRulesDto {
                conquest_enabled: true,
                domination_enabled: true,
                domination_control_percent: "47.5".parse().expect("finite percent"),
                domination_hold_turns: 12,
                score_fallback_enabled: true,
                turn_limit: Some(180),
                hard_time_limit_minutes: Some(95),
                cultural_enabled: true,
                cultural_required_artifacts: 6,
                cultural_hold_turns: 5,
            },
            balance: BTreeMap::from([
                (
                    "economy".to_owned(),
                    RuleValueDto::Object(BTreeMap::from([(
                        "growthMultiplier".to_owned(),
                        RuleValueDto::Number("0.92".parse().expect("finite balance")),
                    )])),
                ),
                (
                    "flags".to_owned(),
                    RuleValueDto::Array(vec![RuleValueDto::Bool(true), RuleValueDto::Null]),
                ),
            ]),
        },
        participants: vec![
            ParticipantDto {
                id: "player-1".to_owned(),
                name: "Ada".to_owned(),
                color_value: 0xff3d_5fa8,
                country: PlayerCountryDto::Poland,
                kind: PlayerKindDto::Human,
                ai: None,
            },
            ParticipantDto {
                id: "player-2".to_owned(),
                name: "Turing".to_owned(),
                color_value: 0xffb8_3a3a,
                country: PlayerCountryDto::UnitedKingdom,
                kind: PlayerKindDto::Ai,
                ai: Some(AiPlayerDto {
                    strategy_id: AiStrategyIdDto::Mcts,
                    difficulty: AiDifficultyDto::Hard,
                    persona: AiPersonaDto::Scientific,
                    seed: -17,
                }),
            },
        ],
        game_mode: GameModeDto::Multiplayer,
    }
}

fn turn_lifecycle() -> TurnLifecycleDto {
    TurnLifecycleDto {
        turn_states_by_player_id: BTreeMap::from([
            ("player-1".to_owned(), PlayerTurnStateDto::Active),
            ("player-2".to_owned(), PlayerTurnStateDto::Finished),
        ]),
        submitted_player_ids: vec!["player-2".to_owned()],
        timeout_streaks_by_player_id: BTreeMap::from([
            ("player-1".to_owned(), 0),
            ("player-2".to_owned(), 2),
        ]),
        afk_player_ids: vec!["player-2".to_owned()],
        kicked_player_ids: vec!["player-1".to_owned()],
        turn_started_at: Some("2026-08-23T12:34:56.123456Z".to_owned()),
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
fn identity_and_lifecycle_round_trip_preserves_typed_dart_values() {
    let source = contract();
    let state = decode_game_state(source.clone()).expect("decode complete identity");
    let lifecycle = state.match_lifecycle();

    assert_eq!(lifecycle.identity().participants()[1].name(), "Turing");
    assert_eq!(
        lifecycle
            .turn()
            .turn_started_at()
            .expect("turn start")
            .as_str(),
        "2026-08-23T12:34:56.123456Z"
    );
    assert_eq!(encode_game_state(&state), source);
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
fn current_turn_skip_round_trip_preserves_restore_balance() {
    let mut source = contract();
    let unit = &mut source.units[0];
    unit.movement_units = 0;
    unit.queued_path = None;
    unit.activity = UnitActivityDto::default();
    unit.posture = UnitPostureDto::Active;
    unit.carried_artifact_id = None;
    source.artifacts.clear();
    source.interaction.pending = Some(PendingInteractionDto::UnitTurnSkip {
        owner_player_id: "player-1".to_owned(),
        unit_id: "unit-1".to_owned(),
        restore_movement_units: 4,
    });

    let state = decode_game_state(source.clone()).expect("decode skipped unit");
    assert_eq!(encode_game_state(&state), source);
}

#[test]
fn invalid_map_bounds_fail_closed() {
    let mut bounds = contract();
    bounds.cols = 0;
    assert_eq!(decode_game_state(bounds).expect_err("bounds").path(), "$");
}

#[test]
fn lifecycle_rejects_unknown_duplicates_and_non_utc_time_with_paths() {
    let mut unknown = contract();
    unknown
        .turn_lifecycle
        .submitted_player_ids
        .push("player-3".to_owned());
    assert_eq!(
        decode_game_state(unknown)
            .expect_err("unknown participant")
            .path(),
        "$.turnLifecycle"
    );

    let mut duplicate = contract();
    duplicate
        .turn_lifecycle
        .submitted_player_ids
        .push("player-2".to_owned());
    assert_eq!(
        decode_game_state(duplicate)
            .expect_err("duplicate participant")
            .path(),
        "$.turnLifecycle"
    );

    let mut local_time = contract();
    local_time.turn_lifecycle.turn_started_at = Some("2026-08-23T14:34:56+02:00".to_owned());
    assert_eq!(
        decode_game_state(local_time)
            .expect_err("non-UTC time")
            .path(),
        "$.turnLifecycle.turnStartedAt"
    );
}
