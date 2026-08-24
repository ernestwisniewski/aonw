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

/// Incrementally assembles one canonical state without exposing a partially
/// validated [`GameState`].
#[must_use = "the state is not validated until try_build is called"]
pub struct GameStateBuilder {
    revision: StateRevision,
    turn: u32,
    match_lifecycle: MatchLifecycle,
    economy: EconomyState,
    knowledge: KnowledgeState,
    combat: CombatState,
    objectives: ObjectiveState,
    bounds: HexGridBounds,
    occupancy_policy: UnitOccupancyPolicy,
    units: Vec<Unit>,
    cities: Vec<City>,
    artifacts: Vec<WorldArtifact>,
    interaction: InteractionState,
    fog_of_war: FogOfWar,
    diplomacy: Diplomacy,
    infrastructure: InfrastructureState,
}

impl GameStateBuilder {
    fn new(
        revision: StateRevision,
        turn: u32,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
    ) -> Self {
        Self {
            revision,
            turn,
            match_lifecycle: MatchLifecycle::default(),
            economy: EconomyState::default(),
            knowledge: KnowledgeState::default(),
            combat: CombatState::default(),
            objectives: ObjectiveState::default(),
            bounds,
            occupancy_policy,
            units: units.into_iter().collect(),
            cities: Vec::new(),
            artifacts: Vec::new(),
            interaction: InteractionState::default(),
            fog_of_war: FogOfWar::default(),
            diplomacy: Diplomacy::default(),
            infrastructure: InfrastructureState::default(),
        }
    }

    /// Replaces the default match identity and turn lifecycle.
    pub fn with_match_lifecycle(mut self, value: MatchLifecycle) -> Self {
        self.match_lifecycle = value;
        self
    }

    /// Replaces the default economy section.
    pub fn with_economy(mut self, value: EconomyState) -> Self {
        self.economy = value;
        self
    }

    /// Replaces the default research and wonder section.
    pub fn with_knowledge(mut self, value: KnowledgeState) -> Self {
        self.knowledge = value;
        self
    }

    /// Replaces the default pending-combat section.
    pub fn with_combat(mut self, value: CombatState) -> Self {
        self.combat = value;
        self
    }

    /// Replaces the default objective-progress section.
    pub fn with_objectives(mut self, value: ObjectiveState) -> Self {
        self.objectives = value;
        self
    }

    /// Replaces the empty city collection.
    pub fn with_cities(mut self, values: impl IntoIterator<Item = City>) -> Self {
        self.cities = values.into_iter().collect();
        self
    }

    /// Replaces the empty artifact collection.
    pub fn with_artifacts(mut self, values: impl IntoIterator<Item = WorldArtifact>) -> Self {
        self.artifacts = values.into_iter().collect();
        self
    }

    /// Replaces the default interaction state.
    pub fn with_interaction(mut self, value: InteractionState) -> Self {
        self.interaction = value;
        self
    }

    /// Replaces the default fog state.
    pub fn with_fog_of_war(mut self, value: FogOfWar) -> Self {
        self.fog_of_war = value;
        self
    }

    /// Replaces the default diplomacy state.
    pub fn with_diplomacy(mut self, value: Diplomacy) -> Self {
        self.diplomacy = value;
        self
    }

    /// Replaces the default infrastructure section.
    pub fn with_infrastructure(mut self, value: InfrastructureState) -> Self {
        self.infrastructure = value;
        self
    }

    /// Uses a transport-only infrastructure section.
    pub fn with_transport_network(mut self, value: TransportNetwork) -> Self {
        self.infrastructure = InfrastructureState::from_transport(value);
        self
    }

