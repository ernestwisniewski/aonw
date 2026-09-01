use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::{
    CoordinateDto, MAX_REPLAY_ENTRY_COUNT, MAX_REPLAY_SEGMENT_COUNT, ReplayContextDto,
    ReplayEntryDto, ReplayLogDto, ReplayRecordDto, ReplayResultDto, ReplaySegmentDto,
    ReplaySystemCommandDto, SaveGameDto,
};
use aonw_domain::{CityId, PlayerId, UnitId, UtcTimestamp};
use aonw_engine::GameEngine;

pub use crate::persistence_error::PersistenceError;
use crate::persistence_validation::validate_save_header;
use crate::session::Session;
use crate::{
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, CommandResult,
    DetachTroopRequest, DiplomacyRequest, FinalizeTimedOutTurnRequest, FoundCityRequest,
    KickParticipantRequest, LocalRuntime, MerchantCityRequest, MoveUnitRequest, OpenSession,
    ProductionCommandRequest, SelectCityExpansionHexRequest, SelectTechnologyRequest, SessionStamp,
    ToggleWorkedHexRequest, TurnCommandRequest, UnitActionRequest, WorkerImprovementRequest,
    WorkerUnitRequest,
};

mod evidence;
mod player_decode;
mod verification;

use evidence::{encode_event, encode_evidence};
use player_decode::decode_command;
use verification::verify_replay;

/// Result of deterministic replay verification.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ReplayVerification {
    /// Number of commands verified.
    pub entry_count: usize,
    /// Final authoritative session identity.
    pub final_stamp: SessionStamp,
    /// Final authoritative event offset.
    pub final_event_offset: u64,
}

#[derive(Clone, Debug)]
pub(crate) struct ReplayRecorder {
    completed_segments: Vec<ReplaySegmentDto>,
    current_segment: ReplaySegmentDto,
}

impl ReplayRecorder {
    pub(crate) fn new(
        state: &aonw_domain::GameState,
        digest: aonw_engine::StateDigest,
        event_offset: u64,
    ) -> Self {
        Self {
            completed_segments: Vec::new(),
            current_segment: Self::checkpoint(state, digest, event_offset),
        }
    }

    pub(crate) fn is_full(&self) -> bool {
        self.current().entries.len() >= MAX_REPLAY_ENTRY_COUNT
    }

    pub(crate) fn checkpoint(
        state: &aonw_domain::GameState,
        digest: aonw_engine::StateDigest,
        event_offset: u64,
    ) -> ReplaySegmentDto {
        ReplaySegmentDto {
            initial_state: encode_game_state(state),
            initial_state_digest: digest.to_string(),
            initial_event_offset: event_offset,
            entries: Vec::new(),
        }
    }

    pub(crate) fn rollover(&mut self, checkpoint: ReplaySegmentDto) {
        if self.completed_segments.len() == MAX_REPLAY_SEGMENT_COUNT - 1 {
            self.completed_segments.remove(0);
        }
        let completed = core::mem::replace(&mut self.current_segment, checkpoint);
        self.completed_segments.push(completed);
    }

    pub(crate) fn push(&mut self, entry: ReplayEntryDto) {
        self.current_mut().entries.push(entry);
    }

    pub(crate) fn current_entry_count(&self) -> usize {
        self.current().entries.len()
    }

    fn current(&self) -> &ReplaySegmentDto {
        &self.current_segment
    }

    fn current_mut(&mut self) -> &mut ReplaySegmentDto {
        &mut self.current_segment
    }

