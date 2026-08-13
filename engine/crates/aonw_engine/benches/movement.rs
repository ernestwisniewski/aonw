//! Diagnostic map and movement baseline without a timing gate.

use std::hint::black_box;
use std::time::Instant;

use aonw_content::{GridLayout, MapDefinition, MapDocument, TerrainType, TileDefinition};
use aonw_domain::{
    HexCoord, MovementState, MovementUnit, MovementUnits, PlayerId, UnitId, UnitKind,
};
use aonw_engine::{
    CompiledMovementMap, EngineContext, GameEngine, MoveUnitCommand, MovementPlanningView,
    MovementSearchMetrics, MovementSearchWorkspace, ReachableMovementQuery, TerrainMovementQuery,
};

const ITERATIONS: usize = 20;

fn main() {
    println!(
        "workload,tiles,units,iterations,median_ns,p95_ns,frontier_pops,expanded_tiles,examined_edges,heap_pushes,route_records,signature"
    );
    for (cols, rows, unit_counts) in [
        (10, 10, &[1, 10][..]),
        (30, 20, &[1, 64][..]),
        (40, 30, &[1, 64, 512][..]),
    ] {
        benchmark_map(cols, rows, unit_counts);
    }
}

fn benchmark_map(cols: u16, rows: u16, unit_counts: &[usize]) {
    let map = map(cols, rows);
    let document = MapDocument::try_new(map.clone(), 1.0).expect("benchmark map document");
    let json = document.to_versioned_json().expect("benchmark map JSON");
    report(
        "open",
        cols,
        rows,
        0,
        MovementSearchMetrics::default(),
        || {
            let opened = MapDocument::from_json(black_box(json.as_bytes())).expect("open map");
            signature_bytes(
                opened
                    .map()
                    .content_hash()
                    .expect("content hash")
                    .as_bytes(),
            )
        },
    );
    report(
        "content_hash",
        cols,
        rows,
        0,
        MovementSearchMetrics::default(),
        || {
            signature_bytes(
                black_box(&map)
                    .content_hash()
                    .expect("content hash")
                    .as_bytes(),
            )
        },
    );
    for &unit_count in unit_counts {
        benchmark_movement(&map, cols, rows, unit_count);
    }
}

fn benchmark_movement(map: &MapDefinition, cols: u16, rows: u16, unit_count: usize) {
    let actor = PlayerId::new("player-1").expect("actor id");
    let mover_id = UnitId::new("unit-0").expect("mover id");
    let state = movement_state(cols, rows, unit_count, &actor);
    let context = EngineContext::new(&actor, map, MovementPlanningView::fog_disabled());
    let compiled = CompiledMovementMap::compile(map, aonw_content::RulesetDefinition::standard())
        .expect("compiled movement map");
    let prepared_context = context.with_compiled_movement_map(&compiled);
    let target = HexCoord::new(i32::from(cols) - 1, i32::from(rows) - 1);
    let (reachable_metrics, route_metrics, apply_metrics) =
        movement_metrics(&state, context, &mover_id, target);

    benchmark_reachable(
        &state,
        context,
        prepared_context,
        &mover_id,
        (cols, rows, unit_count),
        reachable_metrics,
    );
    benchmark_routes(
        &state,
        context,
        prepared_context,
        &mover_id,
        target,
        (cols, rows, unit_count),
        route_metrics,
    );
    benchmark_apply(
        &state,
        context,
        &mover_id,
        (cols, rows, unit_count),
        apply_metrics,
    );
}

