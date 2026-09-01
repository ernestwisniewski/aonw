use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{CityConquestAction, GameState, HexCoord, Unit, UnitKind};

use crate::{
    CommandRejectionCode, DomainEvent, EngineContext, MovementCost,
    movement::{merge_discovered_contacts, recompute_after_move},
    terrain_entry_cost,
};

use super::{
    CombatApplyError, CombatExecution, CombatOutcome, CombatRoll, CombatTarget, CombatUpdate,
    PreparedCombat, PreparedTarget, RevisionMode, damage, retaliation_percent, scale_damage,
};

mod support;

use support::observer_id;

struct RolledCombat {
    seed: u32,
    rolls: Vec<CombatRoll>,
    outcome: CombatOutcome,
}

struct WorldAfterCombat {
    units: Vec<Unit>,
    cities: Vec<aonw_domain::City>,
    artifacts: Vec<aonw_domain::WorldArtifact>,
    attacker_gains: u32,
    defender_gains: u32,
}

pub(super) fn resolve(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: PreparedCombat,
    city_action: CityConquestAction,
    revision_mode: RevisionMode,
) -> Result<CombatUpdate, CombatApplyError> {
    let rolled = roll_combat(state, context, &prepared);
    build_update(state, context, prepared, city_action, rolled, revision_mode)
}

fn roll_combat(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: &PreparedCombat,
) -> RolledCombat {
    let attacker = &state.units()[prepared.attacker_index];
    let defender_id = match &prepared.preview.target {
        CombatTarget::Unit(id) => id.as_str(),
        CombatTarget::City(id) => id.as_str(),
    };
    let mut rng = super::CombatRng::from_turn(state.turn(), attacker.id().as_str(), defender_id);
    let seed = rng.seed();
    let variance = context.ruleset().combat().variance();
    let attack_roll = rng.signed(variance);
    let outgoing_damage = damage(
        prepared.preview.attacker.attack,
        prepared.preview.defender.defense,
        attack_roll,
    );
    let mut rolls = vec![CombatRoll { value: attack_roll }];
    let (attacker_current, defender_current) = current_hit_points(state, prepared);
    let defender_max = prepared.preview.defender.hit_points;
    let mut defender_after =
        defender_current.saturating_sub(i32::try_from(outgoing_damage).unwrap_or(i32::MAX));
    let mut defender_killed = defender_after <= 0;
    let mut retreat = None;
    if let PreparedTarget::Unit(index) = prepared.target
        && defender_after > 0
        && prepared.preview.defender.attack > 0
        && prepared.preview.defender.mobility >= 1
        && i64::from(defender_after) * 100
            < i64::from(defender_max)
                * i64::from(context.ruleset().combat().retreat_threshold_percent())
    {
        retreat = retreat_destination(
            state,
            context.map(),
            context.ruleset(),
            &state.units()[index],
            attacker.position(),
        );
        if retreat.is_some() {
            defender_after = defender_after.max(1);
            defender_killed = false;
        }
    }
    let retaliation_percent = (!defender_killed && retreat.is_none())
        .then(|| {
            retaliation_percent(
                &prepared.preview.defender,
                prepared.preview.distance,
                context.ruleset(),
            )
        })
        .flatten();
    let mut retaliation_damage = 0;
    if let Some(percent) = retaliation_percent {
        let retaliation_roll = rng.signed(variance);
        rolls.push(CombatRoll {
            value: retaliation_roll,
        });
        retaliation_damage = scale_damage(
            damage(
                prepared.preview.defender.attack,
                prepared.preview.attacker.defense,
                retaliation_roll,
            ),
            percent,
        );
    }
    let attacker_after =
        attacker_current.saturating_sub(i32::try_from(retaliation_damage).unwrap_or(i32::MAX));
    let attacker_killed = attacker_after <= 0;
    RolledCombat {
        seed,
        rolls,
        outcome: CombatOutcome {
            attacker_hit_points: attacker_after,
            defender_hit_points: defender_after,
            attacker_killed,
            defender_killed,
            defender_retreat: retreat,
            outgoing_damage,
            retaliation_damage,
        },
    }
}

