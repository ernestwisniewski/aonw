use crate::{HexCoord, HexGridBounds, PlayerId, StateRevision, Unit, UnitId};

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
        Ok(Self {
            revision,
            turn,
            bounds,
            occupancy_policy,
            units: units.into_boxed_slice(),
            unit_indices_by_id: unit_indices_by_id.into_boxed_slice(),
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
    /// Finds a unit through the deterministic secondary index.
    #[must_use]
    pub fn unit(&self, unit_id: &UnitId) -> Option<&Unit> {
        self.unit_indices_by_id
            .binary_search_by(|index| self.units[*index].id().cmp(unit_id))
            .ok()
            .map(|index| &self.units[self.unit_indices_by_id[index]])
    }
}
