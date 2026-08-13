//! Canonical, framework-independent game-domain types.
//!
//! The crate owns invariants and deterministic state representation. It has no
//! serialization, persistence, networking, UI, framework, or ambient-time
//! dependencies.

#![forbid(unsafe_code)]

mod hex_coord;
mod identifier;
mod state;

pub use hex_coord::HexCoord;
pub use identifier::{IdentifierError, PlayerId, UnitId};
pub use state::{StateBuildError, Unit, WorldState};
