use serde::{Deserialize, Serialize};

use crate::{CoordinateDto, FieldImprovementKindDto, UnitKindDto, UnitPostureDto};

use super::MapViewDto;

/// One current client protocol response.
#[derive(Clone, Debug, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientResponseDto {
    /// Client protocol version.
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
        /// Deterministic simulation behavior version.
        behavior_version: u16,
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
        result: ClientCommandResultDto,
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
    /// Save export and restore.
    SaveGame,
    /// Replay export and verification.
    ReplayVerification,
}

/// Identity metadata returned with state-dependent results.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientSessionStampDto {
    /// Deterministic simulation behavior version.
    pub behavior_version: u16,
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
    /// Action currently awaiting input from this recipient.
    pub pending_action: Option<PendingActionViewDto>,
    /// Units currently visible to the recipient.
    pub units: Vec<PlayerUnitViewDto>,
}

/// Recipient-owned action awaiting player input.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum PendingActionViewDto {
    ResearchSelection,
    CityWorkedHexSelection {
        city_id: String,
    },
    CityExpansionSelection {
        city_id: String,
    },
    WorkerActionSelection {
        unit_id: String,
        improvement: Option<FieldImprovementKindDto>,
    },
    MerchantTradeRouteSelection {
        unit_id: String,
    },
    MerchantMoveToCitySelection {
        unit_id: String,
    },
    UnitTurnSkip {
        unit_id: String,
        restore_movement_units: u32,
    },
    AttackTargeting {
        unit_id: String,
        defender: Option<CoordinateDto>,
    },
    CommanderMergeSelection {
        unit_id: String,
    },
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
}

/// Recipient-safe view update produced by one command.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct PlayerViewPatchDto {
    /// Revision to which the patch applies.
    pub from_revision: u64,
    /// Revision represented after the patch.
    pub to_revision: u64,
    /// New or changed visible units.
    pub upserted_units: Vec<PlayerUnitViewDto>,
    /// Units no longer visible.
    pub removed_unit_ids: Vec<String>,
    /// Current action awaiting input from this recipient.
    pub pending_action: Option<PendingActionViewDto>,
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

/// Closed set of stable authoritative command rejection codes.
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ClientCommandRejectionCodeDto {
    /// Command was planned against another canonical revision.
    StaleRevision,
    /// The requested unit does not exist.
    UnitNotFound,
    /// The actor cannot command the requested unit.
    UnitNotControlled,
    /// Current activity prevents manual movement.
    UnitUnavailable,
    /// The unit is controlled by the trade-route subsystem.
    UnitUsesTradeRoutes,
    /// The canonical unit position is outside the map.
    UnitOutOfBounds,
    /// The movement target is outside the map.
    MoveTargetOutOfBounds,
    /// The movement target equals the current unit position.
    MoveTargetIsCurrentTile,
    /// A known foreign city blocks the target.
    MoveTargetIsForeignCityCenter,
    /// A known foreign unit blocks the target.
    MoveTargetOccupied,
    /// The unit cannot pay the minimum movement cost.
    UnitMovementCapacityInsufficient,
    /// No valid route reaches the target.
    MovePathNotFound,
    /// The unit has an activity that prevents the requested action.
    UnitBusy,
    /// The ruleset lacks the requested unit definition.
    UnitDefinitionMissing,
    /// The next canonical revision cannot be represented.
    StateRevisionOverflow,
    /// A queued movement path violates its invariants.
    InvalidQueuedMovementPath,
    /// An engine-produced unit violates its invariants.
    InvalidUnit,
    /// The validated movement unit disappeared during transition construction.
    MovementUnitUpdateFailed,
}

