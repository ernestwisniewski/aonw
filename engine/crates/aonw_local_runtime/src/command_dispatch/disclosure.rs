use aonw_domain::{CityId, FogVisibility, GameState, PlayerId, UnitId};
use aonw_engine::{CombatExecution, CombatTarget, DomainEvent, ExecutionEvidence};

use crate::player_view::PlayerUnitView;

#[derive(Clone, Debug, Eq, PartialEq)]
pub(crate) struct RecipientDisclosure {
    actor: PlayerId,
    unit_ids: Box<[UnitId]>,
    city_ids: Box<[CityId]>,
    combats: Box<[(UnitId, CombatTarget)]>,
}

impl RecipientDisclosure {
    pub(crate) fn new(
        actor: PlayerId,
        visible_units: &[PlayerUnitView],
        visible_city_ids: &[CityId],
        evidence: Option<&ExecutionEvidence>,
    ) -> Self {
        let mut combats = Vec::new();
        match evidence {
            Some(ExecutionEvidence::Combat(execution)) => {
                push_visible_combat(&mut combats, execution, visible_units, visible_city_ids);
            }
            Some(ExecutionEvidence::TurnKernel(execution)) => {
                for combat in execution.combat_executions() {
                    push_visible_combat(&mut combats, combat, visible_units, visible_city_ids);
                }
            }
            Some(
                ExecutionEvidence::UnitMovement(_)
                | ExecutionEvidence::Logistics(_)
                | ExecutionEvidence::WorkerAutomation(_),
            )
            | None => {}
        }
        Self {
            actor,
            unit_ids: visible_units.iter().map(|unit| unit.id().clone()).collect(),
            city_ids: visible_city_ids.into(),
            combats: combats.into_boxed_slice(),
        }
    }

    pub(crate) fn allows_unit(&self, unit_id: &UnitId) -> bool {
        self.unit_ids.contains(unit_id)
    }

    pub(crate) fn allows_combat(&self, execution: &CombatExecution) -> bool {
        self.allows(
            &execution.preview.attacker_unit_id,
            &execution.preview.target,
        )
    }

    pub(crate) fn allows_city(&self, city_id: &CityId) -> bool {
        self.city_ids.contains(city_id)
    }

    pub(crate) fn allows_event(&self, event: &DomainEvent) -> bool {
        match event {
            DomainEvent::ArtifactExcavationStarted(value) => {
                value.owner_player_id() == &self.actor || self.allows_unit(value.unit_id())
            }
            DomainEvent::ArtifactCarried(value) => {
                value.owner_player_id() == &self.actor || self.allows_unit(value.unit_id())
            }
            DomainEvent::ArtifactStored(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::CityFounded(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::CityBuiltBuilding(value) => self.allows_city(value.city_id()),
            DomainEvent::CityProducedUnit(value) => {
                self.allows_city(value.city_id()) || self.allows_unit(value.produced_unit_id())
            }
            DomainEvent::CityBuiltWonder(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::WonderProductionRefunded(value) => {
                value.owner_player_id() == &self.actor || self.allows_city(value.city_id())
            }
            DomainEvent::TechnologyResearched(value) => value.player_id() == &self.actor,
            DomainEvent::ResearchPointsGained(value) => value.player_id() == &self.actor,
            DomainEvent::UnitAttacked(value)
            | DomainEvent::CityAttacked(value)
            | DomainEvent::CombatResolved(value)
            | DomainEvent::UnitGainedExperience(value)
            | DomainEvent::UnitKilled(value)
            | DomainEvent::UnitRetreated(value)
            | DomainEvent::CityCaptured(value)
            | DomainEvent::CityDestroyed(value) => {
                self.allows(value.attacker_unit_id(), value.target())
            }
            DomainEvent::DiplomaticScoreChanged(value) => {
                value.player_a_id() == &self.actor || value.player_b_id() == &self.actor
            }
            DomainEvent::DiplomaticProposalSent(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticProposalResponded(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticMessageSent(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticMessageResponded(value) => {
                value.from_player_id() == &self.actor || value.to_player_id() == &self.actor
            }
            DomainEvent::DiplomaticRelationChanged(value) => {
                value.player_a_id() == &self.actor || value.player_b_id() == &self.actor
            }
            DomainEvent::UnitMoved(value) => self.allows_unit(value.unit_id()),
            DomainEvent::AutoExplorePlanned(value) => self.allows_unit(value.unit_id()),
            DomainEvent::MerchantRouteAssigned(value) => self.allows_unit(value.unit_id()),
            DomainEvent::MerchantTravelQueued(value) => self.allows_unit(value.unit_id()),
            DomainEvent::TroopDetached(value) => self.allows_unit(value.source_unit_id()),
            DomainEvent::WorkerCompletedJob(value) => self.allows_unit(value.unit_id()),
            DomainEvent::TurnEnded(_)
            | DomainEvent::AllPlayersSubmitted(_)
            | DomainEvent::PlayerTimedOut(_)
            | DomainEvent::PlayerKicked(_) => true,
        }
    }

    fn allows(&self, attacker: &UnitId, target: &CombatTarget) -> bool {
        self.combats
            .iter()
            .any(|candidate| &candidate.0 == attacker && &candidate.1 == target)
    }
}

fn push_visible_combat(
    output: &mut Vec<(UnitId, CombatTarget)>,
    execution: &CombatExecution,
    visible_units: &[PlayerUnitView],
    visible_city_ids: &[CityId],
) {
    let preview = &execution.preview;
    let attacker_visible = visible_units
        .iter()
        .any(|unit| unit.id() == &preview.attacker_unit_id);
    let target_visible = match &preview.target {
        CombatTarget::Unit(id) => visible_units.iter().any(|unit| unit.id() == id),
        CombatTarget::City(id) => visible_city_ids.contains(id),
    };
    if attacker_visible && target_visible {
        output.push((preview.attacker_unit_id.clone(), preview.target.clone()));
    }
}

pub(crate) fn visible_city_ids(state: &GameState, actor: &PlayerId) -> Vec<CityId> {
    state
        .cities()
        .iter()
        .filter(|city| {
            city.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, city.center()) == FogVisibility::Visible
        })
        .map(|city| city.id().clone())
        .collect()
}
