mod validation;

use crate::{
    ArtifactId, City, CityId, CombatState, CombatStateValidationError, Diplomacy, EconomyState,
    EconomyStateBuildError, FieldImprovement, FogOfWar, HexCoord, HexGridBounds,
    InfrastructureState, InfrastructureValidationError, InteractionState, KnowledgeState,
    KnowledgeStateValidationError, MatchLifecycle, ObjectiveState, ObjectiveStateBuildError,
    PlayerId, ResearchState, StateRevision, TransportNetwork, Unit, UnitId, WonderRegistry,
    WorldArtifact,
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
    /// Economy data violates participant ownership or map topology.
    InvalidEconomy(EconomyStateBuildError),
    /// Infrastructure data violates map or entity references.
    InvalidInfrastructure(InfrastructureValidationError),
    /// Research or wonder data references an identity outside the match.
    InvalidKnowledge(KnowledgeStateValidationError),
    /// Pending combat declarations violate aggregate references.
    InvalidCombat(CombatStateValidationError),
    /// Victory-progress state violates participant or sparse-value invariants.
    InvalidObjectives(ObjectiveStateBuildError),
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
            Self::InvalidEconomy(error) => error.fmt(formatter),
            Self::InvalidInfrastructure(error) => error.fmt(formatter),
            Self::InvalidKnowledge(error) => error.fmt(formatter),
            Self::InvalidCombat(error) => error.fmt(formatter),
            Self::InvalidObjectives(error) => error.fmt(formatter),
        }
    }
}

impl std::error::Error for GameStateBuildError {}

/// Canonical aggregate root for one atomic game simulation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameState {
    revision: StateRevision,
    turn: u32,
    match_lifecycle: MatchLifecycle,
    economy: EconomyState,
    knowledge: KnowledgeState,
    combat: CombatState,
    objectives: ObjectiveState,
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
    infrastructure: InfrastructureState,
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
        Self::try_new_with_world_and_state_sections(
            revision,
            turn,
            MatchLifecycle::default(),
            EconomyState::default(),
            KnowledgeState::default(),
            CombatState::default(),
            ObjectiveState::default(),
            bounds,
            occupancy_policy,
            units,
            cities,
            artifacts,
            interaction,
            fog_of_war,
            diplomacy,
            InfrastructureState::from_transport(transport_network),
        )
    }

    /// Validates and constructs a complete world with canonical state sections.
    ///
    /// # Errors
    ///
    /// Returns [`GameStateBuildError`] when an aggregate invariant is violated.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new_with_world_and_state_sections(
        revision: StateRevision,
        turn: u32,
        match_lifecycle: MatchLifecycle,
        economy: EconomyState,
        knowledge: KnowledgeState,
        combat: CombatState,
        objectives: ObjectiveState,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
        cities: impl IntoIterator<Item = City>,
        artifacts: impl IntoIterator<Item = WorldArtifact>,
        interaction: InteractionState,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
        infrastructure: InfrastructureState,
    ) -> Result<Self, GameStateBuildError> {
        let units = units.into_iter().collect::<Vec<_>>();
        let unit_indices_by_id = unit_indices(bounds, occupancy_policy, &units)?;
        let cities = cities.into_iter().collect::<Vec<_>>();
        let city_indices_by_id = city_indices(bounds, &cities)?;
        let artifacts = artifacts.into_iter().collect::<Vec<_>>();
        let artifact_indices_by_id = artifact_indices(&artifacts)?;
        validate_artifacts(bounds, &units, &cities, &artifacts)?;
        validate_interaction(bounds, &units, &cities, &interaction)?;
        validate_environment(
            bounds,
            match_lifecycle.identity(),
            &cities,
            &fog_of_war,
            &infrastructure,
        )?;
        economy
            .validate_for(match_lifecycle.identity(), bounds)
            .map_err(GameStateBuildError::InvalidEconomy)?;
        knowledge
            .validate_for(match_lifecycle.identity())
            .map_err(GameStateBuildError::InvalidKnowledge)?;
        combat
            .validate_for(match_lifecycle.identity(), bounds, &units)
            .map_err(GameStateBuildError::InvalidCombat)?;
        objectives
            .validate_for(match_lifecycle.identity())
            .map_err(GameStateBuildError::InvalidObjectives)?;
        Ok(Self {
            revision,
            turn,
            match_lifecycle,
            economy,
            knowledge,
            combat,
            objectives,
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
            infrastructure,
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
    /// Returns canonical match identity and current lifecycle.
    #[must_use]
    pub const fn match_lifecycle(&self) -> &MatchLifecycle {
        &self.match_lifecycle
    }
    /// Returns canonical player economy and match-start resource placement.
    #[must_use]
    pub const fn economy(&self) -> &EconomyState {
        &self.economy
    }
    /// Returns canonical research and global wonder state.
    #[must_use]
    pub const fn knowledge(&self) -> &KnowledgeState {
        &self.knowledge
    }
    /// Returns canonical per-player research.
    #[must_use]
    pub const fn research(&self) -> &ResearchState {
        self.knowledge.research()
    }
    /// Returns the global completed-wonder registry.
    #[must_use]
    pub const fn wonder_registry(&self) -> &WonderRegistry {
        self.knowledge.wonder_registry()
    }
    /// Returns pending simultaneous-combat declarations.
    #[must_use]
    pub const fn combat(&self) -> &CombatState {
        &self.combat
    }
    /// Returns persisted victory and map-objective hold progress.
    #[must_use]
    pub const fn objectives(&self) -> &ObjectiveState {
        &self.objectives
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
        self.infrastructure.transport_network()
    }
    /// Returns complete economic and transport infrastructure.
    #[must_use]
    pub const fn infrastructure(&self) -> &InfrastructureState {
        &self.infrastructure
    }
    /// Returns economic field improvements in contract order.
    #[must_use]
    pub const fn field_improvements(&self) -> &[FieldImprovement] {
        self.infrastructure.field_improvements()
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
        Self::try_new_with_world_and_state_sections(
            revision,
            self.turn,
            self.match_lifecycle,
            self.economy,
            self.knowledge,
            self.combat,
            self.objectives,
            self.bounds,
            self.occupancy_policy,
            units,
            self.cities.into_vec(),
            self.artifacts.into_vec(),
            self.interaction,
            fog_of_war,
            diplomacy,
            self.infrastructure,
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
        Self::try_new_with_world_and_state_sections(
            revision,
            self.turn,
            self.match_lifecycle,
            self.economy,
            self.knowledge,
            self.combat,
            self.objectives,
            self.bounds,
            self.occupancy_policy,
            units,
            self.cities.into_vec(),
            artifacts,
            interaction,
            self.fog_of_war,
            self.diplomacy,
            self.infrastructure,
        )
    }
}
