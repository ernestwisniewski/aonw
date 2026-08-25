use std::collections::BTreeSet;
use std::fs;

use aonw_contract_mapping::canonicalize_game_state;
use aonw_testkit::{CanonicalFixtureLoader, verify_canonical_fixture};

use super::encoding::command_name;
use super::{CanonicalRustEngineExecutor, repository_root};

#[derive(Debug)]
struct ReviewedExecutionDisposition {
    id: Box<str>,
    command: Box<str>,
    accepted: bool,
    rejection: Option<Box<str>>,
    canonical_artifact: Box<str>,
}

#[test]
fn reviewed_reducer_dispositions_gate_execution_by_capability() {
    let root = repository_root();
    let manifest = fs::read_to_string(root.join("engine/migration/reducer_fixture_dispositions"))
        .expect("reviewed disposition manifest");
    let dispositions = manifest
        .lines()
        .filter_map(reviewed_execution_disposition)
        .collect::<Vec<_>>();

    assert_eq!(dispositions.len(), 9);
    assert_eq!(
        dispositions
            .iter()
            .map(|entry| entry.command.as_ref())
            .collect::<BTreeSet<_>>(),
        BTreeSet::from([
            "CancelUnitAction",
            "FortifyUnit",
            "MoveUnit",
            "SkipUnitTurn"
        ])
    );

    for disposition in dispositions {
        let fixture = CanonicalFixtureLoader::default()
            .load_file(root.join(disposition.canonical_artifact.as_ref()))
            .expect("strict current canonical fixture");
        assert_eq!(fixture.id(), disposition.id.as_ref());
        assert_eq!(
            command_name(fixture.input().command()),
            disposition.command.as_ref()
        );
        assert_eq!(fixture.expected().accepted(), disposition.accepted);
        assert_eq!(
            fixture.expected().rejection(),
            disposition.rejection.as_deref()
        );
        assert_eq!(
            canonicalize_game_state(fixture.input().state().clone())
                .expect("canonical input round-trip"),
            *fixture.input().state()
        );
        assert_eq!(
            canonicalize_game_state(fixture.expected().state().clone())
                .expect("canonical output round-trip"),
            *fixture.expected().state()
        );
        verify_canonical_fixture(&fixture, &CanonicalRustEngineExecutor)
            .unwrap_or_else(|failure| panic!("{failure:?}"));
    }
}

fn reviewed_execution_disposition(line: &str) -> Option<ReviewedExecutionDisposition> {
    let line = line.split('#').next().unwrap_or_default().trim();
    if !line.starts_with("case ") {
        return None;
    }
    let fields = line.split_whitespace().collect::<Vec<_>>();
    assert_eq!(fields.len(), 11, "malformed reviewed disposition: {line}");
    if fields[7] != "engine-parity" {
        return None;
    }
    assert_eq!(fields[6], "round-trip");
    assert_eq!(fields[8], "current");
    assert_eq!(fields[9], "-");
    let accepted = match fields[4] {
        "accepted" => true,
        "rejected" => false,
        value => panic!("unknown oracle outcome: {value}"),
    };
    let rejection = (fields[5] != "-").then(|| fields[5].into());
    Some(ReviewedExecutionDisposition {
        id: fields[1].into(),
        command: fields[3].into(),
        accepted,
        rejection,
        canonical_artifact: fields[10].into(),
    })
}
