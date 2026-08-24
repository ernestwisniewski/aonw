//! Validated conversion at the canonical engine boundary.
//!
//! External DTOs are consumed and validated before domain construction. The
//! crate contains no I/O and deliberately exposes no recipient-to-canonical
//! conversion.

#![forbid(unsafe_code)]

mod game_state_mapping;

pub use game_state_mapping::{
    GameStateMappingError, canonicalize_game_state, decode_game_state, decode_troop,
    encode_game_state, encode_improvement, encode_troop,
};

use aonw_contracts::{MovementStepDto, QueuedMovePathDto, UnitKindDto, UnitPostureDto};
use aonw_domain::{
    HexCoord, MovementPathError, MovementStep, MovementUnits, QueuedMovePath, UnitKind, UnitPosture,
};

const fn decode_unit_kind(kind: UnitKindDto) -> UnitKind {
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
