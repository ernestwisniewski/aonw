use std::collections::{BTreeMap, BTreeSet};

use crate::{MatchIdentity, PlayerId, WonderType};

mod errors;

pub use errors::{
    KnowledgeStateValidationError, PlayerResearchStateBuildError, WonderCompletionError,
};

/// Stable identity of one technology in the current ruleset.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd)]
pub enum TechnologyId {
    Agriculture,
    Woodworking,
    Mining,
    AnimalHusbandry,
    Hunting,
    Fishing,
    Craftsmanship,
    Trade,
    Storage,
    WaterEngineering,
    Stoneworking,
    MilitaryOrganization,
    AdvancedTrade,
    Construction,
    Navigation,
    Irrigation,
    Banking,
    Engineering,
    Metallurgy,
    HorsebackRiding,
    IronWorking,
    CoalMining,
    Machinery,
    Administration,
    Logistics,
    Shipbuilding,
    Tactics,
    Economy,
    Urbanization,
    Fortifications,
    Strategy,
    Specialization,
    Writing,
    Mathematics,
    Medicine,
    CivilService,
    Siegecraft,
    Cartography,
    Guilds,
    Law,
    Education,
    UrbanPlanning,
    NavalDoctrine,
    Steel,
    Bureaucracy,
    Nationalism,
    ScientificMethod,
    SteamPower,
    Electricity,
    Combustion,
    Flight,
    MassProduction,
    Radio,
    NuclearPhysics,
}

/// One player's canonical research selection and progress.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct PlayerResearchState {
    unlocked_technology_ids: BTreeSet<TechnologyId>,
    active_technology_id: Option<TechnologyId>,
    progress_by_technology_id: BTreeMap<TechnologyId, i64>,
    science_overflow: i64,
}

impl PlayerResearchState {
    /// Validates canonical research collections and counters.
    ///
    /// # Errors
    ///
    /// Returns an error for duplicates, non-positive progress, inconsistent
    /// unlocked state, or negative overflow.
    pub fn try_new(
        unlocked_technology_ids: impl IntoIterator<Item = TechnologyId>,
        active_technology_id: Option<TechnologyId>,
        progress_by_technology_id: impl IntoIterator<Item = (TechnologyId, i64)>,
        science_overflow: i64,
    ) -> Result<Self, PlayerResearchStateBuildError> {
        let mut unlocked = BTreeSet::new();
        for technology in unlocked_technology_ids {
            if !unlocked.insert(technology) {
                return Err(PlayerResearchStateBuildError::DuplicateUnlocked(technology));
            }
        }
        if let Some(active) = active_technology_id
            && unlocked.contains(&active)
        {
            return Err(PlayerResearchStateBuildError::ActiveAlreadyUnlocked(active));
        }
        let mut progress = BTreeMap::new();
        for (technology, amount) in progress_by_technology_id {
            if amount <= 0 {
                return Err(PlayerResearchStateBuildError::NonPositiveProgress {
                    technology,
                    amount,
                });
            }
            if unlocked.contains(&technology) {
                return Err(PlayerResearchStateBuildError::ProgressForUnlocked(
                    technology,
                ));
            }
            if progress.insert(technology, amount).is_some() {
                return Err(PlayerResearchStateBuildError::DuplicateProgress(technology));
            }
        }
        if science_overflow < 0 {
            return Err(PlayerResearchStateBuildError::NegativeScienceOverflow(
                science_overflow,
            ));
        }
        Ok(Self {
            unlocked_technology_ids: unlocked,
            active_technology_id,
            progress_by_technology_id: progress,
            science_overflow,
        })
    }

    /// Returns unlocked technologies in stable identity order.
    #[must_use]
    pub const fn unlocked_technology_ids(&self) -> &BTreeSet<TechnologyId> {
        &self.unlocked_technology_ids
    }

    /// Returns the currently selected technology.
    #[must_use]
    pub const fn active_technology_id(&self) -> Option<TechnologyId> {
        self.active_technology_id
    }

