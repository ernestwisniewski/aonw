mod validation;

use crate::{
    ArtifactId, City, CityId, Diplomacy, FogOfWar, HexCoord, HexGridBounds, InteractionState,
    PlayerId, StateRevision, TransportNetwork, Unit, UnitId, WorldArtifact,
};
use validation::{
    artifact_indices, city_indices, unit_indices, validate_artifacts, validate_environment,
    validate_interaction,
};

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
    /// More than one artifact used an identifier.
    DuplicateArtifactId(ArtifactId),
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
    /// An artifact map coordinate is outside the map.
    ArtifactOutOfBounds {
        /// Artifact carrying the coordinate.
        artifact_id: ArtifactId,
        /// Invalid coordinate.
        position: HexCoord,
    },
    /// An artifact references an absent unit.
    ArtifactUnitNotFound {
        /// Artifact carrying the invalid reference.
        artifact_id: ArtifactId,
        /// Referenced unit.
        unit_id: UnitId,
    },
    /// An artifact references an absent city.
    ArtifactCityNotFound {
        /// Artifact carrying the invalid reference.
        artifact_id: ArtifactId,
        /// Referenced city.
        city_id: CityId,
    },
    /// Unit and artifact ownership references differ.
    ArtifactUnitMismatch {
        /// Artifact carrying the invalid ownership.
        artifact_id: ArtifactId,
        /// Referenced unit.
        unit_id: UnitId,
    },
    /// A unit references an absent artifact.
    UnitArtifactNotFound {
        /// Unit carrying the invalid reference.
        unit_id: UnitId,
        /// Referenced artifact.
        artifact_id: ArtifactId,
    },
    /// Interaction state references an absent unit.
    InteractionUnitNotFound(UnitId),
    /// Interaction state references an absent city.
    InteractionCityNotFound(CityId),
    /// Interaction state contains an out-of-bounds coordinate.
    InteractionOutOfBounds(HexCoord),
    /// Interaction ownership differs from the referenced unit or city.
    InteractionOwnerMismatch,
    /// A pending turn skip does not match the skipped unit state.
    InvalidTurnSkipState(UnitId),
}

