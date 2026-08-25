//! Current-only production protocol, runtime, save, and replay coverage.

use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandOutcomeDto, ClientOutcomeDto,
    ClientQueryDto, ClientQueryResultDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};
use aonw_contracts::{
    CityBuildingTypeDto, CityProjectTypeDto, CitySpecializationTypeDto, UnitKindDto, WonderTypeDto,
};
use aonw_domain::{
    City, CityBuildingType, CityId, GameMode, GameState, HexCoord, KnowledgeState, MatchIdentity,
    MatchLifecycle, MatchRules, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerResearchState, PlayerTurnState, ResearchState, StateRevision, TechnologyId,
    TurnLifecycle, WonderRegistry,
};
use aonw_local_runtime::{ClientProtocol, LocalRuntime, OpenSession};

#[test]
fn production_protocol_query_commands_save_and_replay_are_current_and_exact() {
    let query = dispatch_client(
        &mut opened_runtime(),
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ProductionOptions {
                expected_revision: 9,
                city_id: "capital".to_owned(),
            },
        },
    );
    let ClientResponseBodyDto::Query {
        result:
            ClientQueryResultDto::ProductionOptions {
                buildings,
                units,
                projects,
                wonders,
                specializations,
                ..
            },
    } = query
    else {
        panic!("production options response")
    };
    assert_eq!(
        (
            buildings.len(),
            units.len(),
            projects.len(),
            wonders.len(),
            specializations.len()
        ),
        (59, 17, 2, 11, 5)
    );

    for command in production_commands() {
        let response = dispatch_client(
            &mut opened_runtime(),
            ClientRequestBodyDto::Dispatch { command },
        );
        let ClientResponseBodyDto::Command { result } = response else {
            panic!("production command response")
        };
        assert_eq!(result.outcome, ClientCommandOutcomeDto::Accepted);
    }

    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(
            map.clone(),
            rules.clone(),
            state,
            actor,
        ))
        .expect("open replay runtime");
    let response = dispatch_client(
        &mut runtime,
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::StartCityProject {
                expected_revision: 9,
                city_id: "capital".to_owned(),
                project: CityProjectTypeDto::Research,
            },
        },
    );
    assert!(matches!(response, ClientResponseBodyDto::Command { .. }));
    let save = runtime.export_save_json().expect("production save");
    let replay = runtime.export_replay_json().expect("production replay");
    let verification =
        LocalRuntime::verify_replay_json(map.clone(), rules.clone(), &replay).expect("replay");
    assert_eq!(verification.entry_count, 1);
    let mut reopened = LocalRuntime::default();
    reopened
        .open_save_json(map, rules, &save)
        .expect("production save reopen");
    assert_eq!(
        reopened.snapshot().expect("reopened snapshot").stamp(),
        runtime.snapshot().expect("source snapshot").stamp()
    );
}

fn production_commands() -> [ClientCommandDto; 5] {
    [
        ClientCommandDto::StartBuilding {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            building: CityBuildingTypeDto::Workshop,
        },
        ClientCommandDto::StartUnitProduction {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            unit: UnitKindDto::Warrior,
            resource_option_index: None,
        },
        ClientCommandDto::StartCityProject {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            project: CityProjectTypeDto::Research,
        },
        ClientCommandDto::StartWonder {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            wonder: WonderTypeDto::GreatLibrary,
        },
        ClientCommandDto::SetCitySpecialization {
            expected_revision: 9,
            city_id: "capital".to_owned(),
            specialization: CitySpecializationTypeDto::Growth,
        },
    ]
}

fn dispatch_client(
    runtime: &mut LocalRuntime,
    request: ClientRequestBodyDto,
) -> ClientResponseBodyDto {
    let document = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request,
    }
    .to_json()
    .expect("client request JSON");
    let response = ClientResponseDto::from_json(&ClientProtocol::dispatch_json(runtime, &document))
        .expect("client response JSON");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("client protocol failure: {:?}", response.outcome)
    };
    *response
}

fn opened_runtime() -> LocalRuntime {
    let (map, rules, state, actor) = fixture();
    let mut runtime = LocalRuntime::default();
    runtime
        .open(OpenSession::from_state(map, rules, state, actor))
        .expect("open production runtime");
    runtime
}

fn fixture() -> (MapDefinition, RulesetDefinition, GameState, PlayerId) {
    let map = map();
    let rules = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("player");
    let participant = Participant::try_new(
        actor.clone(),
        "Player",
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant");
    let identity = MatchIdentity::try_new(MatchRules::default(), [participant], GameMode::HotSeat)
        .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([(actor.clone(), PlayerTurnState::Active)]),
        [actor.clone()],
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("lifecycle");
    let city = City::builder(
        CityId::new("capital").expect("city id"),
        actor.clone(),
        "Capital",
        HexCoord::new(2, 2),
    )
    .with_buildings([CityBuildingType::Granary])
    .build()
    .expect("city");
    let research = ResearchState::try_new([(
        actor.clone(),
        PlayerResearchState::try_new(
            [
                TechnologyId::Craftsmanship,
                TechnologyId::Writing,
                TechnologyId::Specialization,
            ],
            None,
            [],
            0,
        )
        .expect("research"),
    )])
    .expect("research state");
    let state = GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        rules.occupancy_policy(),
        [],
    )
    .with_cities([city])
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_knowledge(KnowledgeState::new(research, WonderRegistry::default()))
    .try_build()
    .expect("state");
    (map, rules, state, actor)
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "production-runtime",
        GridLayout::OddQFlatTop,
        5,
        5,
        (0..5)
            .flat_map(|row| {
                (0..5).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}
