use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    GameState, HexCoord, HexGridBounds, MovementUnits, PlayerId, StateRevision, Unit, UnitId,
    UnitKind, UnitOccupancyPolicy,
};

use crate::{
    CompiledMovementMap, ENGINE_BEHAVIOR_VERSION, EngineContext, GameEngine,
    movement::MovementPlanningView,
};

#[test]
fn engine_summary_reports_canonical_state() {
    let player_id = PlayerId::new("player-1").expect("valid player id");
    let unit = Unit::builder(
        UnitId::new("unit-1").expect("valid unit id"),
        player_id,
        UnitKind::Commander,
        "unit.commander",
        HexCoord::new(3, 2),
        MovementUnits::new(10),
    )
    .build()
    .expect("valid unit");
    let state = GameState::try_new(
        StateRevision::new(12),
        4,
        HexGridBounds::new(5, 5).expect("valid bounds"),
        UnitOccupancyPolicy::Exclusive,
        [unit],
    )
    .expect("valid state");

    let summary = GameEngine::summarize_state(&state);
    assert_eq!(summary.revision, 12);
    assert_eq!(summary.turn, 4);
    assert_eq!(summary.unit_count, 1);
}

#[test]
fn engine_version_axes_are_explicit() {
    let version = GameEngine::version();

    assert_eq!(version.crate_version, env!("CARGO_PKG_VERSION"));
    assert_eq!(version.behavior_version, ENGINE_BEHAVIOR_VERSION);
}

#[test]
fn engine_context_carries_actor_and_map_explicitly() {
    let actor = PlayerId::new("player-1").expect("valid player id");
    let tile = TileDefinition::try_new(
        HexCoord::new(0, 0),
        vec![TerrainType::Plains],
        Vec::new(),
        0,
    )
    .expect("valid tile");
    let map = MapDefinition::try_new(
        "fixture",
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![tile],
        Vec::new(),
    )
    .expect("valid logical map");

    let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());

    assert_eq!(context.actor_player_id(), &actor);
    assert_eq!(context.map().map_id(), "fixture");
}

#[test]
fn compiled_context_uses_the_content_it_was_compiled_from() {
    let actor = PlayerId::new("player-1").expect("valid player id");
    let map = single_tile_map("source");
    let other_map = single_tile_map("other");
    let compiled =
        CompiledMovementMap::compile(&map, RulesetDefinition::standard()).expect("compiled");

    let context = EngineContext::new(&actor, &other_map, MovementPlanningView::fog_disabled())
        .with_compiled_movement_map(&compiled);

    assert_eq!(context.map().map_id(), "source");
    assert_eq!(context.ruleset(), RulesetDefinition::standard());
}

fn single_tile_map(map_id: &str) -> MapDefinition {
    MapDefinition::try_new(
        map_id,
        GridLayout::OddQFlatTop,
        1,
        1,
        vec![
            TileDefinition::try_new(
                HexCoord::new(0, 0),
                vec![TerrainType::Plains],
                Vec::new(),
                0,
            )
            .expect("valid tile"),
        ],
        Vec::new(),
    )
    .expect("valid logical map")
}
