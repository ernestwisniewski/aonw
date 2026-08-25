//! Current-only artifact command and turn-processing acceptance tests.

use aonw_content::RulesetDefinition;
use aonw_domain::{HexCoord, MovementUnits, StateRevision, WorldArtifactLocation};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, EngineContext, GameEngine, PlayerCommand,
    StartArtifactExcavationCommand, StoreArtifactInCityCommand, TradeArtifactCommand, TurnCommand,
};

#[path = "artifact/support.rs"]
mod support;

use support::*;

#[test]
fn excavation_start_is_atomic_and_emits_the_current_typed_event() {
    let map = map();
    let p1 = player("player-1");
    let unit_id = unit_id("scout");
    let artifact_id = artifact_id("sword");
    let state = game_state(
        vec![unit("scout", &p1, HexCoord::new(0, 0))],
        Vec::new(),
        vec![artifact(
            "sword",
            WorldArtifactLocation::Map(HexCoord::new(0, 0)),
        )],
        None,
        false,
    );

    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(9, &unit_id)),
    )
    .expect("start excavation");

    assert!(transition.is_accepted());
    assert_eq!(transition.revision(), StateRevision::new(10));
    let excavator = transition.state().unit(&unit_id).expect("excavator");
    assert_eq!(excavator.movement_units(), MovementUnits::ZERO);
    assert_eq!(
        excavator.activity().excavating_artifact_id(),
        Some(&artifact_id)
    );
    assert!(matches!(
        transition
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        WorldArtifactLocation::Excavation {
            unit_id: owner,
            coordinate,
            remaining_turns: 2,
        } if owner == &unit_id && *coordinate == HexCoord::new(0, 0)
    ));
    let [DomainEvent::ArtifactExcavationStarted(event)] = transition.events() else {
        panic!("typed excavation event")
    };
    assert_eq!(event.artifact_id(), &artifact_id);
    assert_eq!(event.owner_player_id(), &p1);
    assert_eq!(event.unit_id(), &unit_id);
}

#[test]
fn excavation_rejection_precedence_is_revision_control_then_artifact_state() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let foreign_unit = unit_id("foreign");
    let foreign_state = game_state(
        vec![unit("foreign", &p2, HexCoord::new(0, 0))],
        Vec::new(),
        Vec::new(),
        None,
        false,
    );
    let apply = |revision| {
        GameEngine::apply_player_owned(
            foreign_state.clone(),
            EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
            PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(
                revision,
                &foreign_unit,
            )),
        )
        .expect("normal rejection")
    };
    assert_eq!(
        apply(8).rejection().expect("stale").code(),
        CommandRejectionCode::StaleRevision
    );
    assert_eq!(
        apply(9).rejection().expect("control").code(),
        CommandRejectionCode::UnitNotControlled
    );

    let unit = carried_unit("carrier", &p1, HexCoord::new(1, 0), artifact_id("carried"));
    let carrying_state = game_state(
        vec![unit],
        Vec::new(),
        vec![
            artifact(
                "carried",
                WorldArtifactLocation::Carried(unit_id("carrier")),
            ),
            artifact(
                "map-artifact",
                WorldArtifactLocation::Map(HexCoord::new(1, 0)),
            ),
        ],
        None,
        false,
    );
    let carrying = GameEngine::apply_player_owned(
        carrying_state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StartArtifactExcavation(StartArtifactExcavationCommand::new(
            9,
            &unit_id("carrier"),
        )),
    )
    .expect("carrying rejection");
    assert_eq!(
        carrying.rejection().expect("rejection").code(),
        CommandRejectionCode::UnitAlreadyCarryingArtifact
    );
}

#[test]
fn carried_artifact_stores_only_in_one_owned_city_slot() {
    let map = map();
    let p1 = player("player-1");
    let carrier_id = unit_id("carrier");
    let artifact_key = artifact_id("seal");
    let city_key = city_id("capital");
    let state = game_state(
        vec![carried_unit(
            "carrier",
            &p1,
            HexCoord::new(1, 0),
            artifact_key.clone(),
        )],
        vec![city("capital", &p1, HexCoord::new(1, 0))],
        vec![artifact(
            "seal",
            WorldArtifactLocation::Carried(carrier_id.clone()),
        )],
        None,
        false,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StoreArtifactInCity(StoreArtifactInCityCommand::new(
            9,
            &carrier_id,
            Some(&city_key),
        )),
    )
    .expect("store artifact");

    assert!(transition.is_accepted());
    assert!(
        transition
            .state()
            .unit(&carrier_id)
            .expect("carrier")
            .carried_artifact_id()
            .is_none()
    );
    assert_eq!(
        transition
            .state()
            .artifact(&artifact_key)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Stored(city_key.clone())
    );
    let [DomainEvent::ArtifactStored(event)] = transition.events() else {
        panic!("typed storage event")
    };
    assert_eq!(event.source_unit_id(), Some(&carrier_id));
    assert_eq!(event.city_id(), &city_key);

    let occupied = game_state(
        vec![carried_unit(
            "carrier",
            &p1,
            HexCoord::new(1, 0),
            artifact_id("seal"),
        )],
        vec![city("capital", &p1, HexCoord::new(1, 0))],
        vec![
            artifact("seal", WorldArtifactLocation::Carried(unit_id("carrier"))),
            artifact("crown", WorldArtifactLocation::Stored(city_id("capital"))),
        ],
        None,
        false,
    );
    let rejected = GameEngine::apply_player_owned(
        occupied,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::StoreArtifactInCity(StoreArtifactInCityCommand::new(9, &carrier_id, None)),
    )
    .expect("full slot rejection");
    assert_eq!(
        rejected.rejection().expect("rejection").code(),
        CommandRejectionCode::CityArtifactSlotFull
    );
}

