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
    /// Canonical units in contract-preserved order.
    pub units: Vec<UnitDto>,
}

/// Unit transfer object for canonical state exchange.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitDto {
    /// Opaque unit identifier.
    pub id: String,
    /// Opaque owner-player identifier.
    pub owner_player_id: String,
    /// Stable canonical unit type.
    pub kind: UnitKindDto,
    /// Odd-q offset-grid column.
    pub col: i32,
    /// Odd-q offset-grid row.
    pub row: i32,
    /// Integer movement units remaining.
    pub movement_units: u32,
    /// Persistent unit behavior.
    pub posture: UnitPostureDto,
    /// Whether a domain job prevents manual movement.
    pub working: bool,
    /// Persisted route awaiting execution.
    pub queued_path: Option<QueuedMovePathDto>,
    /// Opaque carried-artifact identifier.
    pub carried_artifact_id: Option<String>,
}

/// Stable unit type used at engine boundaries.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum UnitKindDto {
    Commander,
    Warrior,
    Archer,
    Settler,
    Worker,
    Merchant,
    Scout,
    Spearman,
    Cavalry,
    Catapult,
    HeavyInfantry,
    FieldCannon,
    Rifleman,
    Tank,
    ScoutShip,
    Warship,
    ReconPlane,
}

/// Persistent unit behavior used at engine boundaries.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum UnitPostureDto {
    Active,
    Fortified,
    AutoExploring,
    AutoWorking,
}

/// One persisted step of a queued movement route.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MovementStepDto {
    /// Odd-q offset-grid column.
    pub col: i32,
    /// Odd-q offset-grid row.
    pub row: i32,
    /// Fixed-point cost of entering this coordinate.
    pub enter_cost_units: u32,
    /// Fixed-point route cost through this coordinate.
    pub cumulative_cost_units: u32,
}

/// Persisted movement route retained between commands.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct QueuedMovePathDto {
    /// Final requested odd-q column.
    pub target_col: i32,
    /// Final requested odd-q row.
    pub target_row: i32,
    /// Steps in execution order, including the origin.
    pub steps: Vec<MovementStepDto>,
}
