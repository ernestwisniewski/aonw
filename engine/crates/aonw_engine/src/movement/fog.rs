use std::cmp::Ordering;
use std::collections::BinaryHeap;

use aonw_content::{MapDefinition, TerrainType};
use aonw_domain::{City, Diplomacy, FogOfWar, HexCoord, PlayerFog, PlayerId, PlayerPair, Unit};

const UNIT_VISION_RANGE: u32 = 2;
const CITY_CENTER_VISION_RANGE: u32 = 2;
const CONTROLLED_HEX_VISION_RANGE: u32 = 0;
const MAX_VISION_RANGE: u32 = 3;

pub(crate) fn recompute_after_move(
    current: &FogOfWar,
    map: &MapDefinition,
    player_id: &PlayerId,
    units: &[&Unit],
    cities: &[City],
) -> FogOfWar {
    let mut visible = Vec::new();
    for unit in units
        .iter()
        .copied()
        .filter(|unit| unit.owner_player_id() == player_id)
    {
        let observer_height = map
            .tile_at(unit.position())
            .map_or(0, aonw_content::TileDefinition::height);
        let range = (UNIT_VISION_RANGE + u32::from(observer_height / 2)).min(MAX_VISION_RANGE);
        visible.extend(visible_from_source(
            map,
            unit.position(),
            range,
            observer_height,
        ));
    }
    for city in cities
        .iter()
        .filter(|city| city.owner_player_id() == player_id)
    {
        visible.extend(visible_from_source(
            map,
            city.center(),
            CITY_CENTER_VISION_RANGE,
            0,
        ));
        for coordinate in city.controlled_hexes() {
            visible.extend(visible_from_source(
                map,
                *coordinate,
                CONTROLLED_HEX_VISION_RANGE,
                0,
            ));
        }
    }
    let player = match current.player(player_id) {
        Some(current_player) => current_player.with_visible_hexes(visible),
        None => PlayerFog::new(player_id.clone(), [], visible),
    };
    current.updating_player(player)
}

pub(crate) fn merge_discovered_contacts(
    diplomacy: &Diplomacy,
    fog: &FogOfWar,
    units: &[&Unit],
    cities: &[City],
) -> Diplomacy {
    let mut players = fog
        .players()
        .iter()
        .map(|player| player.player_id().clone())
        .chain(units.iter().map(|unit| unit.owner_player_id().clone()))
        .chain(cities.iter().map(|city| city.owner_player_id().clone()))
        .collect::<Vec<_>>();
    players.sort_unstable();
    players.dedup();
    let mut contacts = Vec::new();
    for player_id in players {
        for city in cities
            .iter()
            .filter(|city| city.owner_player_id() != &player_id)
        {
            if fog.visibility(&player_id, city.center()) != aonw_domain::FogVisibility::Hidden
                && let Some(pair) =
                    PlayerPair::new(player_id.clone(), city.owner_player_id().clone())
            {
                contacts.push(pair);
            }
        }
        for unit in units
            .iter()
            .copied()
            .filter(|unit| unit.owner_player_id() != &player_id)
        {
            if fog.visibility(&player_id, unit.position()) == aonw_domain::FogVisibility::Visible
                && let Some(pair) =
                    PlayerPair::new(player_id.clone(), unit.owner_player_id().clone())
            {
                contacts.push(pair);
            }
        }
    }
    diplomacy.merging(contacts)
}

fn visible_from_source(
    map: &MapDefinition,
    origin: HexCoord,
    range: u32,
    observer_height: u8,
) -> Vec<HexCoord> {
    if map.tile_at(origin).is_none() {
        return Vec::new();
    }
    let mut visible = vec![origin];
    let mut best_costs = vec![u32::MAX; map.bounds().tile_count()];
    let Some(origin_index) = map.tile_index(origin) else {
        return Vec::new();
    };
    best_costs[origin_index.get()] = 0;
    let mut frontier = BinaryHeap::new();
    frontier.push(SightNode {
        coordinate: origin,
        cost: 0,
    });

    while let Some(current) = frontier.pop() {
        let Some(index) = map.tile_index(current.coordinate) else {
            continue;
        };
        if best_costs[index.get()] != current.cost {
            continue;
        }
        let is_origin = current.coordinate == origin;
        for neighbor in map.neighbors(current.coordinate) {
            let Some(tile) = map.tile_at(neighbor) else {
                continue;
            };
            let (sight_cost, blocks) = sight_cost(tile.movement_terrains());
            let Some(next_cost) = current.cost.checked_add(sight_cost) else {
                continue;
            };
            if !is_origin && next_cost > range {
                continue;
            }
            visible.push(neighbor);
            let Some(next_index) = map.tile_index(neighbor) else {
                continue;
            };
            if best_costs[next_index.get()] <= next_cost {
                continue;
            }
            best_costs[next_index.get()] = next_cost;
            if blocks || tile.height() > observer_height.saturating_add(1) || next_cost > range {
                continue;
            }
            frontier.push(SightNode {
                coordinate: neighbor,
                cost: next_cost,
            });
        }
    }
    visible.sort_unstable();
    visible.dedup();
    visible
}

fn sight_cost(terrains: &[TerrainType]) -> (u32, bool) {
    let mut cost = 1;
    if terrains.contains(&TerrainType::Forest) {
        cost += 1;
    }
    if terrains.contains(&TerrainType::Jungle) {
        cost += 1;
    }
    if terrains.contains(&TerrainType::Hills) {
        cost += 1;
    }
    (cost, terrains.contains(&TerrainType::Mountain))
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
struct SightNode {
    coordinate: HexCoord,
    cost: u32,
}

impl Ord for SightNode {
    fn cmp(&self, other: &Self) -> Ordering {
        other
            .cost
            .cmp(&self.cost)
            .then_with(|| other.coordinate.col().cmp(&self.coordinate.col()))
            .then_with(|| other.coordinate.row().cmp(&self.coordinate.row()))
    }
}

impl PartialOrd for SightNode {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

#[cfg(test)]
mod tests {
    use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
    use aonw_domain::{FogOfWar, HexCoord, PlayerId};

    use super::visible_from_source;

    fn map() -> MapDefinition {
        let tiles = (0..5)
            .flat_map(|row| {
                (0..5).map(move |col| {
                    TileDefinition::try_new_for_simulation(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect();
        MapDefinition::try_new("fog-map", GridLayout::OddQFlatTop, 5, 5, tiles, Vec::new())
            .expect("map")
    }

    #[test]
    fn visibility_is_deterministic_and_immediate_neighbors_are_visible() {
        let visible = visible_from_source(&map(), HexCoord::new(2, 2), 0, 0);
        assert_eq!(visible.len(), 7);
        assert!(visible.contains(&HexCoord::new(2, 2)));
    }

    #[test]
    fn absent_player_is_inserted_by_authoritative_recompute() {
        let player = PlayerId::new("player-1").expect("player");
        let map = map();
        let unit = aonw_domain::Unit::builder(
            aonw_domain::UnitId::new("unit-1").expect("unit id"),
            player.clone(),
            aonw_domain::UnitKind::Commander,
            "unit.commander",
            HexCoord::new(0, 0),
            aonw_domain::MovementUnits::new(2),
        )
        .build()
        .expect("unit");
        let fog = super::recompute_after_move(&FogOfWar::default(), &map, &player, &[&unit], &[]);
        assert!(fog.tracks(&player));
        assert!(
            !fog.player(&player)
                .expect("player fog")
                .visible_hexes()
                .is_empty()
        );
    }
}