impl ClientCommandRejectionCodeDto {
    /// Every code supported by the current client protocol.
    pub const ALL: [Self; 18] = [
        Self::StaleRevision,
        Self::UnitNotFound,
        Self::UnitNotControlled,
        Self::UnitUnavailable,
        Self::UnitUsesTradeRoutes,
        Self::UnitOutOfBounds,
        Self::MoveTargetOutOfBounds,
        Self::MoveTargetIsCurrentTile,
        Self::MoveTargetIsForeignCityCenter,
        Self::MoveTargetOccupied,
        Self::UnitMovementCapacityInsufficient,
        Self::MovePathNotFound,
        Self::UnitBusy,
        Self::UnitDefinitionMissing,
        Self::StateRevisionOverflow,
        Self::InvalidQueuedMovementPath,
        Self::InvalidUnit,
        Self::MovementUnitUpdateFailed,
    ];

    /// Returns the stable snake-case wire value.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::StaleRevision => "stale_revision",
            Self::UnitNotFound => "unit_not_found",
            Self::UnitNotControlled => "unit_not_controlled",
            Self::UnitUnavailable => "unit_unavailable",
            Self::UnitUsesTradeRoutes => "unit_uses_trade_routes",
            Self::UnitOutOfBounds => "unit_out_of_bounds",
            Self::MoveTargetOutOfBounds => "move_target_out_of_bounds",
            Self::MoveTargetIsCurrentTile => "move_target_is_current_tile",
            Self::MoveTargetIsForeignCityCenter => "move_target_is_foreign_city_center",
            Self::MoveTargetOccupied => "move_target_occupied",
            Self::UnitMovementCapacityInsufficient => "unit_movement_capacity_insufficient",
            Self::MovePathNotFound => "move_path_not_found",
            Self::UnitBusy => "unit_busy",
            Self::UnitDefinitionMissing => "unit_definition_missing",
            Self::StateRevisionOverflow => "state_revision_overflow",
            Self::InvalidQueuedMovementPath => "invalid_queued_movement_path",
            Self::InvalidUnit => "invalid_unit",
            Self::MovementUnitUpdateFailed => "movement_unit_update_failed",
        }
    }
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

/// Presentation-safe authoritative event.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientEventDto {
    /// One visible unit changed map position.
    UnitMoved {
        /// Moved unit.
        unit_id: String,
        /// Previous coordinate.
        from: CoordinateDto,
        /// New coordinate.
        to: CoordinateDto,
    },
}

/// Exact client-visible execution evidence.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientEvidenceDto {
    /// Exact executed movement prefix.
    UnitMovement {
        /// Moved unit.
        unit_id: String,
        /// Position before execution.
        from: CoordinateDto,
        /// Executed steps excluding the origin.
        steps: Vec<MovementStepViewDto>,
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

/// Recipient-safe query result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientQueryResultDto {
    /// Current-turn reachable overlay.
    Reachable {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried unit.
        unit_id: String,
        /// Movement available at query time.
        available_movement_units: u32,
        /// Stable row-major reachable tiles.
        tiles: Vec<ReachableTileViewDto>,
    },
    /// Deterministic route preview.
    RoutePlan {
        /// Identity of the queried state.
        stamp: ClientSessionStampDto,
        /// Queried unit.
        unit_id: String,
        /// Requested target.
        target: CoordinateDto,
        /// Planned destination.
        destination: CoordinateDto,
        /// Fixed-point total route cost.
        total_cost_units: u32,
        /// Movement available at query time.
        available_movement_units: u32,
        /// Movement remaining after the executable prefix.
        remaining_movement_units: u32,
        /// Ordered route including the origin.
        steps: Vec<MovementStepViewDto>,
    },
}

/// One current-turn reachable map tile.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ReachableTileViewDto {
    /// Tile coordinate.
    pub coordinate: CoordinateDto,
    /// Fixed-point route cost.
    pub cost_units: u32,
    /// Whether entry consumes remaining current-turn movement.
    pub exhausts_movement: bool,
}

/// Replay verification summary returned to a client.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientReplayVerificationDto {
    /// Number of verified commands.
    pub entry_count: u64,
    /// Final event offset.
    pub final_event_offset: u64,
    /// Final authoritative identity.
    pub final_stamp: ClientSessionStampDto,
}

/// Stable client failure independent of transport details.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ClientErrorDto {
    /// Stable machine-readable code.
    pub code: String,
    /// Human-readable diagnostic message.
    pub message: String,
}
