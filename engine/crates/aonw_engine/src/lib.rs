//! Pure entry point for deterministic game rules and queries.
//!
//! The first committed slice exposes version metadata and allocation-free state
//! inspection. Authoritative transitions are added only with reviewed parity
//! fixtures so an incomplete Rust rule cannot accidentally replace Dart.

#![forbid(unsafe_code)]

use aonw_domain::{PlayerId, WorldState};

/// Engine behavior version implemented by this workspace.
///
/// This axis is independent of save, wire, and native ABI versions.
pub const ENGINE_BEHAVIOR_VERSION: u16 = 1;

/// Stateless deterministic engine facade.
#[derive(Clone, Copy, Debug, Default)]
pub struct GameEngine;

impl GameEngine {
    /// Returns compile-time crate version metadata.
    #[must_use]
    pub const fn version() -> EngineVersion {
        EngineVersion {
            crate_version: env!("CARGO_PKG_VERSION"),
            behavior_version: ENGINE_BEHAVIOR_VERSION,
        }
    }

    /// Inspects canonical state without allocation or mutation.
    #[must_use]
    pub const fn summarize_state(state: &WorldState) -> StateSummary<'_> {
        StateSummary {
            revision: state.revision(),
            turn: state.turn(),
            active_player_id: state.active_player_id(),
            unit_count: state.units().len(),
        }
    }
}

/// Compile-time engine version metadata.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct EngineVersion {
    /// Cargo crate version.
    pub crate_version: &'static str,
    /// Deterministic behavior compatibility version.
    pub behavior_version: u16,
}

/// Borrowed canonical state summary for health checks and early adapters.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct StateSummary<'state> {
    /// Canonical revision.
    pub revision: u64,
    /// Current turn.
    pub turn: u32,
    /// Active player without identifier cloning.
    pub active_player_id: &'state PlayerId,
    /// Number of canonical units.
    pub unit_count: usize,
}

#[cfg(test)]
mod tests {
    use aonw_domain::{HexCoord, PlayerId, Unit, UnitId, WorldState};

    use super::{ENGINE_BEHAVIOR_VERSION, GameEngine};

    #[test]
    fn engine_summary_borrows_canonical_state() {
        let player_id = PlayerId::new("player-1").expect("valid player id");
        let state = WorldState::try_new(
            12,
            4,
            player_id.clone(),
            [Unit::new(
                UnitId::new("unit-1").expect("valid unit id"),
                player_id,
                HexCoord::new(3, -2),
                100,
            )],
        )
        .expect("valid state");

        let summary = GameEngine::summarize_state(&state);
        assert_eq!(summary.revision, 12);
        assert_eq!(summary.turn, 4);
        assert_eq!(summary.active_player_id.as_str(), "player-1");
        assert_eq!(summary.unit_count, 1);
    }

    #[test]
    fn engine_version_axes_are_explicit() {
        let version = GameEngine::version();

        assert_eq!(version.crate_version, env!("CARGO_PKG_VERSION"));
        assert_eq!(version.behavior_version, ENGINE_BEHAVIOR_VERSION);
    }
}
