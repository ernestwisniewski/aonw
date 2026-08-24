use aonw_content::ContentHash;
use aonw_domain::GameState;

use super::CanonicalEngineError;
use crate::application::{DomainTransition, ExecutionEvidence};

pub(super) fn apply_city(
    state: GameState,
    mutation: Result<crate::city::CityMutation, crate::city::CityRuleError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let mutation = match mutation {
        Ok(value) => value,
        Err(crate::city::CityRuleError::Rejected(code)) => {
            return Ok(DomainTransition::rejected(
                state,
                code,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(crate::city::CityRuleError::Technology(error)) => {
            return Err(CanonicalEngineError::Technology(error));
        }
    };
    let next = match mutation {
        crate::city::CityMutation::Identity => state,
        crate::city::CityMutation::Update(update) => state
            .into_after_city(
                update.revision,
                update.units,
                update.cities,
                update.interaction,
                update.fog_of_war,
                update.diplomacy,
            )
            .map_err(CanonicalEngineError::State)?,
    };
    Ok(DomainTransition::accepted(
        next,
        Box::new([]),
        None,
        map_hash,
        ruleset_hash,
    ))
}

pub(super) fn apply_combat(
    state: GameState,
    update: Result<crate::combat::CombatUpdate, crate::combat::CombatApplyError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let update = match update {
        Ok(value) => value,
        Err(crate::combat::CombatApplyError::Rejected(rejection)) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection,
                map_hash,
                ruleset_hash,
            ));
        }
        Err(crate::combat::CombatApplyError::Diplomacy(error)) => {
            return Err(CanonicalEngineError::Diplomacy(error));
        }
    };
    let next = state
        .into_after_combat(aonw_domain::CombatStateUpdate {
            revision: update.revision,
            units: update.units,
            cities: update.cities,
            artifacts: update.artifacts,
            combat: update.combat,
            fog_of_war: update.fog_of_war,
            diplomacy: update.diplomacy,
        })
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next,
        update.events,
        Some(ExecutionEvidence::Combat(update.evidence)),
        map_hash,
        ruleset_hash,
    ))
}