fn current_hit_points(state: &GameState, prepared: &PreparedCombat) -> (i32, i32) {
    let attacker_max = prepared.preview.attacker.hit_points;
    let defender_max = prepared.preview.defender.hit_points;
    let attacker = &state.units()[prepared.attacker_index];
    let attacker_current = i32::try_from(
        attacker
            .hit_points()
            .unwrap_or(attacker_max)
            .min(attacker_max),
    )
    .unwrap_or(i32::MAX);
    let defender_current = match prepared.target {
        PreparedTarget::Unit(index) => i32::try_from(
            state.units()[index]
                .hit_points()
                .unwrap_or(defender_max)
                .min(defender_max),
        )
        .unwrap_or(i32::MAX),
        PreparedTarget::City(index) => {
            let maximum = i64::from(defender_max);
            i32::try_from(
                state.cities()[index]
                    .hit_points()
                    .unwrap_or(maximum)
                    .clamp(0, maximum),
            )
            .unwrap_or(i32::MAX)
        }
    };
    (attacker_current, defender_current)
}

fn build_update(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: PreparedCombat,
    city_action: CityConquestAction,
    rolled: RolledCombat,
    revision_mode: RevisionMode,
) -> Result<CombatUpdate, CombatApplyError> {
    let world = update_world(
        state,
        context.ruleset(),
        &prepared,
        city_action,
        &rolled.outcome,
    );
    let (fog, diplomacy, score_events) =
        update_visibility_and_diplomacy(state, context, &prepared, &world.units, &world.cities)?;
    let revision = match revision_mode {
        RevisionMode::Advance => {
            state
                .revision()
                .checked_next()
                .ok_or(CombatApplyError::Rejected(
                    CommandRejectionCode::StateRevisionOverflow,
                ))?
        }
        RevisionMode::Preserve => state.revision(),
    };
    let events = combat_events(
        state,
        &prepared,
        city_action,
        &rolled.outcome,
        world.attacker_gains,
        world.defender_gains,
        score_events,
    );
    let evidence = CombatExecution {
        seed: rolled.seed,
        rolls: rolled.rolls.into_boxed_slice(),
        preview: prepared.preview,
        outcome: rolled.outcome,
    };
    Ok(CombatUpdate {
        revision,
        units: world.units,
        cities: world.cities,
        artifacts: world.artifacts,
        combat: state.combat().clone(),
        fog_of_war: fog,
        diplomacy,
        events: events.into_boxed_slice(),
        evidence,
    })
}

