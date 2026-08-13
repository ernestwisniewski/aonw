/// Maximum encoded movement-state document accepted at a native boundary.
pub const MAX_MOVEMENT_STATE_JSON_BYTES: usize = 8 * 1024 * 1024;

/// Maximum encoded known-unit list accepted at a native boundary.
pub const MAX_KNOWN_UNIT_IDS_JSON_BYTES: usize = 512 * 1024;

/// Maximum unit projections accepted in one movement-state document.
pub const MAX_MOVEMENT_STATE_UNIT_COUNT: usize = 4_096;

/// Maximum visibility identifiers accepted for one actor view.
pub const MAX_KNOWN_UNIT_ID_COUNT: usize = MAX_MOVEMENT_STATE_UNIT_COUNT;

/// Maximum route length including its origin.
pub const MAX_QUEUED_PATH_STEP_COUNT: usize = 1_200;

/// Highest fixed-point balance accepted before ruleset validation.
pub const MAX_MOVEMENT_BALANCE_UNITS: u32 = 14;
