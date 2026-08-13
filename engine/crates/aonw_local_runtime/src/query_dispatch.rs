use aonw_domain::{HexCoord, MovementUnits, UnitId};
use aonw_engine::{
    GameEngine, GameQuery, MovementSearchWorkspace, QueryResult, ReachableMovementQuery,
    TerrainMovementQuery,
};

use crate::session::Session;
use crate::{RuntimeError, SessionStampV1};

/// Current reachable-overlay request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReachableRequestV1 {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
}

/// Current route-preview request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RoutePlanRequestV1 {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
    /// Requested target.
    pub target: HexCoord,
}

/// Versioned local query family.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum QueryRequestV1 {
    /// Current-turn reachable overlay.
    Reachable(ReachableRequestV1),
    /// Deterministic complete route preview.
    RoutePlan(RoutePlanRequestV1),
}

/// One reachable tile.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ReachableTileViewV1 {
    /// Tile coordinate.
    pub coordinate: HexCoord,
    /// Fixed-point path cost.
    pub cost: MovementUnits,
    /// Whether entering consumes the remaining current-turn movement.
    pub exhausts_movement: bool,
}

/// Reachable-overlay response.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReachableResultV1 {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStampV1,
    /// Queried unit.
    pub unit_id: UnitId,
    /// Movement available at query time.
    pub available_movement: MovementUnits,
    /// Stable row-major reachable tiles.
    pub tiles: Box<[ReachableTileViewV1]>,
}

/// One route step including the zero-cost origin.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MovementStepViewV1 {
    /// Step coordinate.
    pub coordinate: HexCoord,
    /// Entry cost.
    pub enter_cost: MovementUnits,
    /// Cumulative route cost.
    pub cumulative_cost: MovementUnits,
}

/// Route-preview response.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RoutePlanResultV1 {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStampV1,
    /// Queried unit.
    pub unit_id: UnitId,
    /// Requested target.
    pub target: HexCoord,
    /// Planned destination, which can be an approach coordinate.
    pub destination: HexCoord,
    /// Total complete-route cost.
    pub total_cost: MovementUnits,
    /// Current-turn movement available.
    pub available_movement: MovementUnits,
    /// Current-turn movement remaining after the executable prefix.
    pub remaining_movement: MovementUnits,
    /// Ordered route including the origin.
    pub steps: Box<[MovementStepViewV1]>,
}

/// Versioned local query response family.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum QueryResultV1 {
    /// Reachable overlay.
    Reachable(ReachableResultV1),
    /// Route preview.
    RoutePlan(RoutePlanResultV1),
}

pub(crate) fn dispatch_query(
    session: &Session,
    request: QueryRequestV1,
    workspace: &mut MovementSearchWorkspace,
) -> Result<QueryResultV1, RuntimeError> {
    match request {
        QueryRequestV1::Reachable(request) => {
            let result = GameEngine::query_with_workspace(
                session.state(),
                session.context(),
                GameQuery::Reachable(ReachableMovementQuery::new(
                    request.expected_revision,
                    &request.unit_id,
                )),
                workspace,
            )
            .map_err(RuntimeError::Query)?;
            let QueryResult::Reachable(result) = result else {
                unreachable!("reachable query returns reachable response")
            };
            Ok(QueryResultV1::Reachable(ReachableResultV1 {
                stamp: session.stamp(),
                unit_id: result.unit_id().clone(),
                available_movement: result.available_movement(),
                tiles: result
                    .tiles()
                    .iter()
                    .map(|tile| ReachableTileViewV1 {
                        coordinate: tile.coordinate(),
                        cost: tile.cost(),
                        exhausts_movement: tile.exhausts_movement(),
                    })
                    .collect(),
            }))
        }
        QueryRequestV1::RoutePlan(request) => {
            let result = GameEngine::query_with_workspace(
                session.state(),
                session.context(),
                GameQuery::PlanRoute(TerrainMovementQuery::new(
                    request.expected_revision,
                    &request.unit_id,
                    request.target,
                )),
                workspace,
            )
            .map_err(RuntimeError::Query)?;
            let QueryResult::Route(result) = result else {
                unreachable!("route query returns route response")
            };
            Ok(QueryResultV1::RoutePlan(RoutePlanResultV1 {
                stamp: session.stamp(),
                unit_id: result.unit_id().clone(),
                target: result.target(),
                destination: result.destination(),
                total_cost: result.total_cost(),
                available_movement: result.available_movement(),
                remaining_movement: result.remaining_movement(),
                steps: result
                    .steps()
                    .iter()
                    .map(|step| MovementStepViewV1 {
                        coordinate: step.coordinate(),
                        enter_cost: step.enter_cost(),
                        cumulative_cost: step.cumulative_cost(),
                    })
                    .collect(),
            }))
        }
    }
}
