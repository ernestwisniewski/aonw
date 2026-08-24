use crate::{Diplomacy, FogOfWar, InteractionState, MatchLifecycle, StateRevision, Unit};

use super::{GameState, GameStateBuildError};

/// Canonical turn coordinates replaced atomically by the turn kernel.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TurnAdvance {
    turn: u32,
    lifecycle: MatchLifecycle,
}

impl TurnAdvance {
    /// Creates one trusted turn update.
    #[must_use]
    pub const fn new(turn: u32, lifecycle: MatchLifecycle) -> Self {
        Self { turn, lifecycle }
    }
}

impl GameState {
    /// Consumes the aggregate and applies a complete movement/logistics update.
    ///
    /// # Errors
    ///
    /// Returns an error when the resulting units, fog, diplomacy, or interaction
    /// violate an aggregate invariant.
    pub fn into_after_movement_logistics(
        self,
        revision: StateRevision,
        units: Vec<Unit>,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
        interaction: InteractionState,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = revision;
        builder.units = units;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.interaction = interaction;
        builder.try_build()
    }

    /// Consumes the aggregate and applies one atomic turn-kernel update.
    ///
    /// # Errors
    ///
    /// Returns an error if the replacement lifecycle or units violate aggregate invariants.
    pub fn into_after_turn_kernel(
        self,
        revision: StateRevision,
        advance: TurnAdvance,
        units: Vec<Unit>,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
        interaction: InteractionState,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = revision;
        builder.turn = advance.turn;
        builder.match_lifecycle = advance.lifecycle;
        builder.units = units;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.interaction = interaction;
        builder.try_build()
    }
}
