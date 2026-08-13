//! Validated conversion at the canonical engine boundary.
//!
//! External DTOs are consumed and validated before domain construction. The
//! crate contains no I/O and deliberately exposes no recipient-to-canonical
//! conversion.

#![forbid(unsafe_code)]

use core::fmt;

use aonw_contracts::{
    CURRENT_MOVEMENT_STATE_VERSION, MAX_MOVEMENT_BALANCE_UNITS, MAX_MOVEMENT_STATE_UNIT_COUNT,
    MAX_QUEUED_PATH_STEP_COUNT, MovementStateDto, MovementStepDto, MovementUnitDto,
    QueuedMovePathDto, UnitKindDto, UnitPostureDto,
};
use aonw_domain::{
    ArtifactId, HexCoord, IdentifierError, MovementPathError, MovementState,
    MovementStateBuildError, MovementStep, MovementUnit, MovementUnitBuildError, MovementUnits,
    PlayerId, QueuedMovePath, UnitId, UnitKind, UnitPosture,
};

/// Failure raised while converting untrusted boundary data.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum MappingError {
    /// The state uses a schema this build does not support.
    UnsupportedStateContractVersion {
        /// Version found in the input.
        found: u16,
        /// Version accepted by this build.
        supported: u16,
    },
    /// The state exceeds the bounded entity count.
    TooManyUnits {
        /// Unit count found in the input.
        found: usize,
        /// Maximum accepted unit count.
        maximum: usize,
    },
    /// A unit carries an unbounded current-turn movement balance.
    MovementBalanceOutOfRange {
        /// Unit array index carrying the invalid value.
        index: usize,
        /// Fixed-point balance found in the input.
        found: u32,
        /// Maximum accepted fixed-point balance.
        maximum: u32,
    },
    /// A queued route exceeds the bounded map scale.
    QueuedPathTooLong {
        /// Unit array index carrying the invalid route.
        index: usize,
        /// Step count found in the input.
        found: usize,
        /// Maximum accepted step count.
        maximum: usize,
    },
    /// A unit identifier is invalid.
    InvalidUnitId {
        /// Unit array index carrying the invalid value.
        index: usize,
        /// Identifier validation failure.
        source: IdentifierError,
    },
    /// A unit owner identifier is invalid.
    InvalidUnitOwnerId {
        /// Unit array index carrying the invalid value.
        index: usize,
        /// Identifier validation failure.
        source: IdentifierError,
    },
    /// A carried artifact identifier is invalid.
    InvalidCarriedArtifactId {
        /// Unit array index carrying the invalid value.
        index: usize,
        /// Identifier validation failure.
        source: IdentifierError,
    },
    /// A queued movement route violates canonical path invariants.
    InvalidQueuedMovePath {
        /// Unit array index carrying the invalid route.
        index: usize,
        /// Route validation failure.
        source: MovementPathError,
    },
    /// A unit projection violates an invariant spanning multiple fields.
    InvalidMovementUnit {
        /// Unit array index carrying the invalid projection.
        index: usize,
        /// Projection validation failure.
        source: MovementUnitBuildError,
    },
    /// The validated values still violate a movement-state invariant.
    InvalidMovementState(MovementStateBuildError),
}

impl fmt::Display for MappingError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::UnsupportedStateContractVersion { found, supported } => write!(
                formatter,
                "unsupported state contract version {found}; supported version is {supported}"
            ),
            Self::TooManyUnits { found, maximum } => {
                write!(
                    formatter,
                    "movement state has {found} units; maximum is {maximum}"
                )
            }
            Self::MovementBalanceOutOfRange {
                index,
                found,
                maximum,
            } => write!(
                formatter,
                "movement balance at unit index {index} is {found}; maximum is {maximum}"
            ),
            Self::QueuedPathTooLong {
                index,
                found,
                maximum,
            } => write!(
                formatter,
                "queued path at unit index {index} has {found} steps; maximum is {maximum}"
            ),
            Self::InvalidUnitId { index, source } => {
                write!(formatter, "invalid unit id at index {index}: {source}")
            }
            Self::InvalidUnitOwnerId { index, source } => {
                write!(
                    formatter,
                    "invalid unit owner id at index {index}: {source}"
                )
            }
            Self::InvalidCarriedArtifactId { index, source } => {
                write!(
                    formatter,
                    "invalid carried artifact id for unit at index {index}: {source}"
                )
            }
            Self::InvalidQueuedMovePath { index, source } => {
                write!(
                    formatter,
                    "invalid queued path for unit at index {index}: {source}"
                )
            }
            Self::InvalidMovementUnit { index, source } => {
                write!(
                    formatter,
                    "invalid movement unit at index {index}: {source}"
                )
            }
            Self::InvalidMovementState(source) => {
                write!(formatter, "invalid movement state: {source}")
            }
        }
    }
}

