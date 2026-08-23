use std::collections::BTreeSet;

use crate::{CityId, HexCoord, PlayerId};

use super::{CityBuildingType, CityProductionQueue, CitySpecializationType, WonderType};

/// Complete canonical city state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct City {
    id: CityId,
    owner_player_id: PlayerId,
    founding_owner_player_id: Option<PlayerId>,
    name: Box<str>,
    population: i64,
    stored_food: i64,
    max_hexes: i64,
    territory_radius: i64,
    center: HexCoord,
    controlled_hexes: Box<[HexCoord]>,
    worked_hexes: Box<[HexCoord]>,
    buildings: BTreeSet<CityBuildingType>,
    wonders: BTreeSet<WonderType>,
    production_queue: Option<CityProductionQueue>,
    production_overflow: i64,
    specialization: Option<CitySpecializationType>,
    preferred_expansion_hex: Option<HexCoord>,
    hit_points: Option<i64>,
}

impl City {
    /// Constructs the legacy movement slice with canonical city defaults.
    #[must_use]
    pub fn new(
        id: CityId,
        owner_player_id: PlayerId,
        center: HexCoord,
        controlled_hexes: impl IntoIterator<Item = HexCoord>,
    ) -> Self {
        let mut controlled_hexes = controlled_hexes.into_iter().collect::<Vec<_>>();
        controlled_hexes.sort_unstable();
        controlled_hexes.dedup();
        controlled_hexes.retain(|coordinate| *coordinate != center);
        Self {
            id,
            owner_player_id,
            founding_owner_player_id: None,
            name: "".into(),
            population: 3,
            stored_food: 0,
            max_hexes: 6,
            territory_radius: 2,
            center,
            controlled_hexes: controlled_hexes.into_boxed_slice(),
            worked_hexes: Box::default(),
            buildings: BTreeSet::new(),
            wonders: BTreeSet::new(),
            production_queue: None,
            production_overflow: 0,
            specialization: None,
            preferred_expansion_hex: None,
            hit_points: None,
        }
    }

    /// Starts construction of a complete city without exposing partial state.
    #[must_use]
    pub fn builder(
        id: CityId,
        owner_player_id: PlayerId,
        name: impl Into<Box<str>>,
        center: HexCoord,
    ) -> CityBuilder {
        CityBuilder::new(id, owner_player_id, name.into(), center)
    }

    /// Returns the city identifier.
    #[must_use]
    pub const fn id(&self) -> &CityId {
        &self.id
    }
    /// Returns the current owner.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the founding owner, when retained by the source snapshot.
    #[must_use]
    pub const fn founding_owner_player_id(&self) -> Option<&PlayerId> {
        self.founding_owner_player_id.as_ref()
    }
    /// Returns the persisted city name.
    #[must_use]
    pub const fn name(&self) -> &str {
        &self.name
    }
    /// Returns city population.
    #[must_use]
    pub const fn population(&self) -> i64 {
        self.population
    }
    /// Returns stored food.
    #[must_use]
    pub const fn stored_food(&self) -> i64 {
        self.stored_food
    }
    /// Returns the territory capacity.
    #[must_use]
    pub const fn max_hexes(&self) -> i64 {
        self.max_hexes
    }
    /// Returns the persisted territory radius.
    #[must_use]
    pub const fn territory_radius(&self) -> i64 {
        self.territory_radius
    }
    /// Returns the city-center coordinate.
    #[must_use]
    pub const fn center(&self) -> HexCoord {
        self.center
    }
    /// Returns controlled coordinates in contract order.
    #[must_use]
    pub const fn controlled_hexes(&self) -> &[HexCoord] {
        &self.controlled_hexes
    }
    /// Returns manually worked coordinates in contract order.
    #[must_use]
    pub const fn worked_hexes(&self) -> &[HexCoord] {
        &self.worked_hexes
    }
    /// Returns owned buildings in stable identity order.
    #[must_use]
    pub const fn buildings(&self) -> &BTreeSet<CityBuildingType> {
        &self.buildings
    }
    /// Returns owned wonders in stable identity order.
    #[must_use]
    pub const fn wonders(&self) -> &BTreeSet<WonderType> {
        &self.wonders
    }
    /// Returns the current production queue.
    #[must_use]
    pub const fn production_queue(&self) -> Option<&CityProductionQueue> {
        self.production_queue.as_ref()
    }
    /// Returns stored production overflow.
    #[must_use]
    pub const fn production_overflow(&self) -> i64 {
        self.production_overflow
    }
    /// Returns optional city specialization.
    #[must_use]
    pub const fn specialization(&self) -> Option<CitySpecializationType> {
        self.specialization
    }
    /// Returns the preferred next expansion coordinate.
    #[must_use]
    pub const fn preferred_expansion_hex(&self) -> Option<HexCoord> {
        self.preferred_expansion_hex
    }
    /// Returns persistent combat health when present.
    #[must_use]
    pub const fn hit_points(&self) -> Option<i64> {
        self.hit_points
    }
}

