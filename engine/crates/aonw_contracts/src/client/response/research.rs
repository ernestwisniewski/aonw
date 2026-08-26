use serde::{Deserialize, Serialize};

use crate::{
    CityBuildingTypeDto, FieldImprovementKindDto, ResourceTypeDto, TechnologyIdDto, UnitKindDto,
    WonderTypeDto,
};

/// Current engine-owned availability of one technology.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TechnologyAvailabilityDto {
    Unlocked,
    Active,
    Available,
    LockedByPrerequisites,
    LockedByTechnology,
}

/// One typed capability unlocked by research.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(
    tag = "kind",
    rename_all = "camelCase",
    rename_all_fields = "camelCase",
    deny_unknown_fields
)]
pub enum TechnologyUnlockDto {
    Building {
        building_type: CityBuildingTypeDto,
    },
    Improvement {
        improvement: FieldImprovementKindDto,
    },
    ResourceVisibility {
        resource: ResourceTypeDto,
    },
    Unit {
        unit_type: UnitKindDto,
    },
    Wonder {
        wonder_type: WonderTypeDto,
    },
}

/// Complete selection view of one technology.
#[derive(Clone, Debug, Eq, PartialEq, Deserialize, Serialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ResearchOptionDto {
    /// Stable technology identity.
    pub technology_id: TechnologyIdDto,
    /// Current engine-owned availability.
    pub availability: TechnologyAvailabilityDto,
    /// Exact pace-, city-, and boost-adjusted cost.
    pub effective_cost: u32,
    /// Persisted science progress.
    pub progress: i64,
    /// Best currently fulfilled boost discount.
    pub boost_discount_basis_points: u32,
    /// Required technologies in catalog order.
    pub prerequisites: Vec<TechnologyIdDto>,
    /// Mutually exclusive completed technologies.
    pub blocked_by: Vec<TechnologyIdDto>,
    /// Capabilities granted on completion.
    pub unlocks: Vec<TechnologyUnlockDto>,
}
