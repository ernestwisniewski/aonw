use aonw_local_runtime::{CommandResult, LocalRuntime, MoveUnitRequest, RuntimeError};

/// One standard public runtime command selected by a planner.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum PlannedCommand {
    /// Revision-bound manual movement selected from `Reachable` query output.
    MoveUnit(MoveUnitRequest),
}

impl PlannedCommand {
    /// Executes the plan through the normal authoritative runtime boundary.
    ///
    /// # Errors
    ///
    /// Returns the same session or engine error as a client-issued command.
    pub fn execute(&self, runtime: &mut LocalRuntime) -> Result<CommandResult, RuntimeError> {
        match self {
            Self::MoveUnit(request) => runtime.dispatch(request),
        }
    }

    /// Returns the revision observed while this command was planned.
    #[must_use]
    pub const fn expected_revision(&self) -> u64 {
        match self {
            Self::MoveUnit(request) => request.expected_revision,
        }
    }
}
