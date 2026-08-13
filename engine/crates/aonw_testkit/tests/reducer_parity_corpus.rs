//! Compatibility check against the repository's committed reducer corpus.

use std::collections::BTreeSet;
use std::path::{Path, PathBuf};

use aonw_testkit::{Fixture, FixtureLoader};

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
fn current_reducer_parity_corpus_loads_in_rust() {
    let corpus = FixtureLoader::default()
        .load_corpus(repository_root().join("test/fixtures/reducer_parity"))
        .expect("committed reducer-parity corpus must load");

    assert_eq!(corpus.len(), 120);
    let families = corpus.iter().map(Fixture::family).collect::<BTreeSet<_>>();
    assert_eq!(
        families,
        BTreeSet::from([
            "artifacts",
            "auto-explore",
            "city-expansion",
            "city-founding",
            "city-production",
            "city-worked-hex",
            "combat",
            "detachment",
            "infrastructure",
            "merchant-routing",
            "movement",
            "research",
            "resource-trade",
            "turn-finalization",
            "unit-actions",
            "worker",
        ])
    );
}
