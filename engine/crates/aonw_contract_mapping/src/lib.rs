//! Validated conversion at the canonical engine boundary.
//!
//! External DTOs are consumed and validated before domain construction. The
//! crate contains no I/O and deliberately exposes no recipient-to-canonical
//! conversion.

#![forbid(unsafe_code)]

use core::fmt;

use aonw_contracts::{CURRENT_STATE_CONTRACT_VERSION, UnitDto, WorldStateDto};
use aonw_domain::{HexCoord, IdentifierError, PlayerId, StateBuildError, Unit, UnitId, WorldState};

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
            Self::InvalidState(source) => write!(formatter, "invalid canonical state: {source}"),
        }
    }
}

impl std::error::Error for MappingError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::InvalidUnitId { source, .. } | Self::InvalidUnitOwnerId { source, .. } => {
                Some(source)
            }
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

/// Encodes canonical state in deterministic unit-identifier order.
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
    let id = UnitId::new(dto.id).map_err(|source| MappingError::InvalidUnitId { index, source })?;
    let owner_player_id = PlayerId::new(dto.owner_player_id)
        .map_err(|source| MappingError::InvalidUnitOwnerId { index, source })?;
    Ok(Unit::new(
        id,
        owner_player_id,
        HexCoord::new(dto.col, dto.row),
        dto.movement_units,
    ))
}

fn encode_unit(unit: &Unit) -> UnitDto {
    UnitDto {
        id: unit.id().as_str().to_owned(),
        owner_player_id: unit.owner_player_id().as_str().to_owned(),
        col: unit.position().col(),
        row: unit.position().row(),
        movement_units: unit.movement_units(),
    }
}

#[cfg(test)]
mod tests {
    use aonw_contracts::{CURRENT_STATE_CONTRACT_VERSION, UnitDto, WorldStateDto};
    use aonw_domain::{StateBuildError, UnitId};

    use super::{MappingError, decode_world_state, encode_world_state};

    fn state_dto() -> WorldStateDto {
        WorldStateDto {
            schema_version: CURRENT_STATE_CONTRACT_VERSION,
            revision: 41,
            turn: 8,
            units: vec![
                UnitDto {
                    id: "unit-z".to_owned(),
                    owner_player_id: "player-1".to_owned(),
                    col: 2,
                    row: 1,
                    movement_units: 150,
                },
                UnitDto {
                    id: "unit-a".to_owned(),
                    owner_player_id: "player-2".to_owned(),
                    col: 0,
                    row: 0,
                    movement_units: 0,
                },
            ],
        }
    }

    #[test]
    fn state_round_trip_is_canonical_and_deterministic() {
        let decoded = decode_world_state(state_dto()).expect("valid contract state");
        let encoded = encode_world_state(&decoded);

        let unit_ids = encoded
            .units
            .iter()
            .map(|unit| unit.id.as_str())
            .collect::<Vec<_>>();
        assert_eq!(unit_ids, ["unit-a", "unit-z"]);
        assert_eq!(decode_world_state(encoded), Ok(decoded));
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
}
