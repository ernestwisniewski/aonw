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

pub use client_protocol::ClientProtocol;
pub use command_dispatch::{CommandResult, MoveUnitRequest, PlayerViewPatch, UnitActionRequest};
pub use persistence::{PersistenceError, ReplayVerification, RngState};
pub use player_view::{PendingActionView, PlayerUnitView, PlayerViewSnapshot};
pub use query_cache::QueryCacheStats;
pub use query_dispatch::{
    MovementStepView, ReachableRequest, ReachableResult, ReachableTileView, RoutePlanRequest,
    RoutePlanResult, RuntimeQuery, RuntimeQueryResult,
};
pub use session::{
    LocalRuntime, OpenSession, OpenSessionError, RuntimeCapabilities, RuntimeError, SessionStamp,
};
