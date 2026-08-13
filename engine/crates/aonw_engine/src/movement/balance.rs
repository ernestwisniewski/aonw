use aonw_domain::{MovementUnits, UnitKind};

/// Returns the per-turn movement allowance used by the standard ruleset.
#[must_use]
pub const fn maximum_movement_units(kind: UnitKind, carries_artifact: bool) -> MovementUnits {
    let points = if carries_artifact {
        2
    } else {
        match kind {
            UnitKind::Commander
            | UnitKind::Cavalry
            | UnitKind::Tank
            | UnitKind::ScoutShip
            | UnitKind::Warship => 5,
            UnitKind::Catapult | UnitKind::FieldCannon => 2,
            UnitKind::ReconPlane => 7,
            UnitKind::Warrior
            | UnitKind::Archer
            | UnitKind::Settler
            | UnitKind::Worker
            | UnitKind::Merchant
            | UnitKind::Scout
            | UnitKind::Spearman
            | UnitKind::HeavyInfantry
            | UnitKind::Rifleman => 3,
        }
    };
    MovementUnits::new(points * MovementUnits::PER_POINT)
}

#[cfg(test)]
mod tests {
    use aonw_domain::{MovementUnits, UnitKind};

    use super::maximum_movement_units;

    #[test]
    fn standard_allowances_match_dart_balance() {
        assert_eq!(
            maximum_movement_units(UnitKind::Commander, false),
            MovementUnits::new(10)
        );
        assert_eq!(
            maximum_movement_units(UnitKind::Warrior, false),
            MovementUnits::new(6)
        );
        assert_eq!(
            maximum_movement_units(UnitKind::FieldCannon, false),
            MovementUnits::new(4)
        );
        assert_eq!(
            maximum_movement_units(UnitKind::ReconPlane, false),
            MovementUnits::new(14)
        );
        assert_eq!(
            maximum_movement_units(UnitKind::ReconPlane, true),
            MovementUnits::new(4)
        );
    }
}
