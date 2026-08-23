/// Runtime capabilities independent of session state.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RuntimeCapabilities {
    features: u8,
}

impl RuntimeCapabilities {
    const ROUTE_PLAN: u8 = 1 << 0;
    const REACHABLE: u8 = 1 << 1;
    const MOVE_UNIT: u8 = 1 << 2;
    const SAVE_GAME: u8 = 1 << 3;
    const REPLAY_VERIFICATION: u8 = 1 << 4;
    const UNIT_ACTIONS: u8 = 1 << 5;

    pub(super) const CURRENT: Self = Self {
        features: Self::ROUTE_PLAN
            | Self::REACHABLE
            | Self::MOVE_UNIT
            | Self::SAVE_GAME
            | Self::REPLAY_VERIFICATION
            | Self::UNIT_ACTIONS,
    };

    /// Returns whether route planning is available.
    #[must_use]
    pub const fn route_plan(self) -> bool {
        self.features & Self::ROUTE_PLAN != 0
    }

    /// Returns whether reachable overlays are available.
    #[must_use]
    pub const fn reachable(self) -> bool {
        self.features & Self::REACHABLE != 0
    }

    /// Returns whether manual movement dispatch is available.
    #[must_use]
    pub const fn move_unit(self) -> bool {
        self.features & Self::MOVE_UNIT != 0
    }

    /// Returns whether canonical save export and restore are available.
    #[must_use]
    pub const fn save_game(self) -> bool {
        self.features & Self::SAVE_GAME != 0
    }

    /// Returns whether deterministic replay export and verification are available.
    #[must_use]
    pub const fn replay_verification(self) -> bool {
        self.features & Self::REPLAY_VERIFICATION != 0
    }

    /// Returns whether cancel, skip, and fortify commands are available.
    #[must_use]
    pub const fn unit_actions(self) -> bool {
        self.features & Self::UNIT_ACTIONS != 0
    }
}