fn benchmark_reachable(
    state: &MovementState,
    context: EngineContext<'_>,
    prepared_context: EngineContext<'_>,
    mover_id: &UnitId,
    dimensions: (u16, u16, usize),
    metrics: MovementSearchMetrics,
) {
    let (cols, rows, units) = dimensions;
    let signature = |result: &aonw_engine::ReachableMovement| {
        result
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
            })
    };
    report("reachable", cols, rows, units, metrics, || {
        GameEngine::reachable_movement(
            black_box(state),
            context,
            ReachableMovementQuery::new(state.revision(), mover_id),
        )
        .map_or_else(
            |error| signature_bytes(error.code().as_bytes()),
            |result| signature(&result),
        )
    });
    let mut workspace = MovementSearchWorkspace::default();
    report("prepared_reachable", cols, rows, units, metrics, || {
        GameEngine::reachable_movement_with_workspace(
            black_box(state),
            prepared_context,
            ReachableMovementQuery::new(state.revision(), mover_id),
            &mut workspace,
        )
        .map_or_else(
            |error| signature_bytes(error.code().as_bytes()),
            |result| signature(&result),
        )
    });
}

fn benchmark_routes(
    state: &MovementState,
    context: EngineContext<'_>,
    prepared_context: EngineContext<'_>,
    mover_id: &UnitId,
    target: HexCoord,
    dimensions: (u16, u16, usize),
    metrics: MovementSearchMetrics,
) {
    let (cols, rows, units) = dimensions;
    for (name, selected_context) in [("route", context), ("prepared_route", prepared_context)] {
        report(name, cols, rows, units, metrics, || {
            GameEngine::plan_terrain_route(
                black_box(state),
                selected_context,
                TerrainMovementQuery::new(state.revision(), mover_id, target),
            )
            .map_or_else(
                |error| signature_bytes(error.code().as_bytes()),
                |result| route_signature(&result),
            )
        });
    }
    let occupied_target = HexCoord::new(i32::from(cols) - 2, i32::from(rows) - 1);
    let occupied_state = occupied_target_state(state, occupied_target);
    let query = || TerrainMovementQuery::new(occupied_state.revision(), mover_id, occupied_target);
    let occupied_metrics =
        GameEngine::plan_terrain_route(&occupied_state, prepared_context, query()).map_or_else(
            |_| MovementSearchMetrics::default(),
            |result| result.search_metrics(),
        );
    report(
        "occupied_approach",
        cols,
        rows,
        units + 1,
        occupied_metrics,
        || {
            GameEngine::plan_terrain_route(black_box(&occupied_state), prepared_context, query())
                .map_or_else(
                    |error| signature_bytes(error.code().as_bytes()),
                    |result| {
                        mix(
                            signed(result.destination().col()),
                            signed(result.destination().row()),
                        )
                    },
                )
        },
    );
}

fn benchmark_apply(
    state: &MovementState,
    context: EngineContext<'_>,
    mover_id: &UnitId,
    dimensions: (u16, u16, usize),
    metrics: MovementSearchMetrics,
) {
    let (cols, rows, units) = dimensions;
    report("apply", cols, rows, units, metrics, || {
        GameEngine::apply_move_unit(
            black_box(state),
            context,
            MoveUnitCommand::new(state.revision(), mover_id, HexCoord::new(1, 0)),
        )
        .map_or_else(
            |error| signature_bytes(error.code().as_bytes()),
            |result| {
                let next = result.state();
                let moved = next.unit(mover_id).expect("moved unit");
                mix(
                    mix(next.revision(), signed(moved.position().col())),
                    u64::from(moved.movement_units().get()),
                )
            },
        )
    });
}

fn route_signature(result: &aonw_engine::TerrainMovementPlan) -> u64 {
    result
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
        })
}

fn movement_metrics(
    state: &MovementState,
    context: EngineContext<'_>,
    mover_id: &UnitId,
    target: HexCoord,
) -> (
    MovementSearchMetrics,
    MovementSearchMetrics,
    MovementSearchMetrics,
) {
    let reachable = GameEngine::reachable_movement(
        state,
        context,
        ReachableMovementQuery::new(state.revision(), mover_id),
    )
    .map_or_else(
        |_| MovementSearchMetrics::default(),
        |result| result.search_metrics(),
    );
    let route = GameEngine::plan_terrain_route(
        state,
        context,
        TerrainMovementQuery::new(state.revision(), mover_id, target),
    )
    .map_or_else(
        |_| MovementSearchMetrics::default(),
        |result| result.search_metrics(),
    );
    let apply = GameEngine::apply_move_unit(
        state,
        context,
        MoveUnitCommand::new(state.revision(), mover_id, HexCoord::new(1, 0)),
    )
    .map_or_else(
        |_| MovementSearchMetrics::default(),
        |result| result.search_metrics(),
    );
    (reachable, route, apply)
}

