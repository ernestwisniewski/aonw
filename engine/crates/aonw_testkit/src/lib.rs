//! Independent fixture infrastructure shared by Rust engine adapters.
//!
//! The crate loads the committed reducer-parity corpus without depending on a
//! concrete engine implementation. JSON object order is insignificant, array
//! order remains observable, input sizes are bounded, and expected outputs are
//! never generated or rewritten by the runner.

#![forbid(unsafe_code)]

mod diff;
mod fixture;
mod loader;
mod runner;

pub use diff::{DifferenceKind, JsonDifference, compare_json};
pub use fixture::{
    Fixture, FixtureInput, FixtureOutput, JsonObject, ReducerExpectedOutcome,
    SUPPORTED_FIXTURE_VERSION,
};
pub use loader::{FixtureLimits, FixtureLoadError, FixtureLoader};
pub use runner::{FixtureExecutor, FixtureRunError, verify_corpus, verify_fixture};
