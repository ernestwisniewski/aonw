//! Domain-independent DTOs for versioned engine boundaries.
//!
//! These values define admissible data shape, not game invariants. Conversion
//! into canonical domain types belongs to `aonw_contract_mapping`. A concrete
//! JSON or binary codec is intentionally deferred until the reviewed Dart
//! contract inventory is committed.

#![forbid(unsafe_code)]

/// The only state contract version accepted by the initial mapping crate.
pub const CURRENT_STATE_CONTRACT_VERSION: u16 = 2;

/// Versioned canonical-state transfer object.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorldStateDto {
    /// State schema version, independent of engine behavior version.
    pub schema_version: u16,
    /// Monotonic canonical state revision.
    pub revision: u64,
    /// Current game turn.
    pub turn: u32,
    /// Canonical units. Input order is not semantically significant.
    pub units: Vec<UnitDto>,
}

/// Unit transfer object for the initial state-contract slice.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitDto {
    /// Opaque unit identifier.
    pub id: String,
    /// Opaque owner-player identifier.
    pub owner_player_id: String,
    /// Odd-q offset-grid column.
    pub col: i32,
    /// Odd-q offset-grid row.
    pub row: i32,
    /// Integer movement units remaining.
    pub movement_units: u32,
}
