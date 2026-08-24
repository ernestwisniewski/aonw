use std::io::{self, Write};

use aonw_domain::{MovementUnits, TechnologyId, UnitKind, UnitMovementDomain, UnitOccupancyPolicy};
use serde::Serialize;
use sha2::{Digest, Sha256};

use crate::{
    ContentHash, TechnologyCostBalance, TechnologyDefinition, technology::STANDARD_TECHNOLOGIES,
};

/// Capabilities fixed by a ruleset for one unit kind.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UnitCapabilities {
    /// Traversal category.
    pub movement_domain: UnitMovementDomainValue,
    flags: u8,
}

impl UnitCapabilities {
    const PRODUCIBLE: u8 = 1 << 0;
    const GAINS_EXPERIENCE: u8 = 1 << 1;
    const MILITARY: u8 = 1 << 2;
    const RECON: u8 = 1 << 3;
    const USES_TRADE_ROUTES: u8 = 1 << 4;

    /// Returns whether cities may produce the unit.
    #[must_use]
    pub const fn producible_by_cities(self) -> bool {
        self.flags & Self::PRODUCIBLE != 0
    }
    /// Returns whether the unit gains combat experience.
    #[must_use]
    pub const fn gains_experience(self) -> bool {
        self.flags & Self::GAINS_EXPERIENCE != 0
    }
    /// Returns whether the unit participates in combat as military.
    #[must_use]
    pub const fn military(self) -> bool {
        self.flags & Self::MILITARY != 0
    }
    /// Returns whether the unit has recon behavior.
    #[must_use]
    pub const fn recon(self) -> bool {
        self.flags & Self::RECON != 0
    }
    /// Returns whether manual movement is replaced by trade routes.
    #[must_use]
    pub const fn uses_trade_routes(self) -> bool {
        self.flags & Self::USES_TRADE_ROUTES != 0
    }
}

/// Stable serialized movement domain owned by content.
#[allow(dead_code, missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum UnitMovementDomainValue {
    Land,
    Naval,
    Air,
}

impl UnitMovementDomainValue {
    /// Maps content configuration to the framework-independent domain value.
    #[must_use]
    pub const fn domain(self) -> UnitMovementDomain {
        match self {
            Self::Land => UnitMovementDomain::Land,
            Self::Naval => UnitMovementDomain::Naval,
            Self::Air => UnitMovementDomain::Air,
        }
    }
}

/// Immutable ruleset entry for one canonical unit kind.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct UnitDefinition {
    kind: UnitKindValue,
    maximum_movement_units: u32,
    artifact_movement_units: u32,
    capabilities: UnitCapabilities,
}

impl UnitDefinition {
    /// Returns the unit kind.
    #[must_use]
    pub const fn kind(self) -> UnitKind {
        self.kind.domain()
    }
    /// Returns capabilities.
    #[must_use]
    pub const fn capabilities(self) -> UnitCapabilities {
        self.capabilities
    }
    /// Returns movement allowance for the current carried-artifact state.
    #[must_use]
    pub const fn maximum_movement(self, carries_artifact: bool) -> MovementUnits {
        MovementUnits::new(if carries_artifact {
            self.artifact_movement_units
        } else {
            self.maximum_movement_units
        })
    }
}

/// Stable serialized unit kind owned by content canonicalization.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
enum UnitKindValue {
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

impl UnitKindValue {
    const fn domain(self) -> UnitKind {
        match self {
            Self::Commander => UnitKind::Commander,
            Self::Warrior => UnitKind::Warrior,
            Self::Archer => UnitKind::Archer,
            Self::Settler => UnitKind::Settler,
            Self::Worker => UnitKind::Worker,
            Self::Merchant => UnitKind::Merchant,
            Self::Scout => UnitKind::Scout,
            Self::Spearman => UnitKind::Spearman,
            Self::Cavalry => UnitKind::Cavalry,
            Self::Catapult => UnitKind::Catapult,
            Self::HeavyInfantry => UnitKind::HeavyInfantry,
            Self::FieldCannon => UnitKind::FieldCannon,
            Self::Rifleman => UnitKind::Rifleman,
            Self::Tank => UnitKind::Tank,
            Self::ScoutShip => UnitKind::ScoutShip,
            Self::Warship => UnitKind::Warship,
            Self::ReconPlane => UnitKind::ReconPlane,
        }
    }
}

/// Immutable, hash-addressed simulation rules.
#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct RulesetDefinition {
    schema_version: u16,
    ruleset_id: &'static str,
    occupancy_policy: UnitOccupancyPolicyValue,
    unit_definitions: &'static [UnitDefinition],
    technology_cost_balance: TechnologyCostBalance,
    technology_definitions: &'static [TechnologyDefinition],
}

