use aonw_domain::GameState;

use super::PlayerCommand;

/// Maximum number of authoritative events one player command may emit.
///
/// The runtime reserves this capacity before transferring ownership of the
/// canonical state to the engine. This makes event-offset overflow fail before
/// any transition can be applied.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct EventBudget {
    maximum: u64,
}

impl EventBudget {
    pub(super) const NONE: Self = Self { maximum: 0 };
    pub(super) const SINGLE: Self = Self { maximum: 1 };

    /// Constructs a bounded event allowance.
    #[must_use]
    pub const fn new(maximum: u64) -> Self {
        Self { maximum }
    }

    /// Returns the largest permitted event count.
    #[must_use]
    pub const fn maximum(self) -> u64 {
        self.maximum
    }

    /// Returns whether an actual transition stays within this command budget.
    #[must_use]
    pub const fn accepts(self, actual: u64) -> bool {
        actual <= self.maximum
    }
}

impl PlayerCommand<'_> {
    /// Returns the reviewed upper event bound for this concrete command.
    #[must_use]
    pub fn event_budget(self, state: &GameState) -> EventBudget {
        match self {
            Self::RespondDiplomaticProposal(_) => EventBudget::new(3),
            Self::AttackHex(_) => EventBudget::new(7),
            Self::AutoExploreUnit(_) => EventBudget::new(2),
            Self::SendDiplomaticProposal(_)
            | Self::StartArtifactExcavation(_)
            | Self::StoreArtifactInCity(_)
            | Self::TradeArtifact(_)
            | Self::AutomateWorker(_)
            | Self::MoveUnit(_)
            | Self::AssignMerchantTradeRoute(_)
            | Self::MoveMerchantToCity(_)
            | Self::DetachTroop(_) => EventBudget::SINGLE,
            Self::SelectTechnology(_)
            | Self::FoundCity(_)
            | Self::ToggleWorkedHex(_)
            | Self::SelectCityExpansionHex(_)
            | Self::StartBuilding(_)
            | Self::StartUnitProduction(_)
            | Self::StartCityProject(_)
            | Self::StartWonder(_)
            | Self::SetCitySpecialization(_)
            | Self::CancelUnitAction(_)
            | Self::SkipUnitTurn(_)
            | Self::FortifyUnit(_)
            | Self::SelectWorkerImprovement(_)
            | Self::ConfirmWorkerImprovement(_)
            | Self::CancelWorkerJob(_)
            | Self::AssignWorkerToHex(_)
            | Self::CancelWorkerAssignment(_)
            | Self::BuildRoad(_) => EventBudget::NONE,
            Self::RushProduction(_) => {
                let cities = u64::try_from(state.cities().len()).unwrap_or(u64::MAX);
                EventBudget::new(cities.saturating_add(2))
            }
            Self::EndTurn(_) => {
                let units = u64::try_from(state.units().len()).unwrap_or(u64::MAX);
                let cities = u64::try_from(state.cities().len()).unwrap_or(u64::MAX);
                let participants =
                    u64::try_from(state.match_lifecycle().identity().participants().len())
                        .unwrap_or(u64::MAX);
                EventBudget::new(
                    units
                        .saturating_add(cities)
                        .saturating_add(participants.saturating_mul(2))
                        .saturating_add(2),
                )
            }
            Self::SubmitTurn(_) => {
                let participants =
                    u64::try_from(state.match_lifecycle().identity().participants().len())
                        .unwrap_or(u64::MAX);
                let units = u64::try_from(state.units().len()).unwrap_or(u64::MAX);
                let cities = u64::try_from(state.cities().len()).unwrap_or(u64::MAX);
                let combat = u64::try_from(state.combat().intended_attacks().len())
                    .unwrap_or(u64::MAX)
                    .saturating_mul(7);
                EventBudget::new(
                    participants
                        .saturating_add(units)
                        .saturating_add(cities)
                        .saturating_add(participants)
                        .saturating_add(participants.saturating_mul(2))
                        .saturating_add(combat)
                        .saturating_add(1),
                )
            }
        }
    }
}