/// Builder owning all complete-city construction defaults.
#[derive(Clone, Debug)]
pub struct CityBuilder {
    id: CityId,
    owner_player_id: PlayerId,
    founding_owner_player_id: Option<PlayerId>,
    name: Box<str>,
    population: i64,
    stored_food: i64,
    max_hexes: i64,
    territory_radius: i64,
    center: HexCoord,
    controlled_hexes: Vec<HexCoord>,
    worked_hexes: Vec<HexCoord>,
    buildings: Vec<CityBuildingType>,
    wonders: Vec<WonderType>,
    production_queue: Option<CityProductionQueue>,
    production_overflow: i64,
    specialization: Option<CitySpecializationType>,
    preferred_expansion_hex: Option<HexCoord>,
    hit_points: Option<i64>,
}

impl CityBuilder {
    fn new(id: CityId, owner_player_id: PlayerId, name: Box<str>, center: HexCoord) -> Self {
        Self {
            id,
            owner_player_id,
            founding_owner_player_id: None,
            name,
            population: 3,
            stored_food: 0,
            max_hexes: 6,
            territory_radius: 2,
            center,
            controlled_hexes: Vec::new(),
            worked_hexes: Vec::new(),
            buildings: Vec::new(),
            wonders: Vec::new(),
            production_queue: None,
            production_overflow: 0,
            specialization: None,
            preferred_expansion_hex: None,
            hit_points: None,
        }
    }

    /// Sets optional original owner identity.
    #[must_use]
    pub fn with_founding_owner(mut self, owner: Option<PlayerId>) -> Self {
        self.founding_owner_player_id = owner;
        self
    }

    /// Sets persisted city growth and territory counters.
    #[must_use]
    pub fn with_progression(
        mut self,
        population: i64,
        stored_food: i64,
        max_hexes: i64,
        territory_radius: i64,
    ) -> Self {
        self.population = population;
        self.stored_food = stored_food;
        self.max_hexes = max_hexes;
        self.territory_radius = territory_radius;
        self
    }

    /// Sets controlled coordinates in contract order.
    #[must_use]
    pub fn with_controlled_hexes(mut self, values: impl IntoIterator<Item = HexCoord>) -> Self {
        self.controlled_hexes = values.into_iter().collect();
        self
    }

    /// Sets manually worked coordinates in contract order.
    #[must_use]
    pub fn with_worked_hexes(mut self, values: impl IntoIterator<Item = HexCoord>) -> Self {
        self.worked_hexes = values.into_iter().collect();
        self
    }

    /// Sets owned building identities.
    #[must_use]
    pub fn with_buildings(mut self, values: impl IntoIterator<Item = CityBuildingType>) -> Self {
        self.buildings = values.into_iter().collect();
        self
    }

    /// Sets owned wonder identities.
    #[must_use]
    pub fn with_wonders(mut self, values: impl IntoIterator<Item = WonderType>) -> Self {
        self.wonders = values.into_iter().collect();
        self
    }

    /// Sets the optional production queue and overflow.
    #[must_use]
    pub fn with_production(mut self, queue: Option<CityProductionQueue>, overflow: i64) -> Self {
        self.production_queue = queue;
        self.production_overflow = overflow;
        self
    }

    /// Sets optional specialization and preferred expansion coordinate.
    #[must_use]
    pub fn with_planning(
        mut self,
        specialization: Option<CitySpecializationType>,
        preferred_expansion_hex: Option<HexCoord>,
    ) -> Self {
        self.specialization = specialization;
        self.preferred_expansion_hex = preferred_expansion_hex;
        self
    }

    /// Sets persistent combat health.
    #[must_use]
    pub fn with_hit_points(mut self, hit_points: Option<i64>) -> Self {
        self.hit_points = hit_points;
        self
    }

