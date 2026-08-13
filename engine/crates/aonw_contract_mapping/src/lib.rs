//! Validated conversion at the canonical engine boundary.
//!
//! External DTOs are consumed and validated before domain construction. The
//! crate contains no I/O and deliberately exposes no recipient-to-canonical
//! conversion.

#![forbid(unsafe_code)]

use core::fmt;

use aonw_contracts::{
    CURRENT_STATE_CONTRACT_VERSION, MovementStepDto, QueuedMovePathDto, UnitDto, UnitKindDto,
    UnitPostureDto, WorldStateDto,
};
use aonw_domain::{
    ArtifactId, HexCoord, IdentifierError, MovementPathError, MovementStep, MovementUnits,
    PlayerId, QueuedMovePath, StateBuildError, Unit, UnitId, UnitKind, UnitPosture, WorldState,
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
    /// The validated values still violate a canonical state invariant.
    InvalidState(StateBuildError),
}

impl fmt::Display for MappingError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::UnsupportedStateContractVersion { found, supported } => write!(
                formatter,
                "unsupported state contract version {found}; supported version is {supported}"
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
            Self::InvalidState(source) => write!(formatter, "invalid canonical state: {source}"),
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
            Self::InvalidState(source) => Some(source),
            Self::UnsupportedStateContractVersion { .. } => None,
        }
    }
}

/// Validates and decodes a canonical state DTO.
///
/// # Errors
///
/// Returns [`MappingError`] for unsupported versions, invalid identifiers, or
/// violated canonical-state invariants.
pub fn decode_world_state(dto: WorldStateDto) -> Result<WorldState, MappingError> {
    if dto.schema_version != CURRENT_STATE_CONTRACT_VERSION {
        return Err(MappingError::UnsupportedStateContractVersion {
            found: dto.schema_version,
            supported: CURRENT_STATE_CONTRACT_VERSION,
        });
    }

    let units = dto
        .units
        .into_iter()
        .enumerate()
        .map(|(index, unit)| decode_unit(index, unit))
        .collect::<Result<Vec<_>, _>>()?;

    WorldState::try_new(dto.revision, dto.turn, units).map_err(MappingError::InvalidState)
}

/// Encodes canonical state while preserving contract entity order.
#[must_use]
pub fn encode_world_state(state: &WorldState) -> WorldStateDto {
    WorldStateDto {
        schema_version: CURRENT_STATE_CONTRACT_VERSION,
        revision: state.revision(),
        turn: state.turn(),
        units: state.units().iter().map(encode_unit).collect(),
    }
}

fn decode_unit(index: usize, dto: UnitDto) -> Result<Unit, MappingError> {
    let UnitDto {
        id,
        owner_player_id,
        kind,
        col,
        row,
        movement_units,
        posture,
        working,
        queued_path,
        carried_artifact_id,
    } = dto;
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

    Ok(Unit::new(
        id,
        owner_player_id,
        decode_unit_kind(kind),
        HexCoord::new(col, row),
        MovementUnits::new(movement_units),
    )
    .with_posture(decode_unit_posture(posture))
    .with_working(working)
    .with_queued_path(queued_path)
    .with_carried_artifact(carried_artifact_id))
}

fn encode_unit(unit: &Unit) -> UnitDto {
    UnitDto {
        id: unit.id().as_str().to_owned(),
        owner_player_id: unit.owner_player_id().as_str().to_owned(),
        kind: encode_unit_kind(unit.kind()),
        col: unit.position().col(),
        row: unit.position().row(),
        movement_units: unit.movement_units().get(),
        posture: encode_unit_posture(unit.posture()),
        working: unit.is_working(),
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
        CURRENT_STATE_CONTRACT_VERSION, MovementStepDto, QueuedMovePathDto, UnitDto, UnitKindDto,
        UnitPostureDto, WorldStateDto,
    };
    use aonw_domain::{IdentifierError, MovementPathError, StateBuildError, UnitId};

    use super::{
        MappingError, decode_unit_kind, decode_unit_posture, decode_world_state, encode_unit_kind,
        encode_unit_posture, encode_world_state,
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

    fn state_dto() -> WorldStateDto {
        WorldStateDto {
            schema_version: CURRENT_STATE_CONTRACT_VERSION,
            revision: 41,
            turn: 8,
            units: vec![
                UnitDto {
                    id: "unit-z".to_owned(),
                    owner_player_id: "player-1".to_owned(),
                    kind: UnitKindDto::Worker,
                    col: 2,
                    row: 1,
                    movement_units: 5,
                    posture: UnitPostureDto::AutoWorking,
                    working: true,
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
                UnitDto {
                    id: "unit-a".to_owned(),
                    owner_player_id: "player-2".to_owned(),
                    kind: UnitKindDto::Warship,
                    col: 0,
                    row: 0,
                    movement_units: 0,
                    posture: UnitPostureDto::Fortified,
                    working: false,
                    queued_path: None,
                    carried_artifact_id: None,
                },
            ],
        }
    }

    #[test]
    fn state_round_trip_preserves_contract_order() {
        let source = state_dto();
        let decoded = decode_world_state(source.clone()).expect("valid contract state");
        let encoded = encode_world_state(&decoded);

        let unit_ids = encoded
            .units
            .iter()
            .map(|unit| unit.id.as_str())
            .collect::<Vec<_>>();
        assert_eq!(unit_ids, ["unit-z", "unit-a"]);
        assert_eq!(encoded, source);
        assert_eq!(decode_world_state(encoded), Ok(decoded));
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
        dto.schema_version = CURRENT_STATE_CONTRACT_VERSION + 1;

        assert_eq!(
            decode_world_state(dto),
            Err(MappingError::UnsupportedStateContractVersion {
                found: CURRENT_STATE_CONTRACT_VERSION + 1,
                supported: CURRENT_STATE_CONTRACT_VERSION,
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
            decode_world_state(dto),
            Err(MappingError::InvalidState(
                StateBuildError::DuplicateUnitId(duplicate)
            ))
        );
    }

    #[test]
    fn invalid_unit_identifier_fails_closed_at_its_contract_index() {
        let mut dto = state_dto();
        dto.units[1].id = "  ".to_owned();

        assert_eq!(
            decode_world_state(dto),
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
            decode_world_state(dto),
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
            decode_world_state(dto),
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
            decode_world_state(dto),
            Err(MappingError::InvalidQueuedMovePath {
                index: 1,
                source: MovementPathError::NonAdjacentStep { step_index: 1 },
            })
        );
    }
}
