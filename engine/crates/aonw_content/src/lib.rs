//! Versioned, validated logical content shared by every `AoNW` client.
//!
//! Map documents are normalized into deterministic, immutable storage before
//! they can enter the engine. Rendering assets and client-local presentation
//! metadata do not belong in this crate.

#![forbid(unsafe_code)]

mod codec;
mod error;
mod model;

pub use error::MapLoadError;
pub use model::{
    ContentHash, GridLayout, MapDefinition, MapObjective, MapObjectiveType, ResourceType,
    TerrainType, TileDefinition,
};

/// Map document version emitted by the canonical serializer.
pub const CURRENT_MAP_SCHEMA_VERSION: u64 = 1;
