use serde::{Deserialize, Serialize};

/// Closed set of stable authoritative command rejection codes.
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ClientCommandRejectionCodeDto {
    /// Command was planned against another canonical revision.
    StaleRevision,
    /// The requested unit does not exist.
    UnitNotFound,
    /// The actor cannot command the requested unit.
    UnitNotControlled,
    /// Current activity prevents manual movement.
    UnitUnavailable,
    /// The unit is controlled by the trade-route subsystem.
    UnitUsesTradeRoutes,
    /// The canonical unit position is outside the map.
    UnitOutOfBounds,
    /// The movement target is outside the map.
    MoveTargetOutOfBounds,
    /// The movement target equals the current unit position.
    MoveTargetIsCurrentTile,
    /// A known foreign city blocks the target.
    MoveTargetIsForeignCityCenter,
    /// A known foreign unit blocks the target.
    MoveTargetOccupied,
    /// The unit cannot pay the minimum movement cost.
    UnitMovementCapacityInsufficient,
    /// No valid route reaches the target.
    MovePathNotFound,
    /// Auto-exploration requires a scout.
    UnitNotScout,
    /// The unit has no movement left for auto-exploration.
    UnitExhausted,
    /// Auto-exploration cannot replace an existing queued path.
    UnitHasPath,
    /// No deterministic exploration target remains.
    AutoExploreNoTarget,
    /// Merchant routing requires a merchant unit.
    UnitNotMerchant,
    /// A cyclic route can only start in an owned city center.
    MerchantNotInCity,
    /// The requested destination city does not exist.
    DestinationCityNotFound,
    /// The requested destination city is not controlled by the actor.
    DestinationCityNotControlled,
    /// A cyclic merchant destination equals its origin.
    DestinationCityIsOrigin,
    /// Explicit merchant travel already starts in the destination city.
    DestinationCityIsCurrent,
    /// No cyclic merchant route reaches the destination.
    MerchantRouteNotFound,
    /// No explicit merchant path reaches the destination city.
    MerchantCityPathNotFound,
    /// The requested troop is absent from the source army.
    TroopNotAvailable,
    /// The detachment source is outside immutable map content.
    DetachmentSourceOutOfBounds,
    /// No legal detachment destination exists.
    DetachmentDestinationUnavailable,
    /// No bounded canonical detached-unit identifier is available.
    DetachedUnitIdUnavailable,
    /// The unit has an activity that prevents the requested action.
    UnitBusy,
    /// The ruleset lacks the requested unit definition.
    UnitDefinitionMissing,
    /// The next canonical revision cannot be represented.
    StateRevisionOverflow,
    /// A queued movement path violates its invariants.
    InvalidQueuedMovementPath,
    /// An engine-produced unit violates its invariants.
    InvalidUnit,
    /// The validated movement unit disappeared during transition construction.
    MovementUnitUpdateFailed,
    /// Player payload identity conflicts with authenticated actor identity.
    TurnPlayerNotControlled,
    /// Participant cannot act in the current turn scope.
    TurnPlayerNotActive,
    /// Trusted lifecycle scope is invalid.
    TurnScopeInvalid,
    /// A later turn processor was requested from the partial kernel.
    TurnProcessorUnsupported,
    /// The next turn number cannot be represented.
    TurnNumberOverflow,
}

