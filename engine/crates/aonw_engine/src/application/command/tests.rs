use aonw_domain::{
    CityId, DiplomacyStateBuildError, GameState, GameStateBuildError, HexCoord, HexGridBounds,
    PlayerId, StateRevision, TurnLifecycleBuildError, UnitId, UnitOccupancyPolicy,
};

use super::{CanonicalEngineError, EventBudget, PlayerCommand};
use crate::{
    MoveUnitCommand, SelectCityExpansionHexCommand, ToggleWorkedHexCommand, UnitActionCommand,
};

#[test]
fn player_commands_publish_reviewed_event_budgets() {
    let unit_id = UnitId::new("unit-1").expect("unit id");
    let state = GameState::try_new(
        StateRevision::INITIAL,
        1,
        HexGridBounds::new(1, 1).expect("bounds"),
        UnitOccupancyPolicy::Exclusive,
        [],
    )
    .expect("state");

    assert_eq!(
        PlayerCommand::MoveUnit(MoveUnitCommand::new(0, &unit_id, HexCoord::new(1, 0)))
            .event_budget(&state),
        EventBudget::SINGLE
    );
    assert_eq!(
        PlayerCommand::FortifyUnit(UnitActionCommand::new(0, &unit_id)).event_budget(&state),
        EventBudget::NONE
    );
    let city_id = CityId::new("city-1").expect("city id");
    assert_eq!(
        PlayerCommand::ToggleWorkedHex(ToggleWorkedHexCommand::new(
            0,
            &city_id,
            HexCoord::new(0, 0),
        ))
        .event_budget(&state),
        EventBudget::NONE
    );
    assert_eq!(
        PlayerCommand::SelectCityExpansionHex(SelectCityExpansionHexCommand::new(
            0,
            &city_id,
            HexCoord::new(0, 0),
        ))
        .event_budget(&state),
        EventBudget::NONE
    );
}

#[test]
fn canonical_engine_error_formats_every_current_source_family() {
    let player = PlayerId::new("player").expect("player id");
    let unit = UnitId::new("unit").expect("unit id");
    for error in [
        CanonicalEngineError::ContentHash("hash".into()),
        CanonicalEngineError::State(GameStateBuildError::UnitNotFound(unit)),
        CanonicalEngineError::TurnLifecycle(TurnLifecycleBuildError::UnknownPlayer(player)),
        CanonicalEngineError::Diplomacy(DiplomacyStateBuildError::EmptyId),
    ] {
        assert!(!error.to_string().is_empty());
    }
}
