/// Unit traversal category used by movement rules.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum UnitMovementDomain {
    Land,
    Naval,
    Air,
}

/// Stable canonical unit type.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub enum UnitKind {
    Commander,
    Warrior,
    Archer,
    Settler,
    Worker,
    Merchant,
    Scout,
    Spearman,
    Cavalry,
    Catapult,
    HeavyInfantry,
    FieldCannon,
    Rifleman,
    Tank,
    ScoutShip,
    Warship,
    ReconPlane,
}

impl UnitKind {
    /// Returns the traversal category defined by the canonical unit catalog.
    #[must_use]
    pub const fn movement_domain(self) -> UnitMovementDomain {
        match self {
            Self::ScoutShip | Self::Warship => UnitMovementDomain::Naval,
            Self::ReconPlane => UnitMovementDomain::Air,
            Self::Commander
            | Self::Warrior
            | Self::Archer
            | Self::Settler
            | Self::Worker
            | Self::Merchant
            | Self::Scout
            | Self::Spearman
            | Self::Cavalry
            | Self::Catapult
            | Self::HeavyInfantry
            | Self::FieldCannon
            | Self::Rifleman
            | Self::Tank => UnitMovementDomain::Land,
        }
    }

    /// Returns whether manual movement is replaced by trade-route commands.
    #[must_use]
    pub const fn uses_trade_routes(self) -> bool {
        matches!(self, Self::Merchant)
    }
}

#[cfg(test)]
mod tests {
    use super::{UnitKind, UnitMovementDomain};

    #[test]
    fn movement_domains_match_the_canonical_unit_catalog() {
        assert_eq!(
            UnitKind::ScoutShip.movement_domain(),
            UnitMovementDomain::Naval
        );
        assert_eq!(
            UnitKind::ReconPlane.movement_domain(),
            UnitMovementDomain::Air
        );
        assert_eq!(
            UnitKind::Commander.movement_domain(),
            UnitMovementDomain::Land
        );
    }
}