#[test]
fn trade_uses_authenticated_actor_canonical_target_city_and_atomic_gold_transfer() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let artifact_id = artifact_id("seal");
    let state = game_state(
        Vec::new(),
        vec![
            city("source", &p1, HexCoord::new(0, 0)),
            city("target-b", &p2, HexCoord::new(2, 0)),
            city("target-a", &p2, HexCoord::new(1, 0)),
        ],
        vec![artifact(
            "seal",
            WorldArtifactLocation::Stored(city_id("source")),
        )],
        Some((17, 23)),
        false,
    );
    let transition = GameEngine::apply_player_owned(
        state,
        EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
        PlayerCommand::TradeArtifact(TradeArtifactCommand::new(9, &p2, &artifact_id, 5)),
    )
    .expect("trade artifact");

    assert!(transition.is_accepted());
    assert_eq!(
        transition
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Stored(city_id("target-a"))
    );
    assert_eq!(
        transition.state().economy().player_gold().get(&p1),
        Some(&12)
    );
    assert_eq!(
        transition.state().economy().player_gold().get(&p2),
        Some(&28)
    );
    let [DomainEvent::ArtifactStored(event)] = transition.events() else {
        panic!("typed trade storage event")
    };
    assert_eq!(event.owner_player_id(), &p2);
    assert_eq!(event.source_unit_id(), None);
    assert_eq!(event.city_id(), &city_id("target-a"));
}

#[test]
fn trade_rejects_war_and_unavailable_gold_without_mutation() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let artifact_id = artifact_id("seal");
    let build = |war| {
        game_state(
            Vec::new(),
            vec![
                city("source", &p1, HexCoord::new(0, 0)),
                city("target", &p2, HexCoord::new(1, 0)),
            ],
            vec![artifact(
                "seal",
                WorldArtifactLocation::Stored(city_id("source")),
            )],
            Some((3, 0)),
            war,
        )
    };
    let apply = |state, gold| {
        GameEngine::apply_player_owned(
            state,
            EngineContext::canonical(&p1, &map, RulesetDefinition::standard()),
            PlayerCommand::TradeArtifact(TradeArtifactCommand::new(9, &p2, &artifact_id, gold)),
        )
        .expect("normal trade rejection")
    };

    let war = apply(build(true), 0);
    assert_eq!(
        war.rejection().expect("war rejection").code(),
        CommandRejectionCode::ArtifactTradeBlockedByWar
    );
    let unavailable = apply(build(false), 4);
    assert_eq!(
        unavailable.rejection().expect("gold rejection").code(),
        CommandRejectionCode::ArtifactTradeGoldUnavailable
    );
    assert_eq!(
        unavailable
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Stored(city_id("source"))
    );
}

#[test]
fn artifact_turn_phase_decrements_then_completes_in_owner_scope() {
    let map = map();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let artifact_id = artifact_id("sword");
    let excavator_id = unit_id("excavator");
    let excavator = excavating_unit("excavator", &p1, HexCoord::new(0, 0), artifact_id.clone());
    let excavation = |remaining_turns| {
        artifact(
            "sword",
            WorldArtifactLocation::Excavation {
                unit_id: excavator_id.clone(),
                coordinate: HexCoord::new(0, 0),
                remaining_turns,
            },
        )
    };

    let partial = GameEngine::apply_player_owned(
        state_with_active(
            vec![excavator.clone()],
            Vec::new(),
            vec![excavation(2)],
            None,
            false,
            &p2,
        ),
        EngineContext::canonical(&p2, &map, RulesetDefinition::standard()),
        PlayerCommand::EndTurn(TurnCommand::new(9, &p2)),
    )
    .expect("partial excavation turn");
    assert!(matches!(partial.events(), [DomainEvent::TurnEnded(_)]));
    assert!(matches!(
        partial
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        WorldArtifactLocation::Excavation {
            remaining_turns: 1,
            ..
        }
    ));

    let completed = GameEngine::apply_player_owned(
        state_with_active(
            vec![excavator],
            Vec::new(),
            vec![excavation(1)],
            None,
            false,
            &p2,
        ),
        EngineContext::canonical(&p2, &map, RulesetDefinition::standard()),
        PlayerCommand::EndTurn(TurnCommand::new(9, &p2)),
    )
    .expect("completed excavation turn");
    assert!(matches!(
        completed.events(),
        [DomainEvent::ArtifactCarried(_), DomainEvent::TurnEnded(_)]
    ));
    assert_eq!(
        completed
            .state()
            .unit(&excavator_id)
            .expect("carrier")
            .carried_artifact_id(),
        Some(&artifact_id)
    );
    assert_eq!(
        completed
            .state()
            .artifact(&artifact_id)
            .expect("artifact")
            .location(),
        &WorldArtifactLocation::Carried(excavator_id)
    );
}
