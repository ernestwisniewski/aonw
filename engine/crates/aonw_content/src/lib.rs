//! Versioned, validated logical content shared by every `AoNW` client.
//!
//! Map documents are normalized into deterministic, immutable storage before
//! they can enter the engine. Rendering assets and client-local presentation
//! metadata do not belong in this crate.

#![forbid(unsafe_code)]

mod canonical;
mod catalog;
mod codec;
mod content_hash;
mod document;
mod error;
mod model;
mod raw;
mod validation;

pub use catalog::{GridLayout, MapObjectiveType, ResourceType, TerrainType};
pub use content_hash::ContentHash;
pub use document::MapDocument;
pub use error::MapLoadError;
pub use model::{MapDefinition, MapObjective, TileDefinition};
pub use validation::MapValidationError;

/// Map document version emitted by the canonical serializer.
pub const CURRENT_MAP_SCHEMA_VERSION: u64 = 1;
