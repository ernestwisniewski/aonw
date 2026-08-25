use aonw_domain::{
    City, CityProductionTarget, CityProjectType, CitySpecializationType, GameState, UnitKind,
};

use super::ProductionError;
use super::support::{city_territory, invalid, technology_for};
use crate::{CityYieldQuery, EngineContext};

const BASIS_POINTS: i64 = 10_000;

pub(super) fn production_per_turn(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    target: CityProductionTarget,
) -> Result<i64, ProductionError> {
    let tile = crate::economy::query_city_yield(
        state,
        context,
        CityYieldQuery::new(state.revision().get(), city.id()),
    )
    .map_err(|error| invalid(error.to_string()))?
    .total()
    .production;
    let building = building_production(context, city)?;
    let (wonder, wonder_multiplier) = wonder_production(state, context, city)?;
    let specialization = specialization_production(city.specialization());
    let technology = technology_production(state, context, city)?;
    let gross = checked_sum([tile, building, wonder, specialization, technology])?.max(0);
    let stability = state
        .economy()
        .player_stability_net()
        .get(city.owner_player_id())
        .copied()
        .unwrap_or(0);
    let stability_multiplier = i64::from(
        context
            .ruleset()
            .economy()
            .stability_modifier(stability)
            .production_basis_points(),
    );
    let stable = scale_floor(gross, stability_multiplier)?;
    let with_wonder = stable
        .checked_add(scale_floor(stable, i64::from(wonder_multiplier))?)
        .ok_or_else(|| invalid("wonder production multiplier overflow"))?;
    let with_technology = if let CityProductionTarget::Unit(_) = target {
        unit_technology_production(state, context, city, with_wonder)?
    } else {
        with_wonder
    };
    with_target_specialization(with_technology, city.specialization(), target)
}

fn building_production(context: EngineContext<'_>, city: &City) -> Result<i64, ProductionError> {
    let river_count = city_territory(city)
        .filter(|coordinate| {
            context.map().tile_at(*coordinate).is_some_and(|tile| {
                tile.terrain_tags()
                    .contains(&aonw_content::TerrainType::River)
            })
        })
        .count();
    city.buildings().iter().try_fold(0_i64, |total, building| {
        let definition = context
            .ruleset()
            .production()
            .building(*building)
            .ok_or_else(|| invalid("completed building is absent from production content"))?;
        let applications = river_count.min(definition.max_river_applications() as usize);
        let river = definition
            .river_yield_per_hex()
            .production()
            .checked_mul(i64::try_from(applications).map_err(|_| invalid("river count overflow"))?)
            .ok_or_else(|| invalid("river building production overflow"))?;
        total
            .checked_add(definition.yield_delta().production())
            .and_then(|value| value.checked_add(river))
            .ok_or_else(|| invalid("building production overflow"))
    })
}

fn wonder_production(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
) -> Result<(i64, u32), ProductionError> {
    let registry = state.wonder_registry().completed_by();
    let mut production = 0_i64;
    let mut multiplier = 0_u32;
    for host in state.cities() {
        if host.owner_player_id() != city.owner_player_id() {
            continue;
        }
        for wonder in host.wonders() {
            if registry.get(wonder) != Some(host.owner_player_id()) {
                continue;
            }
            let definition = context
                .ruleset()
                .production()
                .wonder(*wonder)
                .ok_or_else(|| invalid("completed wonder is absent from production content"))?;
            production = production
                .checked_add(definition.empire_yield_per_city().production())
                .ok_or_else(|| invalid("wonder production overflow"))?;
            if host.id() == city.id() {
                production = production
                    .checked_add(definition.host_yield().production())
                    .ok_or_else(|| invalid("host wonder production overflow"))?;
            }
            multiplier = multiplier
                .checked_add(definition.empire_production_basis_points())
                .ok_or_else(|| invalid("wonder production multiplier overflow"))?;
        }
    }
    Ok((production, multiplier))
}

fn technology_production(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
) -> Result<i64, ProductionError> {
    let effects = technology_for(state, context, city)
        .effect_summary()
        .map_err(|error| invalid(error.to_string()))?;
    city_territory(city).try_fold(0_i64, |total, coordinate| {
        crate::economy::rules::resources_at(state, context, coordinate)
            .into_iter()
            .try_fold(total, |sum, resource| {
                sum.checked_add(i64::from(
                    effects
                        .strategic_resource_production
                        .get(&resource)
                        .copied()
                        .unwrap_or(0),
                ))
                .ok_or_else(|| invalid("technology production overflow"))
            })
    })
}

