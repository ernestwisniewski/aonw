use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{CityId, GameState, PlayerId};

use crate::{CanonicalEngineError, DomainEvent};

use super::city_phase::advance_city_phase;
use super::worker_phase::advance_worker_phase;

struct SettlementPhase {
    state: GameState,
    events: Vec<DomainEvent>,
    founded_city_ids: Vec<CityId>,
}

pub(super) struct TurnPreparationPhase {
    pub(super) state: GameState,
    pub(super) events: Vec<DomainEvent>,
    pub(super) research_events: Vec<DomainEvent>,
    pub(super) founded_city_ids: Vec<CityId>,
}

fn advance_settlement_phase(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<SettlementPhase, CanonicalEngineError> {
    let city = advance_city_phase(state, map, ruleset, scope)?;
    let mut events = city.events;
    let founded_city_ids = city.founded_city_ids;
    let worker = advance_worker_phase(city.state, map, ruleset, scope)?;
    events.extend(worker.events);
    Ok(SettlementPhase {
        state: worker.state,
        events,
        founded_city_ids,
    })
}

pub(super) fn advance_turn_preparation(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    scope: &[PlayerId],
) -> Result<TurnPreparationPhase, CanonicalEngineError> {
    let settlement = advance_settlement_phase(state, map, ruleset, scope)?;
    let production =
        crate::production::advance_turn_production(settlement.state, map, ruleset, scope)
            .map_err(CanonicalEngineError::Production)?;
    let artifacts = crate::artifact::advance_turn_artifacts(production.state, scope)
        .map_err(CanonicalEngineError::Artifact)?;
    let research = crate::research::advance_turn_research(
        artifacts.state,
        map,
        ruleset,
        scope,
        &production.research_project_science,
    )
    .map_err(CanonicalEngineError::Research)?;
    let mut events = settlement.events;
    events.extend(production.events);
    events.extend(artifacts.events);
    Ok(TurnPreparationPhase {
        state: research.state,
        events,
        research_events: research.events,
        founded_city_ids: settlement.founded_city_ids,
    })
}
