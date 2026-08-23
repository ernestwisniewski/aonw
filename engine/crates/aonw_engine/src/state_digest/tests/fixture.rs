use std::collections::BTreeMap;

use aonw_contracts::{
    AiDifficultyDto, AiPersonaDto, AiPlayerDto, AiStrategyIdDto, ArmyTroopDto, CityDto,
    CityFoundingDraftDto, CityFoundingJobDto, CoordinateDto, FieldImprovementKindDto, GameModeDto,
    GameStateDto, InteractionStateDto, MatchIdentityDto, MatchRulesDto, MerchantTradeRouteDto,
    MovementStepDto, ParticipantDto, PendingInteractionDto, PlayerCountryDto, PlayerFogDto,
    PlayerKindDto, PlayerPairDto, PlayerTurnStateDto, QueuedMovePathDto, RuleValueDto,
    TransportConditionDto, TransportSegmentDto, TroopKindDto, TurnLifecycleDto, UnitActivityDto,
    UnitDto, UnitKindDto, UnitOccupancyPolicyDto, UnitPostureDto, WorkerJobDto, WorldArtifactDto,
    WorldArtifactLocationDto, WorldArtifactTypeDto,
};

pub(super) fn complete_state_contract() -> GameStateDto {
    GameStateDto {
        revision: 9,
        turn: 3,
        match_identity: complete_match_identity(),
        turn_lifecycle: complete_turn_lifecycle(),
        cols: 5,
        rows: 5,
        occupancy_policy: UnitOccupancyPolicyDto::FriendlyStacking,
        units: vec![complete_unit()],
        cities: vec![
            CityDto {
                id: "city-1".to_owned(),
                owner_player_id: "player-1".to_owned(),
                center: coordinate(0, 0),
                controlled_hexes: vec![coordinate(0, 1)],
            },
            CityDto {
                id: "city-2".to_owned(),
                owner_player_id: "player-1".to_owned(),
                center: coordinate(4, 4),
                controlled_hexes: vec![coordinate(4, 3)],
            },
        ],
        artifacts: vec![
            WorldArtifactDto {
                id: "artifact-1".to_owned(),
                artifact_type: WorldArtifactTypeDto::AstronomersTablets,
                location: WorldArtifactLocationDto::Excavation {
                    unit_id: "unit-1".to_owned(),
                    coordinate: coordinate(1, 1),
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
        interaction: InteractionStateDto {
            city_founding_draft: Some(CityFoundingDraftDto {
                unit_id: "unit-1".to_owned(),
                owner_player_id: "player-1".to_owned(),
                center: coordinate(2, 2),
                controlled_hexes: vec![coordinate(2, 3)],
            }),
            pending: Some(PendingInteractionDto::WorkerActionSelection {
                owner_player_id: "player-1".to_owned(),
                unit_id: "unit-1".to_owned(),
                improvement: Some(FieldImprovementKindDto::Mine),
            }),
        },
        fog_of_war: vec![PlayerFogDto {
            player_id: "player-1".to_owned(),
            discovered_hexes: vec![coordinate(0, 0), coordinate(1, 1)],
            visible_hexes: vec![coordinate(1, 1)],
        }],
        diplomatic_contacts: vec![PlayerPairDto {
            first_player_id: "player-1".to_owned(),
            second_player_id: "player-2".to_owned(),
        }],
        transport_network: vec![TransportSegmentDto {
            coordinate: coordinate(1, 1),
            condition: TransportConditionDto::Operational,
            built_by_player_id: "player-1".to_owned(),
            built_by_city_id: Some("city-1".to_owned()),
        }],
    }
}

fn complete_match_identity() -> MatchIdentityDto {
    let mut rules = MatchRulesDto::default();
    rules.balance.insert(
        "economy".to_owned(),
        RuleValueDto::Object(BTreeMap::from([(
            "growth".to_owned(),
            RuleValueDto::Number(serde_json::Number::from(2)),
        )])),
    );
    MatchIdentityDto {
        match_rules: rules,
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
                    seed: 41,
                }),
            },
        ],
        game_mode: GameModeDto::Multiplayer,
    }
}

fn complete_turn_lifecycle() -> TurnLifecycleDto {
    TurnLifecycleDto {
        turn_states_by_player_id: BTreeMap::from([
            ("player-1".to_owned(), PlayerTurnStateDto::Active),
            ("player-2".to_owned(), PlayerTurnStateDto::Finished),
        ]),
        submitted_player_ids: vec!["player-2".to_owned()],
        timeout_streaks_by_player_id: BTreeMap::from([("player-2".to_owned(), 2)]),
        afk_player_ids: vec!["player-2".to_owned()],
        kicked_player_ids: Vec::new(),
        turn_started_at: Some("2026-08-23T12:34:56.123456Z".to_owned()),
    }
}

fn complete_unit() -> UnitDto {
    UnitDto {
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
            steps: vec![movement_step(1, 1, 0, 0), movement_step(2, 1, 2, 2)],
        }),
        merchant_trade_route: Some(MerchantTradeRouteDto {
            origin_city_id: "city-1".to_owned(),
            destination_city_id: "city-2".to_owned(),
            steps: vec![movement_step(1, 1, 0, 0), movement_step(2, 1, 2, 2)],
            transport_network_fingerprint: "network-1".to_owned(),
        }),
        activity: UnitActivityDto {
            worker_job: Some(WorkerJobDto::FieldImprovement {
                target: coordinate(1, 1),
                improvement: FieldImprovementKindDto::Farm,
                remaining_turns: 1,
                total_turns: 3,
            }),
            city_founding_job: Some(CityFoundingJobDto {
                center: coordinate(2, 2),
                controlled_hexes: vec![coordinate(2, 3)],
                remaining_turns: 2,
                total_turns: 4,
            }),
            worker_assignment: Some(coordinate(1, 1)),
            excavating_artifact_id: Some("artifact-1".to_owned()),
        },
        worker_build_charges: 4,
        hit_points: Some(7),
        experience_points: 11,
        posture: UnitPostureDto::AutoWorking,
        carried_artifact_id: Some("artifact-2".to_owned()),
    }
}

pub(super) const fn coordinate(col: i32, row: i32) -> CoordinateDto {
    CoordinateDto { col, row }
}

fn movement_step(
    col: i32,
    row: i32,
    enter_cost_units: u32,
    cumulative_cost_units: u32,
) -> MovementStepDto {
    MovementStepDto {
        col,
        row,
        enter_cost_units,
        cumulative_cost_units,
    }
}
