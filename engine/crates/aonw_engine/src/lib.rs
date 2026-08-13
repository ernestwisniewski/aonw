//! Pure entry point for deterministic game rules and queries.
//!
//! The first committed slice exposes version metadata and allocation-free state
//! inspection. Authoritative transitions are added only with reviewed parity
//! fixtures so an incomplete Rust rule cannot accidentally replace Dart.

#![forbid(unsafe_code)]

use aonw_content::MapDefinition;
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
    pub const fn summarize_state(state: &WorldState) -> StateSummary {
        StateSummary {
            revision: state.revision(),
            turn: state.turn(),
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

/// Canonical state summary for health checks and early adapters.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct StateSummary {
    /// Canonical revision.
    pub revision: u64,
    /// Current turn.
    pub turn: u32,
    /// Number of canonical units.
    pub unit_count: usize,
}

/// Immutable inputs that are authoritative for one command or query.
#[derive(Clone, Copy, Debug)]
pub struct EngineContext<'context> {
    actor_player_id: &'context PlayerId,
    map: &'context MapDefinition,
}

impl<'context> EngineContext<'context> {
    /// Constructs an explicit context without ambient actor or map state.
    #[must_use]
    pub const fn new(actor_player_id: &'context PlayerId, map: &'context MapDefinition) -> Self {
        Self {
            actor_player_id,
            map,
        }
    }

    /// Returns the player issuing the command or query.
    #[must_use]
    pub const fn actor_player_id(self) -> &'context PlayerId {
        self.actor_player_id
    }

    /// Returns the validated logical map used by the rules engine.
    #[must_use]
    pub const fn map(self) -> &'context MapDefinition {
        self.map
    }
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
    use aonw_domain::{HexCoord, PlayerId, Unit, UnitId, WorldState};

    use super::{ENGINE_BEHAVIOR_VERSION, EngineContext, GameEngine};

    #[test]
    fn engine_summary_reports_canonical_state() {
        let player_id = PlayerId::new("player-1").expect("valid player id");
        let state = WorldState::try_new(
            12,
            4,
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
        assert_eq!(summary.unit_count, 1);
    }

    #[test]
    fn engine_version_axes_are_explicit() {
        let version = GameEngine::version();

        assert_eq!(version.crate_version, env!("CARGO_PKG_VERSION"));
        assert_eq!(version.behavior_version, ENGINE_BEHAVIOR_VERSION);
    }

    #[test]
    fn engine_context_carries_actor_and_map_explicitly() {
        let actor = PlayerId::new("player-1").expect("valid player id");
        let tile = TileDefinition::try_new(
            HexCoord::new(0, 0),
            vec![TerrainType::Plains],
            Vec::new(),
            0,
        )
        .expect("valid tile");
        let map = MapDefinition::try_new(
            "fixture",
            GridLayout::OddQFlatTop,
            1,
            1,
            vec![tile],
            Vec::new(),
        )
        .expect("valid logical map");

        let context = EngineContext::new(&actor, &map);

        assert_eq!(context.actor_player_id(), &actor);
        assert_eq!(context.map().map_id(), "fixture");
    }
}
