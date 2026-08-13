//! Stable output signatures for the reference movement workload.

use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    HexCoord, MovementState, MovementUnit, MovementUnits, PlayerId, UnitId, UnitKind,
};
use aonw_engine::{
    EngineContext, GameEngine, MoveUnitCommand, MovementPlanningView, ReachableMovementQuery,
    TerrainMovementQuery,
};

#[test]
fn reference_workload_outputs_are_deterministic() {
    let map = map();
    let actor = PlayerId::new("player-1").expect("actor id");
    let mover_id = UnitId::new("unit-0").expect("mover id");
    let state = state(&actor);
    let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

    let reachable = GameEngine::reachable_movement(
        &state,
        context,
        ReachableMovementQuery::new(state.revision(), &mover_id),
    )
    .expect("reachable workload");
    let reachable_signature =
        reachable
            .tiles()
            .iter()
            .fold(0xcbf2_9ce4_8422_2325, |digest, tile| {
                mix(
                    mix(
                        mix(digest, signed(tile.coordinate().col())),
                        signed(tile.coordinate().row()),
                    ),
                    u64::from(tile.cost().get()),
                )
            });

    let route = GameEngine::plan_terrain_route(
        &state,
        context,
        TerrainMovementQuery::new(state.revision(), &mover_id, HexCoord::new(39, 29)),
    )
    .expect("route workload");
    let route_signature = route
        .steps()
        .iter()
        .fold(0xcbf2_9ce4_8422_2325, |digest, step| {
            mix(
                mix(
                    mix(digest, signed(step.coordinate().col())),
                    signed(step.coordinate().row()),
                ),
                u64::from(step.cumulative_cost().get()),
            )
        });

    let transition = GameEngine::apply_move_unit(
        &state,
        context,
        MoveUnitCommand::new(state.revision(), &mover_id, HexCoord::new(1, 0)),
    )
    .expect("apply workload");
    let moved = transition.state().unit(&mover_id).expect("moved unit");
    let apply_signature = mix(
        mix(
            transition.state().revision(),
            signed(moved.position().col()),
        ),
        u64::from(moved.movement_units().get()),
    );

    assert_eq!(reachable_signature, 0x0640_82dd_455f_87ae);
    assert_eq!(route_signature, 0xd251_05c5_932a_ff07);
    assert_eq!(apply_signature, 0x000a_2a00_0008_9be3);
    assert_eq!(
        (
            reachable.search_metrics().frontier_pops(),
            reachable.search_metrics().expanded_tiles(),
            reachable.search_metrics().examined_edges(),
            reachable.search_metrics().heap_pushes(),
            reachable.search_metrics().route_records(),
        ),
        (6, 5, 18, 6, 0),
    );
    assert_eq!(
        (
            route.search_metrics().frontier_pops(),
            route.search_metrics().expanded_tiles(),
            route.search_metrics().examined_edges(),
            route.search_metrics().heap_pushes(),
            route.search_metrics().route_records(),
        ),
        (2_824, 2_823, 16_250, 3_021, 3_021),
    );
    assert_eq!(
        (
            transition.search_metrics().frontier_pops(),
            transition.search_metrics().expanded_tiles(),
            transition.search_metrics().examined_edges(),
            transition.search_metrics().heap_pushes(),
            transition.search_metrics().route_records(),
        ),
        (2, 1, 2, 2, 2),
    );
}

fn map() -> MapDefinition {
    let tiles = (0..30)
        .flat_map(|row| {
            (0..40).map(move |col| {
                TileDefinition::try_new(
                    HexCoord::new(col, row),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("reference tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "benchmark_40x30",
        GridLayout::OddQFlatTop,
        40,
        30,
        tiles,
        Vec::new(),
    )
    .expect("reference map")
}

fn state(actor: &PlayerId) -> MovementState {
    let mut units = vec![MovementUnit::new(
        UnitId::new("unit-0").expect("mover id"),
        actor.clone(),
        UnitKind::Commander,
        HexCoord::new(0, 0),
        MovementUnits::new(10),
    )];
    let positions = (1..30).flat_map(|row| (0..39).map(move |col| HexCoord::new(col, row)));
    for (index, position) in positions.take(63).enumerate() {
        units.push(MovementUnit::new(
            UnitId::new(format!("unit-{}", index + 1)).expect("blocker id"),
            actor.clone(),
            UnitKind::Warrior,
            position,
            MovementUnits::new(6),
        ));
    }
    MovementState::try_new(1, 1, units).expect("reference state")
}

fn signed(value: i32) -> u64 {
    i64::from(value).cast_unsigned()
}

const fn mix(digest: u64, value: u64) -> u64 {
    (digest ^ value).wrapping_mul(0x0000_0100_0000_01b3)
}
