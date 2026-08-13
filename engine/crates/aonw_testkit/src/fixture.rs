use serde_json::{Map, Value};

use crate::JsonDifference;
use crate::diff::{JsonOutcome, compare_outcome};

/// JSON object used at language-neutral fixture boundaries.
pub type JsonObject = Map<String, Value>;

/// Reducer-parity fixture version supported by this crate.
pub const SUPPORTED_FIXTURE_VERSION: u64 = 1;

/// One independently reviewed reducer-parity fixture.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Fixture {
    pub(crate) id: Box<str>,
    pub(crate) family: Box<str>,
    pub(crate) input: FixtureInput,
    pub(crate) expected: ReducerExpectedOutcome,
}

impl Fixture {
    /// Returns the kebab-case fixture identifier.
    #[must_use]
    pub fn id(&self) -> &str {
        &self.id
    }

    /// Returns the command-family identifier.
    #[must_use]
    pub fn family(&self) -> &str {
        &self.family
    }

    /// Returns the immutable engine input.
    #[must_use]
    pub const fn input(&self) -> &FixtureInput {
        &self.input
    }

    /// Returns the committed oracle output.
    #[must_use]
    pub const fn expected(&self) -> &ReducerExpectedOutcome {
        &self.expected
    }

    /// Compares an implementation output with the committed oracle.
    #[must_use]
    pub fn differences(&self, actual: &FixtureOutput) -> Vec<JsonDifference> {
        compare_outcome(self.expected.as_json_outcome(), actual.as_json_outcome())
    }
}

/// Complete input retained as typed metadata plus opaque canonical JSON.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FixtureInput {
    pub(crate) now: Box<str>,
    pub(crate) actor_player_id: Box<str>,
    pub(crate) tick: u64,
    pub(crate) ruleset_id: Box<str>,
    pub(crate) map: JsonObject,
    pub(crate) game_match: JsonObject,
    pub(crate) save: JsonObject,
    pub(crate) state: JsonObject,
    pub(crate) command: JsonObject,
}

impl FixtureInput {
    /// Returns the serialized UTC timestamp supplied to the engine.
    #[must_use]
    pub fn now(&self) -> &str {
        &self.now
    }

    /// Returns the authenticated actor identifier.
    #[must_use]
    pub fn actor_player_id(&self) -> &str {
        &self.actor_player_id
    }

    /// Returns the deterministic command tick.
    #[must_use]
    pub const fn tick(&self) -> u64 {
        self.tick
    }

    /// Returns the ruleset identifier.
    #[must_use]
    pub fn ruleset_id(&self) -> &str {
        &self.ruleset_id
    }

    /// Returns the canonical map payload.
    #[must_use]
    pub const fn map(&self) -> &JsonObject {
        &self.map
    }

    /// Returns the multiplayer match payload.
    #[must_use]
    pub const fn game_match(&self) -> &JsonObject {
        &self.game_match
    }

    /// Returns the save metadata payload.
    #[must_use]
    pub const fn save(&self) -> &JsonObject {
        &self.save
    }

    /// Returns the canonical state payload.
    #[must_use]
    pub const fn state(&self) -> &JsonObject {
        &self.state
    }

    /// Returns the serialized domain command.
    #[must_use]
    pub const fn command(&self) -> &JsonObject {
        &self.command
    }
}

/// Committed expected result for the current Dart reducer corpus.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReducerExpectedOutcome {
    pub(crate) accepted: bool,
    pub(crate) reason: Option<Box<str>>,
    pub(crate) save: JsonObject,
    pub(crate) state: JsonObject,
    pub(crate) events: Vec<JsonObject>,
}

impl ReducerExpectedOutcome {
    /// Returns whether the command must be accepted.
    #[must_use]
    pub const fn accepted(&self) -> bool {
        self.accepted
    }

    /// Returns the stable rejection code, if rejected.
    #[must_use]
    pub fn reason(&self) -> Option<&str> {
        self.reason.as_deref()
    }

    /// Returns expected save metadata, excluding the documented `savedAt` seam.
    #[must_use]
    pub const fn save(&self) -> &JsonObject {
        &self.save
    }

    /// Returns the complete expected canonical state.
    #[must_use]
    pub const fn state(&self) -> &JsonObject {
        &self.state
    }

    /// Returns ordered expected domain events.
    #[must_use]
    pub fn events(&self) -> &[JsonObject] {
        &self.events
    }

    /// Creates a standalone output value for adapter tests.
    #[must_use]
    pub fn to_output(&self) -> FixtureOutput {
        FixtureOutput {
            accepted: self.accepted,
            reason: self.reason.clone(),
            save: self.save.clone(),
            state: self.state.clone(),
            events: self.events.clone(),
        }
    }

    fn as_json_outcome(&self) -> JsonOutcome<'_> {
        JsonOutcome::new(
            self.accepted,
            self.reason.as_deref(),
            &self.save,
            &self.state,
            &self.events,
        )
    }
}

/// Output returned by a Dart, Rust, native, Godot, or shadow fixture adapter.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FixtureOutput {
    accepted: bool,
    reason: Option<Box<str>>,
    save: JsonObject,
    state: JsonObject,
    events: Vec<JsonObject>,
}

impl FixtureOutput {
    /// Constructs an accepted implementation output.
    #[must_use]
    pub const fn accept(save: JsonObject, state: JsonObject, events: Vec<JsonObject>) -> Self {
        Self {
            accepted: true,
            reason: None,
            save,
            state,
            events,
        }
    }

    /// Constructs a rejected implementation output with a stable reason code.
    #[must_use]
    pub fn reject(
        reason: impl Into<Box<str>>,
        save: JsonObject,
        state: JsonObject,
        events: Vec<JsonObject>,
    ) -> Self {
        Self {
            accepted: false,
            reason: Some(reason.into()),
            save,
            state,
            events,
        }
    }

    /// Returns whether the implementation accepted the command.
    #[must_use]
    pub const fn accepted(&self) -> bool {
        self.accepted
    }

    /// Returns the implementation rejection code.
    #[must_use]
    pub fn reason(&self) -> Option<&str> {
        self.reason.as_deref()
    }

    /// Returns save metadata produced by the implementation.
    #[must_use]
    pub const fn save(&self) -> &JsonObject {
        &self.save
    }

    /// Returns canonical state produced by the implementation.
    #[must_use]
    pub const fn state(&self) -> &JsonObject {
        &self.state
    }

    /// Returns ordered domain events produced by the implementation.
    #[must_use]
    pub fn events(&self) -> &[JsonObject] {
        &self.events
    }

    fn as_json_outcome(&self) -> JsonOutcome<'_> {
        JsonOutcome::new(
            self.accepted,
            self.reason.as_deref(),
            &self.save,
            &self.state,
            &self.events,
        )
    }
}
