//! Validated conversion at the canonical engine boundary.
//!
//! External DTOs are consumed and validated before domain construction. The
//! crate contains no I/O and deliberately exposes no recipient-to-canonical
//! conversion.

#![forbid(unsafe_code)]

mod game_state_mapping;

pub use game_state_mapping::{
    GameStateMappingError, canonicalize_game_state, decode_city_building, decode_city_project,
    decode_city_specialization, decode_city_wonder, decode_game_state, decode_improvement,
    decode_resource, decode_technology, decode_troop, encode_city_building, encode_city_project,
    encode_city_specialization, encode_city_wonder, encode_game_state, encode_improvement,
    encode_resource, encode_technology, encode_troop,
};

use aonw_contracts::{
    DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto, DiplomaticRelationStatusDto,
    DiplomaticScoreChangeReasonDto, MovementStepDto, QueuedMovePathDto, UnitKindDto,
    UnitPostureDto,
};
use aonw_domain::{
    DiplomaticProposalKind, DiplomaticRelationChangeReason, DiplomaticRelationStatus,
    DiplomaticScoreChangeReason, HexCoord, MovementPathError, MovementStep, MovementUnits,
    QueuedMovePath, UnitKind, UnitPosture,
};

/// Converts a proposal kind into its stable wire value.
#[must_use]
pub const fn encode_proposal_kind(value: DiplomaticProposalKind) -> DiplomaticProposalKindDto {
    match value {
        DiplomaticProposalKind::Friendship => DiplomaticProposalKindDto::Friendship,
        DiplomaticProposalKind::Truce => DiplomaticProposalKindDto::Truce,
    }
}

/// Converts a strict wire proposal kind into its domain value.
#[must_use]
pub const fn decode_proposal_kind(value: DiplomaticProposalKindDto) -> DiplomaticProposalKind {
    match value {
        DiplomaticProposalKindDto::Friendship => DiplomaticProposalKind::Friendship,
        DiplomaticProposalKindDto::Truce => DiplomaticProposalKind::Truce,
    }
}

/// Converts a relation status into its stable wire value.
#[must_use]
pub const fn encode_relation_status(
    value: DiplomaticRelationStatus,
) -> DiplomaticRelationStatusDto {
    match value {
        DiplomaticRelationStatus::Friendly => DiplomaticRelationStatusDto::Friendly,
        DiplomaticRelationStatus::Neutral => DiplomaticRelationStatusDto::Neutral,
        DiplomaticRelationStatus::Hostile => DiplomaticRelationStatusDto::Hostile,
        DiplomaticRelationStatus::Truce => DiplomaticRelationStatusDto::Truce,
        DiplomaticRelationStatus::War => DiplomaticRelationStatusDto::War,
    }
}

/// Converts a relation-change reason into its stable wire value.
#[must_use]
pub const fn encode_relation_reason(
    value: DiplomaticRelationChangeReason,
) -> DiplomaticRelationChangeReasonDto {
    match value {
        DiplomaticRelationChangeReason::Manual => DiplomaticRelationChangeReasonDto::Manual,
        DiplomaticRelationChangeReason::UnitAttack => DiplomaticRelationChangeReasonDto::UnitAttack,
        DiplomaticRelationChangeReason::CityAttack => DiplomaticRelationChangeReasonDto::CityAttack,
        DiplomaticRelationChangeReason::DeclarationOfWar => {
            DiplomaticRelationChangeReasonDto::DeclarationOfWar
        }
        DiplomaticRelationChangeReason::ProposalAccepted => {
            DiplomaticRelationChangeReasonDto::ProposalAccepted
        }
        DiplomaticRelationChangeReason::TruceExpired => {
            DiplomaticRelationChangeReasonDto::TruceExpired
        }
        DiplomaticRelationChangeReason::MessageResponse => {
            DiplomaticRelationChangeReasonDto::MessageResponse
        }
        DiplomaticRelationChangeReason::PromiseBroken => {
            DiplomaticRelationChangeReasonDto::PromiseBroken
        }
    }
}

/// Converts a canonical diplomacy score reason into its stable wire value.
#[must_use]
pub const fn encode_score_reason(
    value: DiplomaticScoreChangeReason,
) -> DiplomaticScoreChangeReasonDto {
    match value {
        DiplomaticScoreChangeReason::Manual => DiplomaticScoreChangeReasonDto::Manual,
        DiplomaticScoreChangeReason::UnitAttack => DiplomaticScoreChangeReasonDto::UnitAttack,
        DiplomaticScoreChangeReason::CityAttack => DiplomaticScoreChangeReasonDto::CityAttack,
        DiplomaticScoreChangeReason::DeclarationOfWar => {
            DiplomaticScoreChangeReasonDto::DeclarationOfWar
        }
        DiplomaticScoreChangeReason::WarmongerPenalty => {
            DiplomaticScoreChangeReasonDto::WarmongerPenalty
        }
        DiplomaticScoreChangeReason::ProposalAccepted => {
            DiplomaticScoreChangeReasonDto::ProposalAccepted
        }
        DiplomaticScoreChangeReason::ProposalRejected => {
            DiplomaticScoreChangeReasonDto::ProposalRejected
        }
        DiplomaticScoreChangeReason::MessageResponse => {
            DiplomaticScoreChangeReasonDto::MessageResponse
        }
        DiplomaticScoreChangeReason::CommonEnemyCooperation => {
            DiplomaticScoreChangeReasonDto::CommonEnemyCooperation
        }
        DiplomaticScoreChangeReason::GoldGift => DiplomaticScoreChangeReasonDto::GoldGift,
        DiplomaticScoreChangeReason::PromiseBroken => DiplomaticScoreChangeReasonDto::PromiseBroken,
    }
}

