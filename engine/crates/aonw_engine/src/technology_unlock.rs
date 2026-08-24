use std::collections::BTreeMap;

use aonw_content::{RulesetDefinition, TechnologyDefinition, TechnologyEffect, TechnologyUnlock};
use aonw_domain::{
    CityBuildingType, FieldImprovementKind, PlayerResearchState, ResourceType, TechnologyId,
    UnitKind, WonderType,
};

const BASIS_POINTS: u128 = 10_000;

/// Read-only availability of one technology for a player.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TechnologyAvailability {
    Unlocked,
    Active,
    Available,
    LockedByPrerequisites,
    LockedByTechnology,
}

/// Aggregated ruleset effects from all unlocked technologies.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct TechnologyEffectSummary {
    /// Production added per controlled strategic resource.
    pub strategic_resource_production: BTreeMap<ResourceType, i32>,
    /// Global gold multiplier in basis points.
    pub global_gold_multiplier_basis_points: u32,
    /// Flat city-defense bonus.
    pub city_defense_bonus: i32,
    /// Army production multiplier in basis points.
    pub army_production_multiplier_basis_points: u32,
    /// Army strength multiplier in basis points.
    pub army_strength_multiplier_basis_points: u32,
    /// Flat army attack bonus.
    pub army_attack_bonus: i32,
    /// Flat army defense bonus.
    pub army_defense_bonus: i32,
    /// Flat army hit-point bonus.
    pub army_hit_points_bonus: i32,
    /// Additional controlled hexes per city.
    pub max_controlled_hexes_bonus: i32,
    /// Flat science bonus per city.
    pub city_science_bonus: i32,
}

/// Invalid technology-query input or incomplete ruleset content.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum TechnologyQueryError {
    TechnologyNotInRuleset(TechnologyId),
    InvalidCityCount(u32),
    CostOverflow(TechnologyId),
    EffectOverflow(TechnologyId),
}

impl core::fmt::Display for TechnologyQueryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::TechnologyNotInRuleset(id) => {
                write!(formatter, "technology is absent from ruleset: {id:?}")
            }
            Self::InvalidCityCount(count) => {
                write!(formatter, "city count must be positive: {count}")
            }
            Self::CostOverflow(id) => write!(formatter, "research cost exceeds u32 for {id:?}"),
            Self::EffectOverflow(id) => write!(formatter, "technology effects overflow for {id:?}"),
        }
    }
}

impl std::error::Error for TechnologyQueryError {}

/// Single authoritative read-only query for research prerequisites and gates.
#[derive(Clone, Copy, Debug)]
pub struct TechnologyUnlockQuery<'query> {
    ruleset: &'query RulesetDefinition,
    research: &'query PlayerResearchState,
}

impl<'query> TechnologyUnlockQuery<'query> {
    /// Binds immutable ruleset content to one player's canonical research state.
    #[must_use]
    pub const fn new(
        ruleset: &'query RulesetDefinition,
        research: &'query PlayerResearchState,
    ) -> Self {
        Self { ruleset, research }
    }

    /// Returns availability after checking unlocked, exclusions, prerequisites, then active state.
    ///
    /// # Errors
    ///
    /// Returns an error when the ruleset omits the requested technology.
    pub fn availability(
        self,
        technology_id: TechnologyId,
    ) -> Result<TechnologyAvailability, TechnologyQueryError> {
        if self.is_unlocked(technology_id) {
            return Ok(TechnologyAvailability::Unlocked);
        }
        let definition = self.definition(technology_id)?;
        if definition
            .blocked_by()
            .iter()
            .any(|blocked| self.is_unlocked(blocked.domain()))
        {
            return Ok(TechnologyAvailability::LockedByTechnology);
        }
        if !definition
            .prerequisites()
            .iter()
            .all(|required| self.is_unlocked(required.domain()))
        {
            return Ok(TechnologyAvailability::LockedByPrerequisites);
        }
        if self.research.active_technology_id() == Some(technology_id) {
            return Ok(TechnologyAvailability::Active);
        }
        Ok(TechnologyAvailability::Available)
    }

