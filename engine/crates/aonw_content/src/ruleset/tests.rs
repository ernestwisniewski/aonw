use std::collections::BTreeSet;

use aonw_domain::{MovementUnits, TechnologyId, UnitKind, UnitMovementDomain};

use super::{RulesetDefinition, STANDARD_UNITS};

#[test]
fn standard_ruleset_owns_movement_balance_and_capabilities() {
    let ruleset = RulesetDefinition::standard();
    let merchant = ruleset
        .unit(UnitKind::Merchant)
        .expect("merchant definition");
    let plane = ruleset
        .unit(UnitKind::ReconPlane)
        .expect("plane definition");
    assert!(merchant.capabilities().uses_trade_routes());
    assert_eq!(
        plane.capabilities().movement_domain.domain(),
        UnitMovementDomain::Air
    );
    assert_eq!(plane.maximum_movement(false), MovementUnits::new(14));
    assert_eq!(plane.maximum_movement(true), MovementUnits::new(4));
}

#[test]
fn standard_ruleset_hash_is_stable() {
    let first = RulesetDefinition::standard().content_hash().expect("hash");
    let second = RulesetDefinition::standard().content_hash().expect("hash");
    assert_eq!(first, second);
    assert_eq!(
        first.to_string(),
        "0c7141f3a5d1b49abc4c33ffc7978576ec28a54896396cec0b2dd89e3451a379"
    );
}

#[test]
fn standard_technology_catalog_is_complete_and_stable() {
    let ruleset = RulesetDefinition::standard();
    assert_eq!(ruleset.technologies().len(), 54);
    for key in crate::TechnologyKey::ALL {
        assert!(!key.as_str().is_empty());
        assert!(
            ruleset
                .technology(key.domain())
                .is_some_and(|value| value.id() == key.domain())
        );
    }
    let mut unique_unlocks = BTreeSet::new();
    let mut counts = [0_u32; 5];
    for unlock in ruleset
        .technologies()
        .iter()
        .flat_map(|definition| definition.unlocks())
    {
        let (category, value, index) = match unlock {
            crate::TechnologyUnlock::Building(value) => {
                let _ = value.domain();
                ("building", format!("{value:?}"), 0)
            }
            crate::TechnologyUnlock::Improvement(value) => {
                let _ = value.domain();
                ("improvement", format!("{value:?}"), 1)
            }
            crate::TechnologyUnlock::ResourceVisibility(value) => {
                let _ = value.domain();
                ("resource", format!("{value:?}"), 2)
            }
            crate::TechnologyUnlock::Unit(value) => {
                let _ = value.domain();
                ("unit", format!("{value:?}"), 3)
            }
            crate::TechnologyUnlock::Wonder(value) => {
                let _ = value.domain();
                ("wonder", format!("{value:?}"), 4)
            }
        };
        assert!(unique_unlocks.insert((category, value)));
        counts[index] += 1;
    }
    assert_eq!(counts, [58, 19, 5, 13, 11]);
    assert_eq!(
        ruleset
            .technology_cost_balance()
            .default_boost_discount_basis_points(),
        2_500
    );
    for boost in ruleset
        .technologies()
        .iter()
        .flat_map(|definition| definition.boosts())
    {
        let _ = boost.condition();
        assert!(boost.discount_basis_points() > 0);
    }
    assert_eq!(
        ruleset
            .technology_catalog_hash()
            .expect("catalog hash")
            .to_string(),
        "be48beb6ec5f8fd457439b78d2b89355b20e88236ecef78e09d60bd2fab2af4b"
    );
    assert_eq!(
        ruleset
            .technology(TechnologyId::NuclearPhysics)
            .expect("nuclear physics")
            .base_cost(),
        48
    );
}

#[test]
fn standard_combat_content_exposes_every_current_rule_value() {
    let ruleset = RulesetDefinition::standard();
    for definition in STANDARD_UNITS {
        assert_eq!(ruleset.unit(definition.kind()), Some(definition));
        let capabilities = definition.capabilities();
        let _ = (
            capabilities.producible_by_cities(),
            capabilities.gains_experience(),
            capabilities.military(),
            capabilities.recon(),
            capabilities.uses_trade_routes(),
        );
        let combat = definition.combat();
        let _ = (
            combat.attack(),
            combat.defense(),
            combat.hit_points(),
            combat.range(),
            combat.mobility(),
        );
    }
    let combat = ruleset.combat();
    assert_eq!(combat.variance(), 2);
    assert_eq!(combat.ranged_retaliation_percent(), 50);
    assert_eq!(combat.retreat_threshold_percent(), 25);
    assert_eq!(combat.defended_city_unit_defense_bonus(), 1);
    assert_eq!(combat.mixed_commander_army_attack_bonus(), 1);
    assert!(combat.city().hit_points() > 0);
    for definition in ruleset.technologies() {
        assert!(!definition.label().is_empty());
        let _ = (
            definition.era(),
            definition.prerequisites(),
            definition.blocked_by(),
            definition.effects(),
        );
    }
}

#[test]
fn technology_value_constructors_preserve_runtime_inputs() {
    use crate::{
        TechnologyBoost, TechnologyBoostCondition, TechnologyDefinition, TechnologyEra,
        TechnologyImprovement, TechnologyKey,
    };

    let boost = TechnologyBoost::new(
        TechnologyBoostCondition::ImprovementCount {
            improvement: TechnologyImprovement::Farm,
            count: std::hint::black_box(2),
        },
        std::hint::black_box(1_750),
    );
    assert_eq!(boost.discount_basis_points(), 1_750);
    let definition = TechnologyDefinition::new(
        TechnologyKey::Agriculture,
        TechnologyEra::Foundation,
        std::hint::black_box(7),
        &[],
        &[],
        &[],
        &[],
    );
    assert_eq!(definition.base_cost(), 7);
    assert!(definition.blocked_by().is_empty());
}
