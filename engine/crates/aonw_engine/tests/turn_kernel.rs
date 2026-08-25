//! Capability, transition ordering, and rejection tests for the T1 turn kernel.

#[path = "turn_kernel/disabled_requirements.rs"]
mod disabled_requirements;

use std::collections::{BTreeMap, BTreeSet};
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, CityId, CityProductionQueue, CityProductionTarget, CityProjectType, GameMode, GameState,
    HexCoord, MatchIdentity, MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry,
    PlayerId, PlayerKind, PlayerTurnState, StateRevision, StrategicResourceStockpile,
    TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy, UnitPosture, UtcTimestamp,
};
use aonw_engine::{
    CommandRejectionCode, DomainEvent, EngineContext, ExecutionEvidence,
    FinalizeTimedOutTurnCommand, GameEngine, KickParticipantCommand, PlayerCommand, SystemCommand,
    SystemContext, TurnCommand, TurnKernelCapabilities, TurnProcessor,
};

#[test]
fn submit_records_readiness_then_finalizes_in_canonical_order() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let initial = state(GameMode::Multiplayer, [], None);

    let partial = GameEngine::apply_player_owned(
        initial,
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &p1)),
    )
    .expect("partial submit");
    assert!(partial.is_accepted());
    assert_eq!(partial.revision(), StateRevision::new(8));
    assert!(partial.events().is_empty());
    assert_eq!(
        partial
            .state()
            .match_lifecycle()
            .turn()
            .submitted_player_ids(),
        &BTreeSet::from([p1.clone()])
    );

    let final_submit = GameEngine::apply_player_owned(
        partial.state().clone(),
        EngineContext::canonical(&p2, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(8, &p2)),
    )
    .expect("final submit");
    assert!(final_submit.is_accepted());
    assert_eq!(final_submit.state().turn(), 8);
    assert_eq!(final_submit.revision(), StateRevision::new(9));
    assert!(matches!(
        final_submit.events(),
        [
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(
        final_submit.state().units()[0].movement_units(),
        MovementUnits::new(10)
    );
    assert_eq!(
        final_submit.state().units()[1].movement_units(),
        MovementUnits::new(10)
    );
    assert!(final_submit.state().interaction().pending().is_none());
    assert_turn_evidence(&final_submit, 2);
}

#[test]
fn player_rejection_precedence_and_sequential_handoff_are_stable() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let initial = state(GameMode::HotSeat, [], None);

    let wrong_actor = GameEngine::apply_player_owned(
        initial.clone(),
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p2)),
    )
    .expect("wrong actor");
    assert_eq!(
        wrong_actor.rejection().expect("rejection").code(),
        CommandRejectionCode::TurnPlayerNotControlled
    );
    let stale = GameEngine::apply_player_owned(
        initial.clone(),
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::EndTurn(TurnCommand::new(6, &p2)),
    )
    .expect("stale");
    assert_eq!(
        stale.rejection().expect("rejection").code(),
        CommandRejectionCode::StaleRevision
    );

    let accepted = GameEngine::apply_player_owned(
        initial,
        EngineContext::canonical(&p1, &map, rules),
        PlayerCommand::EndTurn(TurnCommand::new(7, &p1)),
    )
    .expect("end turn");
    assert!(accepted.is_accepted());
    assert_eq!(accepted.state().turn(), 7);
    assert!(matches!(accepted.events(), [DomainEvent::TurnEnded(_)]));
    assert_eq!(
        accepted.state().units()[0].movement_units(),
        MovementUnits::ZERO
    );
    assert_eq!(
        accepted.state().units()[1].movement_units(),
        MovementUnits::new(10)
    );
    assert_turn_evidence(&accepted, 1);
}

