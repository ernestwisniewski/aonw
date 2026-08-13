use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    HexCoord, MovementState, MovementUnit, MovementUnits, PlayerId, UnitId, UnitKind, UnitPosture,
};

use super::{
    ReachableMovementQuery, TerrainMovementQuery, TerrainMovementQueryError, find_reachable_tiles,
    plan_terrain_route,
};
use crate::{EngineContext, MovementPlanningView};

fn map(cols: u16, rows: u16, rough: &[HexCoord], blocked: &[HexCoord]) -> MapDefinition {
    let mut tiles = Vec::new();
    for row in 0..rows {
        for col in 0..cols {
            let coordinate = HexCoord::new(i32::from(col), i32::from(row));
            let terrains = if blocked.contains(&coordinate) {
                vec![TerrainType::Mountain]
            } else if rough.contains(&coordinate) {
                vec![TerrainType::Plains, TerrainType::Hills]
            } else {
                vec![TerrainType::Plains]
            };
            tiles.push(
                TileDefinition::try_new(coordinate, terrains, Vec::new(), 0).expect("valid tile"),
            );
        }
    }
    MapDefinition::try_new(
        "movement-fixture",
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .expect("valid map")
}

fn unit(id: &str, owner: &PlayerId, position: HexCoord, movement: u32) -> MovementUnit {
    MovementUnit::new(
        UnitId::new(id).expect("valid unit id"),
        owner.clone(),
        UnitKind::Warrior,
        position,
        MovementUnits::new(movement),
    )
}

#[test]
fn route_is_deterministic_when_equal_cost_paths_exist() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(3, 3, &[], &[]);
    let state = MovementState::try_new(7, 1, [unit("unit-1", &actor, HexCoord::new(0, 1), 6)])
        .expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

    let first = plan_terrain_route(
        &state,
        context,
        TerrainMovementQuery::new(7, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("route exists");
    let second = plan_terrain_route(
        &state,
        context,
        TerrainMovementQuery::new(7, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("route exists");

    assert_eq!(first, second);
    assert_eq!(
        first
            .steps()
            .iter()
            .map(|step| step.coordinate())
            .collect::<Vec<_>>(),
        [
            HexCoord::new(0, 1),
            HexCoord::new(1, 0),
            HexCoord::new(2, 1)
        ]
    );
}

#[test]
fn route_reports_rough_cost_and_current_turn_prefix() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(4, 1, &[HexCoord::new(1, 0)], &[]);
    let state = MovementState::try_new(3, 1, [unit("unit-1", &actor, HexCoord::new(0, 0), 3)])
        .expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(3, &unit_id, HexCoord::new(3, 0)),
    )
    .expect("route exists");

    assert_eq!(plan.total_cost(), MovementUnits::new(8));
    assert_eq!(plan.reachable_steps().len(), 2);
    assert_eq!(plan.remaining_movement(), MovementUnits::ZERO);
    assert!(!plan.target_reachable_this_turn());
}

#[test]
fn query_rejects_blocked_occupied_and_out_of_bounds_targets() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(3, 1, &[], &[HexCoord::new(1, 0)]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 0), 6);
    let blocker = unit("unit-2", &actor, HexCoord::new(2, 0), 6);
    let state = MovementState::try_new(5, 1, [mover, blocker]).expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

    assert_eq!(
        plan_terrain_route(
            &state,
            context,
            TerrainMovementQuery::new(5, &unit_id, HexCoord::new(2, 0)),
        ),
        Err(TerrainMovementQueryError::TargetOccupied)
    );
    assert_eq!(
        plan_terrain_route(
            &state,
            context,
            TerrainMovementQuery::new(5, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::PathNotFound)
    );
    assert_eq!(
        plan_terrain_route(
            &state,
            context,
            TerrainMovementQuery::new(5, &unit_id, HexCoord::new(3, 0)),
        ),
        Err(TerrainMovementQueryError::TargetOutOfBounds)
    );
}

#[test]
fn stale_revision_fails_before_route_work() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let state = MovementState::try_new(9, 1, [unit("unit-1", &actor, HexCoord::new(0, 0), 6)])
        .expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    assert_eq!(
        plan_terrain_route(
            &state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(8, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::StaleRevision {
            expected: 8,
            actual: 9,
        })
    );
}

#[test]
fn command_guards_keep_current_rejection_precedence() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let other = PlayerId::new("player-2").expect("valid player");
    let map = map(2, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let foreign = MovementState::try_new(4, 1, [unit("unit-1", &other, HexCoord::new(0, 0), 6)])
        .expect("valid state");
    assert_eq!(
        plan_terrain_route(
            &foreign,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitNotControlled)
    );

    let working = MovementState::try_new(
        4,
        1,
        [unit("unit-1", &actor, HexCoord::new(0, 0), 6).with_movement_blocked(true)],
    )
    .expect("valid state");
    assert_eq!(
        plan_terrain_route(
            &working,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitUnavailable)
    );

    let merchant = MovementUnit::new(
        unit_id.clone(),
        actor.clone(),
        UnitKind::Merchant,
        HexCoord::new(0, 0),
        MovementUnits::new(6),
    );
    let merchant_state = MovementState::try_new(4, 1, [merchant]).expect("valid state");
    assert_eq!(
        plan_terrain_route(
            &merchant_state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitUsesTradeRoutes)
    );
}

#[test]
fn fortified_unit_uses_restored_capacity_for_preview() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let fortified =
        unit("unit-1", &actor, HexCoord::new(0, 0), 0).with_posture(UnitPosture::Fortified);
    let state = MovementState::try_new(2, 1, [fortified]).expect("valid state");

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(2, &unit_id, HexCoord::new(1, 0)),
    )
    .expect("fortified unit can wake and move");

    assert_eq!(plan.available_movement(), MovementUnits::new(6));
    assert!(plan.target_reachable_this_turn());
}

