use crate::{StrategicResourceStockpile, UnitKind};

use super::{CityBuildingType, CityProjectType, WonderType};

/// One typed city production target.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum CityProductionTarget {
    /// A city building.
    Building(CityBuildingType),
    /// A producible unit kind.
    Unit(UnitKind),
    /// A repeatable project.
    Project(CityProjectType),
    /// A world wonder.
    Wonder(WonderType),
}

/// Persisted production investment and reserved strategic resources.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CityProductionQueue {
    target: CityProductionTarget,
    invested_production: i64,
    resource_allocation: StrategicResourceStockpile,
}

impl CityProductionQueue {
    /// Constructs a typed production queue.
    #[must_use]
    pub const fn new(
        target: CityProductionTarget,
        invested_production: i64,
        resource_allocation: StrategicResourceStockpile,
    ) -> Self {
        Self {
            target,
            invested_production,
            resource_allocation,
        }
    }

    /// Returns the current target.
    #[must_use]
    pub const fn target(&self) -> CityProductionTarget {
        self.target
    }

    /// Returns invested production without applying gameplay rules.
    #[must_use]
    pub const fn invested_production(&self) -> i64 {
        self.invested_production
    }

    /// Returns strategic resources reserved by the queue.
    #[must_use]
    pub const fn resource_allocation(&self) -> &StrategicResourceStockpile {
        &self.resource_allocation
    }
}
