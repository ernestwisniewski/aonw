use aonw_domain::{
    GameState, HexCoord, HexGridBounds, InteractionState, MovementUnits, PendingInteraction,
    PlayerId, StateRevision, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};

use super::digest_state;

mod fixture;
mod state_completeness;
mod unit_completeness;

fn unit(id: &str, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("id"),
        PlayerId::new("player-1").expect("player"),
        UnitKind::Commander,
        "unit.commander",
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

#[test]
fn digest_is_independent_of_entity_input_order() {
    let bounds = HexGridBounds::new(3, 3).expect("bounds");
    let left = GameState::try_new(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [
            unit("b", HexCoord::new(1, 1)),
            unit("a", HexCoord::new(0, 0)),
        ],
    )
    .expect("state");
    let right = GameState::try_new(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [
            unit("a", HexCoord::new(0, 0)),
            unit("b", HexCoord::new(1, 1)),
        ],
    )
    .expect("state");
    assert_eq!(digest_state(&left), digest_state(&right));
    assert_eq!(
        digest_state(&left).to_string(),
        "cc004cbbbfb8d0df1180b372e656ae8f9b2aaa61ab3f1f055a538e16900e595a"
    );
}

#[test]
fn digest_includes_reversible_skip_balance() {
    let bounds = HexGridBounds::new(3, 3).expect("bounds");
    let base = unit("unit", HexCoord::new(1, 1));
    let skipped = Unit::builder(
        base.id().clone(),
        base.owner_player_id().clone(),
        base.kind(),
        base.name(),
        base.position(),
        MovementUnits::ZERO,
    )
    .build()
    .expect("skipped unit");
    let base_state = GameState::try_new(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [base],
    )
    .expect("base state");
    let skipped_state = GameState::builder(
        StateRevision::new(1),
        2,
        bounds,
        UnitOccupancyPolicy::Exclusive,
        [skipped],
    )
    .with_interaction(InteractionState::new(
        None,
        Some(PendingInteraction::UnitTurnSkip {
            owner_player_id: PlayerId::new("player-1").expect("player"),
            unit_id: UnitId::new("unit").expect("unit"),
            restore_movement: MovementUnits::new(10),
        }),
    ))
    .try_build()
    .expect("skipped state");

    assert_ne!(digest_state(&base_state), digest_state(&skipped_state));
}
