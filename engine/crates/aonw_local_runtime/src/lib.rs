//! Lifecycle boundary for one deterministic local game session.

#![forbid(unsafe_code)]

mod command_dispatch;
mod player_view;
mod prepared_world;
mod query_cache;
mod query_dispatch;
mod session;

pub use command_dispatch::{MoveUnitResultV1, MoveUnitV1, PlayerViewPatchV1};
pub use player_view::{PlayerUnitViewV1, PlayerViewSnapshotV1};
pub use query_cache::QueryCacheStats;
pub use query_dispatch::{
    MovementStepViewV1, QueryRequestV1, QueryResultV1, ReachableRequestV1, ReachableResultV1,
    ReachableTileViewV1, RoutePlanRequestV1, RoutePlanResultV1,
};
pub use session::{
    LOCAL_SESSION_CONTRACT_VERSION, LocalRuntime, OpenSessionError, OpenSessionV1,
    RuntimeCapabilities, RuntimeError, SessionStampV1,
};
