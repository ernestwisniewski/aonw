use aonw_content::MapDocument;
use aonw_engine::ENGINE_BEHAVIOR_VERSION;
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;
use serde_json::json;

use crate::wire::{failure_json, success_json};

#[derive(GodotClass)]
#[class(tool, base=RefCounted)]
struct AonwEngineBridge {
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for AonwEngineBridge {
    fn init(base: Base<RefCounted>) -> Self {
        Self { base }
    }
}

#[godot_api]
#[allow(clippy::needless_pass_by_value, clippy::unused_self)]
impl AonwEngineBridge {
    #[func]
    fn behavior_version(&self) -> i64 {
        i64::from(ENGINE_BEHAVIOR_VERSION)
    }

    #[func]
    fn validate_map_json(&self, source: GString) -> GString {
        let source = source.to_string();
        let result = MapDocument::from_json(source.as_bytes());
        match result {
            Ok(document) => match document.map().content_hash() {
                Ok(content_hash) => success_json(&json!({
                    "mapId": document.map().map_id(),
                    "cols": document.map().cols(),
                    "rows": document.map().rows(),
                    "contentHash": content_hash.to_string(),
                    "document": render_document(&document),
                })),
                Err(error) => failure_json("map_hash_failed", error),
            },
            Err(error) => failure_json("invalid_map", error),
        }
    }
}

fn render_document(document: &MapDocument) -> serde_json::Value {
    let map = document.map();
    json!({
        "schemaVersion": aonw_content::CURRENT_MAP_SCHEMA_VERSION,
        "gridLayout": map.grid_layout().as_str(),
        "cols": map.cols(),
        "rows": map.rows(),
        "mapName": map.map_id(),
        "defaultZoom": document.default_zoom(),
        "objectives": map.objectives().iter().map(|objective| json!({
            "id": objective.id(),
            "type": objective.objective_type().as_str(),
            "hex": {
                "col": objective.coordinate().col(),
                "row": objective.coordinate().row(),
            },
            "requiredHoldTurns": objective.required_hold_turns(),
            "victoryPoints": objective.victory_points(),
            "goldPerTurn": objective.gold_per_turn(),
        })).collect::<Vec<_>>(),
        "tiles": map.tiles().iter().map(|tile| json!({
            "col": tile.coordinate().col(),
            "row": tile.coordinate().row(),
            "terrains": tile.terrains().iter().map(|terrain| terrain.as_str()).collect::<Vec<_>>(),
            "resources": tile.resources().iter().map(|resource| resource.as_str()).collect::<Vec<_>>(),
            "height": tile.height(),
        })).collect::<Vec<_>>(),
    })
}