impl std::error::Error for MappingError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::InvalidUnitId { source, .. }
            | Self::InvalidUnitOwnerId { source, .. }
            | Self::InvalidCarriedArtifactId { source, .. } => Some(source),
            Self::InvalidQueuedMovePath { source, .. } => Some(source),
            Self::InvalidMovementUnit { source, .. } => Some(source),
            Self::InvalidMovementState(source) => Some(source),
            Self::UnsupportedStateContractVersion { .. }
            | Self::TooManyUnits { .. }
            | Self::MovementBalanceOutOfRange { .. }
            | Self::QueuedPathTooLong { .. } => None,
        }
    }
}

/// Validates and decodes a movement-state DTO.
///
/// # Errors
///
/// Returns [`MappingError`] for unsupported versions, invalid identifiers, or
/// violated movement-projection invariants.
pub fn decode_movement_state(dto: MovementStateDto) -> Result<MovementState, MappingError> {
    if dto.schema_version != CURRENT_MOVEMENT_STATE_VERSION {
        return Err(MappingError::UnsupportedStateContractVersion {
            found: dto.schema_version,
            supported: CURRENT_MOVEMENT_STATE_VERSION,
        });
    }
    if dto.units.len() > MAX_MOVEMENT_STATE_UNIT_COUNT {
        return Err(MappingError::TooManyUnits {
            found: dto.units.len(),
            maximum: MAX_MOVEMENT_STATE_UNIT_COUNT,
        });
    }

    let units = dto
        .units
        .into_iter()
        .enumerate()
        .map(|(index, unit)| decode_unit(index, unit))
        .collect::<Result<Vec<_>, _>>()?;

    MovementState::try_new(dto.revision, dto.turn, units)
        .map_err(MappingError::InvalidMovementState)
}

/// Encodes a movement state while preserving contract entity order.
#[must_use]
pub fn encode_movement_state(state: &MovementState) -> MovementStateDto {
    MovementStateDto {
        schema_version: CURRENT_MOVEMENT_STATE_VERSION,
        revision: state.revision(),
        turn: state.turn(),
        units: state.units().iter().map(encode_unit).collect(),
    }
}

fn decode_unit(index: usize, dto: MovementUnitDto) -> Result<MovementUnit, MappingError> {
    let MovementUnitDto {
        id,
        owner_player_id,
        kind,
        col,
        row,
        movement_units,
        posture,
        movement_blocked,
        queued_path,
        carried_artifact_id,
    } = dto;
    if movement_units > MAX_MOVEMENT_BALANCE_UNITS {
        return Err(MappingError::MovementBalanceOutOfRange {
            index,
            found: movement_units,
            maximum: MAX_MOVEMENT_BALANCE_UNITS,
        });
    }
    if let Some(path) = &queued_path
        && path.steps.len() > MAX_QUEUED_PATH_STEP_COUNT
    {
        return Err(MappingError::QueuedPathTooLong {
            index,
            found: path.steps.len(),
            maximum: MAX_QUEUED_PATH_STEP_COUNT,
        });
    }
    let id = UnitId::new(id).map_err(|source| MappingError::InvalidUnitId { index, source })?;
    let owner_player_id = PlayerId::new(owner_player_id)
        .map_err(|source| MappingError::InvalidUnitOwnerId { index, source })?;
    let carried_artifact_id = carried_artifact_id
        .map(ArtifactId::new)
        .transpose()
        .map_err(|source| MappingError::InvalidCarriedArtifactId { index, source })?;
    let queued_path = queued_path
        .map(decode_queued_path)
        .transpose()
        .map_err(|source| MappingError::InvalidQueuedMovePath { index, source })?;

    MovementUnit::new(
        id,
        owner_player_id,
        decode_unit_kind(kind),
        HexCoord::new(col, row),
        MovementUnits::new(movement_units),
    )
    .with_posture(decode_unit_posture(posture))
    .with_movement_blocked(movement_blocked)
    .try_with_queued_path(queued_path)
    .map_err(|source| MappingError::InvalidMovementUnit { index, source })
    .map(|unit| unit.with_carried_artifact(carried_artifact_id))
}

fn encode_unit(unit: &MovementUnit) -> MovementUnitDto {
    MovementUnitDto {
        id: unit.id().as_str().to_owned(),
        owner_player_id: unit.owner_player_id().as_str().to_owned(),
        kind: encode_unit_kind(unit.kind()),
        col: unit.position().col(),
        row: unit.position().row(),
        movement_units: unit.movement_units().get(),
        posture: encode_unit_posture(unit.posture()),
        movement_blocked: unit.is_movement_blocked(),
        queued_path: unit.queued_path().map(encode_queued_path),
        carried_artifact_id: unit
            .carried_artifact_id()
            .map(|artifact_id| artifact_id.as_str().to_owned()),
    }
}

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

