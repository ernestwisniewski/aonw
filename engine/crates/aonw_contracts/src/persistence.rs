use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, GameStateDto, MovementStepDto};

/// Maximum accepted encoded save document.
pub const MAX_SAVE_GAME_JSON_BYTES: usize = 16 * 1024 * 1024;
/// Maximum accepted encoded replay document.
pub const MAX_REPLAY_LOG_JSON_BYTES: usize = 64 * 1024 * 1024;
/// Maximum commands retained in one replay segment.
pub const MAX_REPLAY_ENTRY_COUNT: usize = 512;

/// Complete canonical save envelope.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct SaveGameDto {
    /// Logical map identifier.
    pub map_id: String,
    /// SHA-256 identity of canonical map content.
    pub map_hash: String,
    /// Ruleset identifier.
    pub ruleset_id: String,
    /// SHA-256 identity of immutable rules.
    pub ruleset_hash: String,
    /// Local player whose recipient view is opened.
    pub actor_player_id: String,
    /// Number of authoritative events preceding this snapshot.
    pub event_offset: u64,
    /// Digest of the complete canonical state.
    pub state_digest: String,
    /// Complete canonical game state.
    pub state: GameStateDto,
}

/// One revision-bound command stored in a replay.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayCommandDto {
    /// Manual movement command.
    MoveUnit {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
        /// Requested movement target.
        target: CoordinateDto,
    },
    /// Clears all cancellable orders owned by one unit.
    CancelUnitAction {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
    },
    /// Consumes one unit's movement for the current turn.
    SkipUnitTurn {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
    },
    /// Fortifies one idle unit.
    FortifyUnit {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
    },
    /// Completes one sequential participant turn.
    EndTurn {
        /// Expected canonical revision.
        expected_revision: u64,
    },
    /// Marks one simultaneous participant ready.
    SubmitTurn {
        /// Expected canonical revision.
        expected_revision: u64,
    },
}

/// Trusted host commands stored separately from player-authored requests.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplaySystemCommandDto {
    /// Finalizes one expired simultaneous turn.
    FinalizeTimedOutTurn {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Ordered participant scope selected by the host.
        player_ids: Vec<String>,
        /// Ordered participants finalized because of timeout.
        skipped_player_ids: Vec<String>,
        /// Explicit host-provided next-turn UTC time when rule-relevant.
        next_turn_started_at: Option<String>,
    },
    /// Removes one participant from the active match lifecycle.
    KickParticipant {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Participant selected by the host.
        player_id: String,
        /// Stable host-owned reason.
        reason: String,
        /// Timeout streak observed by the host.
        timeout_streak: i64,
    },
}

/// Closed replay record boundary distinguishing player and trusted system input.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "recordKind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayRecordDto {
    /// Authenticated player-authored command.
    Player {
        /// Closed player command payload.
        command: ReplayCommandDto,
    },
    /// Host/scheduler-authored command unavailable to player endpoints.
    System {
        /// Closed trusted command payload.
        command: ReplaySystemCommandDto,
    },
}

/// Trusted command context recorded before execution.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayContextDto {
    /// Authenticated actor for player records; absent for trusted system records.
    pub actor_player_id: Option<String>,
    /// Exact canonical map identity.
    pub map_hash: String,
    /// Exact immutable ruleset identity.
    pub ruleset_hash: String,
    /// State digest before execution.
    pub state_digest: String,
    /// Event offset before execution.
    pub event_offset: u64,
}

/// Ordered authoritative event stored in a replay result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayEventDto {
    /// One unit changed map position.
    UnitMoved {
        /// Moved unit.
        unit_id: String,
        /// Previous coordinate.
        from: CoordinateDto,
        /// New coordinate.
        to: CoordinateDto,
    },
    /// One participant completed a sequential turn.
    TurnEnded {
        /// Participant identity.
        player_id: String,
    },
    /// Every required participant submitted the simultaneous turn.
    AllPlayersSubmitted {
        /// Finalized turn number.
        turn: u32,
        /// Canonically ordered participant identities.
        player_ids: Vec<String>,
    },
    /// Trusted timeout fact.
    PlayerTimedOut {
        /// Timed-out turn.
        turn: u32,
        /// Timed-out participant.
        player_id: String,
    },
    /// Trusted participant-removal fact.
    PlayerKicked {
        /// Current turn.
        turn: u32,
        /// Removed participant.
        player_id: String,
        /// Stable host-owned reason.
        reason: String,
        /// Timeout streak observed by the host.
        timeout_streak: i64,
    },
}