fn report(
    workload: &str,
    cols: u16,
    rows: u16,
    units: usize,
    metrics: MovementSearchMetrics,
    mut operation: impl FnMut() -> u64,
) {
    for _ in 0..3 {
        black_box(operation());
    }
    let mut samples = Vec::with_capacity(ITERATIONS);
    let mut signature = 0;
    for _ in 0..ITERATIONS {
        let started = Instant::now();
        signature = black_box(operation());
        samples.push(started.elapsed().as_nanos());
    }
    samples.sort_unstable();
    let median = samples[samples.len() / 2];
    let p95 = samples[(samples.len() * 95 / 100).min(samples.len() - 1)];
    println!(
        "{workload},{},{units},{ITERATIONS},{median},{p95},{},{},{},{},{},{signature:016x}",
        usize::from(cols) * usize::from(rows),
        metrics.frontier_pops(),
        metrics.expanded_tiles(),
        metrics.examined_edges(),
        metrics.heap_pushes(),
        metrics.route_records(),
    );
}

fn map(cols: u16, rows: u16) -> MapDefinition {
    let tiles = (0..rows)
        .flat_map(|row| {
            (0..cols).map(move |col| {
                TileDefinition::try_new(
                    HexCoord::new(i32::from(col), i32::from(row)),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("benchmark tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        format!("benchmark_{cols}x{rows}"),
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .expect("benchmark map")
}

fn movement_state(cols: u16, rows: u16, unit_count: usize, actor: &PlayerId) -> MovementState {
    let mut units = Vec::with_capacity(unit_count);
    units.push(MovementUnit::new(
        UnitId::new("unit-0").expect("mover id"),
        actor.clone(),
        UnitKind::Commander,
        HexCoord::new(0, 0),
        MovementUnits::new(10),
    ));
    let positions = (1..rows).flat_map(|row| {
        (0..cols.saturating_sub(1)).map(move |col| HexCoord::new(i32::from(col), i32::from(row)))
    });
    for (index, position) in positions.take(unit_count.saturating_sub(1)).enumerate() {
        units.push(MovementUnit::new(
            UnitId::new(format!("unit-{}", index + 1)).expect("blocker id"),
            actor.clone(),
            UnitKind::Warrior,
            position,
            MovementUnits::new(6),
        ));
    }
    assert_eq!(units.len(), unit_count, "benchmark unit count must fit map");
    MovementState::try_new(1, 1, units).expect("benchmark state")
}

fn occupied_target_state(state: &MovementState, target: HexCoord) -> MovementState {
    let mut units = state.units().to_vec();
    units.push(MovementUnit::new(
        UnitId::new("occupied-target").expect("blocker id"),
        PlayerId::new("player-2").expect("blocker owner"),
        UnitKind::Warrior,
        target,
        MovementUnits::new(6),
    ));
    MovementState::try_new(state.revision(), state.turn(), units).expect("occupied target state")
}

fn signed(value: i32) -> u64 {
    i64::from(value).cast_unsigned()
}

fn signature_bytes(bytes: &[u8]) -> u64 {
    bytes.iter().fold(0xcbf2_9ce4_8422_2325, |digest, byte| {
        mix(digest, u64::from(*byte))
    })
}

const fn mix(digest: u64, value: u64) -> u64 {
    (digest ^ value).wrapping_mul(0x0000_0100_0000_01b3)
}