#[test]
fn route_search_handles_the_maximum_supported_map() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(40, 30, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let state = MovementState::try_new(11, 1, [unit("unit-1", &actor, HexCoord::new(0, 0), 6)])
        .expect("valid state");

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(11, &unit_id, HexCoord::new(39, 29)),
    )
    .expect("route exists");

    assert_eq!(
        plan.steps().first().map(|step| step.coordinate()),
        Some(HexCoord::new(0, 0))
    );
    assert_eq!(
        plan.steps().last().map(|step| step.coordinate()),
        Some(HexCoord::new(39, 29))
    );
}

#[test]
fn imported_high_movement_balance_does_not_change_query_precedence() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let state = MovementState::try_new(
        12,
        1,
        [unit("unit-1", &actor, HexCoord::new(0, 0), u32::MAX)],
    )
    .expect("structurally valid state");

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(12, &unit_id, HexCoord::new(1, 0)),
    )
    .expect("legacy balance remains usable until import normalization");

    assert_eq!(plan.destination(), HexCoord::new(1, 0));
}

#[test]
fn fog_aware_planning_does_not_reveal_unknown_blockers() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let other = PlayerId::new("player-2").expect("valid player");
    let map = map(3, 3, &[], &[]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 1), 6);
    let hidden = unit("unit-hidden", &other, HexCoord::new(1, 0), 6);
    let state = MovementState::try_new(3, 1, [mover, hidden]).expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let no_known_units: Vec<UnitId> = Vec::new();

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(
            &actor,
            &map,
            MovementPlanningView::known_units(&no_known_units),
        ),
        TerrainMovementQuery::new(3, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("unknown blockers do not affect the actor-visible route");

    assert!(
        plan.steps()
            .iter()
            .any(|step| step.coordinate() == HexCoord::new(1, 0))
    );
}

#[test]
fn friendly_occupancy_is_known_even_when_visibility_ids_omit_it() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(3, 1, &[], &[]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 0), 6);
    let friendly = unit("unit-2", &actor, HexCoord::new(1, 0), 6);
    let state = MovementState::try_new(3, 1, [mover, friendly]).expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");
    let no_known_units: Vec<UnitId> = Vec::new();

    assert_eq!(
        plan_terrain_route(
            &state,
            EngineContext::new(
                &actor,
                &map,
                MovementPlanningView::known_units(&no_known_units),
            ),
            TerrainMovementQuery::new(3, &unit_id, HexCoord::new(2, 0)),
        ),
        Err(TerrainMovementQueryError::PathNotFound)
    );
}

#[test]
fn occupied_target_uses_deterministic_approach_policy() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let other = PlayerId::new("player-2").expect("valid player");
    let map = map(3, 3, &[], &[]);
    let mover = unit("unit-1", &actor, HexCoord::new(0, 1), 6);
    let enemy = unit("unit-2", &other, HexCoord::new(2, 1), 6);
    let state = MovementState::try_new(4, 1, [mover, enemy]).expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let plan = plan_terrain_route(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        TerrainMovementQuery::new(4, &unit_id, HexCoord::new(2, 1)),
    )
    .expect("enemy target produces an approach route");

    assert_eq!(plan.target(), HexCoord::new(2, 1));
    assert_eq!(plan.destination(), HexCoord::new(1, 0));
}

#[test]
fn action_permission_preserves_not_controlled_precedence() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(2, 1, &[], &[]);
    let state = MovementState::try_new(
        4,
        1,
        [unit("unit-1", &actor, HexCoord::new(0, 0), 6).with_movement_blocked(true)],
    )
    .expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    assert_eq!(
        plan_terrain_route(
            &state,
            EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled())
                .with_action_permission(false),
            TerrainMovementQuery::new(4, &unit_id, HexCoord::new(1, 0)),
        ),
        Err(TerrainMovementQueryError::UnitNotControlled)
    );
}

#[test]
fn reachable_query_performs_one_bounded_row_major_search() {
    let actor = PlayerId::new("player-1").expect("valid actor");
    let map = map(4, 1, &[HexCoord::new(1, 0), HexCoord::new(2, 0)], &[]);
    let state = MovementState::try_new(6, 1, [unit("unit-1", &actor, HexCoord::new(0, 0), 3)])
        .expect("valid state");
    let unit_id = UnitId::new("unit-1").expect("valid unit id");

    let reachable = find_reachable_tiles(
        &state,
        EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled()),
        ReachableMovementQuery::new(6, &unit_id),
    )
    .expect("reachable query succeeds");

    assert_eq!(reachable.tiles().len(), 1);
    assert_eq!(reachable.tiles()[0].coordinate(), HexCoord::new(1, 0));
    assert_eq!(reachable.tiles()[0].cost(), MovementUnits::new(4));
    assert!(reachable.tiles()[0].exhausts_movement());
}