fn update_world(
    state: &GameState,
    ruleset: &RulesetDefinition,
    prepared: &PreparedCombat,
    city_action: CityConquestAction,
    outcome: &CombatOutcome,
) -> WorldAfterCombat {
    let attacker = &state.units()[prepared.attacker_index];
    let attacker_gains = experience_gain(
        ruleset,
        attacker.kind(),
        !outcome.attacker_killed,
        outcome.defender_killed,
    );
    let defender_gains = match prepared.target {
        PreparedTarget::Unit(index) if !outcome.defender_killed => experience_gain(
            ruleset,
            state.units()[index].kind(),
            true,
            outcome.attacker_killed,
        ),
        PreparedTarget::Unit(_) | PreparedTarget::City(_) => 0,
    };
    let mut units = Vec::with_capacity(state.units().len());
    for (index, unit) in state.units().iter().enumerate() {
        if index == prepared.attacker_index {
            if !outcome.attacker_killed {
                units.push(unit.after_combat(
                    unit.position(),
                    canonical_hp(
                        outcome.attacker_hit_points,
                        prepared.preview.attacker.hit_points,
                    ),
                    unit.experience_points().saturating_add(attacker_gains),
                    true,
                ));
            }
        } else if matches!(prepared.target, PreparedTarget::Unit(target_index) if target_index == index)
        {
            if !outcome.defender_killed {
                units.push(unit.after_combat(
                    outcome.defender_retreat.unwrap_or(unit.position()),
                    canonical_hp(
                        outcome.defender_hit_points,
                        prepared.preview.defender.hit_points,
                    ),
                    unit.experience_points().saturating_add(defender_gains),
                    outcome.defender_retreat.is_some(),
                ));
            }
        } else {
            units.push(unit.clone());
        }
    }
    let mut destroyed_city = None;
    let mut cities = Vec::with_capacity(state.cities().len());
    for (index, city) in state.cities().iter().enumerate() {
        if matches!(prepared.target, PreparedTarget::City(target_index) if target_index == index) {
            if outcome.defender_killed {
                if city_action == CityConquestAction::Capture {
                    let captured_hp = i64::from(prepared.preview.defender.hit_points.div_ceil(2));
                    cities.push(
                        city.after_combat(attacker.owner_player_id().clone(), Some(captured_hp)),
                    );
                } else {
                    destroyed_city = Some(city.id().clone());
                }
            } else {
                cities.push(city.after_combat(
                    city.owner_player_id().clone(),
                    Some(i64::from(outcome.defender_hit_points)),
                ));
            }
        } else {
            cities.push(city.clone());
        }
    }
    let defeated_unit = match prepared.target {
        PreparedTarget::Unit(index) if outcome.defender_killed => Some(state.units()[index].id()),
        _ => None,
    };
    let attacker_loss = outcome.attacker_killed.then_some(attacker.id());
    let target_coordinate = match prepared.target {
        PreparedTarget::Unit(index) => state.units()[index].position(),
        PreparedTarget::City(index) => state.cities()[index].center(),
    };
    let artifacts = state
        .artifacts()
        .iter()
        .map(|artifact| {
            let dropped = artifact.after_combat_loss(
                defeated_unit,
                destroyed_city.as_ref(),
                target_coordinate,
            );
            dropped.after_combat_loss(attacker_loss, None, attacker.position())
        })
        .collect::<Vec<_>>();
    WorldAfterCombat {
        units,
        cities,
        artifacts,
        attacker_gains,
        defender_gains,
    }
}

fn update_visibility_and_diplomacy(
    state: &GameState,
    context: EngineContext<'_>,
    prepared: &PreparedCombat,
    units: &[Unit],
    cities: &[aonw_domain::City],
) -> Result<
    (
        aonw_domain::FogOfWar,
        aonw_domain::Diplomacy,
        Vec<DomainEvent>,
    ),
    CombatApplyError,
> {
    let attacker = &state.units()[prepared.attacker_index];
    let refs = units.iter().collect::<Vec<_>>();
    let mut fog = state.fog_of_war().clone();
    for participant in state.match_lifecycle().identity().participants() {
        fog = recompute_after_move(&fog, context.map(), participant.id(), &refs, cities);
    }
    let attacked_diplomacy = match prepared.target {
        PreparedTarget::Unit(_) => state.diplomacy().after_unit_attack(
            state.match_lifecycle().identity(),
            attacker.owner_player_id(),
            &prepared.target_owner,
            state.turn(),
            attacker.id().as_str(),
        ),
        PreparedTarget::City(_) => state.diplomacy().after_city_attack(
            state.match_lifecycle().identity(),
            attacker.owner_player_id(),
            &prepared.target_owner,
            state.turn(),
            attacker.id().as_str(),
        ),
    }
    .map_err(CombatApplyError::Diplomacy)?;
    let mut warmonger_entries = attacked_diplomacy
        .score_history()
        .iter()
        .filter(|entry| {
            entry.reason() == aonw_domain::DiplomaticScoreChangeReason::WarmongerPenalty
                && !state.diplomacy().score_history().contains(entry)
        })
        .collect::<Vec<_>>();
    warmonger_entries.sort_by(|left, right| {
        observer_id(left, attacker.owner_player_id())
            .cmp(observer_id(right, attacker.owner_player_id()))
    });
    let diplomacy = merge_discovered_contacts(&attacked_diplomacy, &fog, &refs, cities);
    let score_events = warmonger_entries
        .into_iter()
        .map(|entry| {
            DomainEvent::DiplomaticScoreChanged(
                crate::application::DiplomaticScoreChangedEvent::from_entry(entry),
            )
        })
        .collect();
    Ok((fog, diplomacy, score_events))
}

