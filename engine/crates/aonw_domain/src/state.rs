use crate::{
    ArtifactId, HexCoord, MovementUnits, PlayerId, QueuedMovePath, UnitId, UnitKind, UnitPosture,
};

/// Failure raised when data cannot form a valid movement projection.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum MovementStateBuildError {
    /// More than one unit used the same identifier.
    DuplicateUnitId(UnitId),
}

impl core::fmt::Display for MovementStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateUnitId(unit_id) => write!(formatter, "duplicate unit id: {unit_id}"),
        }
    }
}

impl std::error::Error for MovementStateBuildError {}

/// Failure raised while constructing a movement-oriented unit projection.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MovementUnitBuildError {
    /// A persisted path starts somewhere other than the unit position.
    QueuedPathOriginMismatch {
        /// Current unit position.
        expected: HexCoord,
        /// Origin embedded in the queued path.
        actual: HexCoord,
    },
}

impl core::fmt::Display for MovementUnitBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::QueuedPathOriginMismatch { expected, actual } => write!(
                formatter,
                "queued path origin ({}, {}) does not match unit position ({}, {})",
                actual.col(),
                actual.row(),
                expected.col(),
                expected.row()
            ),
        }
    }
}

impl std::error::Error for MovementUnitBuildError {}

/// Immutable unit projection required by movement rules.
///
/// This is not the complete persisted unit aggregate. Adapters derive it from
/// canonical state and apply returned movement updates without dropping fields
/// outside this projection.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MovementUnit {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    position: HexCoord,
    movement_units: MovementUnits,
    posture: UnitPosture,
    movement_blocked: bool,
    queued_path: Option<QueuedMovePath>,
    carried_artifact_id: Option<ArtifactId>,
}

impl MovementUnit {
    /// Constructs an immutable movement projection.
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
            movement_blocked: false,
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
    pub const fn is_movement_blocked(&self) -> bool {
        self.movement_blocked
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
    pub fn with_movement_blocked(mut self, movement_blocked: bool) -> Self {
        self.movement_blocked = movement_blocked;
        self
    }

    /// Replaces or clears the persisted route after validating its origin.
    ///
    /// # Errors
    ///
    /// Returns [`MovementUnitBuildError::QueuedPathOriginMismatch`] when the
    /// queued route does not start at the current unit position.
    pub fn try_with_queued_path(
        mut self,
        queued_path: Option<QueuedMovePath>,
    ) -> Result<Self, MovementUnitBuildError> {
        if let Some(path) = &queued_path {
            let actual = path
                .steps()
                .first()
                .map_or(path.target(), |step| step.coordinate());
            if actual != self.position {
                return Err(MovementUnitBuildError::QueuedPathOriginMismatch {
                    expected: self.position,
                    actual,
                });
            }
        }
        self.queued_path = queued_path;
        Ok(self)
    }

    /// Replaces or clears the carried artifact.
    #[must_use]
    pub fn with_carried_artifact(mut self, artifact_id: Option<ArtifactId>) -> Self {
        self.carried_artifact_id = artifact_id;
        self
    }

    /// Applies a validated movement result while preserving projection identity.
    ///
    /// # Errors
    ///
    /// Returns [`MovementUnitBuildError`] when a retained queued path does not
    /// start at the new position.
    pub fn try_after_movement(
        mut self,
        position: HexCoord,
        movement_units: MovementUnits,
        queued_path: Option<QueuedMovePath>,
    ) -> Result<Self, MovementUnitBuildError> {
        self.position = position;
        self.movement_units = movement_units;
        self.posture = UnitPosture::Active;
        self.try_with_queued_path(queued_path)
    }
}

/// Immutable state projection required by movement rules.
///
/// Unit storage preserves contract order. A private secondary index keeps
/// identifier lookup deterministic without changing boundary serialization.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MovementState {
    revision: u64,
    turn: u32,
    units: Box<[MovementUnit]>,
    unit_indices_by_id: Box<[usize]>,
}

