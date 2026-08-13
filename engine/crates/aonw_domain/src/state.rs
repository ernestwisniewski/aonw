use crate::{
    ArtifactId, HexCoord, MovementUnits, PlayerId, QueuedMovePath, UnitId, UnitKind, UnitPosture,
};

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

/// Canonical unit state used by deterministic rules and boundary mappings.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Unit {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    position: HexCoord,
    movement_units: MovementUnits,
    posture: UnitPosture,
    working: bool,
    queued_path: Option<QueuedMovePath>,
    carried_artifact_id: Option<ArtifactId>,
}

impl Unit {
    /// Constructs an immutable unit value.
    #[must_use]
    pub fn new(
        id: UnitId,
        owner_player_id: PlayerId,
        kind: UnitKind,
        position: HexCoord,
        movement_units: MovementUnits,
    ) -> Self {
        Self {
            id,
            owner_player_id,
            kind,
            position,
            movement_units,
            posture: UnitPosture::Active,
            working: false,
            queued_path: None,
            carried_artifact_id: None,
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

    /// Returns the canonical unit type.
    #[must_use]
    pub const fn kind(&self) -> UnitKind {
        self.kind
    }

    /// Returns the current canonical position.
    #[must_use]
    pub const fn position(&self) -> HexCoord {
        self.position
    }

    /// Returns integer movement units remaining in the current turn.
    #[must_use]
    pub const fn movement_units(&self) -> MovementUnits {
        self.movement_units
    }

    /// Returns the current persistent posture.
    #[must_use]
    pub const fn posture(&self) -> UnitPosture {
        self.posture
    }

    /// Returns whether a domain job makes manual movement unavailable.
    #[must_use]
    pub const fn is_working(&self) -> bool {
        self.working
    }

    /// Returns the persisted route, if movement remains queued.
    #[must_use]
    pub const fn queued_path(&self) -> Option<&QueuedMovePath> {
        self.queued_path.as_ref()
    }

    /// Returns the carried artifact affecting movement capacity.
    #[must_use]
    pub const fn carried_artifact_id(&self) -> Option<&ArtifactId> {
        self.carried_artifact_id.as_ref()
    }

    /// Replaces the posture in a newly owned unit value.
    #[must_use]
    pub fn with_posture(mut self, posture: UnitPosture) -> Self {
        self.posture = posture;
        self
    }

    /// Replaces the movement-blocking activity state.
    #[must_use]
    pub fn with_working(mut self, working: bool) -> Self {
        self.working = working;
        self
    }

    /// Replaces or clears the persisted route.
    #[must_use]
    pub fn with_queued_path(mut self, queued_path: Option<QueuedMovePath>) -> Self {
        self.queued_path = queued_path;
        self
    }

    /// Replaces or clears the carried artifact.
    #[must_use]
    pub fn with_carried_artifact(mut self, artifact_id: Option<ArtifactId>) -> Self {
        self.carried_artifact_id = artifact_id;
        self
    }
}

/// Minimal canonical world state used by the initial Rust contract slice.
///
/// Unit storage preserves contract order. A private secondary index keeps
/// identifier lookup deterministic without changing boundary serialization.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorldState {
    revision: u64,
    turn: u32,
    units: Box<[Unit]>,
    unit_indices_by_id: Box<[usize]>,
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
        let units = units.into_iter().collect::<Vec<_>>();
        let mut unit_indices_by_id = (0..units.len()).collect::<Vec<_>>();
        unit_indices_by_id
            .sort_unstable_by(|left, right| units[*left].id().cmp(units[*right].id()));
        if let Some(duplicate_indices) = unit_indices_by_id
            .windows(2)
            .find(|indices| units[indices[0]].id() == units[indices[1]].id())
        {
            return Err(StateBuildError::DuplicateUnitId(
                units[duplicate_indices[0]].id().clone(),
            ));
        }
        Ok(Self {
            revision,
            turn,
            units: units.into_boxed_slice(),
            unit_indices_by_id: unit_indices_by_id.into_boxed_slice(),
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
        self.unit_indices_by_id
            .binary_search_by(|index| self.units[*index].id().cmp(unit_id))
            .ok()
            .map(|index| &self.units[self.unit_indices_by_id[index]])
    }

    /// Returns units in the order supplied by the canonical contract.
    #[must_use]
    pub const fn units(&self) -> &[Unit] {
        &self.units
    }
}

#[cfg(test)]
mod tests {
    use crate::{HexCoord, MovementUnits, PlayerId, UnitId, UnitKind};

    use super::{StateBuildError, Unit, WorldState};

    fn unit(id: &str) -> Unit {
        Unit::new(
            UnitId::new(id).expect("valid unit id"),
            PlayerId::new("player-1").expect("valid player id"),
            UnitKind::Commander,
            HexCoord::new(0, 0),
            MovementUnits::new(10),
        )
    }

    #[test]
    fn world_state_preserves_contract_order() {
        let state =
            WorldState::try_new(7, 3, [unit("unit-z"), unit("unit-a")]).expect("valid state");

        let ids = state
            .units()
            .iter()
            .map(|value| value.id().as_str())
            .collect::<Vec<_>>();
        assert_eq!(ids, ["unit-z", "unit-a"]);
    }

    #[test]
    fn world_state_looks_units_up_through_secondary_index() {
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
        let result = WorldState::try_new(0, 1, [unit("unit-1"), unit("unit-2"), unit("unit-1")]);

        assert_eq!(result, Err(StateBuildError::DuplicateUnitId(duplicate_id)));
    }
}
