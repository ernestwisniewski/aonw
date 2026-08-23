//! Canonical state contract and domain round-trip tests.

use std::collections::BTreeMap;

use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::{
    AiDifficultyDto, AiPersonaDto, AiPlayerDto, AiStrategyIdDto, ArmyTroopDto, CityBuildingTypeDto,
    CityConquestActionDto, CityDto, CityProductionQueueDto, CityProductionTargetDto,
    CityProjectTypeDto, CitySpecializationTypeDto, CoordinateDto, EconomyStateDto,
    FieldImprovementDto, FieldImprovementKindDto, GameLengthConfigDto, GameLengthKindDto,
    GameModeDto, GameStateDto, InitialResourceDistributionDto, InitialResourcePlacementDto,
    IntendedAttackDto, InteractionStateDto, MatchIdentityDto, MatchRulesDto, MovementStepDto,
    PaceProfileDto, ParticipantDto, PendingInteractionDto, PlayerCountryDto, PlayerFogDto,
    PlayerKindDto, PlayerPairDto, PlayerResearchStateDto, PlayerTurnStateDto, QueuedMovePathDto,
    ResearchStateDto, ResourceTypeDto, RuleValueDto, StrategicResourceStockpileDto,
    TechnologyIdDto, TransportConditionDto, TransportSegmentDto, TransportSegmentKindDto,
    TroopKindDto, TurnLifecycleDto, UnitActivityDto, UnitDto, UnitKindDto, UnitOccupancyPolicyDto,
    UnitPostureDto, VictoryRulesDto, WonderRegistryDto, WonderTypeDto, WorkerJobDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};
use aonw_domain::{FogVisibility, HexCoord, UnitId};

fn contract() -> GameStateDto {
    GameStateDto {
        revision: 9,
        turn: 3,
        match_identity: match_identity(),
        turn_lifecycle: turn_lifecycle(),
        economy: economy(),
        research: research(),
        wonder_registry: wonder_registry(),
        intended_attacks: intended_attacks(),
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
        cities: vec![city()],
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
        field_improvements: field_improvements(),
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
            kind: TransportSegmentKindDto::Road,
            condition: TransportConditionDto::Operational,
            built_by_player_id: "player-1".to_owned(),
            built_by_city_id: Some("city-1".to_owned()),
        }],
    }
}

fn research() -> ResearchStateDto {
    ResearchStateDto {
        players: BTreeMap::from([
            (
                "player-1".to_owned(),
                PlayerResearchStateDto {
                    unlocked_technology_ids: vec![TechnologyIdDto::Logistics],
                    active_technology_id: Some(TechnologyIdDto::Agriculture),
                    progress_by_technology_id: BTreeMap::from([(TechnologyIdDto::Agriculture, 4)]),
                    science_overflow: 3,
                },
            ),
            (
                "player-2".to_owned(),
                PlayerResearchStateDto {
                    unlocked_technology_ids: vec![TechnologyIdDto::Writing],
                    active_technology_id: None,
                    progress_by_technology_id: BTreeMap::new(),
                    science_overflow: 11,
                },
            ),
        ]),
    }
}

fn wonder_registry() -> WonderRegistryDto {
    WonderRegistryDto(BTreeMap::from([(
        WonderTypeDto::CentralBank,
        "player-2".to_owned(),
    )]))
}

fn intended_attacks() -> Vec<IntendedAttackDto> {
    vec![IntendedAttackDto {
        attacker_unit_id: "unit-1".to_owned(),
        defender_col: 2,
        defender_row: 1,
        declared_at_tick: 41,
        declaring_player_id: "player-1".to_owned(),
        city_conquest_action: CityConquestActionDto::Destroy,
    }]
}

fn field_improvements() -> Vec<FieldImprovementDto> {
    vec![FieldImprovementDto {
        coordinate: CoordinateDto { col: 0, row: 1 },
        kind: FieldImprovementKindDto::Farm,
        built_by_city_id: Some("city-1".to_owned()),
    }]
}