#[test]
fn trusted_timeout_and_kick_have_no_player_context() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let submitted = state(GameMode::Multiplayer, [p1.clone()], None);
    let time = UtcTimestamp::new("2026-08-24T12:00:00Z").expect("UTC");
    let timeout = GameEngine::apply_system_owned(
        submitted,
        SystemContext::canonical(&map, rules),
        SystemCommand::FinalizeTimedOutTurn(FinalizeTimedOutTurnCommand::new(
            7,
            &[p1.clone(), p2.clone()],
            std::slice::from_ref(&p2),
            Some(&time),
        )),
    )
    .expect("timeout");
    assert!(timeout.is_accepted());
    assert!(matches!(
        timeout.events(),
        [
            DomainEvent::PlayerTimedOut(_),
            DomainEvent::AllPlayersSubmitted(_),
            DomainEvent::TurnEnded(_),
            DomainEvent::TurnEnded(_)
        ]
    ));
    assert_eq!(
        timeout
            .state()
            .match_lifecycle()
            .turn()
            .timeout_streaks_by_player_id()
            .get(&p2),
        Some(&1)
    );

    let invalid = GameEngine::apply_system_owned(
        timeout.state().clone(),
        SystemContext::canonical(&map, rules),
        SystemCommand::FinalizeTimedOutTurn(FinalizeTimedOutTurnCommand::new(
            8,
            &[p1.clone(), p1.clone()],
            &[],
            None,
        )),
    )
    .expect("invalid scope");
    assert_eq!(
        invalid.rejection().expect("rejection").code(),
        CommandRejectionCode::TurnScopeInvalid
    );

    let kicked = GameEngine::apply_system_owned(
        timeout.state().clone(),
        SystemContext::canonical(&map, rules),
        SystemCommand::KickParticipant(KickParticipantCommand::new(8, &p2, "turn_timeout", 3)),
    )
    .expect("kick");
    assert!(kicked.is_accepted());
    let [DomainEvent::PlayerKicked(kicked_event)] = kicked.events() else {
        panic!("player kicked event")
    };
    assert_eq!(kicked_event.turn(), 8);
    assert_eq!(kicked_event.player_id(), &p2);
    assert_eq!(kicked_event.reason(), "turn_timeout");
    assert_eq!(kicked_event.timeout_streak(), 3);
    let _ = (kicked.map_hash(), kicked.ruleset_hash());
    let lifecycle = kicked.state().match_lifecycle().turn();
    assert!(lifecycle.kicked_player_ids().contains(&p2));
    assert!(lifecycle.afk_player_ids().contains(&p2));
    assert!(!lifecycle.required_submission_player_ids().contains(&p2));
}

#[test]
fn fixture_manifest_rejects_unimplemented_processors() {
    let root = repository_root();
    let manifest: serde_json::Value = serde_json::from_slice(
        &std::fs::read(root.join("engine/fixtures/turn_kernel/manifest.json")).expect("manifest"),
    )
    .expect("strict JSON");
    assert_eq!(manifest["capability"], TurnKernelCapabilities::LABEL);
    let enabled = manifest["enabledProcessors"]
        .as_array()
        .expect("enabled processors")
        .iter()
        .map(|value| value.as_str().expect("processor"))
        .collect::<Vec<_>>();
    assert_eq!(
        enabled,
        TurnKernelCapabilities::ENABLED.map(TurnProcessor::as_str)
    );
    for fixture in manifest["fixtures"].as_array().expect("fixtures") {
        for required in fixture["requiredProcessors"]
            .as_array()
            .expect("requirements")
        {
            assert!(enabled.contains(&required.as_str().expect("processor")));
        }
    }

    let unsupported: serde_json::Value = serde_json::from_slice(
        &std::fs::read(
            root.join("engine/fixtures/turn_kernel/unsupported-production-manifest.json"),
        )
        .expect("negative manifest"),
    )
    .expect("strict JSON");
    let missing = unsupported["requiredProcessors"]
        .as_array()
        .expect("requirements")
        .iter()
        .filter_map(serde_json::Value::as_str)
        .find(|required| !enabled.contains(required));
    assert_eq!(missing, Some(TurnProcessor::Economy.as_str()));

    let state_requirements: serde_json::Value = serde_json::from_slice(
        &std::fs::read(
            root.join("engine/fixtures/turn_kernel/unsupported-state-processors-manifest.json"),
        )
        .expect("state requirement manifest"),
    )
    .expect("strict JSON");
    let required = state_requirements["fixtures"]
        .as_array()
        .expect("fixtures")
        .iter()
        .map(|fixture| {
            fixture["requiredProcessor"]
                .as_str()
                .expect("required processor")
        })
        .collect::<Vec<_>>();
    assert_eq!(
        required,
        TurnKernelCapabilities::DISABLED.map(TurnProcessor::as_str)
    );
}

