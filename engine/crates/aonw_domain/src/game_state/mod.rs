use crate::{
    City, CityId, Diplomacy, FogOfWar, HexCoord, HexGridBounds, MovementState,
    MovementStateBuildError, MovementUnitBuildError, PlayerId, StateRevision, TransportNetwork,
    Unit, UnitId,
};

/// Failure raised while deriving the temporary movement projection.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum MovementProjectionError {
    /// A canonical unit cannot form a valid movement view.
    InvalidUnit {
        /// Unit array index.
        index: usize,
        /// Violated projection invariant.
        source: MovementUnitBuildError,
    },
    /// Projected units violate movement-state invariants.
    InvalidState(MovementStateBuildError),
}

impl core::fmt::Display for MovementProjectionError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::InvalidUnit { index, source } => {
                write!(formatter, "cannot project unit at index {index}: {source}")
            }
            Self::InvalidState(source) => {
                write!(formatter, "invalid movement projection: {source}")
            }
        }
    }
}

impl std::error::Error for MovementProjectionError {}

/// Occupancy policy selected by the immutable ruleset.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum UnitOccupancyPolicy {
    Exclusive,
    FriendlyStacking,
}

impl UnitOccupancyPolicy {
    /// Returns whether two owners may share a coordinate.
    #[must_use]
    pub fn permits(self, left: &PlayerId, right: &PlayerId) -> bool {
        matches!(self, Self::FriendlyStacking) && left == right
    }
}

/// Failure raised while constructing the canonical simulation aggregate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum GameStateBuildError {
    /// More than one unit used an identifier.
    DuplicateUnitId(UnitId),
    /// A requested unit update does not belong to the aggregate.
    UnitNotFound(UnitId),
    /// A unit is outside the logical map.
    UnitOutOfBounds {
        /// Unit carrying the invalid position.
        unit_id: UnitId,
        /// Position outside aggregate bounds.
        position: HexCoord,
    },
    /// Two units occupy one coordinate while stacking is disabled.
    OccupiedCoordinate {
        /// Colliding position.
        position: HexCoord,
    },
    /// More than one city used an identifier.
    DuplicateCityId(CityId),
    /// A city center or controlled coordinate is outside the map.
    CityOutOfBounds {
        /// City carrying invalid topology.
        city_id: CityId,
        /// Coordinate outside aggregate bounds.
        position: HexCoord,
    },
    /// A fog coordinate is outside the map.
    FogOutOfBounds {
        /// Player carrying invalid fog.
        player_id: PlayerId,
        /// Coordinate outside aggregate bounds.
        position: HexCoord,
    },
    /// A transport segment is outside the map.
    TransportOutOfBounds(HexCoord),
}

#[cfg(test)]
mod tests {
    use crate::{
        GameState, GameStateBuildError, HexCoord, HexGridBounds, MovementUnits, PlayerId,
        StateRevision, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
    };

    fn unit(id: &str, position: HexCoord) -> Unit {
        Unit::builder(
            UnitId::new(id).expect("unit id"),
            PlayerId::new("player-1").expect("player id"),
            UnitKind::Commander,
            "unit.commander",
            position,
            MovementUnits::new(10),
        )
        .build()
        .expect("unit")
    }

    #[test]
    fn aggregate_preserves_contract_order_and_indexes_by_id() {
        let state = GameState::try_new(
            StateRevision::new(7),
            3,
            HexGridBounds::new(5, 5).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [
                unit("unit-z", HexCoord::new(1, 1)),
                unit("unit-a", HexCoord::new(2, 1)),
            ],
        )
        .expect("state");

        assert_eq!(state.units()[0].id().as_str(), "unit-z");
        assert_eq!(
            state
                .unit(&UnitId::new("unit-a").expect("id"))
                .expect("lookup")
                .position(),
            HexCoord::new(2, 1)
        );
    }

    #[test]
    fn aggregate_rejects_out_of_bounds_and_colliding_units() {
        let bounds = HexGridBounds::new(2, 2).expect("bounds");
        let outside = unit("outside", HexCoord::new(2, 0));
        assert!(matches!(
            GameState::try_new(
                StateRevision::INITIAL,
                0,
                bounds,
                UnitOccupancyPolicy::Exclusive,
                [outside]
            ),
            Err(GameStateBuildError::UnitOutOfBounds { .. })
        ));

        let position = HexCoord::new(1, 1);
        assert_eq!(
            GameState::try_new(
                StateRevision::INITIAL,
                0,
                bounds,
                UnitOccupancyPolicy::Exclusive,
                [unit("one", position), unit("two", position)]
            ),
            Err(GameStateBuildError::OccupiedCoordinate { position })
        );
    }

    #[test]
    fn friendly_stacking_is_an_explicit_policy() {
        let position = HexCoord::new(1, 1);
        let state = GameState::try_new(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(2, 2).expect("bounds"),
            UnitOccupancyPolicy::FriendlyStacking,
            [unit("one", position), unit("two", position)],
        );
        assert!(state.is_ok());
    }
}