    /// Validates every local and cross-section invariant and constructs the
    /// canonical aggregate atomically.
    ///
    /// # Errors
    ///
    /// Returns [`GameStateBuildError`] when any aggregate invariant is
    /// violated. No partially validated [`GameState`] is returned.
    pub fn try_build(self) -> Result<GameState, GameStateBuildError> {
        let unit_indices_by_id = unit_indices(self.bounds, self.occupancy_policy, &self.units)?;
        let city_indices_by_id = city_indices(self.bounds, &self.cities)?;
        let artifact_indices_by_id = artifact_indices(&self.artifacts)?;
        validate_artifacts(self.bounds, &self.units, &self.cities, &self.artifacts)?;
        validate_interaction(self.bounds, &self.units, &self.cities, &self.interaction)?;
        validate_environment(
            self.bounds,
            self.match_lifecycle.identity(),
            &self.cities,
            &self.fog_of_war,
            &self.infrastructure,
        )?;
        self.economy
            .validate_for(self.match_lifecycle.identity(), self.bounds)
            .map_err(GameStateBuildError::InvalidEconomy)?;
        self.knowledge
            .validate_for(self.match_lifecycle.identity())
            .map_err(GameStateBuildError::InvalidKnowledge)?;
        self.combat
            .validate_for(self.match_lifecycle.identity(), self.bounds, &self.units)
            .map_err(GameStateBuildError::InvalidCombat)?;
        self.objectives
            .validate_for(self.match_lifecycle.identity())
            .map_err(GameStateBuildError::InvalidObjectives)?;
        Ok(GameState {
            revision: self.revision,
            turn: self.turn,
            match_lifecycle: self.match_lifecycle,
            economy: self.economy,
            knowledge: self.knowledge,
            combat: self.combat,
            objectives: self.objectives,
            bounds: self.bounds,
            occupancy_policy: self.occupancy_policy,
            units: self.units.into_boxed_slice(),
            unit_indices_by_id: unit_indices_by_id.into_boxed_slice(),
            cities: self.cities.into_boxed_slice(),
            city_indices_by_id: city_indices_by_id.into_boxed_slice(),
            artifacts: self.artifacts.into_boxed_slice(),
            artifact_indices_by_id: artifact_indices_by_id.into_boxed_slice(),
            interaction: self.interaction,
            fog_of_war: self.fog_of_war,
            diplomacy: self.diplomacy,
            infrastructure: self.infrastructure,
        })
    }
}

impl GameState {
    /// Starts an aggregate builder with required identity, topology and units.
    pub fn builder(
        revision: StateRevision,
        turn: u32,
        bounds: HexGridBounds,
        occupancy_policy: UnitOccupancyPolicy,
        units: impl IntoIterator<Item = Unit>,
    ) -> GameStateBuilder {
        GameStateBuilder::new(revision, turn, bounds, occupancy_policy, units)
    }

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
        Self::builder(revision, turn, bounds, occupancy_policy, units).try_build()
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

    fn into_builder(self) -> GameStateBuilder {
        GameStateBuilder {
            revision: self.revision,
            turn: self.turn,
            match_lifecycle: self.match_lifecycle,
            economy: self.economy,
            knowledge: self.knowledge,
            combat: self.combat,
            objectives: self.objectives,
            bounds: self.bounds,
            occupancy_policy: self.occupancy_policy,
            units: self.units.into_vec(),
            cities: self.cities.into_vec(),
            artifacts: self.artifacts.into_vec(),
            interaction: self.interaction,
            fog_of_war: self.fog_of_war,
            diplomacy: self.diplomacy,
            infrastructure: self.infrastructure,
        }
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
        let mut builder = self.into_builder();
        builder.units[index] = unit;
        builder.revision = revision;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.try_build()
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
        let mut builder = self.into_builder();
        let unit_id = unit.id().clone();
        builder.units[index] = unit;
        if let Some(artifact_id) = cancelled_excavation
            && let Some(artifact) = builder
                .artifacts
                .iter_mut()
                .find(|artifact| artifact.id() == &artifact_id)
        {
            artifact.restore_excavation(&unit_id);
        }
        builder.revision = revision;
        builder.interaction = interaction;
        builder.try_build()
    }
}
