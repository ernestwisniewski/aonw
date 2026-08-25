mod model;
pub(crate) mod rules;

pub use model::{
    CityYieldBreakdown, CityYieldContribution, CityYieldContributionKind, CityYieldQuery,
    StrategicResourceProjection, StrategicResourceProjectionQuery, StrategicResourceSource,
    YieldValue,
};
pub use rules::EconomyQueryError;

pub(crate) use rules::{query_city_yield, query_strategic_resource_projection};
