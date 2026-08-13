//! Domain-independent DTOs for versioned engine boundaries.
//!
//! These values define admissible data shape, not game invariants. Conversion
//! into canonical domain types belongs to `aonw_contract_mapping`. Current
//! canonical state DTOs provide a strict bounded JSON codec; framework-specific
//! transport remains outside this crate.

#![forbid(unsafe_code)]

mod canonical;
mod limits;

pub use canonical::{
    ArmyTroopDto, CURRENT_GAME_STATE_VERSION, CityDto, CityFoundingJobDto, CoordinateDto,
    FieldImprovementKindDto, GameStateCodecError, GameStateDto, MerchantTradeRouteDto,
    PlayerFogDto, PlayerPairDto, TransportConditionDto, TransportSegmentDto, TroopKindDto,
    UnitActivityDto, UnitDto, UnitOccupancyPolicyDto, WorkerJobDto,
};

pub use limits::{
    MAX_KNOWN_UNIT_ID_COUNT, MAX_KNOWN_UNIT_IDS_JSON_BYTES, MAX_MOVEMENT_BALANCE_UNITS,
    MAX_MOVEMENT_STATE_JSON_BYTES, MAX_MOVEMENT_STATE_UNIT_COUNT, MAX_QUEUED_PATH_STEP_COUNT,
};

/// The only movement projection version accepted by the mapping crate.
pub const CURRENT_MOVEMENT_STATE_VERSION: u16 = 1;

/// Versioned movement-state projection for command and query boundaries.
///
/// This DTO deliberately excludes canonical fields unrelated to movement.
/// Adapters must preserve those fields when applying an engine transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MovementStateDto {
    /// Projection schema version, independent of engine behavior version.
    pub schema_version: u16,
    /// Monotonic canonical state revision.
    pub revision: u64,
    /// Current game turn.
    pub turn: u32,
    /// Movement-oriented unit views in contract-preserved order.
    pub units: Vec<MovementUnitDto>,
}

/// Unit transfer object carrying only values required by movement rules.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MovementUnitDto {
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
    /// Derived availability flag; this is not persisted canonical job state.
    pub movement_blocked: bool,
    /// Persisted route awaiting execution.
    pub queued_path: Option<QueuedMovePathDto>,
    /// Opaque carried-artifact identifier.
    pub carried_artifact_id: Option<String>,
}

/// Stable unit type used at engine boundaries.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase")]
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
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase")]
pub enum UnitPostureDto {
    Active,
    Fortified,
    AutoExploring,
    AutoWorking,
}

/// One persisted step of a queued movement route.
#[derive(Clone, Copy, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
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
#[derive(Clone, Debug, Eq, PartialEq, serde::Deserialize, serde::Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct QueuedMovePathDto {
    /// Final requested odd-q column.
    pub target_col: i32,
    /// Final requested odd-q row.
    pub target_row: i32,
    /// Steps in execution order, including the origin.
    pub steps: Vec<MovementStepDto>,
}
