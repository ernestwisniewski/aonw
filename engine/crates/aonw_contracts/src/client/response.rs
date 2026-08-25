use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, PlayerTurnStateDto, UnitKindDto, UnitPostureDto};

use super::MapViewDto;

mod city;
mod event;
mod logistics;
mod query;
mod rejection;
mod session;
mod worker;

pub use city::{
    CityExpansionCandidateDto, CityFoundingDraftViewDto, OwnedCityPlanningViewDto,
    PlayerCityViewDto,
};
pub use event::ClientEventDto;
pub use logistics::{
    AutoExploreOptionDto, ClientLogisticsEvidenceDto, DetachmentOptionDto,
    MerchantDestinationOptionDto, MovementSearchMetricsDto, UnitMovementExecutionDto,
};
pub use query::{
    ClientEvidenceDto, ClientQueryResultDto, PendingActionViewDto, ReachableTileViewDto,
};
pub use rejection::ClientCommandRejectionCodeDto;
pub use session::{ClientErrorDto, ClientReplayVerificationDto};
pub use worker::{
    FieldImprovementViewDto, RoadViewDto, WorkerAutomationActionDto, WorkerAutomationMetricsDto,
    WorkerAutomationOptionDto, WorkerImprovementOptionDto, WorkerJobCompletionDto,
    WorkerJobViewDto,
};

/// One current client protocol response.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientResponseDto {
    /// Client protocol version shared by independently packaged adapters.
    pub api_version: u16,
    /// Successful result or stable failure.
    pub outcome: ClientOutcomeDto,
}

/// Result envelope shared by Godot and Flutter adapters.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "status",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientOutcomeDto {
    /// Operation completed successfully.
    Success {
        /// Operation-specific result.
        response: Box<ClientResponseBodyDto>,
    },
    /// Operation failed without exposing canonical state.
    Failure {
        /// Stable machine code and diagnostic message.
        error: ClientErrorDto,
    },
}

/// Successful local client results.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientResponseBodyDto {
    /// Supported engine behavior and client operations.
    Capabilities {
        /// Supported current protocol features.
        features: Vec<ClientFeatureDto>,
    },
    /// A strict authored map was projected for presentation.
    MapInspected {
        /// Validated framework-neutral map view.
        map: MapViewDto,
    },
    /// A local session was opened.
    SessionOpened {
        /// Current authoritative identity.
        stamp: ClientSessionStampDto,
    },
    /// The local session was closed.
    SessionClosed,
    /// Complete recipient-safe snapshot.
    Snapshot {
        /// Snapshot payload.
        snapshot: PlayerViewSnapshotDto,
    },
    /// Query result.
    Query {
        /// Query-specific payload.
        result: ClientQueryResultDto,
    },
    /// Authoritative command result.
    Command {
        /// Command-specific payload.
        result: Box<ClientCommandResultDto>,
    },
    /// Current save document.
    SaveExported {
        /// Strict save JSON.
        document: String,
    },
    /// A save was opened transactionally.
    SaveOpened {
        /// Current authoritative identity.
        stamp: ClientSessionStampDto,
    },
    /// Current replay document.
    ReplayExported {
        /// Strict replay JSON.
        document: String,
    },
    /// Replay verification completed.
    ReplayVerified {
        /// Verification summary.
        verification: ClientReplayVerificationDto,
    },
}

/// Stable client-visible feature identifiers.
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ClientFeatureDto {
    /// City founding, worked territory, expansion, and city projections.
    Cities,
    /// Combat preview and authoritative visible attacks.
    Combat,
    /// Stateless strict map inspection.
    InspectMap,
    /// Complete player snapshot.
    Snapshot,
    /// Reachable movement overlay.
    Reachable,
    /// Route planning.
    RoutePlan,
    /// Manual movement command.
    MoveUnit,
    /// Cancel, skip, and fortify commands.
    UnitActions,
    /// Capability-gated `EndTurn` and `SubmitTurn` kernel commands.
    TurnKernel,
    /// Save export and restore.
    SaveGame,
    /// Replay export and verification.
    ReplayVerification,
    /// Auto-exploration, merchant routing, and troop detachment.
    MovementLogistics,
    /// Worker improvements, assignments, roads, automation, and progression.
    Workers,
}

/// Identity metadata returned with state-dependent results.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientSessionStampDto {
    /// Current canonical revision.
    pub revision: u64,
    /// Digest of the complete canonical state.
    pub state_digest: String,
    /// Hash of immutable canonical map content.
    pub map_hash: String,
    /// Hash of immutable ruleset content.
    pub ruleset_hash: String,
}

