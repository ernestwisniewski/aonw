use aonw_domain::MovementUnits;

use crate::{TechnologyCostBalance, technology::STANDARD_TECHNOLOGIES};

use super::{
    CombatBalance, CombatStats, RulesetDefinition, UnitCapabilities, UnitDefinition, UnitKindValue,
    UnitMovementDomainValue, UnitOccupancyPolicyValue,
};

const fn caps(domain: UnitMovementDomainValue, flags: u8) -> UnitCapabilities {
    UnitCapabilities {
        movement_domain: domain,
        flags,
    }
}

const fn stats(
    attack: i32,
    defense: i32,
    hit_points: u32,
    range: u32,
    mobility: u32,
) -> CombatStats {
    CombatStats {
        attack,
        defense,
        hit_points,
        range,
        mobility,
    }
}

const fn unit(
    kind: UnitKindValue,
    points: u32,
    capabilities: UnitCapabilities,
    combat: CombatStats,
) -> UnitDefinition {
    UnitDefinition {
        kind,
        maximum_movement_units: points * MovementUnits::PER_POINT,
        artifact_movement_units: 2 * MovementUnits::PER_POINT,
        capabilities,
        combat,
    }
}

const PRODUCIBLE: u8 = UnitCapabilities::PRODUCIBLE;
const EXPERIENCE: u8 = UnitCapabilities::GAINS_EXPERIENCE;
const MILITARY: u8 = UnitCapabilities::MILITARY;
const RECON: u8 = UnitCapabilities::RECON;
const TRADE: u8 = UnitCapabilities::USES_TRADE_ROUTES;
const LAND_MILITARY: UnitCapabilities = caps(
    UnitMovementDomainValue::Land,
    PRODUCIBLE | EXPERIENCE | MILITARY,
);
const LAND_CIVILIAN: UnitCapabilities = caps(UnitMovementDomainValue::Land, PRODUCIBLE);
const LAND_RECON: UnitCapabilities = caps(
    UnitMovementDomainValue::Land,
    PRODUCIBLE | EXPERIENCE | MILITARY | RECON,
);
const NAVAL_MILITARY: UnitCapabilities = caps(
    UnitMovementDomainValue::Naval,
    PRODUCIBLE | EXPERIENCE | MILITARY,
);
const NAVAL_RECON: UnitCapabilities = caps(
    UnitMovementDomainValue::Naval,
    PRODUCIBLE | EXPERIENCE | MILITARY | RECON,
);
const AIR_RECON: UnitCapabilities = caps(
    UnitMovementDomainValue::Air,
    PRODUCIBLE | EXPERIENCE | MILITARY | RECON,
);

pub(super) static STANDARD_RULESET: RulesetDefinition = RulesetDefinition {
    schema_version: 1,
    ruleset_id: "aonw-standard",
    occupancy_policy: UnitOccupancyPolicyValue::FriendlyStacking,
    combat: CombatBalance {
        variance: 2,
        ranged_retaliation_percent: 50,
        retreat_threshold_percent: 25,
        defended_city_unit_defense_bonus: 1,
        mixed_commander_army_attack_bonus: 1,
        city: stats(0, 2, 16, 1, 0),
    },
    unit_definitions: &STANDARD_UNITS,
    technology_cost_balance: TechnologyCostBalance::STANDARD,
    technology_definitions: &STANDARD_TECHNOLOGIES,
};

pub(super) const STANDARD_UNITS: [UnitDefinition; 17] = [
    unit(
        UnitKindValue::Commander,
        5,
        LAND_MILITARY,
        stats(1, 1, 8, 1, 2),
    ),
    unit(
        UnitKindValue::Warrior,
        3,
        LAND_MILITARY,
        stats(4, 3, 10, 1, 1),
    ),
    unit(
        UnitKindValue::Archer,
        3,
        LAND_MILITARY,
        stats(3, 1, 7, 2, 1),
    ),
    unit(
        UnitKindValue::Settler,
        3,
        LAND_CIVILIAN,
        stats(0, 1, 1, 1, 1),
    ),
    unit(
        UnitKindValue::Worker,
        3,
        LAND_CIVILIAN,
        stats(0, 1, 1, 1, 1),
    ),
    unit(
        UnitKindValue::Merchant,
        3,
        caps(UnitMovementDomainValue::Land, PRODUCIBLE | TRADE),
        stats(0, 1, 1, 1, 1),
    ),
    unit(UnitKindValue::Scout, 3, LAND_RECON, stats(1, 1, 5, 1, 3)),
    unit(
        UnitKindValue::Spearman,
        3,
        LAND_MILITARY,
        stats(3, 5, 10, 1, 1),
    ),
    unit(
        UnitKindValue::Cavalry,
        5,
        LAND_MILITARY,
        stats(6, 3, 10, 1, 3),
    ),
    unit(
        UnitKindValue::Catapult,
        2,
        LAND_MILITARY,
        stats(7, 1, 7, 2, 1),
    ),
    unit(
        UnitKindValue::HeavyInfantry,
        3,
        LAND_MILITARY,
        stats(7, 6, 13, 1, 1),
    ),
    unit(
        UnitKindValue::FieldCannon,
        2,
        LAND_MILITARY,
        stats(10, 2, 8, 2, 1),
    ),
    unit(
        UnitKindValue::Rifleman,
        3,
        LAND_MILITARY,
        stats(8, 7, 11, 1, 1),
    ),
    unit(
        UnitKindValue::Tank,
        5,
        LAND_MILITARY,
        stats(13, 9, 16, 1, 3),
    ),
    unit(
        UnitKindValue::ScoutShip,
        5,
        NAVAL_RECON,
        stats(3, 3, 8, 1, 3),
    ),
    unit(
        UnitKindValue::Warship,
        5,
        NAVAL_MILITARY,
        stats(10, 7, 14, 2, 2),
    ),
    unit(
        UnitKindValue::ReconPlane,
        7,
        AIR_RECON,
        stats(1, 3, 6, 3, 5),
    ),
];
