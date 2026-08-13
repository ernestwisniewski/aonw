use aonw_content::{
    ContentHash, MapDefinition, RulesetDefinition, ScenarioBootstrapError, ScenarioDefinition,
};
use aonw_domain::{GameState, PlayerId, StateRevision};
use aonw_engine::{
    CanonicalEngineError, CanonicalQueryError, ENGINE_BEHAVIOR_VERSION, EngineContext, GameEngine,
    MovementSearchWorkspace, MovementVisibility, StateDigest,
};

use crate::command_dispatch::dispatch_move;
use crate::persistence::{ReplayRecorder, RngStateV1};
use crate::player_view::PlayerViewSnapshotV1;
use crate::prepared_world::PreparedWorld;
use crate::query_cache::{QueryCache, QueryCacheStats};
use crate::query_dispatch::dispatch_query;
use crate::{MoveUnitResultV1, MoveUnitV1, QueryRequestV1, QueryResultV1};

/// Current local session contract version.
pub const LOCAL_SESSION_CONTRACT_VERSION: u16 = 1;

/// Runtime capabilities independent of session state.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RuntimeCapabilities {
    /// Local session contract version.
    pub contract_version: u16,
    /// Deterministic engine behavior version.
    pub behavior_version: u16,
    features: u8,
}

impl RuntimeCapabilities {
    const ROUTE_PLAN: u8 = 1 << 0;
    const REACHABLE: u8 = 1 << 1;
    const MOVE_UNIT: u8 = 1 << 2;
    const SAVE_GAME: u8 = 1 << 3;
    const REPLAY_VERIFICATION: u8 = 1 << 4;

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
}

/// Identity metadata carried by every session response.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SessionStampV1 {
    /// Local session contract version.
    pub contract_version: u16,
    /// Deterministic engine behavior version.
    pub behavior_version: u16,
    /// Canonical state revision.
    pub revision: StateRevision,
    /// Canonical state digest.
    pub state_digest: StateDigest,
    /// Validated map hash.
    pub map_hash: ContentHash,
    /// Validated ruleset hash.
    pub ruleset_hash: ContentHash,
}

/// Fully validated input used to open one local session.
#[derive(Clone, Debug)]
pub struct OpenSessionV1 {
    map: MapDefinition,
    ruleset: RulesetDefinition,
    state: GameState,
    actor: PlayerId,
    rng_state: RngStateV1,
    event_offset: u64,
}

impl OpenSessionV1 {
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
            rng_state: RngStateV1::new(0, 0, 0),
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
            rng_state: RngStateV1::new(0, 0, 0),
            event_offset: 0,
        }
    }

    /// Restores deterministic runtime state owned outside the game aggregate.
    #[must_use]
    pub const fn with_runtime_state(mut self, rng_state: RngStateV1, event_offset: u64) -> Self {
        self.rng_state = rng_state;
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

/// Failure from an operation requiring a valid local session.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuntimeError {
    /// No session is open.
    SessionNotOpen,
    /// A read-only query was rejected.
    Query(CanonicalQueryError),
    /// Canonical transition construction failed.
    Engine(CanonicalEngineError),
    /// Authoritative event offset exhausted its integer range.
    EventOffsetOverflow,
}

impl RuntimeError {
    /// Returns a stable adapter code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::SessionNotOpen => "session_not_open",
            Self::Query(error) => error.code(),
            Self::Engine(_) => "canonical_engine_failed",
            Self::EventOffsetOverflow => "event_offset_overflow",
        }
    }
}

impl core::fmt::Display for RuntimeError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::SessionNotOpen => formatter.write_str("session is not open"),
            Self::Query(source) => source.fmt(formatter),
            Self::Engine(source) => source.fmt(formatter),
            Self::EventOffsetOverflow => formatter.write_str("event offset overflow"),
        }
    }
}

impl std::error::Error for RuntimeError {}

#[derive(Clone, Debug)]
pub(crate) struct Session {
    world: PreparedWorld,
    state: Option<GameState>,
    actor: PlayerId,
    state_digest: StateDigest,
    visibility: MovementVisibility,
    rng_state: RngStateV1,
    event_offset: u64,
    replay: ReplayRecorder,
}

impl Session {
    fn try_open(request: OpenSessionV1) -> Result<Self, OpenSessionError> {
        let world = PreparedWorld::try_new(request.map, request.ruleset, &request.state)?;
        let state_digest = GameEngine::state_digest(&request.state);
        let visibility =
            MovementVisibility::for_player(&request.state, world.map(), &request.actor);
        let replay = ReplayRecorder::new(
            &request.state,
            state_digest,
            request.rng_state,
            request.event_offset,
        );
        Ok(Self {
            world,
            state: Some(request.state),
            actor: request.actor,
            state_digest,
            visibility,
            rng_state: request.rng_state,
            event_offset: request.event_offset,
            replay,
        })
    }

    pub(crate) const fn state(&self) -> &GameState {
        self.state.as_ref().expect("open session owns state")
    }

    pub(crate) const fn actor(&self) -> &PlayerId {
        &self.actor
    }

    pub(crate) const fn map(&self) -> &MapDefinition {
        self.world.map()
    }

    pub(crate) const fn ruleset(&self) -> &RulesetDefinition {
        self.world.ruleset()
    }

    pub(crate) const fn rng_state(&self) -> RngStateV1 {
        self.rng_state
    }

    pub(crate) const fn event_offset(&self) -> u64 {
        self.event_offset
    }