const fn encode_unit_kind(kind: UnitKind) -> UnitKindDto {
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

const fn encode_unit_posture(posture: UnitPosture) -> UnitPostureDto {
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
mod tests {
    use aonw_contracts::{
        CURRENT_MOVEMENT_STATE_VERSION, MAX_MOVEMENT_BALANCE_UNITS, MAX_MOVEMENT_STATE_UNIT_COUNT,
        MAX_QUEUED_PATH_STEP_COUNT, MovementStateDto, MovementStepDto, MovementUnitDto,
        QueuedMovePathDto, UnitKindDto, UnitPostureDto,
    };
    use aonw_domain::{
        HexCoord, IdentifierError, MovementPathError, MovementStateBuildError,
        MovementUnitBuildError, UnitId,
    };

    use super::{
        MappingError, decode_movement_state, decode_unit_kind, decode_unit_posture,
        encode_movement_state, encode_unit_kind, encode_unit_posture,
    };

    const ALL_UNIT_KINDS: [UnitKindDto; 17] = [
        UnitKindDto::Commander,
        UnitKindDto::Warrior,
        UnitKindDto::Archer,
        UnitKindDto::Settler,
        UnitKindDto::Worker,
        UnitKindDto::Merchant,
        UnitKindDto::Scout,
        UnitKindDto::Spearman,
        UnitKindDto::Cavalry,
        UnitKindDto::Catapult,
        UnitKindDto::HeavyInfantry,
        UnitKindDto::FieldCannon,
        UnitKindDto::Rifleman,
        UnitKindDto::Tank,
        UnitKindDto::ScoutShip,
        UnitKindDto::Warship,
        UnitKindDto::ReconPlane,
    ];

    const ALL_UNIT_POSTURES: [UnitPostureDto; 4] = [
        UnitPostureDto::Active,
        UnitPostureDto::Fortified,
        UnitPostureDto::AutoExploring,
        UnitPostureDto::AutoWorking,
    ];

    fn state_dto() -> MovementStateDto {
        MovementStateDto {
            schema_version: CURRENT_MOVEMENT_STATE_VERSION,
            revision: 41,
            turn: 8,
            units: vec![
                MovementUnitDto {
                    id: "unit-z".to_owned(),
                    owner_player_id: "player-1".to_owned(),
                    kind: UnitKindDto::Worker,
                    col: 2,
                    row: 1,
                    movement_units: 5,
                    posture: UnitPostureDto::AutoWorking,
                    movement_blocked: true,
                    queued_path: Some(QueuedMovePathDto {
                        target_col: 3,
                        target_row: 1,
                        steps: vec![
                            MovementStepDto {
                                col: 2,
                                row: 1,
                                enter_cost_units: 0,
                                cumulative_cost_units: 0,
                            },
                            MovementStepDto {
                                col: 3,
                                row: 1,
                                enter_cost_units: 2,
                                cumulative_cost_units: 2,
                            },
                        ],
                    }),
                    carried_artifact_id: Some("artifact-7".to_owned()),
                },
                MovementUnitDto {
                    id: "unit-a".to_owned(),
                    owner_player_id: "player-2".to_owned(),
                    kind: UnitKindDto::Warship,
                    col: 0,
                    row: 0,
                    movement_units: 0,
                    posture: UnitPostureDto::Fortified,
                    movement_blocked: false,
                    queued_path: None,
                    carried_artifact_id: None,
                },
            ],
        }
    }

    #[test]
    fn state_round_trip_preserves_contract_order() {
        let source = state_dto();
        let decoded = decode_movement_state(source.clone()).expect("valid movement state");
        let encoded = encode_movement_state(&decoded);

        let unit_ids = encoded
            .units
            .iter()
            .map(|unit| unit.id.as_str())
            .collect::<Vec<_>>();
        assert_eq!(unit_ids, ["unit-z", "unit-a"]);
        assert_eq!(encoded, source);
        assert_eq!(decode_movement_state(encoded), Ok(decoded));
    }

    #[test]
    fn all_unit_kind_variants_map_bijectively() {
        for dto in ALL_UNIT_KINDS {
            assert_eq!(encode_unit_kind(decode_unit_kind(dto)), dto);
        }
    }

    #[test]
    fn all_unit_posture_variants_map_bijectively() {
        for dto in ALL_UNIT_POSTURES {
            assert_eq!(encode_unit_posture(decode_unit_posture(dto)), dto);
        }
    }

    #[test]
    fn unknown_contract_version_fails_closed() {
        let mut dto = state_dto();
        dto.schema_version = CURRENT_MOVEMENT_STATE_VERSION + 1;

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::UnsupportedStateContractVersion {
                found: CURRENT_MOVEMENT_STATE_VERSION + 1,
                supported: CURRENT_MOVEMENT_STATE_VERSION,
            })
        );
    }

    #[test]
    fn movement_state_entity_count_is_bounded() {
        let mut dto = state_dto();
        let template = dto.units[0].clone();
        dto.units = (0..=MAX_MOVEMENT_STATE_UNIT_COUNT)
            .map(|index| {
                let mut unit = template.clone();
                unit.id = format!("unit-{index}");
                unit.queued_path = None;
                unit
            })
            .collect();

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::TooManyUnits {
                found: MAX_MOVEMENT_STATE_UNIT_COUNT + 1,
                maximum: MAX_MOVEMENT_STATE_UNIT_COUNT,
            })
        );
    }

    #[test]
    fn movement_balance_is_bounded_before_domain_construction() {
        let mut dto = state_dto();
        dto.units[0].movement_units = MAX_MOVEMENT_BALANCE_UNITS + 1;

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::MovementBalanceOutOfRange {
                index: 0,
                found: MAX_MOVEMENT_BALANCE_UNITS + 1,
                maximum: MAX_MOVEMENT_BALANCE_UNITS,
            })
        );
    }

    #[test]
    fn queued_path_length_is_bounded_before_path_validation() {
        let mut dto = state_dto();
        let origin = MovementStepDto {
            col: 2,
            row: 1,
            enter_cost_units: 0,
            cumulative_cost_units: 0,
        };
        dto.units[0]
            .queued_path
            .as_mut()
            .expect("queued path")
            .steps = vec![origin; MAX_QUEUED_PATH_STEP_COUNT + 1];

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::QueuedPathTooLong {
                index: 0,
                found: MAX_QUEUED_PATH_STEP_COUNT + 1,
                maximum: MAX_QUEUED_PATH_STEP_COUNT,
            })
        );
    }

    #[test]
    fn duplicate_unit_identifiers_are_rejected() {
        let mut dto = state_dto();
        let duplicate_value = dto.units[0].id.clone();
        dto.units[1].id.clone_from(&duplicate_value);
        let duplicate = UnitId::new(duplicate_value).expect("valid duplicate id");

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::InvalidMovementState(
                MovementStateBuildError::DuplicateUnitId(duplicate)
            ))
        );
    }

    #[test]
    fn invalid_unit_identifier_fails_closed_at_its_contract_index() {
        let mut dto = state_dto();
        dto.units[1].id = "  ".to_owned();

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::InvalidUnitId {
                index: 1,
                source: IdentifierError::Empty,
            })
        );
    }

    #[test]
    fn invalid_owner_identifier_fails_closed_at_its_contract_index() {
        let mut dto = state_dto();
        dto.units[1].owner_player_id = String::new();

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::InvalidUnitOwnerId {
                index: 1,
                source: IdentifierError::Empty,
            })
        );
    }

    #[test]
    fn invalid_artifact_identifier_fails_closed_at_its_contract_index() {
        let mut dto = state_dto();
        dto.units[1].carried_artifact_id = Some("\t".to_owned());

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::InvalidCarriedArtifactId {
                index: 1,
                source: IdentifierError::Empty,
            })
        );
    }

    #[test]
    fn invalid_queued_path_fails_closed_at_its_contract_index() {
        let mut dto = state_dto();
        dto.units[1].queued_path = Some(QueuedMovePathDto {
            target_col: 2,
            target_row: 0,
            steps: vec![
                MovementStepDto {
                    col: 0,
                    row: 0,
                    enter_cost_units: 0,
                    cumulative_cost_units: 0,
                },
                MovementStepDto {
                    col: 2,
                    row: 0,
                    enter_cost_units: 2,
                    cumulative_cost_units: 2,
                },
            ],
        });

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::InvalidQueuedMovePath {
                index: 1,
                source: MovementPathError::NonAdjacentStep { step_index: 1 },
            })
        );
    }

    #[test]
    fn queued_path_origin_must_match_unit_position() {
        let mut dto = state_dto();
        dto.units[1].queued_path = Some(QueuedMovePathDto {
            target_col: 2,
            target_row: 0,
            steps: vec![
                MovementStepDto {
                    col: 1,
                    row: 0,
                    enter_cost_units: 0,
                    cumulative_cost_units: 0,
                },
                MovementStepDto {
                    col: 2,
                    row: 0,
                    enter_cost_units: 2,
                    cumulative_cost_units: 2,
                },
            ],
        });

        assert_eq!(
            decode_movement_state(dto),
            Err(MappingError::InvalidMovementUnit {
                index: 1,
                source: MovementUnitBuildError::QueuedPathOriginMismatch {
                    expected: HexCoord::new(0, 0),
                    actual: HexCoord::new(1, 0),
                },
            })
        );
    }
}
