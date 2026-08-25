use crate::{
    City, CombatState, Diplomacy, EconomyState, FogOfWar, InfrastructureState, InteractionState,
    KnowledgeState, MatchLifecycle, StateRevision, Unit, WorldArtifact,
};

use super::{GameState, GameStateBuildError};

/// Complete replacement produced by one authoritative artifact transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ArtifactStateUpdate {
    /// Revision after the transition.
    pub revision: StateRevision,
    /// Canonical units after excavation, carrying, or storage.
    pub units: Vec<Unit>,
    /// Canonical artifact locations after the transition.
    pub artifacts: Vec<WorldArtifact>,
    /// Economy after an atomic artifact-and-gold transfer.
    pub economy: EconomyState,
}

/// Complete replacement produced by one authoritative combat transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CombatStateUpdate {
    /// Revision after the transition.
    pub revision: StateRevision,
    /// Canonical units after casualties, experience, and retreats.
    pub units: Vec<Unit>,
    /// Canonical cities after damage, capture, or destruction.
    pub cities: Vec<City>,
    /// Canonical artifact locations after combat losses.
    pub artifacts: Vec<WorldArtifact>,
    /// Pending intended attacks after the transition.
    pub combat: CombatState,
    /// Recipient visibility recomputed after the transition.
    pub fog_of_war: FogOfWar,
    /// Diplomacy after attack consequences and discovered contacts.
    pub diplomacy: Diplomacy,
}

/// Complete replacement produced by one authoritative production transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProductionStateUpdate {
    /// Revision after the transition.
    pub revision: StateRevision,
    /// Canonical units after deterministic production spawns.
    pub units: Vec<Unit>,
    /// Canonical cities after queue, overflow, specialization, and completions.
    pub cities: Vec<City>,
    /// Economy after rush payment, reservations, refunds, and completion effects.
    pub economy: EconomyState,
    /// Research and globally unique wonder ownership after completions.
    pub knowledge: KnowledgeState,
    /// Recipient visibility recomputed after spawned units.
    pub fog_of_war: FogOfWar,
    /// Diplomacy after contacts discovered by spawned units.
    pub diplomacy: Diplomacy,
}

/// Canonical turn coordinates replaced atomically by the turn kernel.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TurnAdvance {
    turn: u32,
    lifecycle: MatchLifecycle,
}

impl TurnAdvance {
    /// Creates one trusted turn update.
    #[must_use]
    pub const fn new(turn: u32, lifecycle: MatchLifecycle) -> Self {
        Self { turn, lifecycle }
    }
}

impl GameState {
    /// Consumes the aggregate and applies one complete artifact update.
    ///
    /// # Errors
    /// Returns an error when unit, artifact, or economy invariants fail.
    pub fn into_after_artifact(
        self,
        update: ArtifactStateUpdate,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = update.revision;
        builder.units = update.units;
        builder.artifacts = update.artifacts;
        builder.economy = update.economy;
        builder.try_build()
    }

    /// Consumes the aggregate and applies one complete city command update.
    ///
    /// # Errors
    ///
    /// Returns an error when any replacement collection violates aggregate invariants.
    pub fn into_after_city(
        self,
        revision: StateRevision,
        units: Vec<Unit>,
        cities: Vec<City>,
        interaction: InteractionState,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = revision;
        builder.units = units;
        builder.cities = cities;
        builder.interaction = interaction;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.try_build()
    }

    /// Consumes the aggregate and applies one complete combat update.
    ///
    /// # Errors
    ///
    /// Returns an error when any replacement collection violates aggregate invariants.
    pub fn into_after_combat(self, update: CombatStateUpdate) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = update.revision;
        builder.units = update.units;
        builder.cities = update.cities;
        builder.artifacts = update.artifacts;
        builder.combat = update.combat;
        builder.fog_of_war = update.fog_of_war;
        builder.diplomacy = update.diplomacy;
        builder.try_build()
    }

    /// Consumes the aggregate and applies one complete production update.
    ///
    /// # Errors
    ///
    /// Returns an error when any replacement violates aggregate invariants.
    pub fn into_after_production(
        self,
        update: ProductionStateUpdate,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = update.revision;
        builder.units = update.units;
        builder.cities = update.cities;
        builder.economy = update.economy;
        builder.knowledge = update.knowledge;
        builder.fog_of_war = update.fog_of_war;
        builder.diplomacy = update.diplomacy;
        builder.try_build()
    }

    /// Consumes the aggregate and applies a complete movement/logistics update.
    ///
    /// # Errors
    ///
    /// Returns an error when the resulting units, fog, diplomacy, or interaction
    /// violate an aggregate invariant.
    pub fn into_after_movement_logistics(
        self,
        revision: StateRevision,
        units: Vec<Unit>,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
        interaction: InteractionState,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = revision;
        builder.units = units;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.interaction = interaction;
        builder.try_build()
    }

    /// Consumes the aggregate and applies a worker/infrastructure command update.
    ///
    /// # Errors
    ///
    /// Returns an error when units or infrastructure violate aggregate invariants.
    pub fn into_after_worker(
        self,
        revision: StateRevision,
        units: Vec<Unit>,
        infrastructure: InfrastructureState,
        interaction: InteractionState,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = revision;
        builder.units = units;
        builder.infrastructure = infrastructure;
        builder.interaction = interaction;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.try_build()
    }

    /// Consumes the aggregate and applies one atomic turn-kernel update.
    ///
    /// # Errors
    ///
    /// Returns an error if the replacement lifecycle or units violate aggregate invariants.
    pub fn into_after_turn_kernel(
        self,
        revision: StateRevision,
        advance: TurnAdvance,
        units: Vec<Unit>,
        fog_of_war: FogOfWar,
        diplomacy: Diplomacy,
        interaction: InteractionState,
    ) -> Result<Self, GameStateBuildError> {
        let mut builder = self.into_builder();
        builder.revision = revision;
        builder.turn = advance.turn;
        builder.match_lifecycle = advance.lifecycle;
        builder.units = units;
        builder.fog_of_war = fog_of_war;
        builder.diplomacy = diplomacy;
        builder.interaction = interaction;
        builder.try_build()
    }
}