    fn to_dto(&self, session: &Session) -> ReplayLogDto {
        let mut segments = Vec::with_capacity(self.completed_segments.len() + 1);
        segments.extend(self.completed_segments.iter().cloned());
        segments.push(self.current_segment.clone());
        ReplayLogDto {
            map_id: session.map().map_id().to_owned(),
            map_hash: session.stamp().map_hash.to_string(),
            ruleset_id: session.ruleset().ruleset_id().to_owned(),
            ruleset_hash: session.stamp().ruleset_hash.to_string(),
            actor_player_id: session.actor().as_str().to_owned(),
            segments,
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
            map_id: session.map().map_id().to_owned(),
            map_hash: session.stamp().map_hash.to_string(),
            ruleset_id: session.ruleset().ruleset_id().to_owned(),
            ruleset_hash: session.stamp().ruleset_hash.to_string(),
            actor_player_id: session.actor().as_str().to_owned(),
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
    ) -> Result<SessionStamp, PersistenceError> {
        let save = SaveGameDto::from_json(input).map_err(PersistenceError::Codec)?;
        validate_save_header(&save, &map, &ruleset)?;
        let state = decode_game_state(save.state).map_err(PersistenceError::State)?;
        if GameEngine::state_digest(&state).to_string() != save.state_digest {
            return Err(PersistenceError::StateDigestMismatch);
        }
        let actor = PlayerId::new(save.actor_player_id).map_err(PersistenceError::InvalidActor)?;
        let request = OpenSession::from_state(map, ruleset, state, actor)
            .with_event_offset(save.event_offset);
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
    ) -> Result<ReplayVerification, PersistenceError> {
        verify_replay(map, ruleset, input)
    }
}

pub(crate) fn replay_entry(
    session: &Session,
    record: ReplayRecordDto,
    before: ReplayContextDto,
    result: &CommandResult,
) -> ReplayEntryDto {
    ReplayEntryDto {
        index: u64::try_from(session.replay().current_entry_count())
            .expect("bounded replay entry count fits u64"),
        context: before,
        record,
        result: replay_result(result, session),
    }
}

pub(crate) fn replay_context(session: &Session, actor: Option<&PlayerId>) -> ReplayContextDto {
    let stamp = session.stamp();
    ReplayContextDto {
        actor_player_id: actor.map(|player| player.as_str().to_owned()),
        map_hash: stamp.map_hash.to_string(),
        ruleset_hash: stamp.ruleset_hash.to_string(),
        state_digest: stamp.state_digest.to_string(),
        event_offset: session.event_offset(),
    }
}

fn replay_result(result: &CommandResult, session: &Session) -> ReplayResultDto {
    ReplayResultDto {
        accepted: result.is_accepted(),
        rejection: result.rejection.map(|code| code.as_str().to_owned()),
        revision: result.stamp.revision.get(),
        state_digest: result.stamp.state_digest.to_string(),
        events: result.events.iter().map(encode_event).collect(),
        evidence: result.evidence.as_ref().map(encode_evidence),
        event_offset: session.event_offset(),
    }
}

enum ReplayRuntimeCommand {
    SelectTechnology(SelectTechnologyRequest),
    Diplomacy(DiplomacyRequest),
    Artifact(ArtifactCommandRequest),
    FoundCity(FoundCityRequest),
    ToggleWorkedHex(ToggleWorkedHexRequest),
    SelectCityExpansionHex(SelectCityExpansionHexRequest),
    Production(ProductionCommandRequest),
    SelectWorkerImprovement(WorkerImprovementRequest),
    ConfirmWorkerImprovement(WorkerImprovementRequest),
    CancelWorkerJob(WorkerUnitRequest),
    AssignWorkerToHex(WorkerUnitRequest),
    CancelWorkerAssignment(WorkerUnitRequest),
    BuildRoad(WorkerUnitRequest),
    AutomateWorker(WorkerUnitRequest),
    Attack(AttackHexRequest),
    Move(MoveUnitRequest),
    AutoExplore(AutoExploreUnitRequest),
    AssignMerchantRoute(MerchantCityRequest),
    MoveMerchantToCity(MerchantCityRequest),
    DetachTroop(DetachTroopRequest),
    Cancel(UnitActionRequest),
    Skip(UnitActionRequest),
    Fortify(UnitActionRequest),
    EndTurn(TurnCommandRequest),
    SubmitTurn(TurnCommandRequest),
    FinalizeTimedOutTurn(FinalizeTimedOutTurnRequest),
    KickParticipant(KickParticipantRequest),
}

fn decode_record(record: &ReplayRecordDto) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match record {
        ReplayRecordDto::Player { command } => decode_command(command),
        ReplayRecordDto::System { command } => decode_system_command(command),
    }
}

