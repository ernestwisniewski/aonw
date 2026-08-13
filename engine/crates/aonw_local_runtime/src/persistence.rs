use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::{
    CURRENT_REPLAY_LOG_VERSION, CURRENT_SAVE_GAME_VERSION, CoordinateDto, MAX_REPLAY_ENTRY_COUNT,
    MovementStepDto, ReplayCommandDto, ReplayContextDto, ReplayEntryDto, ReplayEventDto,
    ReplayEvidenceDto, ReplayLogDto, ReplayResultDto, RngStateDto, SaveGameDto,
};
use aonw_domain::{PlayerId, UnitId};
use aonw_engine::{DomainEvent, ENGINE_BEHAVIOR_VERSION, ExecutionEvidence, GameEngine};

pub use crate::persistence_error::PersistenceError;
use crate::persistence_validation::{validate_replay_header, validate_save_header};
use crate::session::Session;
use crate::{LocalRuntime, MoveUnitResultV1, MoveUnitV1, OpenSessionV1, SessionStampV1};

/// Deterministic random-stream position owned by a local session.
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq)]
pub struct RngStateV1 {
    seed: u64,
    stream: u64,
    counter: u64,
}

impl RngStateV1 {
    /// Creates an explicit deterministic random-stream position.
    #[must_use]
    pub const fn new(seed: u64, stream: u64, counter: u64) -> Self {
        Self {
            seed,
            stream,
            counter,
        }
    }

    /// Returns the initial seed.
    #[must_use]
    pub const fn seed(self) -> u64 {
        self.seed
    }

    /// Returns the independent stream selector.
    #[must_use]
    pub const fn stream(self) -> u64 {
        self.stream
    }

    /// Returns the consumed-value counter.
    #[must_use]
    pub const fn counter(self) -> u64 {
        self.counter
    }

    const fn to_dto(self) -> RngStateDto {
        RngStateDto {
            seed: self.seed,
            stream: self.stream,
            counter: self.counter,
        }
    }
}

impl From<RngStateDto> for RngStateV1 {
    fn from(value: RngStateDto) -> Self {
        Self::new(value.seed, value.stream, value.counter)
    }
}

/// Result of deterministic replay verification.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ReplayVerificationV1 {
    /// Number of commands verified.
    pub entry_count: usize,
    /// Final authoritative session identity.
    pub final_stamp: SessionStampV1,
    /// Final authoritative event offset.
    pub final_event_offset: u64,
}

#[derive(Clone, Debug)]
pub(crate) struct ReplayRecorder {
    initial_state: aonw_contracts::GameStateDto,
    initial_state_digest: String,
    initial_rng_state: RngStateV1,
    initial_event_offset: u64,
    entries: Vec<ReplayEntryDto>,
}

impl ReplayRecorder {
    pub(crate) fn new(
        state: &aonw_domain::GameState,
        digest: aonw_engine::StateDigest,
        rng_state: RngStateV1,
        event_offset: u64,
    ) -> Self {
        Self {
            initial_state: encode_game_state(state),
            initial_state_digest: digest.to_string(),
            initial_rng_state: rng_state,
            initial_event_offset: event_offset,
            entries: Vec::new(),
        }
    }

    pub(crate) fn is_full(&self) -> bool {
        self.entries.len() >= MAX_REPLAY_ENTRY_COUNT
    }

    pub(crate) fn push(&mut self, entry: ReplayEntryDto) {
        self.entries.push(entry);
    }

    fn to_dto(&self, session: &Session) -> ReplayLogDto {
        ReplayLogDto {
            schema_version: CURRENT_REPLAY_LOG_VERSION,
            behavior_version: ENGINE_BEHAVIOR_VERSION,
            map_id: session.map().map_id().to_owned(),
            map_hash: session.stamp().map_hash.to_string(),
            ruleset_id: session.ruleset().ruleset_id().to_owned(),
            ruleset_hash: session.stamp().ruleset_hash.to_string(),
            actor_player_id: session.actor().as_str().to_owned(),
            initial_rng_state: self.initial_rng_state.to_dto(),
            initial_event_offset: self.initial_event_offset,
            initial_state_digest: self.initial_state_digest.clone(),
            initial_state: self.initial_state.clone(),
            entries: self.entries.clone(),
        }
    }
}

