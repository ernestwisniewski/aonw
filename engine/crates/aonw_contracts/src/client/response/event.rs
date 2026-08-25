use serde::{Deserialize, Serialize};

use super::WorkerJobCompletionDto;
use crate::{CombatTargetDto, CoordinateDto, DiplomaticScoreChangeReasonDto, TroopKindDto};

/// Presentation-safe authoritative event.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ClientEventDto {
    /// One city-founding job completed for a visible city.
    CityFounded {
        /// New city identity.
        city_id: String,
        /// Founding player.
        owner_player_id: String,
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
        reason: DiplomaticScoreChangeReasonDto,
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
    /// One visible unit changed map position.
    UnitMoved {
        /// Moved unit.
        unit_id: String,
        /// Previous coordinate.
        from: CoordinateDto,
        /// New coordinate.
        to: CoordinateDto,
    },
    /// A scout selected an engine-owned exploration target.
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
        /// Participant that completed the turn.
        player_id: String,
    },
    /// Every participant in the required scope submitted.
    AllPlayersSubmitted {
        /// Finalized turn number.
        turn: u32,
        /// Participants in canonical turn order.
        player_ids: Vec<String>,
    },
    /// Trusted timeout notification.
    PlayerTimedOut {
        /// Timed-out turn number.
        turn: u32,
        /// Timed-out participant.
        player_id: String,
    },
    /// Trusted participant-removal notification.
    PlayerKicked {
        /// Turn during which removal occurred.
        turn: u32,
        /// Removed participant.
        player_id: String,
        /// Stable host-owned removal reason.
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
