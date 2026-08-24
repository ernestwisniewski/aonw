mod catalog;
mod identity;
mod unlock;

use aonw_domain::TechnologyId;
use serde::Serialize;

pub use identity::{TechnologyEra, TechnologyKey};
pub use unlock::{
    TechnologyBuilding, TechnologyImprovement, TechnologyResource, TechnologyUnit, TechnologyWonder,
};

pub(crate) use catalog::STANDARD_TECHNOLOGIES;

/// One capability introduced by a technology.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(tag = "kind", content = "value", rename_all = "camelCase")]
pub enum TechnologyUnlock {
    Building(TechnologyBuilding),
    Improvement(TechnologyImprovement),
    ResourceVisibility(TechnologyResource),
    Unit(TechnologyUnit),
    Wonder(TechnologyWonder),
}

/// One deterministic gameplay modifier introduced by research.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(tag = "kind", rename_all = "camelCase")]
pub enum TechnologyEffect {
    StrategicResourceProduction {
        resource: TechnologyResource,
        amount: i32,
    },
    GlobalGoldMultiplier {
        basis_points: u32,
    },
    CityDefenseBonus {
        amount: i32,
    },
    ArmyProductionMultiplier {
        basis_points: u32,
    },
    ArmyStrengthMultiplier {
        basis_points: u32,
    },
    ArmyCombatStatsBonus {
        attack: i32,
        defense: i32,
        hit_points: i32,
    },
    MaxControlledHexesBonus {
        amount: i32,
    },
    CityScienceBonus {
        amount: i32,
    },
}

/// Condition that can activate a research discount.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(tag = "kind", rename_all = "camelCase")]
pub enum TechnologyBoostCondition {
    ImprovementCount {
        improvement: TechnologyImprovement,
        count: u32,
    },
    ControlsAnyResource {
        resources: &'static [TechnologyResource],
    },
}

/// Ruleset-owned discount opportunity.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TechnologyBoost {
    condition: TechnologyBoostCondition,
    discount_basis_points: u32,
}

impl TechnologyBoost {
    /// Creates one immutable boost definition.
    #[must_use]
    pub const fn new(condition: TechnologyBoostCondition, discount_basis_points: u32) -> Self {
        Self {
            condition,
            discount_basis_points,
        }
    }

    /// Returns the activation condition.
    #[must_use]
    pub const fn condition(self) -> TechnologyBoostCondition {
        self.condition
    }

    /// Returns the discount in basis points.
    #[must_use]
    pub const fn discount_basis_points(self) -> u32 {
        self.discount_basis_points
    }
}

/// Complete logical definition of one research node.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TechnologyDefinition {
    id: TechnologyKey,
    era: TechnologyEra,
    base_cost: u32,
    prerequisites: &'static [TechnologyKey],
    blocked_by: &'static [TechnologyKey],
    unlocks: &'static [TechnologyUnlock],
    effects: &'static [TechnologyEffect],
    boosts: &'static [TechnologyBoost],
}

impl TechnologyDefinition {
    /// Creates one immutable catalog entry.
    #[must_use]
    pub const fn new(
        id: TechnologyKey,
        era: TechnologyEra,
        base_cost: u32,
        prerequisites: &'static [TechnologyKey],
        unlocks: &'static [TechnologyUnlock],
        effects: &'static [TechnologyEffect],
        boosts: &'static [TechnologyBoost],
    ) -> Self {
        Self {
            id,
            era,
            base_cost,
            prerequisites,
            blocked_by: &[],
            unlocks,
            effects,
            boosts,
        }
    }

    /// Returns the canonical domain identity.
    #[must_use]
    pub const fn id(self) -> TechnologyId {
        self.id.domain()
    }
    /// Returns the canonical technology label used by exact rule evidence.
    #[must_use]
    pub const fn label(self) -> &'static str {
        self.id.as_str()
    }
    /// Returns the cost era.
    #[must_use]
    pub const fn era(self) -> TechnologyEra {
        self.era
    }
    /// Returns the unscaled research cost.
    #[must_use]
    pub const fn base_cost(self) -> u32 {
        self.base_cost
    }
    /// Returns prerequisite identities.
    #[must_use]
    pub const fn prerequisites(self) -> &'static [TechnologyKey] {
        self.prerequisites
    }
    /// Returns mutually exclusive technology identities.
    #[must_use]
    pub const fn blocked_by(self) -> &'static [TechnologyKey] {
        self.blocked_by
    }
    /// Returns unlocked capabilities.
    #[must_use]
    pub const fn unlocks(self) -> &'static [TechnologyUnlock] {
        self.unlocks
    }
    /// Returns gameplay modifiers.
    #[must_use]
    pub const fn effects(self) -> &'static [TechnologyEffect] {
        self.effects
    }
    /// Returns available boost definitions.
    #[must_use]
    pub const fn boosts(self) -> &'static [TechnologyBoost] {
        self.boosts
    }
}

/// Fixed-point research-cost policy. Ten thousand basis points equal one.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct TechnologyCostBalance {
    #[serde(rename = "cityScalingPerExtraCityBasisPoints")]
    city_scaling: u32,
    #[serde(rename = "defaultBoostDiscountBasisPoints")]
    default_boost_discount: u32,
    #[serde(rename = "specializationEraMultiplierBasisPoints")]
    specialization_era_multiplier: u32,
    #[serde(rename = "industryEraMultiplierBasisPoints")]
    industry_era_multiplier: u32,
    #[serde(rename = "strategyEraMultiplierBasisPoints")]
    strategy_era_multiplier: u32,
}

impl TechnologyCostBalance {
    /// Standard research balance characterized from the frozen oracle.
    pub const STANDARD: Self = Self {
        city_scaling: 1_800,
        default_boost_discount: 2_500,
        specialization_era_multiplier: 13_000,
        industry_era_multiplier: 17_500,
        strategy_era_multiplier: 35_000,
    };

    /// Returns city scaling in basis points.
    #[must_use]
    pub const fn city_scaling_basis_points(self) -> u32 {
        self.city_scaling
    }
    /// Returns the standard fulfilled-boost discount.
    #[must_use]
    pub const fn default_boost_discount_basis_points(self) -> u32 {
        self.default_boost_discount
    }
    /// Returns the multiplier for an era.
    #[must_use]
    pub const fn era_multiplier_basis_points(self, era: TechnologyEra) -> u32 {
        match era {
            TechnologyEra::Foundation | TechnologyEra::Settlement | TechnologyEra::Expansion => {
                10_000
            }
            TechnologyEra::Specialization => self.specialization_era_multiplier,
            TechnologyEra::Industry => self.industry_era_multiplier,
            TechnologyEra::Strategy => self.strategy_era_multiplier,
        }
    }
}
