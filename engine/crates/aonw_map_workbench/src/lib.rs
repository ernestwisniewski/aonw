//! Logical map authoring and deterministic generation for the Godot workbench.
//!
//! The crate owns framework-neutral authoring use cases. It produces exact
//! canonical documents but performs no filesystem or Godot operations.

#![forbid(unsafe_code)]

mod error;
mod generation;
mod protocol;
mod spec;

pub use error::MapWorkbenchError;
pub use generation::GeneratedMapPackage;
pub use protocol::{MAP_WORKBENCH_API_VERSION, MapWorkbenchProtocol};
pub use spec::{
    BLANK_GENERATOR_ID, BLANK_GENERATOR_VERSION, CURRENT_MAP_GENERATION_SCHEMA_VERSION,
    GenerationSpecHash, MapGenerationSpec,
};
