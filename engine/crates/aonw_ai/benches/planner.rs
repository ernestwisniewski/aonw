//! Structural allocation baseline for deterministic planning.

use std::alloc::System;
use std::hint::black_box;
use std::time::Instant;

use aonw_ai::{
    BaselinePlanner, BaselinePlanningOutcome, MctsPlanner, MctsPlanningOutcome, PlanningBudget,
    RandomPlanner, RandomPlanningOutcome,
};
use aonw_content::{
    GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
    TerrainType, TileDefinition,
};
use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};
use aonw_local_runtime::{LocalRuntime, OpenSession};
use stats_alloc::{INSTRUMENTED_SYSTEM, Region, Stats, StatsAlloc};

#[global_allocator]
static GLOBAL: &StatsAlloc<System> = &INSTRUMENTED_SYSTEM;

const COLS: u16 = 40;
const ROWS: u16 = 30;
const ITERATIONS: usize = 20;

fn main() {
    println!(
        "workload,tiles,units,iterations,allocations,reallocations,allocated_bytes,payload_bytes,signature,median_ns,p95_ns"
    );
    for unit_count in [1, 64, 512] {
        benchmark(unit_count);
    }
}

fn benchmark(unit_count: usize) {
    let base = opened_runtime(unit_count);
    benchmark_baseline(&base, unit_count);
    benchmark_random(&base, unit_count);
    benchmark_mcts(&base, unit_count);
}

fn benchmark_baseline(base: &LocalRuntime, unit_count: usize) {
    report_with_setup(
        "baseline_plan",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let mut planner = BaselinePlanner::default();
            let BaselinePlanningOutcome::Planned(plan) = planner.plan(&mut runtime).expect("plan")
            else {
                panic!("planned command")
            };
            (fingerprint_signature(plan.fingerprint().as_bytes()), 32)
        },
    );
    report_with_setup(
        "baseline_plan_execute",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let mut planner = BaselinePlanner::default();
            let BaselinePlanningOutcome::Planned(plan) = planner.plan(&mut runtime).expect("plan")
            else {
                panic!("planned command")
            };
            let result = plan.execute(&mut runtime).expect("execute");
            (
                mix(
                    fingerprint_signature(plan.fingerprint().as_bytes()),
                    result.stamp.revision.get(),
                ),
                32,
            )
        },
    );
}

fn benchmark_random(base: &LocalRuntime, unit_count: usize) {
    report_with_setup(
        "random_plan",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let RandomPlanningOutcome::Planned(plan) =
                RandomPlanner::new(77).plan(&mut runtime).expect("plan")
            else {
                panic!("planned command")
            };
            (
                fingerprint_signature(plan.search_fingerprint().as_bytes()),
                trace_payload(plan.rng_trace().draws().len()),
            )
        },
    );
    report_with_setup(
        "random_plan_execute",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let RandomPlanningOutcome::Planned(plan) =
                RandomPlanner::new(77).plan(&mut runtime).expect("plan")
            else {
                panic!("planned command")
            };
            let result = plan.execute(&mut runtime).expect("execute");
            (
                mix(
                    fingerprint_signature(plan.search_fingerprint().as_bytes()),
                    result.stamp.revision.get(),
                ),
                trace_payload(plan.rng_trace().draws().len()),
            )
        },
    );
}

fn benchmark_mcts(base: &LocalRuntime, unit_count: usize) {
    report_with_setup(
        "mcts_plan",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let MctsPlanningOutcome::Planned(plan) = MctsPlanner::new(77, mcts_budget())
                .plan(&mut runtime)
                .expect("search")
            else {
                panic!("planned command")
            };
            (
                fingerprint_signature(plan.search_fingerprint().as_bytes()),
                trace_payload(plan.rng_trace().draws().len()),
            )
        },
    );
    report_with_setup(
        "mcts_plan_execute",
        unit_count,
        || base.clone(),
        |mut runtime| {
            let MctsPlanningOutcome::Planned(plan) = MctsPlanner::new(77, mcts_budget())
                .plan(&mut runtime)
                .expect("search")
            else {
                panic!("planned command")
            };
            let result = plan.execute(&mut runtime).expect("execute");
            (
                mix(
                    fingerprint_signature(plan.search_fingerprint().as_bytes()),
                    result.stamp.revision.get(),
                ),
                trace_payload(plan.rng_trace().draws().len()),
            )
        },
    );
}

