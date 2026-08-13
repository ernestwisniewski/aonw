//! Local runtime lifecycle and movement contract tests.

use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_contracts::{ReplayLogDto, SaveGameDto};
use aonw_domain::{
    GameState, HexCoord, HexGridBounds, PlayerId, StateRevision, UnitId, UnitKind,
    UnitOccupancyPolicy,
};
use aonw_local_runtime::{
    LOCAL_SESSION_CONTRACT_VERSION, LocalRuntime, MoveUnitV1, OpenSessionError, OpenSessionV1,
    PersistenceError, QueryRequestV1, QueryResultV1, ReachableRequestV1, ReplayVerificationV1,
    RngStateV1, RoutePlanRequestV1, RuntimeError,
};

fn map(id: &str, cols: u16, rows: u16) -> MapDefinition {
    let tiles = (0..rows)
        .flat_map(|row| {
            (0..cols).map(move |col| {
                TileDefinition::try_new(
                    HexCoord::new(i32::from(col), i32::from(row)),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(id, GridLayout::OddQFlatTop, cols, rows, tiles, Vec::new()).expect("map")
}

fn request() -> OpenSessionV1 {
    let (map, ruleset) = content();
    let scenario = ScenarioDefinition::try_new(
        "runtime-scenario",
        &map,
        &ruleset,
        [ScenarioUnitDefinition::new(
            UnitId::new("unit-1").expect("unit id"),
            PlayerId::new("player-1").expect("player id"),
            UnitKind::Commander,
            "Commander",
            HexCoord::new(0, 0),
        )],
    )
    .expect("scenario");
    OpenSessionV1::from_scenario(
        map,
        ruleset,
        &scenario,
        PlayerId::new("player-1").expect("player id"),
    )
    .expect("open request")
}

fn content() -> (MapDefinition, RulesetDefinition) {
    (
        map("runtime-map", 3, 3),
        RulesetDefinition::standard().clone(),
    )
}

#[test]
fn local_session_supports_snapshot_queries_and_dispatch() {
    let mut runtime = LocalRuntime::default();
    let opened = runtime.open(request()).expect("open");
    assert_eq!(opened.contract_version, LOCAL_SESSION_CONTRACT_VERSION);
    assert_eq!(opened.revision, StateRevision::INITIAL);

    let snapshot = runtime.snapshot().expect("snapshot");
    assert_eq!(snapshot.units().len(), 1);
    assert_eq!(snapshot.units()[0].id().as_str(), "unit-1");

    let reachable = runtime
        .query(&QueryRequestV1::Reachable(ReachableRequestV1 {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
        }))
        .expect("reachable");
    let QueryResultV1::Reachable(reachable) = reachable else {
        panic!("reachable response")
    };
    assert!(!reachable.tiles.is_empty());

    let route = runtime
        .query(&QueryRequestV1::RoutePlan(RoutePlanRequestV1 {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        }))
        .expect("route");
    let QueryResultV1::RoutePlan(route) = route else {
        panic!("route response")
    };
    assert_eq!(route.destination, HexCoord::new(1, 0));

    let moved = runtime
        .dispatch(&MoveUnitV1 {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("dispatch");
    assert!(moved.is_accepted());
    assert_eq!(moved.stamp.revision, StateRevision::new(1));
    assert_eq!(moved.events.len(), 1);
    assert!(moved.evidence.is_some());
    assert_eq!(moved.view_patch.from_revision, 0);
    assert_eq!(moved.view_patch.to_revision, 1);
    assert_eq!(moved.view_patch.upserted_units[0].col(), 1);
}

#[test]
fn failed_reopen_preserves_session_and_close_is_idempotent() {
    let mut runtime = LocalRuntime::default();
    let original = runtime.open(request()).expect("open");
    let invalid_state = GameState::try_new(
        StateRevision::INITIAL,
        0,
        HexGridBounds::new(2, 2).expect("bounds"),
        UnitOccupancyPolicy::FriendlyStacking,
        [],
    )
    .expect("state");
    let invalid = OpenSessionV1::from_state(
        map("other-map", 3, 3),
        RulesetDefinition::standard().clone(),
        invalid_state,
        PlayerId::new("player-1").expect("player id"),
    );
    assert_eq!(
        runtime.open(invalid),
        Err(OpenSessionError::MapBoundsMismatch)
    );
    assert_eq!(runtime.snapshot().expect("preserved").stamp(), &original);

    runtime.close();
    runtime.close();
    assert_eq!(runtime.snapshot(), Err(RuntimeError::SessionNotOpen));
}

#[test]
fn repeated_and_batch_queries_use_revision_scoped_cache() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    let reachable = QueryRequestV1::Reachable(ReachableRequestV1 {
        expected_revision: 0,
        unit_id: UnitId::new("unit-1").expect("unit id"),
    });
    let route = QueryRequestV1::RoutePlan(RoutePlanRequestV1 {
        expected_revision: 0,
        unit_id: UnitId::new("unit-1").expect("unit id"),
        target: HexCoord::new(1, 0),
    });

    runtime.query(&reachable).expect("cold reachable");
    runtime.query(&reachable).expect("cached reachable");
    let stale = QueryRequestV1::Reachable(ReachableRequestV1 {
        expected_revision: 99,
        unit_id: UnitId::new("unit-1").expect("unit id"),
    });
    assert!(runtime.query(&stale).is_err());
    let results = runtime.query_batch(&[route.clone(), route]);
    assert!(results.iter().all(Result::is_ok));
    assert_eq!(runtime.query_cache_stats().hits, 2);
    assert_eq!(runtime.query_cache_stats().misses, 3);

    runtime
        .dispatch(&MoveUnitV1 {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("move");
    assert!(runtime.query_cache_stats().hits >= 2);
}

#[test]
fn save_round_trip_preserves_complete_state_and_runtime_checkpoint() {
    let mut runtime = LocalRuntime::default();
    runtime
        .open(request().with_runtime_state(RngStateV1::new(41, 7, 3), 11))
        .expect("open");
    runtime
        .dispatch(&MoveUnitV1 {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("move");
    let expected = *runtime.snapshot().expect("snapshot").stamp();
    let save_json = runtime.export_save_json().expect("save");
    let save = SaveGameDto::from_json(&save_json).expect("strict save");
    assert_eq!(save.state.units.len(), 1);
    assert_eq!(save.rng_state.seed, 41);
    assert_eq!(save.rng_state.stream, 7);
    assert_eq!(save.rng_state.counter, 3);
    assert_eq!(save.event_offset, 12);

    let (map, ruleset) = content();
    let mut restored = LocalRuntime::default();
    let actual = restored
        .open_save_json(map, ruleset, &save_json)
        .expect("restore");
    assert_eq!(actual, expected);
    assert_eq!(restored.export_save_json().expect("resave"), save_json);
}

#[test]
fn save_load_is_transactional_and_rejects_identity_or_digest_tampering() {
    let mut runtime = LocalRuntime::default();
    let original = runtime.open(request()).expect("open");
    let save_json = runtime.export_save_json().expect("save");

    let mut wrong_map = SaveGameDto::from_json(&save_json).expect("save dto");
    wrong_map.map_hash = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        runtime.open_save_json(map, ruleset, &wrong_map.to_json().expect("json")),
        Err(PersistenceError::MapHashMismatch)
    ));
    assert_eq!(runtime.snapshot().expect("preserved").stamp(), &original);

    let mut wrong_digest = SaveGameDto::from_json(&save_json).expect("save dto");
    wrong_digest.state_digest = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        runtime.open_save_json(map, ruleset, &wrong_digest.to_json().expect("json")),
        Err(PersistenceError::StateDigestMismatch)
    ));

    let mut wrong_behavior = SaveGameDto::from_json(&save_json).expect("save dto");
    wrong_behavior.behavior_version += 1;
    let (map, ruleset) = content();
    assert!(matches!(
        runtime.open_save_json(map, ruleset, &wrong_behavior.to_json().expect("json")),
        Err(PersistenceError::BehaviorVersionMismatch { .. })
    ));
}

#[test]
fn replay_verifies_accepted_and_rejected_commands_and_detects_drift() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    runtime
        .dispatch(&MoveUnitV1 {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("accepted move");
    let rejected = runtime
        .dispatch(&MoveUnitV1 {
            expected_revision: 0,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(2, 0),
        })
        .expect("domain rejection");
    assert!(!rejected.is_accepted());
    let expected_stamp = *runtime.snapshot().expect("snapshot").stamp();
    let replay_json = runtime.export_replay_json().expect("replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("strict replay");
    assert_eq!(replay.entries.len(), 2);
    assert!(replay.entries[0].result.accepted);
    assert!(!replay.entries[1].result.accepted);

    let (map, ruleset) = content();
    assert_eq!(
        LocalRuntime::verify_replay_json(map, ruleset, &replay_json).expect("verify"),
        ReplayVerificationV1 {
            entry_count: 2,
            final_stamp: expected_stamp,
            final_event_offset: 1,
        }
    );

    let mut tampered = replay;
    tampered.entries[0].result.state_digest = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &tampered.to_json().expect("tampered replay")
        ),
        Err(PersistenceError::ReplayResultMismatch { entry: 0 })
    ));
}
