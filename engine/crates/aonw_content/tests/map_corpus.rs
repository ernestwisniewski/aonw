//! Contract checks for canonical shared map content.

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
