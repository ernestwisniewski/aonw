//! Independent fixture infrastructure shared by Rust engine adapters.
//!
//! The canonical fixture path owns current strict DTOs and validated map
//! content without depending on a concrete engine implementation. The older
//! reducer fixture path remains isolated only while its reviewed behavior cases
//! are migrated. JSON object order is insignificant, array order remains
//! observable, input sizes are bounded, and expected outputs are never
//! generated or rewritten by the runner.

#![forbid(unsafe_code)]

mod canonical_fixture;
mod canonical_fixture_parser;
mod canonical_loader;
mod canonical_runner;
mod diff;
mod fixture;
mod fixture_parser;
mod loader;
mod loader_error;
mod movement_execution;
mod runner;
mod unique_json;

pub use canonical_fixture::{
    CURRENT_CANONICAL_FIXTURE_VERSION, CanonicalFixture, CanonicalFixtureInput,
    CanonicalFixtureOutput,
};
pub use canonical_loader::CanonicalFixtureLoader;
pub use canonical_runner::{
    CanonicalFixtureExecutor, verify_canonical_corpus, verify_canonical_fixture,
};
pub use diff::{DifferenceKind, JsonDifference, compare_json};
pub use fixture::{
    CURRENT_FIXTURE_VERSION, Fixture, FixtureInput, FixtureOutput, JsonObject,
    ReducerExpectedOutcome,
};
pub use loader::{FixtureLimits, FixtureLoader};
pub use loader_error::FixtureLoadError;
pub use movement_execution::{MovementExecution, MovementExecutionError, MovementStep};
pub use runner::{FixtureExecutor, FixtureRunError, verify_corpus, verify_fixture};
