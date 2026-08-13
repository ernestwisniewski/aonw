//! Loads committed fixtures that use the current parity contract.

use std::path::{Path, PathBuf};

use aonw_testkit::FixtureLoader;

const CURRENT_FIXTURE_COUNT: usize = 44;

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| {
            path.join("engine/Cargo.toml").is_file()
                && path.join("test/fixtures/reducer_parity_v2").is_dir()
        })
        .expect("repository root must contain engine and reducer fixtures")
        .to_path_buf()
}

#[test]
fn current_reducer_parity_fixtures_load_in_rust() {
    let fixture_dir = repository_root().join("test/fixtures/reducer_parity_v2");
    let fixtures = FixtureLoader::default()
        .load_corpus(fixture_dir)
        .expect("current reducer-parity corpus must load");

    assert_eq!(fixtures.len(), CURRENT_FIXTURE_COUNT);
    assert!(
        fixtures
            .iter()
            .all(|fixture| fixture.fixture_version() == 2)
    );
    assert!(
        fixtures
            .iter()
            .all(|fixture| matches!(fixture.family(), "movement" | "unit-actions"))
    );
}
