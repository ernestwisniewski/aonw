use std::hint::black_box;
use std::time::Instant;

use serde_json::json;

use super::request::decode_open_request;

fn map_json() -> String {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrains": ["grassland"],
                    "resources": [],
                    "height": 0,
                })
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": 5,
        "rows": 5,
        "mapName": "session-test",
        "defaultZoom": 1.0,
        "objectives": [],
        "tiles": tiles,
    })
    .to_string()
}

fn scenario_json() -> String {
    json!({
        "schemaVersion": 1,
        "scenarioId": "session-test",
        "mapId": "session-test",
        "rulesetId": "aonw-standard",
        "initialUnits": [{
            "id": "unit-1",
            "ownerPlayerId": "player-1",
            "kind": "commander",
            "name": "Commander",
            "col": 0,
            "row": 0,
        }],
    })
    .to_string()
}

fn benchmark_documents() -> (String, String) {
    let tiles = (0..30)
        .flat_map(|row| {
            (0..40).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrains": ["grassland"],
                    "resources": [],
                    "height": 0,
                })
            })
        })
        .collect::<Vec<_>>();
    let units = (0..512)
        .map(|index| {
            json!({
                "id": format!("unit-{index}"),
                "ownerPlayerId": "player-1",
                "kind": "commander",
                "name": "Commander",
                "col": index % 40,
                "row": index / 40,
            })
        })
        .collect::<Vec<_>>();
    (
        json!({
            "schemaVersion": 1,
            "gridLayout": "oddQFlatTop",
            "cols": 40,
            "rows": 30,
            "mapName": "benchmark-session",
            "defaultZoom": 1.0,
            "objectives": [],
            "tiles": tiles,
        })
        .to_string(),
        json!({
            "schemaVersion": 1,
            "scenarioId": "benchmark-session",
            "mapId": "benchmark-session",
            "rulesetId": "aonw-standard",
            "initialUnits": units,
        })
        .to_string(),
    )
}

#[test]
fn adapter_open_contract_is_strict_and_current() {
    decode_open_request(&map_json(), &scenario_json(), "player-1")
        .expect("current contracts must open");
    let future = scenario_json().replace("\"schemaVersion\":1", "\"schemaVersion\":2");
    let error = decode_open_request(&map_json(), &future, "player-1")
        .expect_err("future contract must fail closed");
    assert_eq!(error.0, "invalid_scenario");
}

#[test]
#[ignore = "diagnostic wall-clock benchmark"]
fn native_session_open_benchmark() {
    const ITERATIONS: usize = 20;
    let (map, scenario) = benchmark_documents();
    for _ in 0..3 {
        black_box(decode_open_request(&map, &scenario, "player-1").expect("warm native session"));
    }
    let mut samples = Vec::with_capacity(ITERATIONS);
    for _ in 0..ITERATIONS {
        let started = Instant::now();
        black_box(
            decode_open_request(&map, &scenario, "player-1").expect("benchmark native session"),
        );
        samples.push(started.elapsed().as_nanos());
    }
    samples.sort_unstable();
    let median = samples[samples.len() / 2];
    let p95 = samples[(samples.len() * 95 / 100).min(samples.len() - 1)];
    println!("native_session_open,1200,512,{ITERATIONS},{median},{p95}");
}