fn combat_events(
    state: &GameState,
    prepared: &PreparedCombat,
    city_action: CityConquestAction,
    outcome: &CombatOutcome,
    attacker_gains: u32,
    defender_gains: u32,
    score_events: Vec<DomainEvent>,
) -> Vec<DomainEvent> {
    let attacker = &state.units()[prepared.attacker_index];
    let target = prepared.preview.target.clone();
    let event = || crate::application::CombatEvent::new(attacker.id().clone(), target.clone());
    let unit_event = |unit_id: &aonw_domain::UnitId| {
        crate::application::CombatEvent::for_unit(
            attacker.id().clone(),
            target.clone(),
            unit_id.clone(),
        )
    };
    let attack_started = match prepared.target {
        PreparedTarget::Unit(_) => DomainEvent::UnitAttacked(event()),
        PreparedTarget::City(_) => DomainEvent::CityAttacked(event()),
    };
    let mut events = vec![attack_started, DomainEvent::CombatResolved(event())];
    events.extend(score_events);
    if outcome.defender_retreat.is_some() {
        let PreparedTarget::Unit(index) = prepared.target else {
            unreachable!("only a unit can retreat")
        };
        events.push(DomainEvent::UnitRetreated(unit_event(
            state.units()[index].id(),
        )));
    }
    if outcome.attacker_killed {
        events.push(DomainEvent::UnitKilled(unit_event(attacker.id())));
    } else if attacker_gains > 0 {
        events.push(DomainEvent::UnitGainedExperience(unit_event(attacker.id())));
    }
    if let PreparedTarget::Unit(index) = prepared.target {
        let defender_id = state.units()[index].id();
        if outcome.defender_killed {
            events.push(DomainEvent::UnitKilled(unit_event(defender_id)));
        } else if defender_gains > 0 {
            events.push(DomainEvent::UnitGainedExperience(unit_event(defender_id)));
        }
    }
    if matches!(prepared.target, PreparedTarget::City(_)) && outcome.defender_killed {
        events.push(match city_action {
            CityConquestAction::Capture => DomainEvent::CityCaptured(event()),
            CityConquestAction::Destroy => DomainEvent::CityDestroyed(event()),
        });
    }
    events
}

fn retreat_destination(
    state: &GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
    defender: &Unit,
    attacker: HexCoord,
) -> Option<HexCoord> {
    let domain = ruleset
        .unit(defender.kind())?
        .capabilities()
        .movement_domain
        .domain();
    let mut candidates = state
        .bounds()
        .neighbors(defender.position())
        .filter(|coordinate| {
            map.tile_at(*coordinate).is_some_and(|tile| {
                matches!(terrain_entry_cost(tile, domain), MovementCost::Passable(_))
            }) && !state
                .units()
                .iter()
                .any(|unit| unit.id() != defender.id() && unit.position() == *coordinate)
        })
        .collect::<Vec<_>>();
    candidates.sort_unstable_by(|left, right| {
        right
            .distance_to(attacker)
            .cmp(&left.distance_to(attacker))
            .then_with(|| left.cmp(right))
    });
    candidates.into_iter().next()
}

fn experience_gain(
    ruleset: &RulesetDefinition,
    kind: UnitKind,
    survived: bool,
    defeated: bool,
) -> u32 {
    if !ruleset
        .unit(kind)
        .is_some_and(|definition| definition.capabilities().gains_experience())
    {
        return 0;
    }
    u32::from(survived) + if defeated { 2 } else { 0 }
}

fn canonical_hp(value: i32, maximum: u32) -> Option<u32> {
    let value = u32::try_from(value.max(1)).unwrap_or(u32::MAX).min(maximum);
    (value < maximum).then_some(value)
}

#[cfg(test)]
mod tests;