impl core::fmt::Display for GameStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateUnitId(id) => write!(formatter, "duplicate unit id: {id}"),
            Self::UnitNotFound(id) => write!(formatter, "unit not found: {id}"),
            Self::UnitOutOfBounds { unit_id, position } => write!(
                formatter,
                "unit {unit_id} is outside the map at ({}, {})",
                position.col(),
                position.row()
            ),
            Self::OccupiedCoordinate { position } => write!(
                formatter,
                "multiple units occupy ({}, {})",
                position.col(),
                position.row()
            ),
            Self::DuplicateCityId(id) => write!(formatter, "duplicate city id: {id}"),
            Self::CityOutOfBounds { city_id, position } => write!(
                formatter,
                "city {city_id} references ({}, {}) outside the map",
                position.col(),
                position.row()
            ),
            Self::FogOutOfBounds {
                player_id,
                position,
            } => write!(
                formatter,
                "fog for {player_id} references ({}, {}) outside the map",
                position.col(),
                position.row()
            ),
            Self::TransportOutOfBounds(position) => write!(
                formatter,
                "transport segment at ({}, {}) is outside the map",
                position.col(),
                position.row()
            ),
        }
    }
}

impl std::error::Error for GameStateBuildError {}

/// Canonical aggregate root for one atomic game simulation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameState {
    revision: StateRevision,
    turn: u32,
    bounds: HexGridBounds,
    occupancy_policy: UnitOccupancyPolicy,
    units: Box<[Unit]>,
    unit_indices_by_id: Box<[usize]>,
    cities: Box<[City]>,
    city_indices_by_id: Box<[usize]>,
    fog_of_war: FogOfWar,
    diplomacy: Diplomacy,
    transport_network: TransportNetwork,
}

impl GameState {
    /// Validates map bounds, unique identifiers and one-unit occupancy.
    ///
    /// # Errors
    ///
    /// Returns [`GameStateBuildError`] when aggregate invariants are violated.
    pub fn try_new(
        revision: StateRevision,
        turn: u32,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
    ) -> Result<Self, GameStateBuildError> {
        Self::try_new_with_world(
            revision,
            turn,
            bounds,
            occupancy_policy,
            units,
            [],
            FogOfWar::default(),
            Diplomacy::default(),
            TransportNetwork::default(),
        )
    }

