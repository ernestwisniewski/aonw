//! Loads committed fixtures that use the current parity contract.

use std::path::{Path, PathBuf};

use aonw_testkit::FixtureLoader;

const CURRENT_FIXTURES: [&str; 3] = [
    "movement-adjacent-accepted.json",
    "movement-out-of-bounds-rejected.json",
    "movement-wrong-actor-rejected.json",
];

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| {
            path.join("engine/Cargo.toml").is_file()
                && path.join("test/fixtures/reducer_parity").is_dir()
        })
        .expect("repository root must contain engine and reducer fixtures")
        .to_path_buf()
}

#[test]
fn current_reducer_parity_fixtures_load_in_rust() {
    let fixture_dir = repository_root().join("test/fixtures/reducer_parity");
    let loader = FixtureLoader::default();

    for filename in CURRENT_FIXTURES {
        let fixture = loader
            .load_file(fixture_dir.join(filename))
            .expect("current reducer-parity fixture must load");
        assert_eq!(fixture.fixture_version(), 2);
        assert_eq!(fixture.family(), "movement");
    }
}