fn mcts_budget() -> PlanningBudget {
    PlanningBudget::try_new(8, 8, 2).expect("static benchmark budget")
}

fn trace_payload(draws: usize) -> usize {
    64_usize.saturating_add(draws.saturating_mul(size_of::<u32>()))
}

fn report_with_setup<T>(
    workload: &str,
    units: usize,
    mut setup: impl FnMut() -> T,
    mut operation: impl FnMut(T) -> (u64, usize),
) {
    for _ in 0..3 {
        black_box(operation(setup()));
    }
    let mut samples = Vec::with_capacity(ITERATIONS);
    let mut signature = 0;
    let mut payload_bytes = 0;
    let mut allocation_stats: Option<Stats> = None;
    for _ in 0..ITERATIONS {
        let input = setup();
        let region = Region::new(GLOBAL);
        let started = Instant::now();
        let output = black_box(operation(input));
        samples.push(started.elapsed().as_nanos());
        let observed = region.change();
        if let Some(expected) = allocation_stats {
            assert_eq!(
                observed, expected,
                "allocation sample drifted for {workload}"
            );
        } else {
            allocation_stats = Some(observed);
        }
        signature = output.0;
        payload_bytes = output.1;
    }
    let allocations = allocation_stats.expect("at least one allocation sample");
    samples.sort_unstable();
    let median = samples[samples.len() / 2];
    let p95 = samples[(samples.len() * 95 / 100).min(samples.len() - 1)];
    println!(
        "{workload},{},{units},{ITERATIONS},{},{},{},{payload_bytes},{signature:016x},{median},{p95}",
        usize::from(COLS) * usize::from(ROWS),
        allocations.allocations,
        allocations.reallocations,
        allocations.bytes_allocated,
    );
}

fn opened_runtime(unit_count: usize) -> LocalRuntime {
    let map = map();
    let ruleset = RulesetDefinition::standard().clone();
    let actor = PlayerId::new("player-1").expect("actor");
    let scenario = ScenarioDefinition::try_new(
        "ai-planner-benchmark",
        &map,
        &ruleset,
        scenario_units(unit_count, &actor),
    )
    .expect("scenario");
    let request = OpenSession::from_scenario(map, ruleset, &scenario, actor).expect("request");
    let mut runtime = LocalRuntime::default();
    runtime.open(request).expect("open");
    runtime
}

fn map() -> MapDefinition {
    let tiles = (0..ROWS)
        .flat_map(|row| {
            (0..COLS).map(move |col| {
                TileDefinition::try_new_for_simulation(
                    HexCoord::new(i32::from(col), i32::from(row)),
                    vec![TerrainType::Grassland],
                    Vec::new(),
                    0,
                )
                .expect("tile")
            })
        })
        .collect();
    MapDefinition::try_new(
        "ai-planner-benchmark",
        GridLayout::OddQFlatTop,
        COLS,
        ROWS,
        tiles,
        Vec::new(),
    )
    .expect("map")
}

fn scenario_units(
    unit_count: usize,
    actor: &PlayerId,
) -> impl Iterator<Item = ScenarioUnitDefinition> + '_ {
    core::iter::once(HexCoord::new(0, 0))
        .chain((1..ROWS).flat_map(|row| {
            (0..COLS).map(move |col| HexCoord::new(i32::from(col), i32::from(row)))
        }))
        .take(unit_count)
        .enumerate()
        .map(|(index, position)| {
            ScenarioUnitDefinition::new(
                UnitId::new(format!("unit-{index:04}")).expect("unit id"),
                actor.clone(),
                UnitKind::Commander,
                "Commander",
                position,
            )
        })
}

fn fingerprint_signature(bytes: &[u8; 32]) -> u64 {
    u64::from_le_bytes(bytes[..8].try_into().expect("eight bytes"))
}

const fn mix(digest: u64, value: u64) -> u64 {
    (digest ^ value).wrapping_mul(0x0000_0100_0000_01b3)
}