impl LocalRuntime {
    /// Serializes a complete canonical save document.
    ///
    /// # Errors
    ///
    /// Returns an error when no session is open or serialization fails.
    pub fn export_save_json(&self) -> Result<String, PersistenceError> {
        let session = self.session_ref().map_err(PersistenceError::Runtime)?;
        let dto = SaveGameDto {
            schema_version: CURRENT_SAVE_GAME_VERSION,
            behavior_version: ENGINE_BEHAVIOR_VERSION,
            map_id: session.map().map_id().to_owned(),
            map_hash: session.stamp().map_hash.to_string(),
            ruleset_id: session.ruleset().ruleset_id().to_owned(),
            ruleset_hash: session.stamp().ruleset_hash.to_string(),
            actor_player_id: session.actor().as_str().to_owned(),
            rng_state: session.rng_state().to_dto(),
            event_offset: session.event_offset(),
            state_digest: session.stamp().state_digest.to_string(),
            state: encode_game_state(session.state()),
        };
        dto.to_json()
            .map_err(|error| PersistenceError::Serialize(error.to_string()))
    }

    /// Transactionally opens a strict canonical save against supplied content.
    ///
    /// # Errors
    ///
    /// Returns an error for incompatible content, behavior, state, or JSON.
    pub fn open_save_json(
        &mut self,
        map: MapDefinition,
        ruleset: RulesetDefinition,
        input: &str,
    ) -> Result<SessionStampV1, PersistenceError> {
        let save = SaveGameDto::from_json(input).map_err(PersistenceError::Codec)?;
        validate_save_header(&save, &map, &ruleset)?;
        let state = decode_game_state(save.state).map_err(PersistenceError::State)?;
        if GameEngine::state_digest(&state).to_string() != save.state_digest {
            return Err(PersistenceError::StateDigestMismatch);
        }
        let actor = PlayerId::new(save.actor_player_id).map_err(PersistenceError::InvalidActor)?;
        let request = OpenSessionV1::from_state(map, ruleset, state, actor)
            .with_runtime_state(save.rng_state.into(), save.event_offset);
        self.open(request).map_err(PersistenceError::Open)
    }

    /// Serializes the bounded deterministic replay segment for the open session.
    ///
    /// # Errors
    ///
    /// Returns an error when no session is open or serialization fails.
    pub fn export_replay_json(&self) -> Result<String, PersistenceError> {
        let session = self.session_ref().map_err(PersistenceError::Runtime)?;
        session
            .replay()
            .to_dto(session)
            .to_json()
            .map_err(|error| PersistenceError::Serialize(error.to_string()))
    }

    /// Replays and verifies every command against exact recorded outcomes.
    ///
    /// # Errors
    ///
    /// Returns an error for incompatible content, state, context, or output.
    pub fn verify_replay_json(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        input: &str,
    ) -> Result<ReplayVerificationV1, PersistenceError> {
        let replay = ReplayLogDto::from_json(input).map_err(PersistenceError::Codec)?;
        validate_replay_header(&replay, &map, &ruleset)?;
        let state =
            decode_game_state(replay.initial_state.clone()).map_err(PersistenceError::State)?;
        if GameEngine::state_digest(&state).to_string() != replay.initial_state_digest {
            return Err(PersistenceError::StateDigestMismatch);
        }
        let actor = PlayerId::new(replay.actor_player_id.clone())
            .map_err(PersistenceError::InvalidActor)?;
        let mut runtime = Self::default();
        runtime
            .open(
                OpenSessionV1::from_state(map, ruleset, state, actor).with_runtime_state(
                    replay.initial_rng_state.into(),
                    replay.initial_event_offset,
                ),
            )
            .map_err(PersistenceError::Open)?;

        for (entry_index, entry) in replay.entries.iter().enumerate() {
            let expected_index = u64::try_from(entry_index).unwrap_or(u64::MAX);
            if entry.index != expected_index {
                return Err(PersistenceError::ReplayIndexMismatch {
                    expected: expected_index,
                    found: entry.index,
                });
            }
            let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
            if entry.context != replay_context(session) {
                return Err(PersistenceError::ReplayContextMismatch { entry: entry_index });
            }
            let command = decode_command(&entry.command)?;
            let result = runtime
                .dispatch(&command)
                .map_err(PersistenceError::Runtime)?;
            let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
            if entry.result != replay_result(&result, session) {
                return Err(PersistenceError::ReplayResultMismatch { entry: entry_index });
            }
        }
        let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
        Ok(ReplayVerificationV1 {
            entry_count: replay.entries.len(),
            final_stamp: session.stamp(),
            final_event_offset: session.event_offset(),
        })
    }
}

