use aonw_content::{MapDefinition, MapDocument};
use aonw_engine::ENGINE_BEHAVIOR_VERSION;
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;
use serde_json::json;

use crate::wire::{failure_json, success_json};

#[derive(GodotClass)]
#[class(base=RefCounted)]
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
    fn validate_map_json(&self, source: GString, legacy: bool) -> GString {
        let source = source.to_string();
        let result = if legacy {
            MapDefinition::from_legacy_json(source.as_bytes())
        } else {
            MapDocument::from_json(source.as_bytes()).map(|document| document.map().clone())
        };
        match result {
            Ok(map) => match map.content_hash() {
                Ok(content_hash) => success_json(&json!({
                    "mapId": map.map_id(),
                    "cols": map.cols(),
                    "rows": map.rows(),
                    "contentHash": content_hash.to_string(),
                })),
                Err(error) => failure_json("map_hash_failed", error),
            },
            Err(error) => failure_json("invalid_map", error),
        }
    }
}
