use aonw_content::{ContentHash, MapDefinition, RulesetDefinition};
use aonw_domain::{GameState, PlayerId, StateRevision};
use aonw_engine::{EngineContext, GameEngine, MovementVisibility, StateDigest};

use crate::persistence::{ReplayRecorder, RngState};
use crate::prepared_world::PreparedWorld;

use super::{OpenSession, OpenSessionError, RuntimeError};

/// Identity metadata carried by every session response.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SessionStamp {
    /// Canonical state revision.
    pub revision: StateRevision,
    /// Canonical state digest.
    pub state_digest: StateDigest,
    /// Validated map hash.
    pub map_hash: ContentHash,
    /// Validated ruleset hash.
    pub ruleset_hash: ContentHash,
}

#[derive(Clone, Debug)]
pub(crate) struct Session {
    world: PreparedWorld,
    state: Option<GameState>,
    actor: PlayerId,
    state_digest: StateDigest,
    visibility: MovementVisibility,
    rng_state: RngState,
    event_offset: u64,
    replay: ReplayRecorder,
}

impl Session {
    pub(super) fn try_open(request: OpenSession) -> Result<Self, OpenSessionError> {
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

    pub(crate) const fn rng_state(&self) -> RngState {
        self.rng_state
    }

    pub(crate) const fn event_offset(&self) -> u64 {
        self.event_offset
    }

    pub(crate) fn ensure_event_capacity(&self, count: usize) -> Result<(), RuntimeError> {
        let count = u64::try_from(count).map_err(|_| RuntimeError::EventOffsetOverflow)?;
        self.event_offset
            .checked_add(count)
            .map(|_| ())
            .ok_or(RuntimeError::EventOffsetOverflow)
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

    pub(crate) fn stamp(&self) -> SessionStamp {
        SessionStamp {
            revision: self.state().revision(),
            state_digest: self.state_digest,
            map_hash: self.world.map_hash(),
            ruleset_hash: self.world.ruleset_hash(),
        }
    }
}