impl ClientCommandRejectionCodeDto {
    /// Every code supported by the current client protocol.
    pub const ALL: [Self; 39] = [
        Self::StaleRevision,
        Self::UnitNotFound,
        Self::UnitNotControlled,
        Self::UnitUnavailable,
        Self::UnitUsesTradeRoutes,
        Self::UnitOutOfBounds,
        Self::MoveTargetOutOfBounds,
        Self::MoveTargetIsCurrentTile,
        Self::MoveTargetIsForeignCityCenter,
        Self::MoveTargetOccupied,
        Self::UnitMovementCapacityInsufficient,
        Self::MovePathNotFound,
        Self::UnitNotScout,
        Self::UnitExhausted,
        Self::UnitHasPath,
        Self::AutoExploreNoTarget,
        Self::UnitNotMerchant,
        Self::MerchantNotInCity,
        Self::DestinationCityNotFound,
        Self::DestinationCityNotControlled,
        Self::DestinationCityIsOrigin,
        Self::DestinationCityIsCurrent,
        Self::MerchantRouteNotFound,
        Self::MerchantCityPathNotFound,
        Self::TroopNotAvailable,
        Self::DetachmentSourceOutOfBounds,
        Self::DetachmentDestinationUnavailable,
        Self::DetachedUnitIdUnavailable,
        Self::UnitBusy,
        Self::UnitDefinitionMissing,
        Self::StateRevisionOverflow,
        Self::InvalidQueuedMovementPath,
        Self::InvalidUnit,
        Self::MovementUnitUpdateFailed,
        Self::TurnPlayerNotControlled,
        Self::TurnPlayerNotActive,
        Self::TurnScopeInvalid,
        Self::TurnProcessorUnsupported,
        Self::TurnNumberOverflow,
    ];

    /// Returns the stable snake-case wire value.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::StaleRevision => "stale_revision",
            Self::UnitNotFound => "unit_not_found",
            Self::UnitNotControlled => "unit_not_controlled",
            Self::UnitUnavailable => "unit_unavailable",
            Self::UnitUsesTradeRoutes => "unit_uses_trade_routes",
            Self::UnitOutOfBounds => "unit_out_of_bounds",
            Self::MoveTargetOutOfBounds => "move_target_out_of_bounds",
            Self::MoveTargetIsCurrentTile => "move_target_is_current_tile",
            Self::MoveTargetIsForeignCityCenter => "move_target_is_foreign_city_center",
            Self::MoveTargetOccupied => "move_target_occupied",
            Self::UnitMovementCapacityInsufficient => "unit_movement_capacity_insufficient",
            Self::MovePathNotFound => "move_path_not_found",
            Self::UnitNotScout => "unit_not_scout",
            Self::UnitExhausted => "unit_exhausted",
            Self::UnitHasPath => "unit_has_path",
            Self::AutoExploreNoTarget => "auto_explore_no_target",
            Self::UnitNotMerchant => "unit_not_merchant",
            Self::MerchantNotInCity => "merchant_not_in_city",
            Self::DestinationCityNotFound => "destination_city_not_found",
            Self::DestinationCityNotControlled => "destination_city_not_controlled",
            Self::DestinationCityIsOrigin => "destination_city_is_origin",
            Self::DestinationCityIsCurrent => "destination_city_is_current",
            Self::MerchantRouteNotFound => "merchant_route_not_found",
            Self::MerchantCityPathNotFound => "merchant_city_path_not_found",
            Self::TroopNotAvailable => "troop_not_available",
            Self::DetachmentSourceOutOfBounds => "detachment_source_out_of_bounds",
            Self::DetachmentDestinationUnavailable => "detachment_destination_unavailable",
            Self::DetachedUnitIdUnavailable => "detached_unit_id_unavailable",
            Self::UnitBusy => "unit_busy",
            Self::UnitDefinitionMissing => "unit_definition_missing",
            Self::StateRevisionOverflow => "state_revision_overflow",
            Self::InvalidQueuedMovementPath => "invalid_queued_movement_path",
            Self::InvalidUnit => "invalid_unit",
            Self::MovementUnitUpdateFailed => "movement_unit_update_failed",
            Self::TurnPlayerNotControlled => "turn_player_not_controlled",
            Self::TurnPlayerNotActive => "turn_player_not_active",
            Self::TurnScopeInvalid => "turn_scope_invalid",
            Self::TurnProcessorUnsupported => "turn_processor_unsupported",
            Self::TurnNumberOverflow => "turn_number_overflow",
        }
    }
}
