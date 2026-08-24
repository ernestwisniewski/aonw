use aonw_content::{ResourceType, TerrainType, TileDefinition};

pub(super) fn worked_score(tile: &TileDefinition) -> i32 {
    let (food, production) = tile_yield(tile);
    food.saturating_mul(100)
        .saturating_add(production.saturating_mul(30))
}

pub(super) fn expansion_score(tile: &TileDefinition) -> i32 {
    let (food, production) = tile_yield(tile);
    food.saturating_mul(100)
        .saturating_add(production.saturating_mul(30))
        .saturating_add(if tile.terrain_tags().contains(&TerrainType::River) {
            10
        } else {
            0
        })
        .saturating_add(if tile.resources().is_empty() { 0 } else { 5 })
}

fn tile_yield(tile: &TileDefinition) -> (i32, i32) {
    let (mut food, mut production) = match tile.yield_terrain() {
        TerrainType::Grassland | TerrainType::Wetlands => (2, 0),
        TerrainType::Plains | TerrainType::Forest => (1, 1),
        TerrainType::Hills => (0, 2),
        TerrainType::Tundra | TerrainType::Jungle | TerrainType::Coast | TerrainType::Lake => {
            (1, 0)
        }
        TerrainType::Ocean
        | TerrainType::Desert
        | TerrainType::Snow
        | TerrainType::Mountain
        | TerrainType::River => (0, 0),
    };
    if tile.terrain_tags().contains(&TerrainType::River) {
        food += 1;
    }
    for resource in tile.resources() {
        match resource {
            ResourceType::Wheat
            | ResourceType::Fish
            | ResourceType::Rice
            | ResourceType::Apple
            | ResourceType::Banana
            | ResourceType::Citrus => food += 2,
            ResourceType::Deer | ResourceType::Cow | ResourceType::Sheep => {
                food += 1;
                production += 1;
            }
            ResourceType::Iron | ResourceType::Marble => production += 2,
            ResourceType::Gold
            | ResourceType::Silver
            | ResourceType::Gems
            | ResourceType::Silk
            | ResourceType::Spices
            | ResourceType::Cotton
            | ResourceType::Grapes
            | ResourceType::Ivory
            | ResourceType::Pearls
            | ResourceType::Coffee
            | ResourceType::Cocoa
            | ResourceType::Tobacco
            | ResourceType::Sugar
            | ResourceType::Coal
            | ResourceType::Oil
            | ResourceType::Aluminium
            | ResourceType::Uranium
            | ResourceType::Horses => {}
        }
    }
    (food, production)
}