fn decode_found_city(
    expected_revision: u64,
    founder_unit_id: &str,
    controlled_hexes: &[CoordinateDto],
) -> Result<FoundCityRequest, PersistenceError> {
    Ok(FoundCityRequest {
        expected_revision,
        founder_unit_id: UnitId::new(founder_unit_id.to_owned())
            .map_err(PersistenceError::InvalidUnit)?,
        controlled_hexes: controlled_hexes
            .iter()
            .map(|coordinate| aonw_domain::HexCoord::new(coordinate.col, coordinate.row))
            .collect(),
    })
}

fn decode_toggle_worked_hex(
    expected_revision: u64,
    city_id: &str,
    target: CoordinateDto,
) -> Result<ToggleWorkedHexRequest, PersistenceError> {
    Ok(ToggleWorkedHexRequest {
        expected_revision,
        city_id: CityId::new(city_id.to_owned()).map_err(PersistenceError::InvalidCity)?,
        target: aonw_domain::HexCoord::new(target.col, target.row),
    })
}

fn decode_select_city_expansion_hex(
    expected_revision: u64,
    city_id: &str,
    target: CoordinateDto,
) -> Result<SelectCityExpansionHexRequest, PersistenceError> {
    Ok(SelectCityExpansionHexRequest {
        expected_revision,
        city_id: CityId::new(city_id.to_owned()).map_err(PersistenceError::InvalidCity)?,
        target: aonw_domain::HexCoord::new(target.col, target.row),
    })
}

fn decode_system_command(
    command: &ReplaySystemCommandDto,
) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match command {
        ReplaySystemCommandDto::FinalizeTimedOutTurn {
            expected_revision,
            player_ids,
            skipped_player_ids,
            next_turn_started_at,
        } => Ok(ReplayRuntimeCommand::FinalizeTimedOutTurn(
            FinalizeTimedOutTurnRequest {
                expected_revision: *expected_revision,
                player_ids: decode_player_ids(player_ids)?.into_boxed_slice(),
                skipped_player_ids: decode_player_ids(skipped_player_ids)?.into_boxed_slice(),
                next_turn_started_at: next_turn_started_at
                    .as_ref()
                    .map(|value| UtcTimestamp::new(value.clone()))
                    .transpose()
                    .map_err(|error| PersistenceError::InvalidTurnTime(error.into()))?,
            },
        )),
        ReplaySystemCommandDto::KickParticipant {
            expected_revision,
            player_id,
            reason,
            timeout_streak,
        } => Ok(ReplayRuntimeCommand::KickParticipant(
            KickParticipantRequest {
                expected_revision: *expected_revision,
                player_id: PlayerId::new(player_id.clone())
                    .map_err(PersistenceError::InvalidActor)?,
                reason: reason.clone().into_boxed_str(),
                timeout_streak: *timeout_streak,
            },
        )),
    }
}

fn decode_player_ids(values: &[String]) -> Result<Vec<PlayerId>, PersistenceError> {
    values
        .iter()
        .cloned()
        .map(PlayerId::new)
        .map(|result| result.map_err(PersistenceError::InvalidActor))
        .collect()
}

fn decode_unit_action(
    expected_revision: u64,
    unit_id: &str,
) -> Result<UnitActionRequest, PersistenceError> {
    Ok(UnitActionRequest {
        expected_revision,
        unit_id: UnitId::new(unit_id.to_owned()).map_err(PersistenceError::InvalidUnit)?,
    })
}

fn decode_worker_unit(
    expected_revision: u64,
    unit_id: &str,
) -> Result<WorkerUnitRequest, PersistenceError> {
    Ok(WorkerUnitRequest {
        expected_revision,
        unit_id: UnitId::new(unit_id.to_owned()).map_err(PersistenceError::InvalidUnit)?,
    })
}

fn decode_merchant_city(
    expected_revision: u64,
    unit_id: &str,
    destination_city_id: &str,
) -> Result<MerchantCityRequest, PersistenceError> {
    Ok(MerchantCityRequest {
        expected_revision,
        unit_id: UnitId::new(unit_id.to_owned()).map_err(PersistenceError::InvalidUnit)?,
        destination_city_id: CityId::new(destination_city_id.to_owned())
            .map_err(PersistenceError::InvalidCity)?,
    })
}