/// Complete recipient-safe player snapshot.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerViewSnapshotDto {
    /// Identity of the represented state.
    pub stamp: ClientSessionStampDto,
    /// Authoritative turn number.
    pub turn: u32,
    /// Recipient-owned lifecycle status and aggregate submission progress.
    pub turn_lifecycle: PlayerTurnLifecycleViewDto,
    /// Action currently awaiting input from this recipient.
    pub pending_action: Option<PendingActionViewDto>,
    /// Recipient-owned city-founding workflow, when one is persisted.
    pub city_founding_draft: Option<CityFoundingDraftViewDto>,
    /// Units currently visible to the recipient.
    pub units: Vec<PlayerUnitViewDto>,
    /// Cities currently known to the recipient.
    pub cities: Vec<PlayerCityViewDto>,
    /// Field improvements currently known to the recipient.
    pub field_improvements: Vec<FieldImprovementViewDto>,
    /// Roads currently known to the recipient.
    pub roads: Vec<RoadViewDto>,
}

/// Recipient-safe lifecycle projection with no per-opponent readiness map.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerTurnLifecycleViewDto {
    /// Current lifecycle status of the recipient.
    pub own_state: Option<PlayerTurnStateDto>,
    /// Whether the recipient already submitted this turn.
    pub own_submitted: bool,
    /// Number of participants required to submit.
    pub required_submission_count: u32,
    /// Number of required submissions received, without participant identities.
    pub submitted_count: u32,
}

/// Recipient-safe unit read model.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerUnitViewDto {
    /// Unit identifier.
    pub id: String,
    /// Visible owning player.
    pub owner_player_id: String,
    /// Stable unit kind.
    pub kind: UnitKindDto,
    /// Authored display name.
    pub name: String,
    /// Current map coordinate.
    pub coordinate: CoordinateDto,
    /// Fixed-point movement balance.
    pub movement_units: u32,
    /// Persistent unit posture.
    pub posture: UnitPostureDto,
    /// Remaining improvement charges for workers.
    pub worker_build_charges: u32,
    /// Current worker construction, when visible.
    pub worker_job: Option<WorkerJobViewDto>,
    /// Current worker assignment, when visible.
    pub worker_assignment: Option<CoordinateDto>,
}

/// Recipient-safe view update produced by one command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerViewPatchDto {
    /// Revision to which the patch applies.
    pub from_revision: u64,
    /// Revision represented after the patch.
    pub to_revision: u64,
    /// Replacement lifecycle projection when turn/readiness changed.
    pub turn_lifecycle: Option<PlayerTurnLifecycleViewDto>,
    /// New or changed visible units.
    pub upserted_units: Vec<PlayerUnitViewDto>,
    /// Units no longer visible.
    pub removed_unit_ids: Vec<String>,
    /// New or changed recipient-safe cities.
    pub upserted_cities: Vec<PlayerCityViewDto>,
    /// Cities no longer known to the recipient.
    pub removed_city_ids: Vec<String>,
    /// New or changed known field improvements.
    pub upserted_field_improvements: Vec<FieldImprovementViewDto>,
    /// Field-improvement coordinates no longer known.
    pub removed_field_improvement_coordinates: Vec<CoordinateDto>,
    /// New or changed known roads.
    pub upserted_roads: Vec<RoadViewDto>,
    /// Road coordinates no longer known.
    pub removed_road_coordinates: Vec<CoordinateDto>,
    /// Current action awaiting input from this recipient.
    pub pending_action: Option<PendingActionViewDto>,
    /// Current recipient-owned founding workflow; null clears it.
    pub city_founding_draft: Option<CityFoundingDraftViewDto>,
}

/// Result of one authoritative command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientCommandResultDto {
    /// Identity of the resulting canonical state.
    pub stamp: ClientSessionStampDto,
    /// Accepted or rejected authoritative outcome.
    pub outcome: ClientCommandOutcomeDto,
    /// Ordered presentation-safe domain events.
    pub events: Vec<ClientEventDto>,
    /// Exact execution evidence when produced.
    pub evidence: Option<ClientEvidenceDto>,
    /// Recipient-safe state delta.
    pub view_patch: PlayerViewPatchDto,
}

/// Coherent authoritative command outcome.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "status",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientCommandOutcomeDto {
    /// The command was accepted.
    Accepted,
    /// The command was rejected without changing canonical state.
    Rejected {
        /// Stable language-neutral rejection code.
        code: ClientCommandRejectionCodeDto,
    },
}

/// One movement step exposed by a query or command result.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct MovementStepViewDto {
    /// Step coordinate.
    pub coordinate: CoordinateDto,
    /// Fixed-point entry cost.
    pub enter_cost_units: u32,
    /// Fixed-point cumulative cost.
    pub cumulative_cost_units: u32,
}
