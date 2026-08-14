use crate::{
    GameState, GameStateBuildError, HexCoord, HexGridBounds, MovementUnits, PlayerId,
    StateRevision, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};

fn unit(id: &str, position: HexCoord) -> Unit {
    Unit::builder(
        UnitId::new(id).expect("unit id"),
        PlayerId::new("player-1").expect("player id"),
        UnitKind::Commander,
        "unit.commander",
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

#[test]
fn aggregate_preserves_contract_order_and_indexes_by_id() {
    let state = GameState::try_new(
        StateRevision::new(7),
        3,
        HexGridBounds::new(5, 5).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [
            unit("unit-z", HexCoord::new(1, 1)),
            unit("unit-a", HexCoord::new(2, 1)),
        ],
    )
    .expect("state");

    assert_eq!(state.units()[0].id().as_str(), "unit-z");
    assert_eq!(
        state
            .unit(&UnitId::new("unit-a").expect("id"))
            .expect("lookup")
            .position(),
        HexCoord::new(2, 1)
    );
}

#[test]
fn aggregate_rejects_out_of_bounds_and_colliding_units() {
    let bounds = HexGridBounds::new(2, 2).expect("bounds");
    let outside = unit("outside", HexCoord::new(2, 0));
    assert!(matches!(
        GameState::try_new(
            StateRevision::INITIAL,
            0,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [outside]
        ),
        Err(GameStateBuildError::UnitOutOfBounds { .. })
    ));

    let position = HexCoord::new(1, 1);
    assert_eq!(
        GameState::try_new(
            StateRevision::INITIAL,
            0,
            bounds,
            UnitOccupancyPolicy::Exclusive,
            [unit("one", position), unit("two", position)]
        ),
        Err(GameStateBuildError::OccupiedCoordinate { position })
    );
}

#[test]
fn friendly_stacking_is_an_explicit_policy() {
    let position = HexCoord::new(1, 1);
    let state = GameState::try_new(
        StateRevision::INITIAL,
        0,
        HexGridBounds::new(2, 2).expect("bounds"),
        UnitOccupancyPolicy::FriendlyStacking,
        [unit("one", position), unit("two", position)],
    );
    assert!(state.is_ok());
}
