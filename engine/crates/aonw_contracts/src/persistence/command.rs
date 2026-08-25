use serde::{Deserialize, Serialize};

use crate::{CityConquestActionDto, CoordinateDto, FieldImprovementKindDto, TroopKindDto};

/// One revision-bound command stored in a replay.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayCommandDto {
    /// Schedules a validated city-founding job.
    FoundCity {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled founder.
        founder_unit_id: String,
        /// Complete initial non-center territory.
        controlled_hexes: Vec<CoordinateDto>,
    },
    /// Toggles one manually worked city coordinate.
    ToggleWorkedHex {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
        /// Non-center controlled coordinate.
        target: CoordinateDto,
    },
    /// Selects one current city-expansion candidate.
    SelectCityExpansionHex {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Controlled city.
        city_id: String,
        /// Preferred expansion coordinate.
        target: CoordinateDto,
    },
    /// Starts one explicitly selected field improvement.
    SelectWorkerImprovement {
        expected_revision: u64,
        unit_id: String,
        improvement: FieldImprovementKindDto,
    },
    /// Confirms an explicit or matching pending field improvement.
    ConfirmWorkerImprovement {
        expected_revision: u64,
        unit_id: String,
        improvement: Option<FieldImprovementKindDto>,
    },
    /// Cancels current worker construction.
    CancelWorkerJob {
        expected_revision: u64,
        unit_id: String,
    },
    /// Assigns a worker to an improved coordinate.
    AssignWorkerToHex {
        expected_revision: u64,
        unit_id: String,
    },
    /// Cancels a worker assignment.
    CancelWorkerAssignment {
        expected_revision: u64,
        unit_id: String,
    },
    /// Starts road construction.
    BuildRoad {
        expected_revision: u64,
        unit_id: String,
    },
    /// Starts or continues worker automation.
    AutomateWorker {
        expected_revision: u64,
        unit_id: String,
    },
    /// Visible unit or city attack.
    AttackHex {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Attacking unit.
        attacker_unit_id: String,
        /// Target coordinate.
        defender: CoordinateDto,
        /// Requested city disposition.
        city_conquest_action: CityConquestActionDto,
    },
    /// Manual movement command.
    MoveUnit {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Opaque canonical unit identifier.
        unit_id: String,
        /// Requested movement target.
        target: CoordinateDto,
    },
    /// Starts or continues deterministic scout auto-exploration.
    AutoExploreUnit {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Scout identity.
        unit_id: String,
    },
    /// Assigns a cyclic merchant route.
    AssignMerchantTradeRoute {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Merchant identity.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Queues explicit merchant travel.
    MoveMerchantToCity {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Merchant identity.
        unit_id: String,
        /// Owned destination city.
        destination_city_id: String,
    },
    /// Detaches one troop into an engine-selected tile.
    DetachTroop {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Source army unit.
        unit_id: String,
        /// Troop kind to detach.
        troop_kind: TroopKindDto,
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
