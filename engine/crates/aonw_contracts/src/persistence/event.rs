use serde::{Deserialize, Serialize};

use crate::client::WorkerJobCompletionDto;
use crate::{
    CityBuildingTypeDto, CombatTargetDto, CoordinateDto, TechnologyIdDto, TroopKindDto,
    UnitKindDto, WonderTypeDto,
};

/// Ordered authoritative event stored in a replay result.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "type",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum ReplayEventDto {
    /// One unit started excavating an artifact.
    ArtifactExcavationStarted {
        /// Artifact identity.
        artifact_id: String,
        /// Player controlling the excavation.
        owner_player_id: String,
        /// Excavating unit.
        unit_id: String,
        /// Excavation coordinate.
        coordinate: CoordinateDto,
    },
    /// One unit completed an excavation and took its artifact.
    ArtifactCarried {
        /// Artifact identity.
        artifact_id: String,
        /// Player controlling the carrier.
        owner_player_id: String,
        /// Carrier unit.
        unit_id: String,
        /// Completion coordinate.
        coordinate: CoordinateDto,
    },
    /// One artifact entered city storage.
    ArtifactStored {
        /// Artifact identity.
        artifact_id: String,
        /// Player owning the destination city.
        owner_player_id: String,
        /// Direct carrier, absent for a city-to-city trade.
        source_unit_id: Option<String>,
        /// Destination city.
        city_id: String,
        /// Destination city center.
        coordinate: CoordinateDto,
    },
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
    /// One participant produced positive science during turn progression.
    ResearchPointsGained {
        /// Research owner.
        player_id: String,
        /// Exact positive science total.
        points: i64,
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
    /// One participant sent a private bilateral proposal.
    DiplomaticProposalSent {
        /// Proposal identity.
        proposal_id: String,
        /// Sender identity.
        from_player_id: String,
        /// Recipient identity.
        to_player_id: String,
        /// Friendship or truce request.
        kind: crate::DiplomaticProposalKindDto,
        /// Last actionable turn boundary.
        expires_on_turn: u32,
    },
    /// The proposal recipient accepted or rejected it.
    DiplomaticProposalResponded {
        /// Proposal identity.
        proposal_id: String,
        /// Original sender.
        from_player_id: String,
        /// Responding recipient.
        to_player_id: String,
        /// Original proposal kind.
        kind: crate::DiplomaticProposalKindDto,
        /// Recipient decision.
        accepted: bool,
    },
    /// One participant sent a private bilateral message.
    DiplomaticMessageSent {
        /// Message identity.
        message_id: String,
        /// Sender identity.
        from_player_id: String,
        /// Recipient identity.
        to_player_id: String,
        /// Message topic.
        topic: crate::DiplomaticMessageTopicDto,
        /// Category fixed by the topic.
        category: crate::DiplomaticMessageCategoryDto,
        /// Last actionable turn boundary.
        expires_on_turn: u32,
    },
    /// The message recipient selected one response tone.
    DiplomaticMessageResponded {
        /// Message identity.
        message_id: String,
        /// Original sender identity.
        from_player_id: String,
        /// Responding recipient identity.
        to_player_id: String,
        /// Original message topic.
        topic: crate::DiplomaticMessageTopicDto,
        /// Selected response tone.
        response: crate::DiplomaticMessageResponseDto,
        /// Applied relation-score delta.
        relation_delta: i64,
        /// Relation score after the response.
        relation_score_after: i64,
        /// Optional withdrawal-promise deadline.
        promise_due_turn: Option<u32>,
    },
    /// One bilateral relation status changed.
    DiplomaticRelationChanged {
        /// Canonical first participant.
        player_a_id: String,
        /// Canonical second participant.
        player_b_id: String,
        /// Status before the transition.
        old_status: crate::DiplomaticRelationStatusDto,
        /// Status after the transition.
        new_status: crate::DiplomaticRelationStatusDto,
        /// Exact change reason.
        reason: crate::DiplomaticRelationChangeReasonDto,
        /// Optional expiry for a temporary status.
        expires_on_turn: Option<u32>,
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
