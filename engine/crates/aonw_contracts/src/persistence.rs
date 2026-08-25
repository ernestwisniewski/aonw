use serde::{Deserialize, Serialize};

use crate::client::{WorkerAutomationOptionDto, WorkerJobCompletionDto};
use crate::{
    CityBuildingTypeDto, CombatExecutionDto, CombatTargetDto, CoordinateDto, GameStateDto,
    MovementStepDto, TechnologyIdDto, TroopKindDto, UnitKindDto, WonderTypeDto,
};

mod codec;
mod command;
mod logistics;

pub use command::{ReplayCommandDto, ReplaySystemCommandDto};
pub use logistics::{ReplayLogisticsEvidenceDto, ReplayUnitMovementExecutionDto};

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
    /// One city-founding job completed.
    CityFounded {
        /// New city identity.
        city_id: String,
        /// Founding player.
        owner_player_id: String,
    },
    /// One city completed a building.
    CityBuiltBuilding {
        /// City that completed the building.
        city_id: String,
        /// Completed building kind.
        building_type: CityBuildingTypeDto,
    },
    /// One city produced a unit.
    CityProducedUnit {
        /// City that produced the unit.
        city_id: String,
        /// Produced unit kind.
        unit_type: UnitKindDto,
        /// New unit identity.
        produced_unit_id: String,
    },
    /// One city won a globally unique wonder race.
    CityBuiltWonder {
        /// City that completed the wonder.
        city_id: String,
        /// Player that owns the completed wonder.
        owner_player_id: String,
        /// Completed wonder kind.
        wonder_type: WonderTypeDto,
    },
    /// One losing wonder queue was converted to overflow.
    WonderProductionRefunded {
        /// City whose losing queue was cleared.
        city_id: String,
        /// Player that owns the refunded city.
        owner_player_id: String,
        /// Wonder kind lost in the global race.
        wonder_type: WonderTypeDto,
        /// Production returned to the city's overflow.
        refunded_production: i64,
    },
    /// A completion effect unlocked the selected technology.
    TechnologyResearched {
        /// Player that completed the technology.
        player_id: String,
        /// Completed technology identity.
        technology_id: TechnologyIdDto,
    },
    /// A visible attacker engaged a visible target.
    UnitAttacked {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
    },
    /// A visible attacker engaged a city.
    CityAttacked {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
    },
    /// Exact combat resolution occurred.
    CombatResolved {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
    },
    /// A known observer applied a city-attack reputation penalty.
    DiplomaticScoreChanged {
        /// Canonical first participant.
        player_a_id: String,
        /// Canonical second participant.
        player_b_id: String,
        /// Applied score delta.
        delta: i64,
        /// Score after the change.
        score_after: i64,
        /// Canonical reason.
        reason: crate::DiplomaticScoreChangeReasonDto,
        /// Deterministic source identity.
        source_id: Option<String>,
    },
    /// A combat participant gained experience.
    UnitGainedExperience {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
        /// Unit receiving experience.
        subject_unit_id: String,
    },
    /// A combat participant was removed.
    UnitKilled {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
        /// Unit removed by the resolution.
        subject_unit_id: String,
    },
    /// A defender retreated.
    UnitRetreated {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
        /// Unit that changed position.
        subject_unit_id: String,
    },
    /// A city changed owner.
    CityCaptured {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
    },
    /// A city was removed.
    CityDestroyed {
        /// Attacking unit identity.
        attacker_unit_id: String,
        /// Visible target identity.
        target: CombatTargetDto,
    },
    /// One unit changed map position.
    UnitMoved {
        /// Moved unit.
        unit_id: String,
        /// Previous coordinate.
        from: CoordinateDto,
        /// New coordinate.
        to: CoordinateDto,
    },
    /// A scout selected an exploration target.
    AutoExplorePlanned {
        /// Scout identity.
        unit_id: String,
        /// Selected target.
        target: CoordinateDto,
    },
    /// A cyclic merchant route was assigned.
    MerchantRouteAssigned {
        /// Merchant identity.
        unit_id: String,
        /// Route origin.
        origin_city_id: String,
        /// Route destination.
        destination_city_id: String,
    },
    /// Explicit merchant travel was queued.
    MerchantTravelQueued {
        /// Merchant identity.
        unit_id: String,
        /// Destination city.
        destination_city_id: String,
    },
    /// One army troop became an independent unit.
    TroopDetached {
        /// Source army unit.
        source_unit_id: String,
        /// New independent unit.
        detached_unit_id: String,
        /// Detached troop kind.
        troop_kind: TroopKindDto,
        /// Spawn coordinate.
        destination: CoordinateDto,
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
    /// One worker job completed successfully.
    WorkerCompletedJob {
        /// Worker identity before charge consumption.
        unit_id: String,
        /// Completed coordinate.
        target: CoordinateDto,
        /// Completed construction kind.
        completion: WorkerJobCompletionDto,
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
    /// Exact combat evidence.
    Combat {
        /// Exact combat execution.
        execution: CombatExecutionDto,
    },
    /// Executed movement prefix.
    UnitMovement {
        /// Moved unit.
        unit_id: String,
        /// Position before execution.
        from: CoordinateDto,
        /// Exact executed movement steps.
        steps: Vec<MovementStepDto>,
    },
    /// Exact auto-exploration, merchant, or detachment execution.
    Logistics {
        /// Typed logistics execution.
        execution: ReplayLogisticsEvidenceDto,
    },
    /// Exact partial turn pipeline that executed.
    TurnKernel {
        /// Processor names in execution order.
        processors: Vec<String>,
        /// Cities founded during the pipeline in canonical order.
        founded_city_ids: Vec<String>,
        /// Exact intended-attack resolutions in execution order.
        combat_executions: Vec<CombatExecutionDto>,
        /// Units whose movement phase began, in canonical unit order.
        reset_unit_ids: Vec<String>,
        /// Exact movements performed by turn processors.
        movement_executions: Vec<ReplayUnitMovementExecutionDto>,
        /// Units whose stored movement order became invalid.
        invalidated_order_unit_ids: Vec<String>,
        /// Scouts whose auto-exploration ended without another target.
        finished_auto_explore_unit_ids: Vec<String>,
    },
    /// Exact worker automation execution.
    WorkerAutomation {
        /// Worker receiving the command.
        unit_id: String,
        /// Selected action and deterministic counters.
        option: WorkerAutomationOptionDto,
        /// Executed movement prefix, when any.
        movement: Option<ReplayUnitMovementExecutionDto>,
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

#[cfg(test)]
mod tests;