    /// Computes the oracle-characterized cost using deterministic fixed-point arithmetic.
    ///
    /// A fulfilled boost applies the definition's first discount only when that
    /// technology actually declares a boost.
    ///
    /// # Errors
    ///
    /// Returns an error for a missing definition, zero cities, or a result above `u32`.
    pub fn effective_cost(
        self,
        technology_id: TechnologyId,
        city_count: u32,
        fulfilled_boost: bool,
    ) -> Result<u32, TechnologyQueryError> {
        if city_count == 0 {
            return Err(TechnologyQueryError::InvalidCityCount(city_count));
        }
        let definition = self.definition(technology_id)?;
        let balance = self.ruleset.technology_cost_balance();
        let city_multiplier = BASIS_POINTS
            + u128::from(city_count - 1) * u128::from(balance.city_scaling_basis_points());
        let discount = if fulfilled_boost {
            definition
                .boosts()
                .first()
                .map_or(0, |boost| boost.discount_basis_points())
        } else {
            0
        };
        let boost_multiplier = BASIS_POINTS - u128::from(discount.min(10_000));
        let era_multiplier = u128::from(balance.era_multiplier_basis_points(definition.era()));
        let numerator = u128::from(definition.base_cost())
            * city_multiplier
            * boost_multiplier
            * era_multiplier;
        let denominator = BASIS_POINTS * BASIS_POINTS * BASIS_POINTS;
        let rounded_up = numerator.div_ceil(denominator).max(1);
        u32::try_from(rounded_up).map_err(|_| TechnologyQueryError::CostOverflow(technology_id))
    }

    /// Returns the complete capability breakdown for a technology.
    ///
    /// # Errors
    ///
    /// Returns an error when the ruleset omits the requested technology.
    pub fn unlock_breakdown(
        self,
        technology_id: TechnologyId,
    ) -> Result<&'static [TechnologyUnlock], TechnologyQueryError> {
        Ok(self.definition(technology_id)?.unlocks())
    }

    /// Returns the technology that gates a building, or `None` for a base building.
    #[must_use]
    pub fn unlocking_technology_for_building(
        self,
        building: CityBuildingType,
    ) -> Option<TechnologyId> {
        self.unlocking_technology(|unlock| {
            matches!(unlock, TechnologyUnlock::Building(value) if value.domain() == building)
        })
    }

    /// Returns whether a building is legal for the player research state.
    #[must_use]
    pub fn is_building_unlocked(self, building: CityBuildingType) -> bool {
        if building == CityBuildingType::Granary {
            return true;
        }
        self.unlocking_technology_for_building(building)
            .is_some_and(|technology| self.is_unlocked(technology))
    }

    /// Returns the technology that gates a field improvement.
    #[must_use]
    pub fn unlocking_technology_for_improvement(
        self,
        improvement: FieldImprovementKind,
    ) -> Option<TechnologyId> {
        self.unlocking_technology(|unlock| {
            matches!(unlock, TechnologyUnlock::Improvement(value) if value.domain() == improvement)
        })
    }

    /// Returns whether a worker improvement is legal for the player research state.
    #[must_use]
    pub fn is_improvement_unlocked(self, improvement: FieldImprovementKind) -> bool {
        self.unlocking_technology_for_improvement(improvement)
            .is_some_and(|technology| self.is_unlocked(technology))
    }

    /// Returns the technology that gates a producible unit kind.
    #[must_use]
    pub fn unlocking_technology_for_unit(self, unit: UnitKind) -> Option<TechnologyId> {
        self.unlocking_technology(
            |unlock| matches!(unlock, TechnologyUnlock::Unit(value) if value.domain() == unit),
        )
    }

    /// Returns whether a city may produce a unit for the player research state.
    #[must_use]
    pub fn is_unit_unlocked(self, unit: UnitKind) -> bool {
        let Some(definition) = self.ruleset.unit(unit) else {
            return false;
        };
        if !definition.capabilities().producible_by_cities() {
            return false;
        }
        match self.unlocking_technology_for_unit(unit) {
            Some(technology) => self.is_unlocked(technology),
            None => matches!(
                unit,
                UnitKind::Warrior | UnitKind::Settler | UnitKind::Worker | UnitKind::Scout
            ),
        }
    }

    /// Returns the technology that gates a wonder.
    #[must_use]
    pub fn unlocking_technology_for_wonder(self, wonder: WonderType) -> Option<TechnologyId> {
        self.unlocking_technology(
            |unlock| matches!(unlock, TechnologyUnlock::Wonder(value) if value.domain() == wonder),
        )
    }

    /// Returns whether a wonder is legal for the player research state.
    #[must_use]
    pub fn is_wonder_unlocked(self, wonder: WonderType) -> bool {
        self.unlocking_technology_for_wonder(wonder)
            .is_some_and(|technology| self.is_unlocked(technology))
    }

    /// Returns the technology required to reveal a strategic resource.
    #[must_use]
    pub fn revealing_technology_for_resource(self, resource: ResourceType) -> Option<TechnologyId> {
        self.unlocking_technology(|unlock| {
            matches!(unlock, TechnologyUnlock::ResourceVisibility(value) if value.domain() == resource)
        })
    }

    /// Returns whether resource identity may be disclosed to this player.
    #[must_use]
    pub fn is_resource_revealed(self, resource: ResourceType) -> bool {
        match resource {
            ResourceType::Horses
            | ResourceType::Coal
            | ResourceType::Oil
            | ResourceType::Aluminium
            | ResourceType::Uranium => self
                .revealing_technology_for_resource(resource)
                .is_some_and(|technology| self.is_unlocked(technology)),
            _ => true,
        }
    }

    /// Aggregates all unlocked technology modifiers without local combat tables.
    ///
    /// # Errors
    ///
    /// Returns an error if unlocked content is absent or additive values overflow.
    pub fn effect_summary(self) -> Result<TechnologyEffectSummary, TechnologyQueryError> {
        let mut summary = TechnologyEffectSummary::default();
        for technology_id in self.research.unlocked_technology_ids() {
            let definition = self.definition(*technology_id)?;
            for effect in definition.effects() {
                apply_effect(&mut summary, *technology_id, *effect)?;
            }
        }
        Ok(summary)
    }

    fn definition(
        self,
        technology_id: TechnologyId,
    ) -> Result<TechnologyDefinition, TechnologyQueryError> {
        self.ruleset
            .technology(technology_id)
            .ok_or(TechnologyQueryError::TechnologyNotInRuleset(technology_id))
    }

    fn is_unlocked(self, technology_id: TechnologyId) -> bool {
        self.research
            .unlocked_technology_ids()
            .contains(&technology_id)
    }

    fn unlocking_technology(
        self,
        matches_unlock: impl Fn(TechnologyUnlock) -> bool,
    ) -> Option<TechnologyId> {
        self.ruleset.technologies().iter().find_map(|definition| {
            definition
                .unlocks()
                .iter()
                .copied()
                .any(&matches_unlock)
                .then(|| definition.id())
        })
    }
}