    pub(crate) fn advance_event_offset(&mut self, count: usize) -> Result<(), RuntimeError> {
        let count = u64::try_from(count).map_err(|_| RuntimeError::EventOffsetOverflow)?;
        self.event_offset = self
            .event_offset
            .checked_add(count)
            .ok_or(RuntimeError::EventOffsetOverflow)?;
        Ok(())
    }

    pub(crate) const fn replay(&self) -> &ReplayRecorder {
        &self.replay
    }

    pub(crate) fn prepare_replay_segment(&mut self) {
        if self.replay.is_full() {
            self.replay = ReplayRecorder::new(
                self.state(),
                self.state_digest,
                self.rng_state,
                self.event_offset,
            );
        }
    }

    pub(crate) fn push_replay(&mut self, entry: aonw_contracts::ReplayEntryDto) {
        self.replay.push(entry);
    }

    pub(crate) fn context(&self) -> EngineContext<'_> {
        EngineContext::canonical(self.actor(), self.world.map(), self.world.ruleset())
            .with_compiled_movement_map(self.world.movement_map())
            .with_movement_visibility(&self.visibility)
    }

    pub(crate) fn replace_state(&mut self, state: GameState, state_digest: StateDigest) {
        self.state_digest = state_digest;
        self.visibility = MovementVisibility::for_player(&state, self.world.map(), &self.actor);
        self.state = Some(state);
    }

    pub(crate) fn take_state(&mut self) -> GameState {
        self.state.take().expect("open session owns state")
    }

    pub(crate) const fn is_valid(&self) -> bool {
        self.state.is_some()
    }

    pub(crate) fn stamp(&self) -> SessionStampV1 {
        SessionStampV1 {
            contract_version: LOCAL_SESSION_CONTRACT_VERSION,
            behavior_version: ENGINE_BEHAVIOR_VERSION,
            revision: self.state().revision(),
            state_digest: self.state_digest,
            map_hash: self.world.map_hash(),
            ruleset_hash: self.world.ruleset_hash(),
        }
    }
}

/// Mutable owner of at most one local game session.
#[derive(Clone, Debug, Default)]
pub struct LocalRuntime {
    session: Option<Session>,
    workspace: MovementSearchWorkspace,
    query_cache: QueryCache,
}

impl LocalRuntime {
    /// Returns supported operations and versions.
    #[must_use]
    pub const fn capabilities() -> RuntimeCapabilities {
        RuntimeCapabilities {
            contract_version: LOCAL_SESSION_CONTRACT_VERSION,
            behavior_version: ENGINE_BEHAVIOR_VERSION,
            features: RuntimeCapabilities::ROUTE_PLAN
                | RuntimeCapabilities::REACHABLE
                | RuntimeCapabilities::MOVE_UNIT
                | RuntimeCapabilities::SAVE_GAME
                | RuntimeCapabilities::REPLAY_VERIFICATION,
        }
    }

    /// Transactionally opens a new session.
    ///
    /// A failed reopen preserves the previous valid session.
    ///
    /// # Errors
    ///
    /// Returns an error when map, ruleset, scenario, or state identities differ.
    pub fn open(&mut self, request: OpenSessionV1) -> Result<SessionStampV1, OpenSessionError> {
        let candidate = Session::try_open(request)?;
        let stamp = candidate.stamp();
        self.session = Some(candidate);
        self.query_cache.clear();
        Ok(stamp)
    }

    pub(crate) fn session_ref(&self) -> Result<&Session, RuntimeError> {
        self.session.as_ref().ok_or(RuntimeError::SessionNotOpen)
    }

    /// Closes the current session. Repeated calls are harmless.
    pub fn close(&mut self) {
        self.session = None;
        self.query_cache.clear();
    }

    /// Returns a full recipient-safe view.
    ///
    /// # Errors
    ///
    /// Returns [`RuntimeError::SessionNotOpen`] when closed.
    pub fn snapshot(&self) -> Result<PlayerViewSnapshotV1, RuntimeError> {
        let session = self.session.as_ref().ok_or(RuntimeError::SessionNotOpen)?;
        Ok(PlayerViewSnapshotV1::new(
            session.stamp(),
            session.state(),
            session.actor(),
        ))
    }

    /// Executes a versioned read-only query.
    ///
    /// # Errors
    ///
    /// Returns a stable query rejection or session error.
    pub fn query(&mut self, request: &QueryRequestV1) -> Result<QueryResultV1, RuntimeError> {
        let stamp = self
            .session
            .as_ref()
            .ok_or(RuntimeError::SessionNotOpen)?
            .stamp();
        if let Some(result) = self.query_cache.get(stamp, request) {
            return Ok(result);
        }
        let session = self.session.as_ref().ok_or(RuntimeError::SessionNotOpen)?;
        let result = dispatch_query(session, request.clone(), &mut self.workspace)?;
        self.query_cache.insert(stamp, request, &result);
        Ok(result)
    }

    /// Executes independent queries while reusing runtime caches and buffers.
    pub fn query_batch(
        &mut self,
        requests: &[QueryRequestV1],
    ) -> Vec<Result<QueryResultV1, RuntimeError>> {
        requests.iter().map(|request| self.query(request)).collect()
    }

    /// Returns diagnostic query-cache counters.
    #[must_use]
    pub const fn query_cache_stats(&self) -> QueryCacheStats {
        self.query_cache.stats()
    }

    /// Dispatches one revision-bound manual movement command.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error. Domain rejections are
    /// successful typed results with a rejection code.
    pub fn dispatch(&mut self, command: &MoveUnitV1) -> Result<MoveUnitResultV1, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_move(session, command)
        };
        if self
            .session
            .as_ref()
            .is_some_and(|session| !session.is_valid())
        {
            self.session = None;
        }
        self.query_cache.clear();
        result
    }
}
