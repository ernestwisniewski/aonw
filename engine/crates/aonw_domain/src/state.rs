use crate::{HexCoord, PlayerId, UnitId};

/// Failure raised when external data cannot form a valid canonical state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum StateBuildError {
    /// More than one unit used the same identifier.
    DuplicateUnitId(UnitId),
}

impl core::fmt::Display for StateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateUnitId(unit_id) => write!(formatter, "duplicate unit id: {unit_id}"),
        }
    }
}

impl std::error::Error for StateBuildError {}

/// Canonical unit data required by the first state-contract slice.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Unit {
    id: UnitId,
    owner_player_id: PlayerId,
    position: HexCoord,
    movement_units: u32,
}

impl Unit {
    /// Constructs an immutable unit value.
    #[must_use]
    pub const fn new(
        id: UnitId,
        owner_player_id: PlayerId,
        position: HexCoord,
        movement_units: u32,
    ) -> Self {
        Self {
            id,
            owner_player_id,
            position,
            movement_units,
        }
    }

    /// Returns the unit identifier.
    #[must_use]
    pub const fn id(&self) -> &UnitId {
        &self.id
    }

    /// Returns the owning player identifier.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }

    /// Returns the current canonical position.
    #[must_use]
    pub const fn position(&self) -> HexCoord {
        self.position
    }

    /// Returns integer movement units remaining in the current turn.
    #[must_use]
    pub const fn movement_units(&self) -> u32 {
        self.movement_units
    }
}

/// Minimal canonical world state used by the initial Rust contract slice.
///
/// Units use sorted contiguous storage. This keeps iteration and boundary
/// encoding deterministic, improves cache locality, and supports allocation-
/// free binary-search lookup.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorldState {
    revision: u64,
    turn: u32,
    units: Box<[Unit]>,
}

impl WorldState {
    /// Builds canonical state and rejects duplicate entity identifiers.
    ///
    /// # Errors
    ///
    /// Returns [`StateBuildError::DuplicateUnitId`] when two units share one
    /// identifier.
    pub fn try_new(
        revision: u64,
        turn: u32,
        units: impl IntoIterator<Item = Unit>,
    ) -> Result<Self, StateBuildError> {
        let mut units = units.into_iter().collect::<Vec<_>>();
        units.sort_unstable_by(|left, right| left.id().cmp(right.id()));
        if let Some(duplicate) = units.windows(2).find(|pair| pair[0].id() == pair[1].id()) {
            return Err(StateBuildError::DuplicateUnitId(duplicate[0].id().clone()));
        }
        Ok(Self {
            revision,
            turn,
            units: units.into_boxed_slice(),
        })
    }

    /// Returns the canonical state revision.
    #[must_use]
    pub const fn revision(&self) -> u64 {
        self.revision
    }

    /// Returns the current turn number.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }

    /// Returns a unit by its opaque identifier.
    #[must_use]
    pub fn unit(&self, unit_id: &UnitId) -> Option<&Unit> {
        self.units
            .binary_search_by(|unit| unit.id().cmp(unit_id))
            .ok()
            .map(|index| &self.units[index])
    }

    /// Returns units in stable identifier order.
    #[must_use]
    pub const fn units(&self) -> &[Unit] {
        &self.units
    }
}

#[cfg(test)]
mod tests {
    use crate::{HexCoord, PlayerId, UnitId};

    use super::{StateBuildError, Unit, WorldState};

    fn unit(id: &str) -> Unit {
        Unit::new(
            UnitId::new(id).expect("valid unit id"),
            PlayerId::new("player-1").expect("valid player id"),
            HexCoord::new(0, 0),
            100,
        )
    }

    #[test]
    fn world_state_iteration_is_identifier_ordered() {
        let state =
            WorldState::try_new(7, 3, [unit("unit-z"), unit("unit-a")]).expect("valid state");

        let ids = state
            .units()
            .iter()
            .map(|value| value.id().as_str())
            .collect::<Vec<_>>();
        assert_eq!(ids, ["unit-a", "unit-z"]);
    }

    #[test]
    fn world_state_looks_units_up_in_sorted_storage() {
        let state = WorldState::try_new(7, 3, [unit("unit-z"), unit("unit-a"), unit("unit-m")])
            .expect("valid state");
        let requested = UnitId::new("unit-m").expect("valid unit id");

        assert_eq!(
            state.unit(&requested).map(|value| value.id().as_str()),
            Some("unit-m")
        );
    }

    #[test]
    fn world_state_rejects_duplicate_units() {
        let duplicate_id = UnitId::new("unit-1").expect("valid unit id");
        let result = WorldState::try_new(0, 1, [unit("unit-1"), unit("unit-1")]);

        assert_eq!(result, Err(StateBuildError::DuplicateUnitId(duplicate_id)));
    }
}
