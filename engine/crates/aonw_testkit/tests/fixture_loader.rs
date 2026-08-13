//! Validation tests for the engine-neutral fixture loader.

use std::fs;

use aonw_testkit::{FixtureLimits, FixtureLoadError, FixtureLoader};
use serde_json::{Value, json};

fn fixture_json() -> Value {
    json!({
        "fixtureVersion": 1,
        "id": "movement-accepted",
        "family": "movement",
        "input": {
            "now": "2026-01-02T03:04:05.000Z",
            "actorPlayerId": "player_1",
            "tick": 3,
            "rulesetId": "standard",
            "map": {}, "match": {}, "save": {}, "state": {}, "command": {}
        },
        "expected": {
            "accepted": true,
            "reason": null,
            "save": {}, "state": {}, "events": []
        }
    })
}

fn encoded(value: &Value) -> Vec<u8> {
    serde_json::to_vec(value).expect("fixture JSON must encode")
}

#[test]
fn parser_retains_typed_metadata_and_opaque_payloads() {
    let fixture = FixtureLoader::default()
        .parse(&encoded(&fixture_json()))
        .expect("valid fixture");

    assert_eq!(fixture.id(), "movement-accepted");
    assert_eq!(fixture.family(), "movement");
    assert_eq!(fixture.input().tick(), 3);
    assert_eq!(fixture.input().actor_player_id(), "player_1");
    assert!(fixture.expected().accepted());
}

#[test]
fn unsupported_fixture_versions_fail_closed() {
    let mut value = fixture_json();
    value["fixtureVersion"] = json!(2);

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::UnsupportedVersion {
            found: 2,
            supported: 1,
            ..
        })
    ));
}

#[test]
fn structural_contract_rejects_unknown_root_fields() {
    let mut value = fixture_json();
    value["generatedBy"] = json!("rust");

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$"
    ));
}

#[test]
fn accepted_and_reason_must_be_coherent() {
    let mut value = fixture_json();
    value["expected"]["reason"] = json!("command_rejected");

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. })
            if field.as_ref() == "$.expected.reason"
    ));
}

#[test]
fn fixture_size_is_checked_before_json_parsing() {
    let source = encoded(&fixture_json());
    let loader = FixtureLoader::new(FixtureLimits {
        max_fixture_bytes: source.len() - 1,
        ..FixtureLimits::default()
    });

    assert!(matches!(
        loader.parse(&source),
        Err(FixtureLoadError::FixtureTooLarge { .. })
    ));
}

#[test]
fn file_loading_stops_at_the_configured_byte_limit() {
    let path = std::env::temp_dir().join(format!(
        "aonw-testkit-bounded-read-{}.json",
        std::process::id()
    ));
    fs::write(&path, [0_u8; 9]).expect("temporary fixture must be writable");
    let result = FixtureLoader::new(FixtureLimits {
        max_fixture_bytes: 8,
        ..FixtureLimits::default()
    })
    .load_file(&path);
    fs::remove_file(path).expect("temporary fixture must be removable");

    assert!(matches!(
        result,
        Err(FixtureLoadError::FixtureTooLarge {
            actual: 9,
            limit: 8,
            ..
        })
    ));
}

#[test]
fn duplicate_json_keys_are_rejected() {
    let source = br#"{
      "fixtureVersion": 1, "fixtureVersion": 1,
      "id": "movement-accepted", "family": "movement",
      "input": {}, "expected": {}
    }"#;

    assert!(matches!(
        FixtureLoader::default().parse(source),
        Err(FixtureLoadError::Json { .. })
    ));
}

#[test]
fn invalid_utc_timestamp_is_rejected() {
    for timestamp in [
        "not-a-dateZ",
        "2026-02-29T03:04:05.000Z",
        "2026-13-02T03:04:05.000Z",
        "2026-01-02T24:04:05.000Z",
    ] {
        let mut value = fixture_json();
        value["input"]["now"] = json!(timestamp);

        assert!(matches!(
            FixtureLoader::default().parse(&encoded(&value)),
            Err(FixtureLoadError::Invalid { ref field, .. })
                if field.as_ref() == "$.input.now"
        ));
    }
}
