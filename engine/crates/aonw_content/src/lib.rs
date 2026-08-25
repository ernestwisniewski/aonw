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
mod ruleset;
mod scenario;
mod technology;
mod validation;

pub use catalog::{GridLayout, MapObjectiveType, ResourceType, TerrainType};
pub use content_hash::ContentHash;
pub use document::{MIN_AUTHORED_MAP_COLS, MIN_AUTHORED_MAP_ROWS, MapDocument};
pub use error::MapLoadError;
pub use model::{
    MAX_MAP_COLS, MAX_MAP_ROWS, MIN_MAP_COLS, MIN_MAP_ROWS, MapDefinition, MapObjective,
    TerrainProfile, TileDefinition,
};
pub use ruleset::{
    CityBalance, CityNameSet, RulesetDefinition, UnitCapabilities, UnitDefinition,
    UnitMovementDomainValue, WorkerBalance, WorkerImprovementDefinition, WorkerYield,
};
pub use scenario::{
    ScenarioBootstrapError, ScenarioDefinition, ScenarioLoadError, ScenarioUnitDefinition,
    ScenarioValidationError,
};
pub use technology::{
    TechnologyBoost, TechnologyBoostCondition, TechnologyBuilding, TechnologyCostBalance,
    TechnologyDefinition, TechnologyEffect, TechnologyEra, TechnologyImprovement, TechnologyKey,
    TechnologyResource, TechnologyUnit, TechnologyUnlock, TechnologyWonder,
};
pub use validation::{MapValidationError, validate_map_id};

/// Map document version emitted by the canonical serializer.
pub const CURRENT_MAP_SCHEMA_VERSION: u64 = 1;
