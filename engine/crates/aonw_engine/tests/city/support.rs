use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    City, CityId, FogOfWar, GameMode, GameState, HexCoord, InteractionState, MatchIdentity,
    MatchLifecycle, MatchRules, MovementUnits, Participant, PlayerCountry, PlayerId, PlayerKind,
    PlayerTurnState, StateRevision, TurnLifecycle, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
};

pub(super) fn state(
    map: &MapDefinition,
    units: Vec<Unit>,
    cities: Vec<City>,
    interaction: InteractionState,
) -> GameState {
    let mut players = units
        .iter()
        .map(|unit| unit.owner_player_id().clone())
        .chain(cities.iter().map(|city| city.owner_player_id().clone()))
        .chain(
            interaction
                .city_founding_draft()
                .map(|draft| draft.owner_player_id().clone()),
        )
        .chain(
            interaction
                .pending()
                .map(|pending| pending.owner_player_id().clone()),
        )
        .collect::<Vec<_>>();
    players.sort_unstable();
    players.dedup();
    let participants = players
        .iter()
        .enumerate()
        .map(|(index, id)| {
            Participant::try_new(
                id.clone(),
                id.as_str(),
                0xff00_0000 | u32::try_from(index).expect("participant index"),
                PlayerCountry::Poland,
                PlayerKind::Human,
                None,
            )
            .expect("participant")
        })
        .collect::<Vec<_>>();
    let identity =
        MatchIdentity::try_new(MatchRules::default(), participants, GameMode::Multiplayer)
            .expect("identity");
    let lifecycle = TurnLifecycle::try_new(
        &identity,
        players
            .iter()
            .cloned()
            .map(|id| (id, PlayerTurnState::Active))
            .collect::<BTreeMap<_, _>>(),
        players.iter().cloned(),
        [],
        BTreeMap::new(),
        [],
        [],
        None,
    )
    .expect("turn lifecycle");
    GameState::builder(
        StateRevision::new(9),
        4,
        map.bounds(),
        UnitOccupancyPolicy::Exclusive,
        units,
    )
    .with_cities(cities)
    .with_fog_of_war(FogOfWar::default())
    .with_interaction(interaction)
    .with_match_lifecycle(MatchLifecycle::new(identity, lifecycle))
    .try_build()
    .expect("state")
}

pub(super) fn map(width: u16, height: u16) -> MapDefinition {
    MapDefinition::try_new(
        "city-test",
        GridLayout::OddQFlatTop,
        width,
        height,
        (0..i32::from(height))
            .flat_map(|row| {
                (0..i32::from(width)).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect(),
        Vec::new(),
    )
    .expect("map")
}

pub(super) fn unit(id: &str, owner: &PlayerId, kind: UnitKind, position: HexCoord) -> Unit {
    Unit::builder(
        unit_id(id),
        owner.clone(),
        kind,
        id,
        position,
        MovementUnits::new(10),
    )
    .build()
    .expect("unit")
}

pub(super) fn player(id: &str) -> PlayerId {
    PlayerId::new(id).expect("player")
}

pub(super) fn unit_id(id: &str) -> UnitId {
    UnitId::new(id).expect("unit")
}

pub(super) fn city_id(id: &str) -> CityId {
    CityId::new(id).expect("city")
}
