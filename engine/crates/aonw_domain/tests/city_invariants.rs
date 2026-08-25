//! Public-boundary coverage for canonical city invariants.

use aonw_domain::{
    City, CityBuildError, CityBuilder, CityId, CityProductionQueue, CityProductionQueueBuildError,
    CityProductionTarget, CityProjectType, HexCoord, PlayerId, StrategicResourceStockpile,
};

fn city() -> CityBuilder {
    City::builder(
        CityId::new("city").expect("city id"),
        PlayerId::new("player").expect("player id"),
        "City",
        HexCoord::new(1, 1),
    )
}

#[test]
fn complete_city_rejects_duplicate_and_uncontrolled_coordinates() {
    assert_eq!(
        city()
            .with_controlled_hexes([HexCoord::new(0, 1), HexCoord::new(0, 1)])
            .build(),
        Err(CityBuildError::DuplicateControlledHex(HexCoord::new(0, 1)))
    );
    assert_eq!(
        city()
            .with_controlled_hexes([HexCoord::new(0, 1)])
            .with_worked_hexes([HexCoord::new(2, 1)])
            .build(),
        Err(CityBuildError::WorkedHexNotControlled(HexCoord::new(2, 1)))
    );
}

#[test]
fn complete_city_rejects_invalid_numeric_state() {
    let cases = [
        (
            city().with_progression(0, 0, 6, 2).build(),
            CityBuildError::NonPositivePopulation(0),
        ),
        (
            city().with_progression(3, -1, 6, 2).build(),
            CityBuildError::NegativeStoredFood(-1),
        ),
        (
            city().with_progression(3, 0, 0, 2).build(),
            CityBuildError::NonPositiveMaxHexes(0),
        ),
        (
            city().with_progression(3, 0, 6, -1).build(),
            CityBuildError::NegativeTerritoryRadius(-1),
        ),
        (
            city().with_production(None, -1).build(),
            CityBuildError::NegativeProductionOverflow(-1),
        ),
        (
            city().with_hit_points(Some(0)).build(),
            CityBuildError::NonPositiveHitPoints(0),
        ),
    ];
    for (actual, expected) in cases {
        assert_eq!(actual, Err(expected));
    }
}

#[test]
fn production_queue_rejects_negative_investment() {
    assert_eq!(
        CityProductionQueue::try_new(
            CityProductionTarget::Project(CityProjectType::Wealth),
            -1,
            StrategicResourceStockpile::default(),
        ),
        Err(CityProductionQueueBuildError::NegativeInvestedProduction(
            -1
        ))
    );
}
