//! Validation tests for the engine-neutral fixture loader.

use std::fs;

use aonw_testkit::{FixtureLimits, FixtureLoadError, FixtureLoader};
use serde_json::{Value, json};

fn fixture_json() -> Value {
    json!({
        "fixtureVersion": 2,
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
            "save": {}, "state": {}, "events": [], "movementExecutions": []
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
    assert_eq!(fixture.fixture_version(), 2);
    assert_eq!(fixture.input().tick(), 3);
    assert_eq!(fixture.input().actor_player_id(), "player_1");
    assert!(fixture.expected().accepted());
}

#[test]
fn unsupported_fixture_versions_fail_closed() {
    let mut value = fixture_json();
    value["fixtureVersion"] = json!(3);

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::UnsupportedVersion {
            found: 3,
            supported: 2,
            ..
        })
    ));
}

#[test]
fn version_one_is_migrated_without_inventing_execution_evidence() {
    let mut value = fixture_json();
    value["fixtureVersion"] = json!(1);
    value["expected"]
        .as_object_mut()
        .expect("object")
        .remove("movementExecutions");

    let fixture = FixtureLoader::default()
        .parse(&encoded(&value))
        .expect("legacy fixture must remain readable");

    assert_eq!(fixture.fixture_version(), 1);
    assert_eq!(fixture.expected().movement_executions(), None);
}

#[test]
fn version_two_requires_explicit_movement_evidence() {
    let mut value = fixture_json();
    value["expected"]
        .as_object_mut()
        .expect("object")
        .remove("movementExecutions");

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$.expected"
    ));
}

#[test]
fn movement_execution_is_parsed_as_a_validated_value() {
    let mut value = fixture_json();
    value["expected"]["movementExecutions"] = json!([{
        "unitId": "unit_1",
        "fromCol": 0,
        "fromRow": 1,
        "steps": [
            {"col": 1, "row": 1, "enterCost": 50, "cumulativeCost": 50},
            {"col": 2, "row": 1, "enterCost": 25, "cumulativeCost": 75}
        ]
    }]);

    let fixture = FixtureLoader::default()
        .parse(&encoded(&value))
        .expect("valid execution");
    let execution = &fixture
        .expected()
        .movement_executions()
        .expect("version two evidence")[0];

    assert_eq!(execution.unit_id(), "unit_1");
    assert_eq!(execution.from_row(), 1);
    assert_eq!(execution.steps()[1].cumulative_cost(), 75);
}

#[test]
fn malformed_movement_execution_fails_closed() {
    let mut value = fixture_json();
    value["expected"]["movementExecutions"] = json!([{
        "unitId": "unit_1",
        "fromCol": 0,
        "fromRow": 0,
        "steps": [{"col": 1, "row": 0, "enterCost": 50, "cumulativeCost": 49}]
    }]);

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. })
            if field.as_ref()
                == "$.expected.movementExecutions[0].steps[0].cumulativeCost"
    ));
}

#[test]
fn movement_execution_rejects_unknown_fields() {
    let mut value = fixture_json();
    value["expected"]["movementExecutions"] = json!([{
        "unitId": "unit_1",
        "fromCol": 0,
        "fromRow": 0,
        "steps": [{"col": 1, "row": 0, "enterCost": 1, "cumulativeCost": 1}],
        "path": []
    }]);

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. })
            if field.as_ref() == "$.expected.movementExecutions[0]"
    ));
}

#[test]
fn movement_execution_rejects_empty_steps() {
    let mut value = fixture_json();
    value["expected"]["movementExecutions"] = json!([{
        "unitId": "unit_1",
        "fromCol": 0,
        "fromRow": 0,
        "steps": []
    }]);

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. })
            if field.as_ref() == "$.expected.movementExecutions[0].steps"
    ));
}

#[test]
fn legacy_version_rejects_v2_execution_field() {
    let mut value = fixture_json();
    value["fixtureVersion"] = json!(1);

    assert!(matches!(
        FixtureLoader::default().parse(&encoded(&value)),
        Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$.expected"
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
