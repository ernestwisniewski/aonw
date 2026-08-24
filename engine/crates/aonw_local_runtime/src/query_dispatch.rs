use aonw_domain::{CityId, HexCoord, MovementUnits, TroopKind, UnitId};
use aonw_engine::{
    GameEngine, GameQuery, MovementSearchMetrics, MovementSearchWorkspace, QueryResult,
    ReachableMovementQuery, TerrainMovementQuery, UnitLogisticsOptionsQuery,
};

use crate::session::Session;
use crate::{RuntimeError, SessionStamp};

/// Current reachable-overlay request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReachableRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
}

/// Current route-preview request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RoutePlanRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
    /// Requested target.
    pub target: HexCoord,
}

/// Current engine-owned logistics-options request.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitLogisticsOptionsRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to inspect.
    pub unit_id: UnitId,
}

/// Versioned local query family.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuntimeQuery {
    /// Current-turn reachable overlay.
    Reachable(ReachableRequest),
    /// Deterministic complete route preview.
    RoutePlan(RoutePlanRequest),
    /// Auto-exploration, merchant, and detachment options.
    UnitLogisticsOptions(UnitLogisticsOptionsRequest),
}

/// One reachable tile.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct ReachableTileView {
    /// Tile coordinate.
    pub coordinate: HexCoord,
    /// Fixed-point path cost.
    pub cost: MovementUnits,
    /// Whether entering consumes the remaining current-turn movement.
    pub exhausts_movement: bool,
}

/// Reachable-overlay response.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ReachableResult {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStamp,
    /// Queried unit.
    pub unit_id: UnitId,
    /// Movement available at query time.
    pub available_movement: MovementUnits,
    /// Stable row-major reachable tiles.
    pub tiles: Box<[ReachableTileView]>,
}

/// One route step including the zero-cost origin.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MovementStepView {
    /// Step coordinate.
    pub coordinate: HexCoord,
    /// Entry cost.
    pub enter_cost: MovementUnits,
    /// Cumulative route cost.
    pub cumulative_cost: MovementUnits,
}

/// Route-preview response.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RoutePlanResult {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStamp,
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
    pub steps: Box<[MovementStepView]>,
}

/// Engine-selected auto-exploration action.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct AutoExploreOptionView {
    /// Selected target.
    pub target: HexCoord,
    /// Complete route cost.
    pub total_cost: MovementUnits,
    /// Bounded route-search evidence.
    pub search_metrics: MovementSearchMetrics,
}

/// One owned merchant destination accepted by engine rules.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MerchantDestinationView {
    /// Destination city.
    pub city_id: CityId,
    /// Complete route cost.
    pub total_cost: MovementUnits,
}

/// One exact legal troop-detachment action.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct DetachmentOptionView {
    /// Troop kind to detach.
    pub troop_kind: TroopKind,
    /// Engine-selected adjacent destination.
    pub destination: HexCoord,
}

/// Complete engine-owned logistics options for one unit.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitLogisticsOptionsResult {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStamp,
    /// Queried unit.
    pub unit_id: UnitId,
    /// Selected auto-exploration action, when legal.
    pub auto_explore: Option<AutoExploreOptionView>,
    /// Valid cyclic-route destinations.
    pub merchant_route_destinations: Box<[MerchantDestinationView]>,
    /// Valid explicit-travel destinations.
    pub merchant_travel_destinations: Box<[MerchantDestinationView]>,
    /// Exact legal detachments.
    pub detachments: Box<[DetachmentOptionView]>,
}

/// Versioned local query response family.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuntimeQueryResult {
    /// Reachable overlay.
    Reachable(ReachableResult),
    /// Route preview.
    RoutePlan(RoutePlanResult),
    /// Engine-owned logistics options.
    UnitLogisticsOptions(UnitLogisticsOptionsResult),
}

pub(crate) fn dispatch_query(
    session: &Session,
    request: RuntimeQuery,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    match request {
        RuntimeQuery::Reachable(request) => {
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
            Ok(RuntimeQueryResult::Reachable(ReachableResult {
                stamp: session.stamp(),
                unit_id: result.unit_id().clone(),
                available_movement: result.available_movement(),
                tiles: result
                    .tiles()
                    .iter()
                    .map(|tile| ReachableTileView {
                        coordinate: tile.coordinate(),
                        cost: tile.cost(),
                        exhausts_movement: tile.exhausts_movement(),
                    })
                    .collect(),
            }))
        }
        RuntimeQuery::RoutePlan(request) => {
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
            Ok(RuntimeQueryResult::RoutePlan(RoutePlanResult {
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
                    .map(|step| MovementStepView {
                        coordinate: step.coordinate(),
                        enter_cost: step.enter_cost(),
                        cumulative_cost: step.cumulative_cost(),
                    })
                    .collect(),
            }))
        }
        RuntimeQuery::UnitLogisticsOptions(request) => {
            dispatch_logistics_query(session, &request, workspace)
        }
    }
}

fn dispatch_logistics_query(
    session: &Session,
    request: &UnitLogisticsOptionsRequest,
    workspace: &mut MovementSearchWorkspace,
) -> Result<RuntimeQueryResult, RuntimeError> {
    let result = GameEngine::query_with_workspace(
        session.state(),
        session.context(),
        GameQuery::UnitLogisticsOptions(UnitLogisticsOptionsQuery::new(
            request.expected_revision,
            &request.unit_id,
        )),
        workspace,
    )
    .map_err(RuntimeError::Query)?;
    let QueryResult::UnitLogisticsOptions(result) = result else {
        unreachable!("logistics query returns logistics options")
    };
    Ok(RuntimeQueryResult::UnitLogisticsOptions(
        UnitLogisticsOptionsResult {
            stamp: session.stamp(),
            unit_id: result.unit_id().clone(),
            auto_explore: result.auto_explore().map(|option| AutoExploreOptionView {
                target: option.target(),
                total_cost: MovementUnits::new(option.total_cost_units()),
                search_metrics: option.search_metrics(),
            }),
            merchant_route_destinations: result
                .merchant_route_destinations()
                .iter()
                .map(merchant_destination)
                .collect(),
            merchant_travel_destinations: result
                .merchant_travel_destinations()
                .iter()
                .map(merchant_destination)
                .collect(),
            detachments: result
                .detachments()
                .iter()
                .map(|option| DetachmentOptionView {
                    troop_kind: option.troop_kind(),
                    destination: option.destination(),
                })
                .collect(),
        },
    ))
}

fn merchant_destination(
    option: &aonw_engine::MerchantDestinationOption,
) -> MerchantDestinationView {
    MerchantDestinationView {
        city_id: option.city_id().clone(),
        total_cost: MovementUnits::new(option.total_cost_units()),
    }
}