pub(crate) fn replay_entry(
    session: &Session,
    command: &MoveUnitV1,
    before: ReplayContextDto,
    result: &MoveUnitResultV1,
) -> ReplayEntryDto {
    ReplayEntryDto {
        index: u64::try_from(session.replay().entries.len()).unwrap_or(u64::MAX),
        context: before,
        command: ReplayCommandDto::MoveUnit {
            expected_revision: command.expected_revision,
            unit_id: command.unit_id.as_str().to_owned(),
            target: coordinate(command.target),
        },
        result: replay_result(result, session),
    }
}

pub(crate) fn replay_context(session: &Session) -> ReplayContextDto {
    let stamp = session.stamp();
    ReplayContextDto {
        actor_player_id: session.actor().as_str().to_owned(),
        behavior_version: stamp.behavior_version,
        map_hash: stamp.map_hash.to_string(),
        ruleset_hash: stamp.ruleset_hash.to_string(),
        state_digest: stamp.state_digest.to_string(),
        rng_state: session.rng_state().to_dto(),
        event_offset: session.event_offset(),
    }
}

fn replay_result(result: &MoveUnitResultV1, session: &Session) -> ReplayResultDto {
    ReplayResultDto {
        accepted: result.is_accepted(),
        rejection: result.rejection.map(str::to_owned),
        revision: result.stamp.revision.get(),
        state_digest: result.stamp.state_digest.to_string(),
        events: result.events.iter().map(encode_event).collect(),
        evidence: result.evidence.as_ref().map(encode_evidence),
        rng_state: session.rng_state().to_dto(),
        event_offset: session.event_offset(),
    }
}

fn encode_event(event: &DomainEvent) -> ReplayEventDto {
    match event {
        DomainEvent::UnitMoved(event) => ReplayEventDto::UnitMoved {
            unit_id: event.unit_id().as_str().to_owned(),
            from: coordinate(event.from()),
            to: coordinate(event.to()),
        },
    }
}

fn encode_evidence(evidence: &ExecutionEvidence) -> ReplayEvidenceDto {
    match evidence {
        ExecutionEvidence::UnitMovement(execution) => ReplayEvidenceDto::UnitMovement {
            unit_id: execution.unit_id().as_str().to_owned(),
            from: coordinate(execution.from()),
            steps: execution
                .steps()
                .iter()
                .map(|step| MovementStepDto {
                    col: step.coordinate().col(),
                    row: step.coordinate().row(),
                    enter_cost_units: step.enter_cost().get(),
                    cumulative_cost_units: step.cumulative_cost().get(),
                })
                .collect(),
        },
    }
}

const fn coordinate(value: aonw_domain::HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}

fn decode_command(command: &ReplayCommandDto) -> Result<MoveUnitV1, PersistenceError> {
    match command {
        ReplayCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => Ok(MoveUnitV1 {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            target: aonw_domain::HexCoord::new(target.col, target.row),
        }),
    }
}