fn city() -> CityDto {
    CityDto {
        id: "city-1".to_owned(),
        owner_player_id: "player-1".to_owned(),
        founding_owner_player_id: Some("player-2".to_owned()),
        name: "Warsaw".to_owned(),
        population: 7,
        stored_food: -3,
        max_hexes: 10,
        territory_radius: 3,
        center: CoordinateDto { col: 0, row: 0 },
        controlled_hexes: vec![CoordinateDto { col: 0, row: 1 }],
        worked_hexes: vec![CoordinateDto { col: 0, row: 1 }],
        buildings: vec![CityBuildingTypeDto::Granary, CityBuildingTypeDto::Workshop],
        wonders: vec![WonderTypeDto::GreatLibrary],
        production_queue: Some(CityProductionQueueDto {
            target: CityProductionTargetDto::Wonder {
                wonder_type: WonderTypeDto::GrandExposition,
            },
            invested_production: 23,
            resource_allocation: StrategicResourceStockpileDto(BTreeMap::from([(
                ResourceTypeDto::Oil,
                2,
            )])),
        }),
        production_overflow: -5,
        specialization: Some(CitySpecializationTypeDto::Science),
        preferred_expansion_hex: Some(CoordinateDto { col: 1, row: 0 }),
        hit_points: Some(41),
    }
}