/// Exact execution evidence stored in a replay result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayEvidenceDto {
    /// Executed movement prefix.
    UnitMovement {
        /// Moved unit.
        unit_id: String,
        /// Position before execution.
        from: CoordinateDto,
        /// Exact executed movement steps.
        steps: Vec<MovementStepDto>,
    },
    /// Exact partial turn pipeline that executed.
    TurnKernel {
        /// Processor names in execution order.
        processors: Vec<String>,
        /// Units whose movement phase began, in canonical unit order.
        reset_unit_ids: Vec<String>,
    },
}

/// Deterministic outcome expected after replaying one command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayResultDto {
    /// Whether the command was accepted.
    pub accepted: bool,
    /// Stable rejection code when not accepted.
    pub rejection: Option<String>,
    /// Canonical revision after execution.
    pub revision: u64,
    /// Canonical state digest after execution.
    pub state_digest: String,
    /// Ordered authoritative events.
    pub events: Vec<ReplayEventDto>,
    /// Exact execution evidence when produced.
    pub evidence: Option<ReplayEvidenceDto>,
    /// Event offset after execution.
    pub event_offset: u64,
}

/// One deterministic replay step.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayEntryDto {
    /// Zero-based index within this replay segment.
    pub index: u64,
    /// Complete trusted context before execution.
    pub context: ReplayContextDto,
    /// Explicit player or trusted system record.
    pub record: ReplayRecordDto,
    /// Exact authoritative result.
    pub result: ReplayResultDto,
}

/// Deterministic replay segment beginning at one canonical snapshot.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReplayLogDto {
    /// Logical map identifier.
    pub map_id: String,
    /// SHA-256 identity of canonical map content.
    pub map_hash: String,
    /// Ruleset identifier.
    pub ruleset_id: String,
    /// SHA-256 identity of immutable rules.
    pub ruleset_hash: String,
    /// Actor used by every recorded context.
    pub actor_player_id: String,
    /// Event offset at the segment start.
    pub initial_event_offset: u64,
    /// Digest of the initial canonical state.
    pub initial_state_digest: String,
    /// Complete initial canonical state.
    pub initial_state: GameStateDto,
    /// Commands and exact expected outcomes.
    pub entries: Vec<ReplayEntryDto>,
}

/// Strict save or replay codec failure.
#[derive(Debug)]
pub enum PersistenceCodecError {
    /// Input exceeds its contract byte boundary.
    TooLarge {
        /// Actual input size.
        actual: usize,
        /// Maximum accepted size.
        maximum: usize,
    },
    /// Replay contains too many commands.
    TooManyReplayEntries {
        /// Actual command count.
        actual: usize,
        /// Maximum accepted command count.
        maximum: usize,
    },
    /// JSON violates the strict DTO contract.
    Json(serde_json::Error),
}

