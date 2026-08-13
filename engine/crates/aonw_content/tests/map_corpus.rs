//! Compatibility checks for shared and legacy map content.

use std::fs;
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDocument};

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/Cargo.toml").is_file() && path.join("content").is_dir())
        .expect("repository root must contain engine and content")
        .to_path_buf()
}

fn legacy_map_path(map_id: &str) -> PathBuf {
    let root = repository_root();
    [
        root.join("assets/maps"),
        root.join("clients/aonw_flutter/assets/maps"),
    ]
    .into_iter()
    .map(|directory| directory.join(map_id).join("map.json"))
    .find(|path| path.is_file())
    .expect("legacy Flutter map must exist in the active or target client location")
}

#[test]
fn shared_starter_map_loads_and_round_trips_canonically() {
    let path = repository_root().join("content/maps/aonw2_starter/map.json");
    let source = fs::read(path).expect("starter map must be readable");
    let document = MapDocument::from_json(&source).expect("starter map must validate");
    let map = document.map();
    let versioned = document.to_versioned_json().expect("map must serialize");

    assert_eq!(map.map_id(), "aonw2_starter");
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
        map.content_hash().expect("starter map must hash")
    );
}

#[test]
fn current_flutter_maps_load_through_the_legacy_adapter() {
    for map_name in ["dravonia", "myranth", "terenos", "verdantia"] {
        let path = legacy_map_path(map_name);
        let source = fs::read(path).expect("legacy map must be readable");
        let document = MapDocument::from_legacy_json(&source).expect("legacy map must validate");
        let map = document.map();

        assert_eq!(map.map_id(), map_name);
        assert!(!map.tiles().is_empty());
    }
}