    /// Returns positive progress entries in stable identity order.
    #[must_use]
    pub const fn progress_by_technology_id(&self) -> &BTreeMap<TechnologyId, i64> {
        &self.progress_by_technology_id
    }

    /// Returns stored non-negative science overflow.
    #[must_use]
    pub const fn science_overflow(&self) -> i64 {
        self.science_overflow
    }

    /// Completes the selected technology while preserving unrelated progress.
    ///
    /// Returns the unchanged state and `None` when no technology is selected.
    #[must_use]
    pub fn after_unlocking_active(&self) -> (Self, Option<TechnologyId>) {
        let Some(active) = self.active_technology_id else {
            return (self.clone(), None);
        };
        let mut updated = self.clone();
        updated.unlocked_technology_ids.insert(active);
        updated.active_technology_id = None;
        updated.progress_by_technology_id.remove(&active);
        (updated, Some(active))
    }
}

/// Canonical research state keyed by player identity.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct ResearchState {
    players: BTreeMap<PlayerId, PlayerResearchState>,
}

impl ResearchState {
    /// Constructs deterministic per-player research state.
    ///
    /// # Errors
    ///
    /// Returns a duplicated player identity.
    pub fn try_new(
        players: impl IntoIterator<Item = (PlayerId, PlayerResearchState)>,
    ) -> Result<Self, PlayerId> {
        let mut values = BTreeMap::new();
        for (player, state) in players {
            if values.insert(player.clone(), state).is_some() {
                return Err(player);
            }
        }
        Ok(Self { players: values })
    }

    /// Returns player research in stable player-id order.
    #[must_use]
    pub const fn players(&self) -> &BTreeMap<PlayerId, PlayerResearchState> {
        &self.players
    }

    /// Replaces one participant's canonical research state.
    #[must_use]
    pub fn updating_player(&self, player: PlayerId, research: PlayerResearchState) -> Self {
        let mut players = self.players.clone();
        players.insert(player, research);
        Self { players }
    }
}

/// Globally completed wonders keyed by wonder identity.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct WonderRegistry {
    completed_by: BTreeMap<WonderType, PlayerId>,
}

impl WonderRegistry {
    /// Constructs a deterministic completed-wonder registry.
    ///
    /// # Errors
    ///
    /// Returns a duplicated wonder identity.
    pub fn try_new(
        completed_by: impl IntoIterator<Item = (WonderType, PlayerId)>,
    ) -> Result<Self, WonderType> {
        let mut values = BTreeMap::new();
        for (wonder, player) in completed_by {
            if values.insert(wonder, player).is_some() {
                return Err(wonder);
            }
        }
        Ok(Self {
            completed_by: values,
        })
    }

    /// Returns completed wonders in stable wonder order.
    #[must_use]
    pub const fn completed_by(&self) -> &BTreeMap<WonderType, PlayerId> {
        &self.completed_by
    }

    /// Records one globally unique wonder completion atomically.
    ///
    /// # Errors
    ///
    /// Returns the existing owner when the wonder was already completed.
    pub fn try_with_completed(
        &self,
        wonder: WonderType,
        player: PlayerId,
    ) -> Result<Self, WonderCompletionError> {
        if let Some(existing_owner) = self.completed_by.get(&wonder) {
            return Err(WonderCompletionError {
                wonder,
                existing_owner: existing_owner.clone(),
            });
        }
        let mut updated = self.clone();
        updated.completed_by.insert(wonder, player);
        Ok(updated)
    }
}

/// Research and global wonder state validated as one canonical component.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct KnowledgeState {
    research: ResearchState,
    wonder_registry: WonderRegistry,
}

impl KnowledgeState {
    /// Constructs a complete knowledge-state component.
    #[must_use]
    pub const fn new(research: ResearchState, wonder_registry: WonderRegistry) -> Self {
        Self {
            research,
            wonder_registry,
        }
    }

    /// Returns per-player research state.
    #[must_use]
    pub const fn research(&self) -> &ResearchState {
        &self.research
    }

    /// Returns globally completed wonders.
    #[must_use]
    pub const fn wonder_registry(&self) -> &WonderRegistry {
        &self.wonder_registry
    }