fn unit_technology_production(
    state: &GameState,
    context: EngineContext<'_>,
    city: &City,
    production: i64,
) -> Result<i64, ProductionError> {
    let basis_points = technology_for(state, context, city)
        .effect_summary()
        .map_err(|error| invalid(error.to_string()))?
        .army_production_multiplier_basis_points;
    if production <= 0 || basis_points == 0 {
        return Ok(production);
    }
    let numerator = production
        .checked_mul(i64::from(basis_points))
        .and_then(|value| value.checked_add(BASIS_POINTS / 2))
        .ok_or_else(|| invalid("unit technology production overflow"))?;
    let bonus = (numerator / BASIS_POINTS).max(1);
    production
        .checked_add(bonus)
        .ok_or_else(|| invalid("unit technology production overflow"))
}

const fn specialization_production(specialization: Option<CitySpecializationType>) -> i64 {
    match specialization {
        Some(CitySpecializationType::Industry) => 2,
        Some(CitySpecializationType::Military) => 1,
        Some(
            CitySpecializationType::Growth
            | CitySpecializationType::Commerce
            | CitySpecializationType::Science,
        )
        | None => 0,
    }
}

fn with_target_specialization(
    production: i64,
    specialization: Option<CitySpecializationType>,
    target: CityProductionTarget,
) -> Result<i64, ProductionError> {
    if production <= 0 {
        return Ok(0);
    }
    let boosted = matches!(
        (specialization, target),
        (
            Some(CitySpecializationType::Growth),
            CityProductionTarget::Unit(UnitKind::Worker | UnitKind::Settler)
        ) | (
            Some(CitySpecializationType::Industry),
            CityProductionTarget::Building(_)
        ) | (
            Some(CitySpecializationType::Commerce),
            CityProductionTarget::Project(CityProjectType::Wealth)
        ) | (
            Some(CitySpecializationType::Science),
            CityProductionTarget::Project(CityProjectType::Research)
        ) | (
            Some(CitySpecializationType::Military),
            CityProductionTarget::Unit(_)
        )
    );
    if boosted {
        production
            .checked_add(1)
            .ok_or_else(|| invalid("specialized production overflow"))
    } else {
        Ok(production)
    }
}

fn checked_sum(values: impl IntoIterator<Item = i64>) -> Result<i64, ProductionError> {
    values.into_iter().try_fold(0_i64, |sum, value| {
        sum.checked_add(value)
            .ok_or_else(|| invalid("city production overflow"))
    })
}

fn scale_floor(value: i64, basis_points: i64) -> Result<i64, ProductionError> {
    value
        .checked_mul(basis_points)
        .and_then(|numerator| numerator.checked_div(BASIS_POINTS))
        .ok_or_else(|| invalid("production multiplier overflow"))
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        CityBuildingType, CityProductionTarget, CityProjectType, CitySpecializationType, UnitKind,
    };

    use super::{specialization_production, with_target_specialization};

    #[test]
    fn specialization_values_and_target_bonuses_cover_every_current_kind() {
        for (specialization, expected) in [
            (None, 0),
            (Some(CitySpecializationType::Growth), 0),
            (Some(CitySpecializationType::Industry), 2),
            (Some(CitySpecializationType::Commerce), 0),
            (Some(CitySpecializationType::Science), 0),
            (Some(CitySpecializationType::Military), 1),
        ] {
            assert_eq!(
                specialization_production(std::hint::black_box(specialization)),
                expected
            );
        }

        for (specialization, target) in [
            (
                CitySpecializationType::Growth,
                CityProductionTarget::Unit(UnitKind::Worker),
            ),
            (
                CitySpecializationType::Growth,
                CityProductionTarget::Unit(UnitKind::Settler),
            ),
            (
                CitySpecializationType::Industry,
                CityProductionTarget::Building(CityBuildingType::Workshop),
            ),
            (
                CitySpecializationType::Commerce,
                CityProductionTarget::Project(CityProjectType::Wealth),
            ),
            (
                CitySpecializationType::Science,
                CityProductionTarget::Project(CityProjectType::Research),
            ),
            (
                CitySpecializationType::Military,
                CityProductionTarget::Unit(UnitKind::Warrior),
            ),
        ] {
            assert_eq!(
                with_target_specialization(4, Some(specialization), target).expect("bonus"),
                5
            );
        }
        assert_eq!(
            with_target_specialization(
                4,
                Some(CitySpecializationType::Growth),
                CityProductionTarget::Building(CityBuildingType::Workshop),
            )
            .expect("no bonus"),
            4
        );
        assert_eq!(
            with_target_specialization(
                0,
                Some(CitySpecializationType::Industry),
                CityProductionTarget::Building(CityBuildingType::Workshop),
            )
            .expect("zero production"),
            0
        );
    }
}
