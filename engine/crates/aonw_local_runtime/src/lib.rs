//! Lifecycle boundary for one deterministic local game session.

#![forbid(unsafe_code)]

mod client_protocol;
mod command_dispatch;
mod persistence;
mod persistence_error;
mod persistence_validation;
mod player_view;
mod prepared_world;
mod query_cache;
mod query_dispatch;
mod session;
mod turn_dispatch;

pub use client_protocol::ClientProtocol;
pub use command_dispatch::{
    AttackHexRequest, AutoExploreUnitRequest, CommandResult, DetachTroopRequest, FoundCityRequest,
    MerchantCityRequest, MoveUnitRequest, PlayerViewPatch, SelectCityExpansionHexRequest,
    ToggleWorkedHexRequest, UnitActionRequest,
};
pub use persistence::{PersistenceError, ReplayVerification};
pub use player_view::{
    CityFoundingDraftView, OwnedCityPlanningView, PendingActionView, PlayerCityView,
    PlayerTurnLifecycleView, PlayerUnitView, PlayerViewSnapshot,
};
pub use query_cache::QueryCacheStats;
pub use query_dispatch::{
    AutoExploreOptionView, CityExpansionOptionsRequest, CityFoundingOptionsRequest,
    CityWorkedHexOptionsRequest, CombatPreviewRequest, DetachmentOptionView,
    MerchantDestinationView, MovementStepView, ReachableRequest, ReachableResult,
    ReachableTileView, RoutePlanRequest, RoutePlanResult, RuntimeQuery, RuntimeQueryResult,
    UnitLogisticsOptionsRequest, UnitLogisticsOptionsResult,
};
pub use session::{
    LocalRuntime, OpenSession, OpenSessionError, RuntimeCapabilities, RuntimeError, SessionStamp,
};
pub use turn_dispatch::{FinalizeTimedOutTurnRequest, KickParticipantRequest, TurnCommandRequest};