    /// Replaces the globally completed-wonder registry.
    #[must_use]
    pub fn with_wonder_registry(&self, wonder_registry: WonderRegistry) -> Self {
        Self {
            research: self.research.clone(),
            wonder_registry,
        }
    }

    /// Validates all player references against match identity.
    ///
    /// # Errors
    ///
    /// Returns the first player reference absent from match participants.
    pub fn validate_for(
        &self,
        identity: &MatchIdentity,
    ) -> Result<(), KnowledgeStateValidationError> {
        for player in self.research.players().keys() {
            if !identity.contains(player) {
                return Err(KnowledgeStateValidationError::ResearchPlayerNotFound(
                    player.clone(),
                ));
            }
        }
        for (wonder, player) in self.wonder_registry.completed_by() {
            if !identity.contains(player) {
                return Err(KnowledgeStateValidationError::WonderOwnerNotFound {
                    wonder: *wonder,
                    player_id: player.clone(),
                });
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::{PlayerId, WonderType};

    use super::{
        KnowledgeState, PlayerResearchState, PlayerResearchStateBuildError, ResearchState,
        TechnologyId, WonderRegistry,
    };

    #[test]
    fn player_research_rejects_noncanonical_progress_and_unlocks() {
        assert_eq!(
            PlayerResearchState::try_new(
                [TechnologyId::Agriculture],
                Some(TechnologyId::Agriculture),
                [],
                0,
            ),
            Err(PlayerResearchStateBuildError::ActiveAlreadyUnlocked(
                TechnologyId::Agriculture
            ))
        );
        assert_eq!(
            PlayerResearchState::try_new([], None, [(TechnologyId::Mining, 0)], 0,),
            Err(PlayerResearchStateBuildError::NonPositiveProgress {
                technology: TechnologyId::Mining,
                amount: 0,
            })
        );
    }

    #[test]
    fn wonder_completion_is_unique_and_preserves_research() {
        let owner = PlayerId::new("owner").expect("owner");
        let registry = WonderRegistry::default()
            .try_with_completed(WonderType::GreatLibrary, owner.clone())
            .expect("completion");
        let error = registry
            .try_with_completed(WonderType::GreatLibrary, owner.clone())
            .expect_err("duplicate completion");
        assert_eq!(error.wonder(), WonderType::GreatLibrary);
        assert_eq!(error.existing_owner(), &owner);
        assert!(error.to_string().contains("GreatLibrary"));

        let knowledge = KnowledgeState::new(ResearchState::default(), WonderRegistry::default())
            .with_wonder_registry(registry);
        assert!(knowledge.research().players().is_empty());
        assert_eq!(
            knowledge
                .wonder_registry()
                .completed_by()
                .get(&WonderType::GreatLibrary),
            Some(&owner)
        );
    }

    #[test]
    fn active_technology_completion_is_explicit_and_preserves_other_progress() {
        let player = PlayerId::new("player").expect("player");
        let idle = PlayerResearchState::default();
        assert_eq!(idle.after_unlocking_active(), (idle.clone(), None));

        let selected = PlayerResearchState::try_new(
            [TechnologyId::Agriculture],
            Some(TechnologyId::Writing),
            [(TechnologyId::Writing, 3), (TechnologyId::Mining, 2)],
            1,
        )
        .expect("selected research");
        let (completed, technology) = selected.after_unlocking_active();
        assert_eq!(technology, Some(TechnologyId::Writing));
        assert_eq!(completed.active_technology_id(), None);
        assert!(
            completed
                .unlocked_technology_ids()
                .contains(&TechnologyId::Writing)
        );
        assert_eq!(
            completed
                .progress_by_technology_id()
                .get(&TechnologyId::Mining),
            Some(&2)
        );
        assert!(
            !completed
                .progress_by_technology_id()
                .contains_key(&TechnologyId::Writing)
        );
        assert_eq!(completed.science_overflow(), 1);

        let research = ResearchState::default().updating_player(player.clone(), completed.clone());
        assert_eq!(research.players().get(&player), Some(&completed));
    }
}
