use std::collections::{BTreeMap, BTreeSet};

use crate::{MatchIdentity, PlayerId, WonderType};

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

/// Structural player-research validation failure.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum PlayerResearchStateBuildError {
    /// An unlocked technology appeared more than once.
    DuplicateUnlocked(TechnologyId),
    /// The active selection was already unlocked.
    ActiveAlreadyUnlocked(TechnologyId),
    /// A progress entry appeared more than once.
    DuplicateProgress(TechnologyId),
    /// A progress entry was zero or negative.
    NonPositiveProgress {
        /// Technology carrying invalid progress.
        technology: TechnologyId,
        /// Invalid progress value.
        amount: i64,
    },
    /// An unlocked technology retained progress.
    ProgressForUnlocked(TechnologyId),
    /// Science overflow was negative.
    NegativeScienceOverflow(i64),
}

impl core::fmt::Display for PlayerResearchStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::DuplicateUnlocked(value) => {
                write!(formatter, "duplicate unlocked technology: {value:?}")
            }
            Self::ActiveAlreadyUnlocked(value) => write!(
                formatter,
                "active technology is already unlocked: {value:?}"
            ),
            Self::DuplicateProgress(value) => {
                write!(formatter, "duplicate technology progress: {value:?}")
            }
            Self::NonPositiveProgress { technology, amount } => write!(
                formatter,
                "technology progress must be positive for {technology:?}: {amount}"
            ),
            Self::ProgressForUnlocked(value) => {
                write!(formatter, "unlocked technology retains progress: {value:?}")
            }
            Self::NegativeScienceOverflow(value) => {
                write!(formatter, "science overflow must be non-negative: {value}")
            }
        }
    }
}

impl std::error::Error for PlayerResearchStateBuildError {}

/// Cross-section knowledge-state validation failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum KnowledgeStateValidationError {
    /// Research was keyed by a non-participant player.
    ResearchPlayerNotFound(PlayerId),
    /// A completed wonder was attributed to a non-participant player.
    WonderOwnerNotFound {
        /// Wonder carrying invalid attribution.
        wonder: WonderType,
        /// Player absent from match identity.
        player_id: PlayerId,
    },
}

impl core::fmt::Display for KnowledgeStateValidationError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::ResearchPlayerNotFound(player) => {
                write!(formatter, "research references non-participant {player}")
            }
            Self::WonderOwnerNotFound { wonder, player_id } => write!(
                formatter,
                "wonder {wonder:?} references non-participant {player_id}"
            ),
        }
    }
}

impl std::error::Error for KnowledgeStateValidationError {}

#[cfg(test)]
mod tests {
    use super::{PlayerResearchState, PlayerResearchStateBuildError, TechnologyId};

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
}
