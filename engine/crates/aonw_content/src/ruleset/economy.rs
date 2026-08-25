use serde::Serialize;

use crate::{ResourceType, TerrainType};

/// Integer city yield used by deterministic economy rules.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Default, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EconomyYield {
    food: i64,
    production: i64,
    gold: i64,
    defense: i64,
}

#[allow(missing_docs)]
impl EconomyYield {
    /// Creates one exact integer yield value.
    #[must_use]
    pub const fn new(food: i64, production: i64, gold: i64, defense: i64) -> Self {
        Self {
            food,
            production,
            gold,
            defense,
        }
    }
    #[must_use]
    pub const fn food(self) -> i64 {
        self.food
    }
    #[must_use]
    pub const fn production(self) -> i64 {
        self.production
    }
    #[must_use]
    pub const fn gold(self) -> i64 {
        self.gold
    }
    #[must_use]
    pub const fn defense(self) -> i64 {
        self.defense
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct TerrainYieldDefinition {
    terrain: TerrainType,
    value: EconomyYield,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
struct ResourceYieldDefinition {
    resource: ResourceType,
    value: EconomyYield,
}

/// Fixed-point stability effects selected from the current stability net.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct StabilityModifierDefinition {
    production_basis_points: u32,
    gold_basis_points: u32,
    food_bonus: i64,
    halts_growth: bool,
}

#[allow(missing_docs)]
impl StabilityModifierDefinition {
    #[must_use]
    pub const fn production_basis_points(self) -> u32 {
        self.production_basis_points
    }
    #[must_use]
    pub const fn gold_basis_points(self) -> u32 {
        self.gold_basis_points
    }
    #[must_use]
    pub const fn food_bonus(self) -> i64 {
        self.food_bonus
    }
    #[must_use]
    pub const fn halts_growth(self) -> bool {
        self.halts_growth
    }
}

/// Hash-addressed city economy and growth balance.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct EconomyBalance {
    city_center_yield: EconomyYield,
    river_yield: EconomyYield,
    terrain_yields: &'static [TerrainYieldDefinition],
    resource_yields: &'static [ResourceYieldDefinition],
    passive_improvement_numerator: u32,
    passive_improvement_denominator: u32,
    food_upkeep_per_population: i64,
    growth_base_cost: i64,
    growth_cost_per_population: i64,
    growth_cost_per_controlled_hex: i64,
    content_stability_threshold: i64,
    unrest_stability_threshold: i64,
    content_stability: StabilityModifierDefinition,
    stable_stability: StabilityModifierDefinition,
    strained_stability: StabilityModifierDefinition,
    unrest_stability: StabilityModifierDefinition,
}

macro_rules! value {
    ($food:expr, $production:expr, $gold:expr, $defense:expr) => {
        EconomyYield {
            food: $food,
            production: $production,
            gold: $gold,
            defense: $defense,
        }
    };
}

macro_rules! terrain {
    ($terrain:expr, $value:expr) => {
        TerrainYieldDefinition {
            terrain: $terrain,
            value: $value,
        }
    };
}

macro_rules! resource {
    ($resource:expr, $value:expr) => {
        ResourceYieldDefinition {
            resource: $resource,
            value: $value,
        }
    };
}

macro_rules! modifier {
    ($production:expr, $gold:expr, $food:expr, $halts:expr) => {
        StabilityModifierDefinition {
            production_basis_points: $production,
            gold_basis_points: $gold,
            food_bonus: $food,
            halts_growth: $halts,
        }
    };
}

impl EconomyBalance {
    pub(super) const STANDARD: Self = Self {
        city_center_yield: value!(2, 1, 0, 0),
        river_yield: value!(1, 0, 0, 0),
        terrain_yields: &STANDARD_TERRAIN_YIELDS,
        resource_yields: &STANDARD_RESOURCE_YIELDS,
        passive_improvement_numerator: 1,
        passive_improvement_denominator: 2,
        food_upkeep_per_population: 1,
        growth_base_cost: 10,
        growth_cost_per_population: 4,
        growth_cost_per_controlled_hex: 3,
        content_stability_threshold: 4,
        unrest_stability_threshold: -4,
        content_stability: modifier!(10_000, 10_000, 1, false),
        stable_stability: modifier!(10_000, 10_000, 0, false),
        strained_stability: modifier!(10_000, 9_000, 0, true),
        unrest_stability: modifier!(7_500, 7_500, 0, true),
    };

    /// Returns the yield of a city center independently of map terrain.
    #[must_use]
    pub const fn city_center_yield(self) -> EconomyYield {
        self.city_center_yield
    }

    /// Returns the additive yield of the river terrain tag.
    #[must_use]
    pub const fn river_yield(self) -> EconomyYield {
        self.river_yield
    }

