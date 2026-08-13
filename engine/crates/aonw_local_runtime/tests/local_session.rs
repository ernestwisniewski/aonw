//! Local runtime lifecycle and movement contract tests.

use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_domain::{
    GameState, HexCoord, HexGridBounds, PlayerId, StateRevision, UnitId, UnitKind,
    UnitOccupancyPolicy,
};
use aonw_local_runtime::{
    LOCAL_SESSION_CONTRACT_VERSION, LocalRuntime, MoveUnitV1, OpenSessionError, OpenSessionV1,
    QueryRequestV1, QueryResultV1, ReachableRequestV1, RoutePlanRequestV1, RuntimeError,
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
    let map = map("runtime-map", 3, 3);
    let ruleset = RulesetDefinition::standard().clone();
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