fn economy() -> EconomyStateDto {
    EconomyStateDto {
        player_gold: BTreeMap::from([
            ("player-1".to_owned(), 9_007_199_254_740_991),
            ("player-2".to_owned(), -17),
        ]),
        player_war_weariness: BTreeMap::from([
            ("player-1".to_owned(), -3),
            ("player-2".to_owned(), 14),
        ]),
        player_stability_net: BTreeMap::from([
            ("player-1".to_owned(), 8),
            ("player-2".to_owned(), -11),
        ]),
        strategic_resources: BTreeMap::from([
            (
                "player-1".to_owned(),
                StrategicResourceStockpileDto(BTreeMap::from([
                    (ResourceTypeDto::Oil, 13),
                    (ResourceTypeDto::Aluminium, 5),
                ])),
            ),
            (
                "player-2".to_owned(),
                StrategicResourceStockpileDto::default(),
            ),
        ]),
        initial_resource_distribution: InitialResourceDistributionDto {
            seed: -9_007_199_254_740_991,
            placements: vec![
                InitialResourcePlacementDto {
                    col: 4,
                    row: 3,
                    resource: ResourceTypeDto::Wheat,
                },
                InitialResourcePlacementDto {
                    col: 3,
                    row: 4,
                    resource: ResourceTypeDto::Oil,
                },
            ],
        },
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
fn economy_round_trip_preserves_signed_accounts_stockpiles_and_ordered_placements() {
    let source = contract();
    let state = decode_game_state(source.clone()).expect("decode complete economy");
    let economy = state.economy();

    assert_eq!(
        economy.player_gold().values().copied().collect::<Vec<_>>(),
        [9_007_199_254_740_991, -17]
    );
    assert_eq!(
        economy.initial_resource_distribution().placements()[0].coordinate(),
        HexCoord::new(4, 3)
    );
    assert_eq!(encode_game_state(&state), source);
}

#[test]
fn complete_city_round_trip_preserves_progression_topology_production_and_planning() {
    let source = contract();
    let state = decode_game_state(source.clone()).expect("decode complete city");
    let city = state.cities().first().expect("city");

    assert_eq!(
        city.founding_owner_player_id().expect("founder").as_str(),
        "player-2"
    );
    assert_eq!(city.name(), "Warsaw");
    assert_eq!(city.population(), 7);
    assert_eq!(city.stored_food(), -3);
    assert_eq!(city.worked_hexes(), [HexCoord::new(0, 1)]);
    assert_eq!(
        city.production_queue()
            .expect("production")
            .resource_allocation()
            .amounts()
            .values()
            .copied()
            .collect::<Vec<_>>(),
        [2]
    );
    assert_eq!(encode_game_state(&state), source);
}

#[test]
fn every_city_production_target_round_trips() {
    for target in [
        CityProductionTargetDto::Building {
            building_type: CityBuildingTypeDto::WorldFairGrounds,
        },
        CityProductionTargetDto::Unit {
            unit_type: UnitKindDto::ReconPlane,
        },
        CityProductionTargetDto::Project {
            project_type: CityProjectTypeDto::Research,
        },
        CityProductionTargetDto::Wonder {
            wonder_type: WonderTypeDto::SvalbardSeedVault,
        },
    ] {
        let mut source = contract();
        source.cities[0]
            .production_queue
            .as_mut()
            .expect("queue")
            .target = target;
        let state = decode_game_state(source.clone()).expect("decode target");
        assert_eq!(encode_game_state(&state), source);
    }
}

#[test]
fn every_field_improvement_kind_round_trips() {
    let kinds = [
        FieldImprovementKindDto::Farm,
        FieldImprovementKindDto::RiverFarm,
        FieldImprovementKindDto::Mine,
        FieldImprovementKindDto::LumberMill,
        FieldImprovementKindDto::Pasture,
        FieldImprovementKindDto::Camp,
        FieldImprovementKindDto::Quarry,
        FieldImprovementKindDto::FishingBoats,
        FieldImprovementKindDto::Orchard,
        FieldImprovementKindDto::Plantation,
        FieldImprovementKindDto::Vineyard,
        FieldImprovementKindDto::TradingPost,
        FieldImprovementKindDto::ProspectorCamp,
        FieldImprovementKindDto::HorseRanch,
        FieldImprovementKindDto::PearlDivers,
        FieldImprovementKindDto::CoalShaft,
        FieldImprovementKindDto::OilWell,
        FieldImprovementKindDto::BauxiteMine,
        FieldImprovementKindDto::UraniumMine,
    ];
    for kind in kinds {
        let mut source = contract();
        source.field_improvements[0].kind = kind;
        let state = decode_game_state(source.clone()).expect("decode improvement kind");
        assert_eq!(encode_game_state(&state), source);
    }
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

#[test]
fn economy_rejects_unknown_players_invalid_stockpiles_and_invalid_placements_with_paths() {
    let mut unknown = contract();
    unknown.economy.player_gold.insert("player-3".to_owned(), 1);
    assert_eq!(
        decode_game_state(unknown)
            .expect_err("unknown player")
            .path(),
        "$.economy.playerGold.player-3"
    );

    let mut invalid_stockpile = contract();
    invalid_stockpile.economy.strategic_resources.insert(
        "player-1".to_owned(),
        StrategicResourceStockpileDto(BTreeMap::from([(ResourceTypeDto::Iron, 2)])),
    );
    assert_eq!(
        decode_game_state(invalid_stockpile)
            .expect_err("non-stockpiled resource")
            .path(),
        "$.economy.strategicResources.player-1"
    );

    let mut zero_stockpile = contract();
    zero_stockpile.economy.strategic_resources.insert(
        "player-1".to_owned(),
        StrategicResourceStockpileDto(BTreeMap::from([(ResourceTypeDto::Oil, 0)])),
    );
    assert_eq!(
        decode_game_state(zero_stockpile)
            .expect_err("zero canonical entry")
            .path(),
        "$.economy.strategicResources.player-1"
    );

    let mut duplicate = contract();
    duplicate
        .economy
        .initial_resource_distribution
        .placements
        .push(InitialResourcePlacementDto {
            col: 4,
            row: 3,
            resource: ResourceTypeDto::Fish,
        });
    assert_eq!(
        decode_game_state(duplicate)
            .expect_err("duplicate placement")
            .path(),
        "$.economy.initialResourceDistribution.placements"
    );

    let mut outside = contract();
    outside.economy.initial_resource_distribution.placements[0].col = 5;
    assert_eq!(
        decode_game_state(outside)
            .expect_err("out-of-bounds placement")
            .path(),
        "$.economy.initialResourceDistribution.placements[0]"
    );
}

#[test]
fn city_rejects_unknown_owners_duplicates_and_invalid_resource_allocations_with_paths() {
    let mut unknown = contract();
    unknown.cities[0].founding_owner_player_id = Some("player-3".to_owned());
    assert_eq!(
        decode_game_state(unknown)
            .expect_err("unknown founding owner")
            .path(),
        "$.cities[0].foundingOwnerPlayerId"
    );

    let mut duplicate_controlled = contract();
    duplicate_controlled.cities[0]
        .controlled_hexes
        .push(CoordinateDto { col: 0, row: 1 });
    assert_eq!(
        decode_game_state(duplicate_controlled)
            .expect_err("duplicate controlled hex")
            .path(),
        "$.cities[0].controlledHexes"
    );

    let mut invalid_worked = contract();
    invalid_worked.cities[0].worked_hexes[0] = CoordinateDto { col: 2, row: 2 };
    assert_eq!(
        decode_game_state(invalid_worked)
            .expect_err("uncontrolled worked hex")
            .path(),
        "$.cities[0].workedHexes"
    );

    let mut duplicate_building = contract();
    duplicate_building.cities[0]
        .buildings
        .push(CityBuildingTypeDto::Granary);
    assert_eq!(
        decode_game_state(duplicate_building)
            .expect_err("duplicate building")
            .path(),
        "$.cities[0].buildings"
    );

    let mut invalid_allocation = contract();
    invalid_allocation.cities[0]
        .production_queue
        .as_mut()
        .expect("queue")
        .resource_allocation =
        StrategicResourceStockpileDto(BTreeMap::from([(ResourceTypeDto::Iron, 1)]));
    assert_eq!(
        decode_game_state(invalid_allocation)
            .expect_err("invalid allocation")
            .path(),
        "$.cities[0].productionQueue.resourceAllocation"
    );

    let mut outside = contract();
    outside.cities[0].preferred_expansion_hex = Some(CoordinateDto { col: 5, row: 0 });
    assert_eq!(
        decode_game_state(outside)
            .expect_err("out-of-bounds preferred expansion")
            .path(),
        "$.cities[0].preferredExpansionHex"
    );
}

#[test]
fn infrastructure_rejects_invalid_coordinates_references_and_duplicates_with_paths() {
    let mut outside = contract();
    outside.field_improvements[0].coordinate.col = 5;
    assert_eq!(
        decode_game_state(outside)
            .expect_err("out-of-bounds improvement")
            .path(),
        "$.fieldImprovements[0].coordinate"
    );

    let mut missing_city = contract();
    missing_city.field_improvements[0].built_by_city_id = Some("city-missing".to_owned());
    assert_eq!(
        decode_game_state(missing_city)
            .expect_err("missing improvement city")
            .path(),
        "$.fieldImprovements[0].builtByCityId"
    );

    let mut duplicate = contract();
    duplicate
        .field_improvements
        .push(duplicate.field_improvements[0].clone());
    assert_eq!(
        decode_game_state(duplicate)
            .expect_err("duplicate improvement")
            .path(),
        "$.fieldImprovements"
    );

    let mut unknown_builder = contract();
    unknown_builder.transport_network[0].built_by_player_id = "player-3".to_owned();
    assert_eq!(
        decode_game_state(unknown_builder)
            .expect_err("unknown transport builder")
            .path(),
        "$.transportNetwork[0].builtByPlayerId"
    );

    let mut missing_transport_city = contract();
    missing_transport_city.transport_network[0].built_by_city_id = Some("city-missing".to_owned());
    assert_eq!(
        decode_game_state(missing_transport_city)
            .expect_err("missing transport city")
            .path(),
        "$.transportNetwork[0].builtByCityId"
    );
}

#[test]
fn research_and_wonders_reject_unknown_players_and_noncanonical_progress_with_paths() {
    let mut unknown = contract();
    let research = unknown
        .research
        .players
        .remove("player-1")
        .expect("research player");
    unknown
        .research
        .players
        .insert("player-3".to_owned(), research);
    assert_eq!(
        decode_game_state(unknown)
            .expect_err("unknown research player")
            .path(),
        "$.research.players.player-3"
    );

    let mut duplicate = contract();
    duplicate
        .research
        .players
        .get_mut("player-1")
        .expect("research player")
        .unlocked_technology_ids
        .push(TechnologyIdDto::Logistics);
    assert_eq!(
        decode_game_state(duplicate)
            .expect_err("duplicate unlocked technology")
            .path(),
        "$.research.players.player-1.unlockedTechnologyIds"
    );

    let mut active_unlocked = contract();
    active_unlocked
        .research
        .players
        .get_mut("player-1")
        .expect("research player")
        .active_technology_id = Some(TechnologyIdDto::Logistics);
    assert_eq!(
        decode_game_state(active_unlocked)
            .expect_err("active unlocked technology")
            .path(),
        "$.research.players.player-1.activeTechnologyId"
    );

    let mut zero_progress = contract();
    zero_progress
        .research
        .players
        .get_mut("player-1")
        .expect("research player")
        .progress_by_technology_id
        .insert(TechnologyIdDto::Agriculture, 0);
    assert_eq!(
        decode_game_state(zero_progress)
            .expect_err("zero research progress")
            .path(),
        "$.research.players.player-1.progressByTechnologyId"
    );

    let mut negative_overflow = contract();
    negative_overflow
        .research
        .players
        .get_mut("player-1")
        .expect("research player")
        .science_overflow = -1;
    assert_eq!(
        decode_game_state(negative_overflow)
            .expect_err("negative science overflow")
            .path(),
        "$.research.players.player-1.scienceOverflow"
    );

    let mut unknown_wonder_owner = contract();
    unknown_wonder_owner
        .wonder_registry
        .0
        .insert(WonderTypeDto::GreatWall, "player-3".to_owned());
    assert_eq!(
        decode_game_state(unknown_wonder_owner)
            .expect_err("unknown wonder owner")
            .path(),
        "$.wonderRegistry.greatWall"
    );
}

#[test]
fn intended_attacks_reject_invalid_references_with_paths() {
    let mut outside = contract();
    outside.intended_attacks[0].defender_col = 99;
    assert_eq!(
        decode_game_state(outside)
            .expect_err("outside attack target")
            .path(),
        "$.intendedAttacks[0].defenderCol"
    );

    let mut unknown_player = contract();
    unknown_player.intended_attacks[0].declaring_player_id = "player-3".to_owned();
    assert_eq!(
        decode_game_state(unknown_player)
            .expect_err("unknown declaring player")
            .path(),
        "$.intendedAttacks[0].declaringPlayerId"
    );

    let mut missing_attacker = contract();
    missing_attacker.intended_attacks[0].attacker_unit_id = "unit-404".to_owned();
    assert_eq!(
        decode_game_state(missing_attacker)
            .expect_err("missing attacker")
            .path(),
        "$.intendedAttacks[0].attackerUnitId"
    );

    let mut wrong_owner = contract();
    wrong_owner.intended_attacks[0].declaring_player_id = "player-2".to_owned();
    assert_eq!(
        decode_game_state(wrong_owner)
            .expect_err("wrong attacker owner")
            .path(),
        "$.intendedAttacks[0].declaringPlayerId"
    );

    let mut duplicate = contract();
    duplicate
        .intended_attacks
        .push(duplicate.intended_attacks[0].clone());
    assert_eq!(
        decode_game_state(duplicate)
            .expect_err("duplicate attacker declaration")
            .path(),
        "$.intendedAttacks"
    );
}
