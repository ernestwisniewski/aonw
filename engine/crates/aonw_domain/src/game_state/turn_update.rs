use crate::{InteractionState, MatchLifecycle, StateRevision, Unit};

use super::{GameState, GameStateBuildError};

impl GameState {
    /// Consumes the aggregate and applies one atomic turn-kernel update.
    ///
    /// # Errors
    ///
    /// Returns an error if the replacement lifecycle or units violate aggregate invariants.
    pub fn into_after_turn_kernel(
        self,
        revision: StateRevision,
        turn: u32,
        lifecycle: MatchLifecycle,
        units: Vec<Unit>,
        interaction: InteractionState,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = revision;
        builder.turn = turn;
        builder.match_lifecycle = lifecycle;
        builder.units = units;
        builder.interaction = interaction;
        builder.try_build()
    }
}
