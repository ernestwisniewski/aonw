use aonw_content::{MapDefinition, RulesetDefinition, ScenarioBootstrapError, ScenarioDefinition};
use aonw_domain::{GameState, PlayerId};

/// Fully validated input used to open one local session.
#[derive(Clone, Debug)]
pub struct OpenSession {
    pub(super) map: MapDefinition,
    pub(super) ruleset: RulesetDefinition,
    pub(super) state: GameState,
    pub(super) actor: PlayerId,
    pub(super) event_offset: u64,
}

impl OpenSession {
    /// Builds an open request from immutable scenario content.
    ///
    /// # Errors
    ///
    /// Returns an error when scenario content cannot bootstrap canonical state.
    pub fn from_scenario(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        scenario: &ScenarioDefinition,
        actor: PlayerId,
    ) -> Result<Self, OpenSessionError> {
        let state = scenario
            .bootstrap(&map, &ruleset)
            .map_err(OpenSessionError::Scenario)?;
        Ok(Self {
            map,
            ruleset,
            state,
            actor,
            event_offset: 0,
        })
    }

    /// Builds an open request from a previously decoded canonical snapshot.
    #[must_use]
    pub const fn from_state(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        state: GameState,
        actor: PlayerId,
    ) -> Self {
        Self {
            map,
            ruleset,
            state,
            actor,
            event_offset: 0,
        }
    }

    /// Restores the authoritative event-log position owned by the runtime.
    #[must_use]
    pub const fn with_event_offset(mut self, event_offset: u64) -> Self {
        self.event_offset = event_offset;
        self
    }
}

/// Failure while preparing a new session.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum OpenSessionError {
    /// Scenario bootstrap failed.
    Scenario(ScenarioBootstrapError),
    /// State and map bounds differ.
    MapBoundsMismatch,
    /// State and ruleset occupancy policies differ.
    OccupancyPolicyMismatch,
    /// Immutable content identity could not be computed.
    ContentHash(Box<str>),
}

impl core::fmt::Display for OpenSessionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Scenario(source) => source.fmt(formatter),
            Self::MapBoundsMismatch => formatter.write_str("state bounds do not match the map"),
            Self::OccupancyPolicyMismatch => {
                formatter.write_str("state occupancy policy does not match the ruleset")
            }
            Self::ContentHash(source) => write!(formatter, "content hash failed: {source}"),
        }
    }
}

impl std::error::Error for OpenSessionError {}
