//! Current-only persistence corruption, rollover, and checkpoint-chain tests.

use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_contracts::{
    MAX_REPLAY_ENTRY_COUNT, MAX_REPLAY_SEGMENT_COUNT, MAX_SAVE_GAME_JSON_BYTES, ReplayLogDto,
    SaveGameDto,
};
use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};
use aonw_local_runtime::{
    LocalRuntime, MoveUnitRequest, OpenSession, PersistenceError, ReplayVerification,
};

#[test]
fn persistence_manifest_is_current_only_and_bounded() {
    let manifest: serde_json::Value =
        serde_json::from_str(include_str!("../../../fixtures/persistence/manifest.json"))
            .expect("persistence manifest");
    assert_eq!(manifest["capability"], "current-persistence-hardened");
    assert_eq!(manifest["compatibility"], "current-only");
    assert_eq!(manifest["legacyPaths"], false);
    assert_eq!(manifest["upcasters"], false);
    assert_eq!(manifest["internalVersionFields"], false);
    assert_eq!(manifest["limits"]["replayEntriesPerSegment"], 512);
    assert_eq!(manifest["limits"]["replaySegments"], 8);
    let cases = manifest["cases"].as_array().expect("case list");
    assert_eq!(cases.len(), 11);
    assert!(
        cases
            .windows(2)
            .all(|pair| pair[0].as_str() < pair[1].as_str())
    );
}

#[test]
fn corrupt_save_corpus_never_replaces_the_open_session() {
    let mut runtime = LocalRuntime::default();
    let expected = runtime.open(request()).expect("open");
    let save_json = runtime.export_save_json().expect("save");
    let mut hash_mismatch = SaveGameDto::from_json(&save_json).expect("save DTO");
    hash_mismatch.map_hash = "00".repeat(32);
    let inputs = [
        save_json[..save_json.len() - 1].to_owned(),
        save_json.replacen("\"state\":", "\"unknown\":true,\"state\":", 1),
        save_json.replacen("\"mapId\":", "\"mapId\":\"duplicate\",\"mapId\":", 1),
        hash_mismatch.to_json().expect("hash mismatch JSON"),
        "x".repeat(MAX_SAVE_GAME_JSON_BYTES + 1),
    ];

    for input in inputs {
        let (map, ruleset) = content();
        assert!(runtime.open_save_json(map, ruleset, &input).is_err());
        assert_eq!(runtime.snapshot().expect("preserved").stamp(), &expected);
    }
}

#[test]
fn replay_rollover_restores_each_checkpoint_and_reports_exact_drift() {
    let mut runtime = LocalRuntime::default();
    let expected = runtime.open(request()).expect("open");
    for _ in 0..=MAX_REPLAY_ENTRY_COUNT {
        let result = runtime
            .dispatch(&MoveUnitRequest {
                expected_revision: 1,
                unit_id: UnitId::new("unit-1").expect("unit id"),
                target: HexCoord::new(1, 0),
            })
            .expect("typed rejection");
        assert!(!result.is_accepted());
    }

    let replay_json = runtime.export_replay_json().expect("replay");
    let replay = ReplayLogDto::from_json(&replay_json).expect("strict replay");
    assert_eq!(replay.segments.len(), 2);
    assert_eq!(replay.segments[0].entries.len(), MAX_REPLAY_ENTRY_COUNT);
    assert_eq!(replay.segments[1].entries.len(), 1);
    assert_eq!(replay.segments[1].entries[0].index, 0);

    let (map, ruleset) = content();
    assert_eq!(
        LocalRuntime::verify_replay_json(map, ruleset, &replay_json).expect("verify archive"),
        ReplayVerification {
            entry_count: MAX_REPLAY_ENTRY_COUNT + 1,
            final_stamp: expected,
            final_event_offset: 0,
        }
    );

    let mut broken_chain = replay.clone();
    broken_chain.segments[1].initial_event_offset = 1;
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &broken_chain.to_json().expect("broken chain")
        ),
        Err(PersistenceError::ReplayCheckpointMismatch { segment: 1 })
    ));

    let mut broken_digest = replay;
    broken_digest.segments[1].initial_state_digest = "00".repeat(32);
    let (map, ruleset) = content();
    assert!(matches!(
        LocalRuntime::verify_replay_json(
            map,
            ruleset,
            &broken_digest.to_json().expect("broken digest")
        ),
        Err(PersistenceError::ReplayCheckpointDigestMismatch { segment: 1 })
    ));
}

#[test]
fn replay_archive_codec_enforces_segment_and_entry_bounds() {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    let mut replay = ReplayLogDto::from_json(&runtime.export_replay_json().expect("replay"))
        .expect("replay DTO");
    replay.segments = vec![replay.segments[0].clone(); MAX_REPLAY_SEGMENT_COUNT + 1];
    assert!(replay.to_json().is_err());

    replay.segments.truncate(1);
    let entry = rejected_entry();
    replay.segments[0].entries = vec![entry; MAX_REPLAY_ENTRY_COUNT + 1];
    assert!(replay.to_json().is_err());
}

fn rejected_entry() -> aonw_contracts::ReplayEntryDto {
    let mut runtime = LocalRuntime::default();
    runtime.open(request()).expect("open");
    runtime
        .dispatch(&MoveUnitRequest {
            expected_revision: 1,
            unit_id: UnitId::new("unit-1").expect("unit id"),
            target: HexCoord::new(1, 0),
        })
        .expect("typed rejection");
    ReplayLogDto::from_json(&runtime.export_replay_json().expect("replay"))
        .expect("replay DTO")
        .segments
        .remove(0)
        .entries
        .remove(0)
}

fn request() -> OpenSession {
    let (map, ruleset) = content();
    let scenario = ScenarioDefinition::try_new(
        "persistence-hardening",
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
    OpenSession::from_scenario(
        map,
        ruleset,
        &scenario,
        PlayerId::new("player-1").expect("player id"),
    )
    .expect("open request")
}

fn content() -> (MapDefinition, RulesetDefinition) {
    let tiles = (0..3)
        .flat_map(|row| {
            (0..3).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(col, row),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    let map = MapDefinition::try_new(
        "runtime-map",
        GridLayout::OddQFlatTop,
        3,
        3,
        tiles,
        Vec::new(),
    )
    .expect("map");
    (map, RulesetDefinition::standard().clone())
}
