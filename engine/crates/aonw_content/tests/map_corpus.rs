//! Compatibility checks for shared and legacy map content.

use std::fs;
use std::path::Path;

use aonw_content::{GridLayout, MapDefinition};

fn repository_root() -> &'static Path {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .and_then(Path::parent)
        .and_then(Path::parent)
        .expect("content crate must remain under engine/crates")
}

#[test]
fn shared_starter_map_loads_and_round_trips_canonically() {
    let path = repository_root().join("content/maps/aonw2_starter/map.json");
    let source = fs::read(path).expect("starter map must be readable");
    let map = MapDefinition::from_json(&source).expect("starter map must validate");
    let canonical = map.to_canonical_json().expect("map must serialize");

    assert_eq!(map.map_name(), "aonw2_starter");
    assert_eq!(map.grid_layout(), GridLayout::OddQFlatTop);
    assert_eq!(
        map.tiles().len(),
        usize::from(map.cols()) * usize::from(map.rows())
    );
    assert_eq!(
        MapDefinition::from_json(canonical.as_bytes())
            .expect("canonical map must reload")
            .content_hash()
            .expect("reloaded map must hash"),
        map.content_hash().expect("starter map must hash")
    );
}

#[test]
fn current_flutter_maps_load_through_the_legacy_adapter() {
    for map_name in ["dravonia", "myranth", "terenos", "verdantia"] {
        let path = repository_root().join(format!("assets/maps/{map_name}/map.json"));
        let source = fs::read(path).expect("legacy map must be readable");
        let map = MapDefinition::from_legacy_json(&source).expect("legacy map must validate");

        assert_eq!(map.map_name(), map_name);
        assert!(!map.tiles().is_empty());
    }
}