    /// Validates list/set topology and constructs a complete city.
    ///
    /// # Errors
    ///
    /// Returns an error for duplicated or inconsistent city collections.
    pub fn build(self) -> Result<City, CityBuildError> {
        let controlled = unique_coordinates(
            self.controlled_hexes,
            CityBuildError::DuplicateControlledHex,
        )?;
        if controlled.contains(&self.center) {
            return Err(CityBuildError::CenterInControlledHexes);
        }
        let worked = unique_coordinates(self.worked_hexes, CityBuildError::DuplicateWorkedHex)?;
        for coordinate in &worked {
            if *coordinate == self.center || !controlled.contains(coordinate) {
                return Err(CityBuildError::WorkedHexNotControlled(*coordinate));
            }
        }
        let buildings = unique_values(self.buildings, CityBuildError::DuplicateBuilding)?;
        let wonders = unique_values(self.wonders, CityBuildError::DuplicateWonder)?;
        Ok(City {
            id: self.id,
            owner_player_id: self.owner_player_id,
            founding_owner_player_id: self.founding_owner_player_id,
            name: self.name,
            population: self.population,
            stored_food: self.stored_food,
            max_hexes: self.max_hexes,
            territory_radius: self.territory_radius,
            center: self.center,
            controlled_hexes: controlled.into_boxed_slice(),
            worked_hexes: worked.into_boxed_slice(),
            buildings,
            wonders,
            production_queue: self.production_queue,
            production_overflow: self.production_overflow,
            specialization: self.specialization,
            preferred_expansion_hex: self.preferred_expansion_hex,
            hit_points: self.hit_points,
        })
    }
}

fn unique_coordinates(
    values: Vec<HexCoord>,
    duplicate: impl Fn(HexCoord) -> CityBuildError,
) -> Result<Vec<HexCoord>, CityBuildError> {
    let mut seen = BTreeSet::new();
    for coordinate in &values {
        if !seen.insert(*coordinate) {
            return Err(duplicate(*coordinate));
        }
    }
    Ok(values)
}

fn unique_values<T: Copy + Ord>(
    values: Vec<T>,
    duplicate: impl Fn(T) -> CityBuildError,
) -> Result<BTreeSet<T>, CityBuildError> {
    let mut unique = BTreeSet::new();
    for value in values {
        if !unique.insert(value) {
            return Err(duplicate(value));
        }
    }
    Ok(unique)
}

/// Structural complete-city validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CityBuildError {
    /// A controlled coordinate occurred more than once.
    DuplicateControlledHex(HexCoord),
    /// The city center was repeated in controlled coordinates.
    CenterInControlledHexes,
    /// A worked coordinate occurred more than once.
    DuplicateWorkedHex(HexCoord),
    /// A worked coordinate was not a non-center controlled coordinate.
    WorkedHexNotControlled(HexCoord),
    /// A building identity occurred more than once.
    DuplicateBuilding(CityBuildingType),
    /// A wonder identity occurred more than once.
    DuplicateWonder(WonderType),
}

impl core::fmt::Display for CityBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateControlledHex(value) => write!(
                formatter,
                "duplicate controlled hex: ({}, {})",
                value.col(),
                value.row()
            ),
            Self::CenterInControlledHexes => {
                formatter.write_str("city center must not be repeated in controlled hexes")
            }
            Self::DuplicateWorkedHex(value) => write!(
                formatter,
                "duplicate worked hex: ({}, {})",
                value.col(),
                value.row()
            ),
            Self::WorkedHexNotControlled(value) => write!(
                formatter,
                "worked hex is not controlled: ({}, {})",
                value.col(),
                value.row()
            ),
            Self::DuplicateBuilding(value) => write!(formatter, "duplicate building: {value:?}"),
            Self::DuplicateWonder(value) => write!(formatter, "duplicate wonder: {value:?}"),
        }
    }
}

impl std::error::Error for CityBuildError {}

#[cfg(test)]
mod tests {
    use crate::{CityId, HexCoord, PlayerId};

    use super::{City, CityBuildError};

    #[test]
    fn complete_city_rejects_duplicate_and_uncontrolled_coordinates() {
        let city = || {
            City::builder(
                CityId::new("city").expect("city id"),
                PlayerId::new("player").expect("player id"),
                "City",
                HexCoord::new(1, 1),
            )
        };
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
}
