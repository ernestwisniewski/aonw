use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contract_mapping::{decode_game_state, decode_troop, encode_game_state};
use aonw_contracts::{
    MAX_REPLAY_ENTRY_COUNT, ReplayCommandDto, ReplayContextDto, ReplayEntryDto, ReplayLogDto,
    ReplayRecordDto, ReplayResultDto, ReplaySystemCommandDto, SaveGameDto,
};
use aonw_domain::{CityId, PlayerId, UnitId, UtcTimestamp};
use aonw_engine::GameEngine;

pub use crate::persistence_error::PersistenceError;
use crate::persistence_validation::{validate_replay_header, validate_save_header};
use crate::session::Session;
use crate::{
    AutoExploreUnitRequest, CommandResult, DetachTroopRequest, FinalizeTimedOutTurnRequest,
    KickParticipantRequest, LocalRuntime, MerchantCityRequest, MoveUnitRequest, OpenSession,
    SessionStamp, TurnCommandRequest, UnitActionRequest,
};

mod evidence;

use evidence::{encode_event, encode_evidence};

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
    initial_state: aonw_contracts::GameStateDto,
    initial_state_digest: String,
    initial_event_offset: u64,
    entries: Vec<ReplayEntryDto>,
}

impl ReplayRecorder {
    pub(crate) fn new(
        state: &aonw_domain::GameState,
        digest: aonw_engine::StateDigest,
        event_offset: u64,
    ) -> Self {
        Self {
            initial_state: encode_game_state(state),
            initial_state_digest: digest.to_string(),
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
            map_id: session.map().map_id().to_owned(),
            map_hash: session.stamp().map_hash.to_string(),
            ruleset_id: session.ruleset().ruleset_id().to_owned(),
            ruleset_hash: session.stamp().ruleset_hash.to_string(),
            actor_player_id: session.actor().as_str().to_owned(),
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
                OpenSession::from_state(map, ruleset, state, actor)
                    .with_event_offset(replay.initial_event_offset),
            )
            .map_err(PersistenceError::Open)?;

        for (entry_index, entry) in replay.entries.iter().enumerate() {
            let expected_index =
                u64::try_from(entry_index).map_err(|_| PersistenceError::ReplayIndexOverflow)?;
            if entry.index != expected_index {
                return Err(PersistenceError::ReplayIndexMismatch {
                    expected: expected_index,
                    found: entry.index,
                });
            }
            let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
            let actor = match &entry.record {
                ReplayRecordDto::Player { .. } => Some(session.actor()),
                ReplayRecordDto::System { .. } => None,
            };
            if entry.context != replay_context(session, actor) {
                return Err(PersistenceError::ReplayContextMismatch { entry: entry_index });
            }
            let result = match decode_record(&entry.record)? {
                ReplayRuntimeCommand::Move(command) => runtime.dispatch(&command),
                ReplayRuntimeCommand::AutoExplore(command) => runtime.auto_explore_unit(&command),
                ReplayRuntimeCommand::AssignMerchantRoute(command) => {
                    runtime.assign_merchant_trade_route(&command)
                }
                ReplayRuntimeCommand::MoveMerchantToCity(command) => {
                    runtime.move_merchant_to_city(&command)
                }
                ReplayRuntimeCommand::DetachTroop(command) => runtime.detach_troop(&command),
                ReplayRuntimeCommand::Cancel(command) => runtime.cancel_unit_action(&command),
                ReplayRuntimeCommand::Skip(command) => runtime.skip_unit_turn(&command),
                ReplayRuntimeCommand::Fortify(command) => runtime.fortify_unit(&command),
                ReplayRuntimeCommand::EndTurn(command) => runtime.end_turn(command),
                ReplayRuntimeCommand::SubmitTurn(command) => runtime.submit_turn(command),
                ReplayRuntimeCommand::FinalizeTimedOutTurn(command) => {
                    runtime.finalize_timed_out_turn(&command)
                }
                ReplayRuntimeCommand::KickParticipant(command) => {
                    runtime.kick_participant(&command)
                }
            }
            .map_err(PersistenceError::Runtime)?;
            let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
            if entry.result != replay_result(&result, session) {
                return Err(PersistenceError::ReplayResultMismatch { entry: entry_index });
            }
        }
        let session = runtime.session_ref().map_err(PersistenceError::Runtime)?;
        Ok(ReplayVerification {
            entry_count: replay.entries.len(),
            final_stamp: session.stamp(),
            final_event_offset: session.event_offset(),
        })
    }
}

pub(crate) fn replay_entry(
    session: &Session,
    record: ReplayRecordDto,
    before: ReplayContextDto,
    result: &CommandResult,
) -> ReplayEntryDto {
    ReplayEntryDto {
        index: u64::try_from(session.replay().entries.len())
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

fn decode_command(command: &ReplayCommandDto) -> Result<ReplayRuntimeCommand, PersistenceError> {
    match command {
        ReplayCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => Ok(ReplayRuntimeCommand::Move(MoveUnitRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            target: aonw_domain::HexCoord::new(target.col, target.row),
        })),
        ReplayCommandDto::AutoExploreUnit {
            expected_revision,
            unit_id,
        } => Ok(ReplayRuntimeCommand::AutoExplore(AutoExploreUnitRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
        })),
        ReplayCommandDto::AssignMerchantTradeRoute {
            expected_revision,
            unit_id,
            destination_city_id,
        } => decode_merchant_city(*expected_revision, unit_id, destination_city_id)
            .map(ReplayRuntimeCommand::AssignMerchantRoute),
        ReplayCommandDto::MoveMerchantToCity {
            expected_revision,
            unit_id,
            destination_city_id,
        } => decode_merchant_city(*expected_revision, unit_id, destination_city_id)
            .map(ReplayRuntimeCommand::MoveMerchantToCity),
        ReplayCommandDto::DetachTroop {
            expected_revision,
            unit_id,
            troop_kind,
        } => Ok(ReplayRuntimeCommand::DetachTroop(DetachTroopRequest {
            expected_revision: *expected_revision,
            unit_id: UnitId::new(unit_id.clone()).map_err(PersistenceError::InvalidUnit)?,
            troop_kind: decode_troop(*troop_kind),
        })),
        ReplayCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Cancel),
        ReplayCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Skip),
        ReplayCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => decode_unit_action(*expected_revision, unit_id).map(ReplayRuntimeCommand::Fortify),
        ReplayCommandDto::EndTurn { expected_revision } => {
            Ok(ReplayRuntimeCommand::EndTurn(TurnCommandRequest {
                expected_revision: *expected_revision,
            }))
        }
        ReplayCommandDto::SubmitTurn { expected_revision } => {
            Ok(ReplayRuntimeCommand::SubmitTurn(TurnCommandRequest {
                expected_revision: *expected_revision,
            }))
        }
    }
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
