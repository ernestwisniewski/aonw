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
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, CommandResult,
    DetachTroopRequest, FoundCityRequest, MerchantCityRequest, MoveUnitRequest, PlayerViewPatch,
    ProductionCommandRequest, SelectCityExpansionHexRequest, SelectTechnologyRequest,
    ToggleWorkedHexRequest, UnitActionRequest, WorkerImprovementRequest, WorkerUnitRequest,
};
pub use persistence::{PersistenceError, ReplayVerification};
pub use player_view::{
    CityFoundingDraftView, OwnedCityPlanningView, PendingActionView, PlayerArtifactLocationView,
    PlayerArtifactView, PlayerCityView, PlayerFieldImprovementView, PlayerRoadView,
    PlayerTurnLifecycleView, PlayerUnitView, PlayerViewSnapshot,
};
pub use query_cache::QueryCacheStats;
pub use query_dispatch::{
    AutoExploreOptionView, CityExpansionOptionsRequest, CityFoundingOptionsRequest,
    CityWorkedHexOptionsRequest, CityYieldRequest, CombatPreviewRequest, DetachmentOptionView,
    MerchantDestinationView, MovementStepView, ProductionOptionsRequest, ReachableRequest,
    ReachableResult, ReachableTileView, ResearchOptionsRequest, RoutePlanRequest, RoutePlanResult,
    RuntimeQuery, RuntimeQueryResult, StrategicResourceProjectionRequest,
    UnitLogisticsOptionsRequest, UnitLogisticsOptionsResult, WorkerOptionsRequest,
};
pub use session::{
    LocalRuntime, OpenSession, OpenSessionError, RuntimeCapabilities, RuntimeError, SessionStamp,
};
pub use turn_dispatch::{FinalizeTimedOutTurnRequest, KickParticipantRequest, TurnCommandRequest};