#[test]
fn finalization_fails_closed_when_state_requires_disabled_processor() {
    let map = map();
    let rules = RulesetDefinition::standard();
    let p1 = player("player-1");
    let p2 = player("player-2");
    let initial = state_with_posture(GameMode::Multiplayer, [p1], None, None, true);
    let before = GameEngine::state_digest(&initial);

    let transition = GameEngine::apply_player_owned(
        initial,
        EngineContext::canonical(&p2, &map, rules),
        PlayerCommand::SubmitTurn(TurnCommand::new(7, &p2)),
    )
    .expect("disabled processor rejection");

    assert_eq!(
        transition.rejection().expect("rejection").code(),
        CommandRejectionCode::TurnProcessorUnsupported
    );
    assert_eq!(GameEngine::state_digest(transition.state()), before);
}

fn state(
    mode: GameMode,
    submitted: impl IntoIterator<Item = PlayerId>,
    started: Option<UtcTimestamp>,
) -> GameState {
    state_with_posture(mode, submitted, started, None, false)
}

fn state_with_posture(
    mode: GameMode,
    submitted: impl IntoIterator<Item = PlayerId>,
    started: Option<UtcTimestamp>,
    second_unit_posture: Option<UnitPosture>,
    with_production: bool,
) -> GameState {
    let p1 = player("player-1");
    let p2 = player("player-2");
    let participants = [
        participant(p1.clone(), "One"),
        participant(p2.clone(), "Two"),
    ];
    let identity =
        MatchIdentity::try_new(MatchRules::default(), participants, mode).expect("identity");
    let submitted = submitted.into_iter().collect::<BTreeSet<_>>();
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        BTreeMap::from([
            (
                p1.clone(),
                if submitted.contains(&p1) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
            (
                p2.clone(),
                if submitted.contains(&p2) {
                    PlayerTurnState::Finished
                } else {
                    PlayerTurnState::Active
                },
            ),
        ]),
        [p1.clone(), p2.clone()],
        submitted,
        BTreeMap::new(),
        [],
        [],
        started,
    )
    .expect("turn lifecycle");
    let mut second_unit = Unit::builder(
        UnitId::new("unit-2").expect("unit id"),
        p2.clone(),
        UnitKind::Commander,
        "unit-2",
        HexCoord::new(1, 0),
        MovementUnits::ZERO,
    );
    if let Some(posture) = second_unit_posture {
        second_unit = second_unit.with_posture(posture);
    }
    let units = [unit("unit-1", &p1), second_unit.build().expect("unit")];
    let interaction = if second_unit_posture.is_none() {
        aonw_domain::InteractionState::default().after_skip(&units[1])
    } else {
        aonw_domain::InteractionState::default()
    };
    let cities = with_production.then(|| {
        City::builder(
            CityId::new("city-2").expect("city id"),
            p2.clone(),
            "Queued city",
            HexCoord::new(1, 0),
        )
        .with_production(
            Some(
                CityProductionQueue::try_new(
                    CityProductionTarget::Project(CityProjectType::Wealth),
                    0,
                    StrategicResourceStockpile::default(),
                )
                .expect("production queue"),
            ),
            0,
        )
        .build()
        .expect("city")
    });
    GameState::builder(
        StateRevision::new(7),
        7,
        map().bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .with_cities(cities)
    .with_interaction(interaction)
    .try_build()
    .expect("state")
}

fn participant(id: PlayerId, name: &str) -> Participant {
    Participant::try_new(
        id,
        name,
        0xff00_0000,
        PlayerCountry::Poland,
        PlayerKind::Human,
        None,
    )
    .expect("participant")
}

fn unit(id: &str, owner: &PlayerId) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        owner.clone(),
        UnitKind::Commander,
        id,
        HexCoord::new(i32::from(id != "unit-1"), 0),
        MovementUnits::ZERO,
    )
    .build()
    .expect("unit")
}

fn map() -> MapDefinition {
    MapDefinition::try_new(
        "turn-kernel",
        GridLayout::OddQFlatTop,
        2,
        1,
        (0..2)
            .map(|col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, 0),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

fn assert_turn_evidence(transition: &aonw_engine::DomainTransition, reset_count: usize) {
    let Some(ExecutionEvidence::TurnKernel(evidence)) = transition.evidence() else {
        panic!("expected turn kernel evidence")
    };
    assert_eq!(evidence.reset_unit_ids().len(), reset_count);
    assert!(
        evidence
            .processors()
            .iter()
            .all(|processor| TurnKernelCapabilities::supports(*processor))
    );
}

fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player id")
}

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/fixtures/turn_kernel").is_dir())
        .expect("repository root")
        .to_path_buf()
}