    /// Finds the base yield for the authored economic terrain.
    #[must_use]
    pub fn terrain_yield(self, terrain: TerrainType) -> EconomyYield {
        self.terrain_yields
            .iter()
            .find(|definition| definition.terrain == terrain)
            .map_or(EconomyYield::default(), |definition| definition.value)
    }

    /// Finds the additive yield for a map resource.
    #[must_use]
    pub fn resource_yield(self, resource: ResourceType) -> EconomyYield {
        self.resource_yields
            .iter()
            .find(|definition| definition.resource == resource)
            .map_or(EconomyYield::default(), |definition| definition.value)
    }

    /// Returns the passive-improvement yield scale as an integer fraction.
    #[must_use]
    pub const fn passive_improvement_scale(self) -> (u32, u32) {
        (
            self.passive_improvement_numerator,
            self.passive_improvement_denominator,
        )
    }

    /// Returns per-population food upkeep.
    #[must_use]
    pub const fn food_upkeep_per_population(self) -> i64 {
        self.food_upkeep_per_population
    }

    /// Computes checked city growth cost.
    #[must_use]
    pub fn growth_cost(self, population: i64, territory_hex_count: usize) -> Option<i64> {
        let territory = i64::try_from(territory_hex_count).ok()?;
        self.growth_cost_per_population
            .checked_mul(population)?
            .checked_add(self.growth_cost_per_controlled_hex.checked_mul(territory)?)?
            .checked_add(self.growth_base_cost)
    }

    /// Resolves stability effects without floating-point arithmetic.
    #[must_use]
    pub const fn stability_modifier(self, stability_net: i64) -> StabilityModifierDefinition {
        if stability_net >= self.content_stability_threshold {
            self.content_stability
        } else if stability_net <= self.unrest_stability_threshold {
            self.unrest_stability
        } else if stability_net < 0 {
            self.strained_stability
        } else {
            self.stable_stability
        }
    }
}

const ZERO: EconomyYield = value!(0, 0, 0, 0);
const STANDARD_TERRAIN_YIELDS: [TerrainYieldDefinition; 14] = [
    terrain!(TerrainType::Ocean, ZERO),
    terrain!(TerrainType::Coast, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Lake, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Plains, value!(1, 1, 0, 0)),
    terrain!(TerrainType::Grassland, value!(2, 0, 0, 0)),
    terrain!(TerrainType::Desert, ZERO),
    terrain!(TerrainType::Tundra, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Snow, ZERO),
    terrain!(TerrainType::Mountain, ZERO),
    terrain!(TerrainType::Hills, value!(0, 2, 0, 0)),
    terrain!(TerrainType::Wetlands, value!(2, 0, 0, 0)),
    terrain!(TerrainType::Jungle, value!(1, 0, 0, 0)),
    terrain!(TerrainType::Forest, value!(1, 1, 0, 0)),
    terrain!(TerrainType::River, ZERO),
];

const STANDARD_RESOURCE_YIELDS: [ResourceYieldDefinition; 29] = [
    resource!(ResourceType::Wheat, value!(2, 0, 0, 0)),
    resource!(ResourceType::Fish, value!(2, 0, 0, 0)),
    resource!(ResourceType::Deer, value!(1, 1, 0, 0)),
    resource!(ResourceType::Sheep, value!(1, 1, 0, 0)),
    resource!(ResourceType::Rice, value!(2, 0, 0, 0)),
    resource!(ResourceType::Cow, value!(1, 1, 0, 0)),
    resource!(ResourceType::Apple, value!(2, 0, 0, 0)),
    resource!(ResourceType::Banana, value!(2, 0, 0, 0)),
    resource!(ResourceType::Citrus, value!(2, 0, 0, 0)),
    resource!(ResourceType::Gold, ZERO),
    resource!(ResourceType::Silver, ZERO),
    resource!(ResourceType::Gems, ZERO),
    resource!(ResourceType::Silk, ZERO),
    resource!(ResourceType::Spices, ZERO),
    resource!(ResourceType::Cotton, ZERO),
    resource!(ResourceType::Grapes, ZERO),
    resource!(ResourceType::Ivory, ZERO),
    resource!(ResourceType::Pearls, ZERO),
    resource!(ResourceType::Coffee, ZERO),
    resource!(ResourceType::Cocoa, ZERO),
    resource!(ResourceType::Tobacco, ZERO),
    resource!(ResourceType::Sugar, ZERO),
    resource!(ResourceType::Iron, value!(0, 2, 0, 0)),
    resource!(ResourceType::Coal, ZERO),
    resource!(ResourceType::Oil, ZERO),
    resource!(ResourceType::Aluminium, ZERO),
    resource!(ResourceType::Uranium, ZERO),
    resource!(ResourceType::Horses, ZERO),
    resource!(ResourceType::Marble, value!(0, 2, 0, 0)),
];
