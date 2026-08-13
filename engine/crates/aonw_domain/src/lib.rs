//! Canonical, framework-independent game-domain types.
//!
//! The crate owns invariants and deterministic state representation. It has no
//! serialization, persistence, networking, UI, framework, or ambient-time
//! dependencies.

#![forbid(unsafe_code)]

mod hex_coord;
mod hex_grid;
mod identifier;
mod movement_path;
mod movement_units;
mod state;
mod unit_kind;
mod unit_posture;

pub use hex_coord::HexCoord;
pub use hex_grid::{HexGridBounds, HexTileIndex};
pub use identifier::{ArtifactId, IdentifierError, PlayerId, UnitId};
pub use movement_path::{MovementPathError, MovementStep, QueuedMovePath};
pub use movement_units::MovementUnits;
pub use state::{StateBuildError, Unit, WorldState};
pub use unit_kind::{UnitKind, UnitMovementDomain};
pub use unit_posture::UnitPosture;