    /// Validates and constructs all movement-authoritative world slices.
    ///
    /// # Errors
    ///
    /// Returns [`GameStateBuildError`] when an aggregate invariant is violated.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new_with_world(
        revision: StateRevision,
        turn: u32,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
        cities: impl IntoIterator<Item = City>,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
        transport_network: TransportNetwork,
    ) -> Result<Self, GameStateBuildError> {
        let units = units.into_iter().collect::<Vec<_>>();
        for unit in &units {
            if !bounds.contains(unit.position()) {
                return Err(GameStateBuildError::UnitOutOfBounds {
                    unit_id: unit.id().clone(),
                    position: unit.position(),
                });
            }
        }
        let mut unit_indices_by_id = (0..units.len()).collect::<Vec<_>>();
        unit_indices_by_id
            .sort_unstable_by(|left, right| units[*left].id().cmp(units[*right].id()));
        if let Some(pair) = unit_indices_by_id
            .windows(2)
            .find(|pair| units[pair[0]].id() == units[pair[1]].id())
        {
            return Err(GameStateBuildError::DuplicateUnitId(
                units[pair[0]].id().clone(),
            ));
        }
        let mut units_by_position = units.iter().collect::<Vec<_>>();
        units_by_position.sort_unstable_by_key(|unit| unit.position());
        if let Some(pair) = units_by_position.windows(2).find(|pair| {
            pair[0].position() == pair[1].position()
                && !occupancy_policy.permits(pair[0].owner_player_id(), pair[1].owner_player_id())
        }) {
            return Err(GameStateBuildError::OccupiedCoordinate {
                position: pair[0].position(),
            });
        }
        let cities = cities.into_iter().collect::<Vec<_>>();
        for city in &cities {
            for position in
                core::iter::once(city.center()).chain(city.controlled_hexes().iter().copied())
            {
                if !bounds.contains(position) {
                    return Err(GameStateBuildError::CityOutOfBounds {
                        city_id: city.id().clone(),
                        position,
                    });
                }
            }
        }
        let mut city_indices_by_id = (0..cities.len()).collect::<Vec<_>>();
        city_indices_by_id
            .sort_unstable_by(|left, right| cities[*left].id().cmp(cities[*right].id()));
        if let Some(pair) = city_indices_by_id
            .windows(2)
            .find(|pair| cities[pair[0]].id() == cities[pair[1]].id())
        {
            return Err(GameStateBuildError::DuplicateCityId(
                cities[pair[0]].id().clone(),
            ));
        }
        for player_fog in fog_of_war.players() {
            if let Some(position) = player_fog
                .discovered_hexes()
                .iter()
                .find(|coordinate| !bounds.contains(**coordinate))
            {
                return Err(GameStateBuildError::FogOutOfBounds {
                    player_id: player_fog.player_id().clone(),
                    position: *position,
                });
            }
        }
        if let Some(segment) = transport_network
            .segments()
            .iter()
            .find(|segment| !bounds.contains(segment.coordinate()))
        {
            return Err(GameStateBuildError::TransportOutOfBounds(
                segment.coordinate(),
            ));
        }
        Ok(Self {
            revision,
            turn,
            bounds,
            occupancy_policy,
            units: units.into_boxed_slice(),
            unit_indices_by_id: unit_indices_by_id.into_boxed_slice(),
            cities: cities.into_boxed_slice(),
            city_indices_by_id: city_indices_by_id.into_boxed_slice(),
            fog_of_war,
            diplomacy,
            transport_network,
        })
    }

    /// Returns the state revision.
    #[must_use]
    pub const fn revision(&self) -> StateRevision {
        self.revision
    }
    /// Returns the current turn.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }
    /// Returns logical map bounds.
    #[must_use]
    pub const fn bounds(&self) -> HexGridBounds {
        self.bounds
    }
    /// Returns the occupancy policy validated by this aggregate.
    #[must_use]
    pub const fn occupancy_policy(&self) -> UnitOccupancyPolicy {
        self.occupancy_policy
    }
    /// Returns canonical units in contract order.
    #[must_use]
    pub const fn units(&self) -> &[Unit] {
        &self.units
    }
    /// Returns cities in canonical contract order.
    #[must_use]
    pub const fn cities(&self) -> &[City] {
        &self.cities
    }
    /// Returns canonical fog state.
    #[must_use]
    pub const fn fog_of_war(&self) -> &FogOfWar {
        &self.fog_of_war
    }
    /// Returns canonical diplomacy state.
    #[must_use]
    pub const fn diplomacy(&self) -> &Diplomacy {
        &self.diplomacy
    }
    /// Returns canonical transport infrastructure.
    #[must_use]
    pub const fn transport_network(&self) -> &TransportNetwork {
        &self.transport_network
    }
    /// Finds a unit through the deterministic secondary index.
    #[must_use]
    pub fn unit(&self, unit_id: &UnitId) -> Option<&Unit> {
        self.unit_indices_by_id
            .binary_search_by(|index| self.units[*index].id().cmp(unit_id))
            .ok()
            .map(|index| &self.units[self.unit_indices_by_id[index]])
    }
    /// Finds a city through the deterministic secondary index.
    #[must_use]
    pub fn city(&self, city_id: &CityId) -> Option<&City> {
        self.city_indices_by_id
            .binary_search_by(|index| self.cities[*index].id().cmp(city_id))
            .ok()
            .map(|index| &self.cities[self.city_indices_by_id[index]])
    }

    /// Finds the first city center at a coordinate.
    #[must_use]
    pub fn city_at(&self, coordinate: HexCoord) -> Option<&City> {
        self.cities.iter().find(|city| city.center() == coordinate)
    }

    /// Derives the compatibility movement projection from canonical entities.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical data cannot satisfy projection invariants.
    pub fn movement_projection(&self) -> Result<MovementState, MovementProjectionError> {
        let units = self
            .units
            .iter()
            .enumerate()
            .map(|(index, unit)| {
                unit.movement_projection()
                    .map_err(|source| MovementProjectionError::InvalidUnit { index, source })
            })
            .collect::<Result<Vec<_>, _>>()?;
        MovementState::try_new(self.revision.get(), self.turn, units)
            .map_err(MovementProjectionError::InvalidState)
    }

    /// Rebuilds the aggregate after a movement transition.
    ///
    /// # Errors
    ///
    /// Returns an error if the updated slices violate aggregate invariants.
    pub fn after_movement(
        &self,
        revision: StateRevision,
        unit: Unit,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
    ) -> Result<Self, GameStateBuildError> {
        self.clone()
            .into_after_movement(revision, unit, fog_of_war, diplomacy)
    }

    /// Consumes the aggregate and reuses its entity storage for a movement update.
    ///
    /// # Errors
    ///
    /// Returns an error if the updated slices violate aggregate invariants.
    pub fn into_after_movement(
        self,
        revision: StateRevision,
        unit: Unit,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
    ) -> Result<Self, GameStateBuildError> {
        let index = self
            .unit_indices_by_id
            .binary_search_by(|index| self.units[*index].id().cmp(unit.id()))
            .map(|source_index| self.unit_indices_by_id[source_index])
            .map_err(|_| GameStateBuildError::UnitNotFound(unit.id().clone()))?;
        let mut units = self.units.into_vec();
        units[index] = unit;
        Self::try_new_with_world(
            revision,
            self.turn,
            self.bounds,
            self.occupancy_policy,
            units,
            self.cities.into_vec(),
            fog_of_war,
            diplomacy,
            self.transport_network,
        )
    }
}
