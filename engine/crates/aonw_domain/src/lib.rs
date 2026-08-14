//! Canonical, framework-independent game-domain types.
//!
//! The crate owns invariants and deterministic state representation. It has no
//! serialization, persistence, networking, UI, framework, or ambient-time
//! dependencies.

#![forbid(unsafe_code)]

mod artifact;
mod city;
mod diplomacy;
mod fog;
mod game_state;
mod hex_coord;
mod hex_grid;
mod identifier;
mod interaction;
mod movement_path;
mod movement_units;
mod shared;
mod transport;
mod unit;
mod unit_kind;
mod unit_posture;

pub use artifact::{WorldArtifact, WorldArtifactLocation, WorldArtifactType};
pub use city::City;
pub use diplomacy::{Diplomacy, PlayerPair};
pub use fog::{FogOfWar, FogVisibility, PlayerFog};
pub use game_state::{GameState, GameStateBuildError, UnitOccupancyPolicy};
pub use hex_coord::HexCoord;
pub use hex_grid::{HexGridBounds, HexTileIndex};
pub use identifier::{ArtifactId, CityId, IdentifierError, PlayerId, UnitId};
pub use interaction::{CityFoundingDraft, InteractionState, PendingInteraction};
pub use movement_path::{MovementPathError, MovementStep, QueuedMovePath};
pub use movement_units::MovementUnits;
pub use shared::StateRevision;
pub use transport::{TransportCondition, TransportNetwork, TransportSegment};
pub use unit::{
    ArmyTroop, CityFoundingJob, FieldImprovementKind, MerchantTradeRoute, TroopKind, Unit,
    UnitActivity, UnitBuildError, UnitBuilder, WorkerJob,
};
pub use unit_kind::{UnitKind, UnitMovementDomain};
pub use unit_posture::UnitPosture;