/// Converts a current client unit identity into the domain identity.
#[must_use]
pub const fn decode_unit_kind(kind: UnitKindDto) -> UnitKind {
    match kind {
        UnitKindDto::Commander => UnitKind::Commander,
        UnitKindDto::Warrior => UnitKind::Warrior,
        UnitKindDto::Archer => UnitKind::Archer,
        UnitKindDto::Settler => UnitKind::Settler,
        UnitKindDto::Worker => UnitKind::Worker,
        UnitKindDto::Merchant => UnitKind::Merchant,
        UnitKindDto::Scout => UnitKind::Scout,
        UnitKindDto::Spearman => UnitKind::Spearman,
        UnitKindDto::Cavalry => UnitKind::Cavalry,
        UnitKindDto::Catapult => UnitKind::Catapult,
        UnitKindDto::HeavyInfantry => UnitKind::HeavyInfantry,
        UnitKindDto::FieldCannon => UnitKind::FieldCannon,
        UnitKindDto::Rifleman => UnitKind::Rifleman,
        UnitKindDto::Tank => UnitKind::Tank,
        UnitKindDto::ScoutShip => UnitKind::ScoutShip,
        UnitKindDto::Warship => UnitKind::Warship,
        UnitKindDto::ReconPlane => UnitKind::ReconPlane,
    }
}

/// Converts a validated domain unit kind into its stable wire value.
#[must_use]
pub const fn encode_unit_kind(kind: UnitKind) -> UnitKindDto {
    match kind {
        UnitKind::Commander => UnitKindDto::Commander,
        UnitKind::Warrior => UnitKindDto::Warrior,
        UnitKind::Archer => UnitKindDto::Archer,
        UnitKind::Settler => UnitKindDto::Settler,
        UnitKind::Worker => UnitKindDto::Worker,
        UnitKind::Merchant => UnitKindDto::Merchant,
        UnitKind::Scout => UnitKindDto::Scout,
        UnitKind::Spearman => UnitKindDto::Spearman,
        UnitKind::Cavalry => UnitKindDto::Cavalry,
        UnitKind::Catapult => UnitKindDto::Catapult,
        UnitKind::HeavyInfantry => UnitKindDto::HeavyInfantry,
        UnitKind::FieldCannon => UnitKindDto::FieldCannon,
        UnitKind::Rifleman => UnitKindDto::Rifleman,
        UnitKind::Tank => UnitKindDto::Tank,
        UnitKind::ScoutShip => UnitKindDto::ScoutShip,
        UnitKind::Warship => UnitKindDto::Warship,
        UnitKind::ReconPlane => UnitKindDto::ReconPlane,
    }
}

const fn decode_unit_posture(posture: UnitPostureDto) -> UnitPosture {
    match posture {
        UnitPostureDto::Active => UnitPosture::Active,
        UnitPostureDto::Fortified => UnitPosture::Fortified,
        UnitPostureDto::AutoExploring => UnitPosture::AutoExploring,
        UnitPostureDto::AutoWorking => UnitPosture::AutoWorking,
    }
}

/// Converts a validated domain posture into its stable wire value.
#[must_use]
pub const fn encode_unit_posture(posture: UnitPosture) -> UnitPostureDto {
    match posture {
        UnitPosture::Active => UnitPostureDto::Active,
        UnitPosture::Fortified => UnitPostureDto::Fortified,
        UnitPosture::AutoExploring => UnitPostureDto::AutoExploring,
        UnitPosture::AutoWorking => UnitPostureDto::AutoWorking,
    }
}

fn decode_queued_path(path: QueuedMovePathDto) -> Result<QueuedMovePath, MovementPathError> {
    QueuedMovePath::try_new(
        HexCoord::new(path.target_col, path.target_row),
        path.steps
            .into_iter()
            .map(|step| {
                MovementStep::new(
                    HexCoord::new(step.col, step.row),
                    MovementUnits::new(step.enter_cost_units),
                    MovementUnits::new(step.cumulative_cost_units),
                )
            })
            .collect::<Vec<_>>(),
    )
}

fn encode_queued_path(path: &QueuedMovePath) -> QueuedMovePathDto {
    QueuedMovePathDto {
        target_col: path.target().col(),
        target_row: path.target().row(),
        steps: path
            .steps()
            .iter()
            .map(|step| MovementStepDto {
                col: step.coordinate().col(),
                row: step.coordinate().row(),
                enter_cost_units: step.enter_cost().get(),
                cumulative_cost_units: step.cumulative_cost().get(),
            })
            .collect(),
    }
}

#[cfg(test)]
mod tests;