impl RulesetDefinition {
    /// Returns the built-in ruleset matching current movement behavior.
    #[must_use]
    pub const fn standard() -> &'static Self {
        &STANDARD_RULESET
    }

    /// Returns the stable identifier.
    #[must_use]
    pub fn ruleset_id(&self) -> &str {
        self.ruleset_id
    }

    /// Returns the unit occupancy policy.
    #[must_use]
    pub const fn occupancy_policy(&self) -> UnitOccupancyPolicy {
        self.occupancy_policy.domain()
    }

    /// Finds a definition by canonical kind.
    #[must_use]
    pub fn unit(&self, kind: UnitKind) -> Option<UnitDefinition> {
        self.unit_definitions
            .iter()
            .copied()
            .find(|definition| definition.kind() == kind)
    }

    /// Returns every technology in canonical catalog order.
    #[must_use]
    pub const fn technologies(&self) -> &'static [TechnologyDefinition] {
        self.technology_definitions
    }

    /// Finds a technology definition by canonical identity.
    #[must_use]
    pub fn technology(&self, id: TechnologyId) -> Option<TechnologyDefinition> {
        self.technology_definitions
            .iter()
            .copied()
            .find(|definition| definition.id() == id)
    }

    /// Returns deterministic research-cost balance.
    #[must_use]
    pub const fn technology_cost_balance(&self) -> TechnologyCostBalance {
        self.technology_cost_balance
    }

    /// Returns the configured movement allowance for one unit.
    #[must_use]
    pub fn maximum_movement(
        &self,
        kind: UnitKind,
        carries_artifact: bool,
    ) -> Option<MovementUnits> {
        self.unit(kind)
            .map(|definition| definition.maximum_movement(carries_artifact))
    }

    /// Computes SHA-256 over stable compact ruleset JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical serialization fails.
    pub fn content_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let mut writer = HashWriter(Sha256::new());
        serde_json::to_writer(&mut writer, self)?;
        Ok(ContentHash(writer.0.finalize().into()))
    }

    /// Computes SHA-256 over the canonical technology balance and catalog.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical serialization fails.
    pub fn technology_catalog_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let mut writer = HashWriter(Sha256::new());
        serde_json::to_writer(
            &mut writer,
            &CanonicalTechnologyCatalog {
                cost_balance: self.technology_cost_balance,
                definitions: self.technology_definitions,
            },
        )?;
        Ok(ContentHash(writer.0.finalize().into()))
    }
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CanonicalTechnologyCatalog {
    cost_balance: TechnologyCostBalance,
    definitions: &'static [TechnologyDefinition],
}

/// Stable serialized occupancy policy owned by content.
#[allow(dead_code, missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
enum UnitOccupancyPolicyValue {
    Exclusive,
    FriendlyStacking,
}

impl UnitOccupancyPolicyValue {
    const fn domain(self) -> UnitOccupancyPolicy {
        match self {
            Self::Exclusive => UnitOccupancyPolicy::Exclusive,
            Self::FriendlyStacking => UnitOccupancyPolicy::FriendlyStacking,
        }
    }
}

struct HashWriter(Sha256);
impl Write for HashWriter {
    fn write(&mut self, buffer: &[u8]) -> io::Result<usize> {
        self.0.update(buffer);
        Ok(buffer.len())
    }
    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

const fn caps(domain: UnitMovementDomainValue, flags: u8) -> UnitCapabilities {
    UnitCapabilities {
        movement_domain: domain,
        flags,
    }
}
const fn unit(kind: UnitKindValue, points: u32, capabilities: UnitCapabilities) -> UnitDefinition {
    UnitDefinition {
        kind,
        maximum_movement_units: points * MovementUnits::PER_POINT,
        artifact_movement_units: 2 * MovementUnits::PER_POINT,
        capabilities,
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
static STANDARD_RULESET: RulesetDefinition = RulesetDefinition {
    schema_version: 1,
    ruleset_id: "aonw-standard",
    occupancy_policy: UnitOccupancyPolicyValue::FriendlyStacking,
    unit_definitions: &STANDARD_UNITS,
    technology_cost_balance: TechnologyCostBalance::STANDARD,
    technology_definitions: &STANDARD_TECHNOLOGIES,
};
const STANDARD_UNITS: [UnitDefinition; 17] = [
    unit(UnitKindValue::Commander, 5, LAND_MILITARY),
    unit(UnitKindValue::Warrior, 3, LAND_MILITARY),
    unit(UnitKindValue::Archer, 3, LAND_MILITARY),
    unit(UnitKindValue::Settler, 3, LAND_CIVILIAN),
    unit(UnitKindValue::Worker, 3, LAND_CIVILIAN),
    unit(
        UnitKindValue::Merchant,
        3,
        caps(UnitMovementDomainValue::Land, PRODUCIBLE | TRADE),
    ),
    unit(UnitKindValue::Scout, 3, LAND_RECON),
    unit(UnitKindValue::Spearman, 3, LAND_MILITARY),
    unit(UnitKindValue::Cavalry, 5, LAND_MILITARY),
    unit(UnitKindValue::Catapult, 2, LAND_MILITARY),
    unit(UnitKindValue::HeavyInfantry, 3, LAND_MILITARY),
    unit(UnitKindValue::FieldCannon, 2, LAND_MILITARY),
    unit(UnitKindValue::Rifleman, 3, LAND_MILITARY),
    unit(UnitKindValue::Tank, 5, LAND_MILITARY),
    unit(UnitKindValue::ScoutShip, 5, NAVAL_RECON),
    unit(UnitKindValue::Warship, 5, NAVAL_MILITARY),
    unit(UnitKindValue::ReconPlane, 7, AIR_RECON),
];

#[cfg(test)]
mod tests {
    use std::collections::BTreeSet;

    use super::RulesetDefinition;
    use aonw_domain::{MovementUnits, TechnologyId, UnitKind, UnitMovementDomain};

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
            "e37d5db8e6a532afaaf1496b238cda3778b23bf609ec97505416bc7525443709"
        );
    }

    #[test]
    fn standard_technology_catalog_is_complete_and_stable() {
        let ruleset = RulesetDefinition::standard();
        assert_eq!(ruleset.technologies().len(), 54);
        for key in crate::TechnologyKey::ALL {
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
}