#[cfg(test)]
mod tests;

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
            Self::DuplicateArtifactId(id) => write!(formatter, "duplicate artifact id: {id}"),
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
            Self::ArtifactOutOfBounds {
                artifact_id,
                position,
            } => write!(
                formatter,
                "artifact {artifact_id} is outside the map at ({}, {})",
                position.col(),
                position.row()
            ),
            Self::ArtifactUnitNotFound {
                artifact_id,
                unit_id,
            } => write!(
                formatter,
                "artifact {artifact_id} references missing unit {unit_id}"
            ),
            Self::ArtifactCityNotFound {
                artifact_id,
                city_id,
            } => write!(
                formatter,
                "artifact {artifact_id} references missing city {city_id}"
            ),
            Self::ArtifactUnitMismatch {
                artifact_id,
                unit_id,
            } => write!(
                formatter,
                "artifact {artifact_id} and unit {unit_id} ownership differ"
            ),
            Self::UnitArtifactNotFound {
                unit_id,
                artifact_id,
            } => write!(
                formatter,
                "unit {unit_id} references missing artifact {artifact_id}"
            ),
            Self::InteractionUnitNotFound(id) => {
                write!(formatter, "interaction references missing unit {id}")
            }
            Self::InteractionCityNotFound(id) => {
                write!(formatter, "interaction references missing city {id}")
            }
            Self::InteractionOutOfBounds(position) => write!(
                formatter,
                "interaction references ({}, {}) outside the map",
                position.col(),
                position.row()
            ),
            Self::InteractionOwnerMismatch => {
                formatter.write_str("interaction owner does not own its referenced entity")
            }
            Self::InvalidTurnSkipState(id) => {
                write!(formatter, "pending turn skip does not match unit {id}")
            }
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
    artifacts: Box<[WorldArtifact]>,
    artifact_indices_by_id: Box<[usize]>,
    interaction: InteractionState,
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
            [],
            InteractionState::default(),
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
        artifacts: impl IntoIterator<Item = WorldArtifact>,
        interaction: InteractionState,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
        transport_network: TransportNetwork,
    ) -> Result<Self, GameStateBuildError> {
        let units = units.into_iter().collect::<Vec<_>>();
        let unit_indices_by_id = unit_indices(bounds, occupancy_policy, &units)?;
        let cities = cities.into_iter().collect::<Vec<_>>();
        let city_indices_by_id = city_indices(bounds, &cities)?;
        let artifacts = artifacts.into_iter().collect::<Vec<_>>();
        let artifact_indices_by_id = artifact_indices(&artifacts)?;
        validate_artifacts(bounds, &units, &cities, &artifacts)?;
        validate_interaction(bounds, &units, &cities, &interaction)?;
        validate_environment(bounds, &fog_of_war, &transport_network)?;
        Ok(Self {
            revision,
            turn,
            bounds,
            occupancy_policy,
            units: units.into_boxed_slice(),
            unit_indices_by_id: unit_indices_by_id.into_boxed_slice(),
            cities: cities.into_boxed_slice(),
            city_indices_by_id: city_indices_by_id.into_boxed_slice(),
            artifacts: artifacts.into_boxed_slice(),
            artifact_indices_by_id: artifact_indices_by_id.into_boxed_slice(),
            interaction,
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
    /// Returns artifacts in canonical contract order.
    #[must_use]
    pub const fn artifacts(&self) -> &[WorldArtifact] {
        &self.artifacts
    }
    /// Returns rule-relevant interaction state.
    #[must_use]
    pub const fn interaction(&self) -> &InteractionState {
        &self.interaction
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
    /// Finds an artifact through the deterministic secondary index.
    #[must_use]
    pub fn artifact(&self, artifact_id: &ArtifactId) -> Option<&WorldArtifact> {
        self.artifact_indices_by_id
            .binary_search_by(|index| self.artifacts[*index].id().cmp(artifact_id))
            .ok()
            .map(|index| &self.artifacts[self.artifact_indices_by_id[index]])
    }

    /// Finds the first city center at a coordinate.
    #[must_use]
    pub fn city_at(&self, coordinate: HexCoord) -> Option<&City> {
        self.cities.iter().find(|city| city.center() == coordinate)
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
            self.artifacts.into_vec(),
            self.interaction,
            fog_of_war,
            diplomacy,
            self.transport_network,
        )
    }

    /// Consumes the aggregate and applies one complete unit-action update.
    ///
    /// # Errors
    ///
    /// Returns an error if the unit is absent or the next aggregate is invalid.
    pub fn into_after_unit_action(
        self,
        revision: StateRevision,
        unit: Unit,
        interaction: InteractionState,
        cancelled_excavation: Option<ArtifactId>,
    ) -> Result<Self, GameStateBuildError> {
        let index = self
            .unit_indices_by_id
            .binary_search_by(|index| self.units[*index].id().cmp(unit.id()))
            .map(|source_index| self.unit_indices_by_id[source_index])
            .map_err(|_| GameStateBuildError::UnitNotFound(unit.id().clone()))?;
        let mut units = self.units.into_vec();
        let unit_id = unit.id().clone();
        units[index] = unit;
        let mut artifacts = self.artifacts.into_vec();
        if let Some(artifact_id) = cancelled_excavation
            && let Some(artifact) = artifacts
                .iter_mut()
                .find(|artifact| artifact.id() == &artifact_id)
        {
            artifact.restore_excavation(&unit_id);
        }
        Self::try_new_with_world(
            revision,
            self.turn,
            self.bounds,
            self.occupancy_policy,
            units,
            self.cities.into_vec(),
            artifacts,
            interaction,
            self.fog_of_war,
            self.diplomacy,
            self.transport_network,
        )
    }
}