fn apply_effect(
    summary: &mut TechnologyEffectSummary,
    technology_id: TechnologyId,
    effect: TechnologyEffect,
) -> Result<(), TechnologyQueryError> {
    let overflow = || TechnologyQueryError::EffectOverflow(technology_id);
    match effect {
        TechnologyEffect::StrategicResourceProduction { resource, amount } => {
            let current = summary
                .strategic_resource_production
                .entry(resource.domain())
                .or_default();
            *current = current.checked_add(amount).ok_or_else(overflow)?;
        }
        TechnologyEffect::GlobalGoldMultiplier { basis_points } => {
            summary.global_gold_multiplier_basis_points = summary
                .global_gold_multiplier_basis_points
                .checked_add(basis_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::CityDefenseBonus { amount } => {
            summary.city_defense_bonus = summary
                .city_defense_bonus
                .checked_add(amount)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::ArmyProductionMultiplier { basis_points } => {
            summary.army_production_multiplier_basis_points = summary
                .army_production_multiplier_basis_points
                .checked_add(basis_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::ArmyStrengthMultiplier { basis_points } => {
            summary.army_strength_multiplier_basis_points = summary
                .army_strength_multiplier_basis_points
                .checked_add(basis_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::ArmyCombatStatsBonus {
            attack,
            defense,
            hit_points,
        } => {
            summary.army_attack_bonus = summary
                .army_attack_bonus
                .checked_add(attack)
                .ok_or_else(overflow)?;
            summary.army_defense_bonus = summary
                .army_defense_bonus
                .checked_add(defense)
                .ok_or_else(overflow)?;
            summary.army_hit_points_bonus = summary
                .army_hit_points_bonus
                .checked_add(hit_points)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::MaxControlledHexesBonus { amount } => {
            summary.max_controlled_hexes_bonus = summary
                .max_controlled_hexes_bonus
                .checked_add(amount)
                .ok_or_else(overflow)?;
        }
        TechnologyEffect::CityScienceBonus { amount } => {
            summary.city_science_bonus = summary
                .city_science_bonus
                .checked_add(amount)
                .ok_or_else(overflow)?;
        }
    }
    Ok(())
}
