use aonw_content::{TerrainType, TileDefinition};
use aonw_domain::{MovementUnits, UnitMovementDomain};

use super::terrain_profile::TerrainProfile;

/// Result of applying terrain passability and entry-cost rules.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MovementCost {
    /// The destination cannot be entered.
    Blocked,
    /// The destination is passable at the given fixed-point cost.
    Passable(MovementUnits),
}

/// Computes the canonical terrain cost for entering a tile.
#[must_use]
pub fn terrain_entry_cost(tile: &TileDefinition, domain: UnitMovementDomain) -> MovementCost {
    let profile = TerrainProfile::from_tile(tile);
    if profile.has_mountain() {
        return MovementCost::Blocked;
    }
    if domain == UnitMovementDomain::Naval {
        return match profile.base {
            Some(TerrainType::Coast | TerrainType::Ocean) => {
                MovementCost::Passable(MovementUnits::new(2))
            }
            _ => MovementCost::Blocked,
        };
    }

    let Some(mut cost) = base_land_cost(profile.base) else {
        return MovementCost::Blocked;
    };
    if profile.has_forest()
        && (profile.base != Some(TerrainType::Snow)
            || profile.has_jungle()
            || profile.has_wetlands()
            || profile.has_hills())
    {
        cost += MovementUnits::PER_POINT;
    }
    if profile.has_jungle() {
        cost += MovementUnits::PER_POINT;
    }
    if profile.has_wetlands() {
        cost += MovementUnits::PER_POINT;
    }
    if profile.has_hills() {
        cost += MovementUnits::PER_POINT;
    }
    MovementCost::Passable(MovementUnits::new(cost))
}

const fn base_land_cost(base: Option<TerrainType>) -> Option<u32> {
    match base {
        Some(TerrainType::Grassland | TerrainType::Plains | TerrainType::Coast) => Some(2),
        Some(TerrainType::Desert | TerrainType::Tundra | TerrainType::Wetlands) => Some(4),
        Some(TerrainType::Snow) => Some(6),
        Some(
            TerrainType::Ocean
            | TerrainType::Lake
            | TerrainType::Forest
            | TerrainType::Jungle
            | TerrainType::Hills
            | TerrainType::Mountain
            | TerrainType::River,
        )
        | None => None,
    }
}

#[cfg(test)]
mod tests {
    use aonw_content::{TerrainType, TileDefinition};
    use aonw_domain::{HexCoord, MovementUnits, UnitMovementDomain};

    use super::{MovementCost, terrain_entry_cost};

    fn tile(terrains: Vec<TerrainType>) -> TileDefinition {
        TileDefinition::try_new(HexCoord::new(0, 0), terrains, Vec::new(), 0)
            .expect("valid terrain fixture")
    }

    #[test]
    fn land_costs_match_the_current_rules() {
        assert_eq!(
            terrain_entry_cost(
                &tile(vec![TerrainType::Plains, TerrainType::Forest]),
                UnitMovementDomain::Land
            ),
            MovementCost::Passable(MovementUnits::new(4))
        );
        assert_eq!(
            terrain_entry_cost(
                &tile(vec![
                    TerrainType::Grassland,
                    TerrainType::Forest,
                    TerrainType::Hills
                ]),
                UnitMovementDomain::Land
            ),
            MovementCost::Passable(MovementUnits::new(6))
        );
        assert_eq!(
            terrain_entry_cost(&tile(vec![TerrainType::Mountain]), UnitMovementDomain::Land),
            MovementCost::Blocked
        );
    }

    #[test]
    fn primary_terrain_is_explicit() {
        assert!(
            TileDefinition::try_new(
                HexCoord::new(0, 0),
                vec![TerrainType::Forest],
                Vec::new(),
                0,
            )
            .is_err()
        );
    }

    #[test]
    fn naval_units_only_enter_coast_and_ocean() {
        assert_eq!(
            terrain_entry_cost(&tile(vec![TerrainType::Ocean]), UnitMovementDomain::Naval),
            MovementCost::Passable(MovementUnits::new(2))
        );
        assert_eq!(
            terrain_entry_cost(&tile(vec![TerrainType::Lake]), UnitMovementDomain::Naval),
            MovementCost::Blocked
        );
    }

    #[test]
    fn air_units_retain_current_land_terrain_semantics() {
        assert_eq!(
            terrain_entry_cost(
                &tile(vec![TerrainType::Plains, TerrainType::Hills]),
                UnitMovementDomain::Air
            ),
            MovementCost::Passable(MovementUnits::new(4))
        );
    }
}