impl core::fmt::Display for PersistenceCodecError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TooLarge { actual, maximum } => {
                write!(
                    formatter,
                    "document is {actual} bytes; maximum is {maximum}"
                )
            }
            Self::TooManyReplayEntries { actual, maximum } => write!(
                formatter,
                "replay has {actual} entries; maximum is {maximum}"
            ),
            Self::Json(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for PersistenceCodecError {}

impl SaveGameDto {
    /// Parses a bounded strict save document.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid input.
    pub fn from_json(input: &str) -> Result<Self, PersistenceCodecError> {
        parse_bounded(input, MAX_SAVE_GAME_JSON_BYTES)
    }

    /// Serializes compact save JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails.
    pub fn to_json(&self) -> Result<String, PersistenceCodecError> {
        serialize_bounded(self, MAX_SAVE_GAME_JSON_BYTES)
    }
}

impl ReplayLogDto {
    /// Parses a bounded strict replay document.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized, structurally invalid, or unbounded input.
    pub fn from_json(input: &str) -> Result<Self, PersistenceCodecError> {
        let replay: Self = parse_bounded(input, MAX_REPLAY_LOG_JSON_BYTES)?;
        if replay.entries.len() > MAX_REPLAY_ENTRY_COUNT {
            return Err(PersistenceCodecError::TooManyReplayEntries {
                actual: replay.entries.len(),
                maximum: MAX_REPLAY_ENTRY_COUNT,
            });
        }
        Ok(replay)
    }

    /// Serializes compact replay JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails.
    pub fn to_json(&self) -> Result<String, PersistenceCodecError> {
        if self.entries.len() > MAX_REPLAY_ENTRY_COUNT {
            return Err(PersistenceCodecError::TooManyReplayEntries {
                actual: self.entries.len(),
                maximum: MAX_REPLAY_ENTRY_COUNT,
            });
        }
        serialize_bounded(self, MAX_REPLAY_LOG_JSON_BYTES)
    }
}

fn parse_bounded<T>(input: &str, maximum: usize) -> Result<T, PersistenceCodecError>
where
    T: for<'input> Deserialize<'input>,
{
    if input.len() > maximum {
        return Err(PersistenceCodecError::TooLarge {
            actual: input.len(),
            maximum,
        });
    }
    serde_json::from_str(input).map_err(PersistenceCodecError::Json)
}

fn serialize_bounded<T>(value: &T, maximum: usize) -> Result<String, PersistenceCodecError>
where
    T: Serialize,
{
    let output = serde_json::to_string(value).map_err(PersistenceCodecError::Json)?;
    if output.len() > maximum {
        return Err(PersistenceCodecError::TooLarge {
            actual: output.len(),
            maximum,
        });
    }
    Ok(output)
}

#[cfg(test)]
mod tests {
    use super::{MAX_SAVE_GAME_JSON_BYTES, ReplayCommandDto, ReplayLogDto, SaveGameDto};

    #[test]
    fn strict_save_codec_rejects_unknown_duplicate_and_oversized_input() {
        let base = r#"{"mapId":"m","mapHash":"h","rulesetId":"r","rulesetHash":"h","actorPlayerId":"p","eventOffset":0,"stateDigest":"d","state":{"revision":0,"turn":0,"matchIdentity":{"matchRules":{"gameLength":{"kind":"unlimited","targetMinutes":null,"turnLimit":null,"paceProfile":"unlimited","scoreFallbackEnabled":false},"victory":{"conquestEnabled":true,"dominationEnabled":true,"dominationControlPercent":60,"dominationHoldTurns":5,"scoreFallbackEnabled":false,"turnLimit":null,"hardTimeLimitMinutes":null,"culturalEnabled":true,"culturalRequiredArtifacts":6,"culturalHoldTurns":5},"balance":{}},"participants":[],"gameMode":"hotSeat"},"turnLifecycle":{"turnStatesByPlayerId":{},"requiredSubmissionPlayerIds":[],"submittedPlayerIds":[],"timeoutStreaksByPlayerId":{},"afkPlayerIds":[],"kickedPlayerIds":[],"turnStartedAt":null},"economy":{"playerGold":{},"playerWarWeariness":{},"playerStabilityNet":{},"strategicResources":{},"initialResourceDistribution":{"seed":0,"placements":[]}},"research":{"players":{}},"wonderRegistry":{},"intendedAttacks":[],"cols":1,"rows":1,"occupancyPolicy":"exclusive","units":[],"cities":[],"artifacts":[],"fieldImprovements":[],"interaction":{"cityFoundingDraft":null,"pending":null},"fogOfWar":[],"diplomacy":{"contacts":[],"relations":[],"pendingProposals":[],"messages":[],"scoreHistory":[]},"resourceTradeAgreements":[],"dominationHoldTurnsByPlayerId":{},"culturalVictoryHoldTurnsByPlayerId":{},"mapObjectiveHoldStates":[],"transportNetwork":[]}}"#;
        assert!(SaveGameDto::from_json(base).is_ok());
        let unknown = base.replacen("\"state\":", "\"extra\":true,\"state\":", 1);
        assert!(SaveGameDto::from_json(&unknown).is_err());
        let duplicate = base.replacen("\"mapId\":\"m\",", "\"mapId\":\"m\",\"mapId\":\"m\",", 1);
        assert!(SaveGameDto::from_json(&duplicate).is_err());
        assert!(SaveGameDto::from_json(&"x".repeat(MAX_SAVE_GAME_JSON_BYTES + 1)).is_err());
    }

    #[test]
    fn strict_replay_codec_rejects_unknown_and_duplicate_fields() {
        let base = r#"{"mapId":"m","mapHash":"h","rulesetId":"r","rulesetHash":"h","actorPlayerId":"p","initialEventOffset":0,"initialStateDigest":"d","initialState":{"revision":0,"turn":0,"matchIdentity":{"matchRules":{"gameLength":{"kind":"unlimited","targetMinutes":null,"turnLimit":null,"paceProfile":"unlimited","scoreFallbackEnabled":false},"victory":{"conquestEnabled":true,"dominationEnabled":true,"dominationControlPercent":60,"dominationHoldTurns":5,"scoreFallbackEnabled":false,"turnLimit":null,"hardTimeLimitMinutes":null,"culturalEnabled":true,"culturalRequiredArtifacts":6,"culturalHoldTurns":5},"balance":{}},"participants":[],"gameMode":"hotSeat"},"turnLifecycle":{"turnStatesByPlayerId":{},"requiredSubmissionPlayerIds":[],"submittedPlayerIds":[],"timeoutStreaksByPlayerId":{},"afkPlayerIds":[],"kickedPlayerIds":[],"turnStartedAt":null},"economy":{"playerGold":{},"playerWarWeariness":{},"playerStabilityNet":{},"strategicResources":{},"initialResourceDistribution":{"seed":0,"placements":[]}},"research":{"players":{}},"wonderRegistry":{},"intendedAttacks":[],"cols":1,"rows":1,"occupancyPolicy":"exclusive","units":[],"cities":[],"artifacts":[],"fieldImprovements":[],"interaction":{"cityFoundingDraft":null,"pending":null},"fogOfWar":[],"diplomacy":{"contacts":[],"relations":[],"pendingProposals":[],"messages":[],"scoreHistory":[]},"resourceTradeAgreements":[],"dominationHoldTurnsByPlayerId":{},"culturalVictoryHoldTurnsByPlayerId":{},"mapObjectiveHoldStates":[],"transportNetwork":[]},"entries":[]}"#;
        assert!(ReplayLogDto::from_json(base).is_ok());
        let unknown = base.replacen("\"entries\":", "\"extra\":true,\"entries\":", 1);
        assert!(ReplayLogDto::from_json(&unknown).is_err());
        let duplicate = base.replacen("\"mapId\":\"m\",", "\"mapId\":\"m\",\"mapId\":\"m\",", 1);
        assert!(ReplayLogDto::from_json(&duplicate).is_err());
    }

    #[test]
    fn every_current_unit_action_command_has_a_strict_wire_shape() {
        for kind in ["cancelUnitAction", "skipUnitTurn", "fortifyUnit"] {
            let json = format!(r#"{{"type":"{kind}","expectedRevision":7,"unitId":"unit-1"}}"#);
            assert!(serde_json::from_str::<ReplayCommandDto>(&json).is_ok());
            let unknown = json.replacen('}', ",\"unknown\":true}", 1);
            assert!(serde_json::from_str::<ReplayCommandDto>(&unknown).is_err());
        }
    }
}
