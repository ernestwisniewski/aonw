use aonw_content::MapDocument;
use aonw_engine::ENGINE_BEHAVIOR_VERSION;
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;
use serde_json::{Value, json};

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
            Ok(document) => validated_document_json(&document),
            Err(error) => failure_json("invalid_map", error),
        }
    }
}

fn validated_document_json(document: &MapDocument) -> GString {
    let content_hash = match document.map().content_hash() {
        Ok(content_hash) => content_hash,
        Err(error) => return failure_json("map_hash_failed", error),
    };
    let document_json = match document
        .to_versioned_json()
        .and_then(|source| serde_json::from_str::<Value>(&source))
    {
        Ok(value) => value,
        Err(error) => return failure_json("map_serialization_failed", error),
    };
    success_json(&json!({
        "mapId": document.map().map_id(),
        "cols": document.map().cols(),
        "rows": document.map().rows(),
        "contentHash": content_hash.to_string(),
        "document": document_json,
    }))
}
