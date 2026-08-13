//! Contract checks for canonical shared map content.

use std::fs;
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDocument, RulesetDefinition, ScenarioDefinition};

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/Cargo.toml").is_file() && path.join("content").is_dir())
        .expect("repository root must contain engine and content")
        .to_path_buf()
}

#[test]
fn starter_scenario_bootstraps_against_canonical_content() {
    let root = repository_root();
    let map_source = fs::read(root.join("content/maps/aonw2_starter/map.json"))
        .expect("starter map must be readable");
    let document = MapDocument::from_json(&map_source).expect("starter map must validate");
    let scenario_source = fs::read(root.join("content/scenarios/aonw2_starter/scenario.json"))
        .expect("starter scenario must be readable");
    let ruleset = RulesetDefinition::standard();
    let scenario = ScenarioDefinition::from_json(&scenario_source, document.map(), ruleset)
        .expect("starter scenario must validate");
    let state = scenario
        .bootstrap(document.map(), ruleset)
        .expect("starter scenario must bootstrap");

    assert_eq!(scenario.map_id(), document.map().map_id());
    assert_eq!(scenario.ruleset_id(), ruleset.ruleset_id());
    assert_eq!(state.units().len(), 1);
}

#[test]
fn every_shared_map_loads_and_round_trips_canonically() {
    for map_name in [
        "aonw2_starter",
        "dravonia",
        "myranth",
        "terenos",
        "verdantia",
    ] {
        let path = repository_root()
            .join("content/maps")
            .join(map_name)
            .join("map.json");
        let source = fs::read(path).expect("canonical map must be readable");
        let document = MapDocument::from_json(&source).expect("canonical map must validate");
        let map = document.map();
        let versioned = document.to_versioned_json().expect("map must serialize");

        assert_eq!(map.map_id(), map_name);
        assert_eq!(map.grid_layout(), GridLayout::OddQFlatTop);
        assert_eq!(
            map.tiles().len(),
            usize::from(map.cols()) * usize::from(map.rows())
        );
        assert_eq!(
            MapDocument::from_json(versioned.as_bytes())
                .expect("canonical map must reload")
                .map()
                .content_hash()
                .expect("reloaded map must hash"),
            map.content_hash().expect("canonical map must hash")
        );
    }
}
