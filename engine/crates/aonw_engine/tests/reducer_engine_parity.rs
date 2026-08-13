//! Executes the current Dart command oracle through the canonical Rust engine.

use std::collections::BTreeSet;

use aonw_testkit::{FixtureLoader, verify_corpus};

#[path = "support/reducer_fixture_adapter.rs"]
mod reducer_fixture_adapter;

use reducer_fixture_adapter::{RustEngineFixtureExecutor, repository_root};

const REVIEWED_FIXTURE_COUNT: usize = 44;

#[test]
fn rust_executes_complete_current_command_oracle() {
    let fixture_dir = repository_root().join("test/fixtures/reducer_parity_v2");
    let fixtures = FixtureLoader::default()
        .load_corpus(&fixture_dir)
        .expect("current reducer-parity corpus must load");

    assert_eq!(fixtures.len(), REVIEWED_FIXTURE_COUNT);
    assert!(
        fixtures
            .iter()
            .all(|fixture| fixture.fixture_version() == 2)
    );
    assert_eq!(
        fixtures
            .iter()
            .map(aonw_testkit::Fixture::id)
            .collect::<BTreeSet<_>>()
            .len(),
        REVIEWED_FIXTURE_COUNT
    );
    verify_corpus(&fixtures, &RustEngineFixtureExecutor)
        .unwrap_or_else(|failure| panic!("{failure:?}"));
}