impl MovementState {
    /// Builds a movement projection and rejects duplicate entity identifiers.
    ///
    /// # Errors
    ///
    /// Returns [`MovementStateBuildError::DuplicateUnitId`] when two units share one
    /// identifier.
    pub fn try_new(
        revision: u64,
        turn: u32,
        units: impl IntoIterator<Item = MovementUnit>,
    ) -> Result<Self, MovementStateBuildError> {
        let units = units.into_iter().collect::<Vec<_>>();
        let mut unit_indices_by_id = (0..units.len()).collect::<Vec<_>>();
        unit_indices_by_id
            .sort_unstable_by(|left, right| units[*left].id().cmp(units[*right].id()));
        if let Some(duplicate_indices) = unit_indices_by_id
            .windows(2)
            .find(|indices| units[indices[0]].id() == units[indices[1]].id())
        {
            return Err(MovementStateBuildError::DuplicateUnitId(
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
    pub fn unit(&self, unit_id: &UnitId) -> Option<&MovementUnit> {
        self.unit_indices_by_id
            .binary_search_by(|index| self.units[*index].id().cmp(unit_id))
            .ok()
            .map(|index| &self.units[self.unit_indices_by_id[index]])
    }

    /// Returns units in the order supplied by the canonical contract.
    #[must_use]
    pub const fn units(&self) -> &[MovementUnit] {
        &self.units
    }

    /// Returns a new projection with one existing unit and revision replaced.
    #[must_use]
    pub fn replacing_unit(&self, revision: u64, unit: MovementUnit) -> Option<Self> {
        let source_index = self
            .unit_indices_by_id
            .binary_search_by(|index| self.units[*index].id().cmp(unit.id()))
            .ok()?;
        let unit_index = self.unit_indices_by_id[source_index];
        let mut units = self.units.to_vec();
        units[unit_index] = unit;
        Some(Self {
            revision,
            turn: self.turn,
            units: units.into_boxed_slice(),
            unit_indices_by_id: self.unit_indices_by_id.clone(),
        })
    }

    /// Returns an otherwise identical projection at a new revision.
    #[must_use]
    pub fn with_revision(&self, revision: u64) -> Self {
        Self {
            revision,
            turn: self.turn,
            units: self.units.clone(),
            unit_indices_by_id: self.unit_indices_by_id.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::{HexCoord, MovementUnits, PlayerId, UnitId, UnitKind};

    use super::{MovementState, MovementStateBuildError, MovementUnit};

    fn unit(id: &str) -> MovementUnit {
        MovementUnit::new(
            UnitId::new(id).expect("valid unit id"),
            PlayerId::new("player-1").expect("valid player id"),
            UnitKind::Commander,
            HexCoord::new(0, 0),
            MovementUnits::new(10),
        )
    }

    #[test]
    fn movement_state_preserves_contract_order() {
        let state =
            MovementState::try_new(7, 3, [unit("unit-z"), unit("unit-a")]).expect("valid state");

        let ids = state
            .units()
            .iter()
            .map(|value| value.id().as_str())
            .collect::<Vec<_>>();
        assert_eq!(ids, ["unit-z", "unit-a"]);
    }

    #[test]
    fn movement_state_looks_units_up_through_secondary_index() {
        let state = MovementState::try_new(7, 3, [unit("unit-z"), unit("unit-a"), unit("unit-m")])
            .expect("valid state");
        let requested = UnitId::new("unit-m").expect("valid unit id");

        assert_eq!(
            state.unit(&requested).map(|value| value.id().as_str()),
            Some("unit-m")
        );
    }

    #[test]
    fn movement_state_rejects_duplicate_units() {
        let duplicate_id = UnitId::new("unit-1").expect("valid unit id");
        let result = MovementState::try_new(0, 1, [unit("unit-1"), unit("unit-2"), unit("unit-1")]);

        assert_eq!(
            result,
            Err(MovementStateBuildError::DuplicateUnitId(duplicate_id))
        );
    }
}
