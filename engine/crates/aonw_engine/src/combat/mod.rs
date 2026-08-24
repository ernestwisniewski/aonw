mod model;
mod resolution;
mod rng;
mod stats;

pub use model::{
    AttackHexCommand, CombatExecution, CombatModifier, CombatModifierKind, CombatOutcome,
    CombatPreview, CombatPreviewQuery, CombatRoll, CombatStatTarget, CombatTarget,
    EffectiveCombatStats,
};
pub use rng::CombatRng;

use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_domain::{
    CombatState, Diplomacy, DiplomacyStateBuildError, FogOfWar, FogVisibility, GameState, HexCoord,
    MovementUnits, PlayerId, StateRevision, Unit, WorldArtifact,
};

use crate::{CommandRejectionCode, DiplomacyPolicyQuery, DomainEvent, EngineContext};

use resolution::resolve;

pub(crate) struct CombatUpdate {
    pub revision: StateRevision,
    pub units: Vec<Unit>,
    pub cities: Vec<aonw_domain::City>,
    pub artifacts: Vec<WorldArtifact>,
    pub combat: CombatState,
    pub fog_of_war: FogOfWar,
    pub diplomacy: Diplomacy,
    pub events: Box<[DomainEvent]>,
    pub evidence: CombatExecution,
}

pub(crate) enum CombatApplyError {
    Rejected(CommandRejectionCode),
    Diplomacy(DiplomacyStateBuildError),
}

pub(crate) struct CombatPhaseUpdate {
    pub state: GameState,
    pub events: Box<[DomainEvent]>,
    pub executions: Box<[CombatExecution]>,
}

pub(crate) enum CombatPhaseError {
    Diplomacy(DiplomacyStateBuildError),
    State(aonw_domain::GameStateBuildError),
}

#[derive(Clone)]
struct PreparedCombat {
    attacker_index: usize,
    target: PreparedTarget,
    target_owner: PlayerId,
    preview: CombatPreview,
}

struct PreparedDefender {
    target: PreparedTarget,
    owner: PlayerId,
    identity: CombatTarget,
    stats: EffectiveCombatStats,
}

#[derive(Clone, Copy)]
enum PreparedTarget {
    Unit(usize),
    City(usize),
}

#[derive(Clone, Copy)]
enum PreparationMode {
    Direct { expected_revision: u64 },
    Intended,
}

#[derive(Clone, Copy)]
enum RevisionMode {
    Advance,
    Preserve,
}

pub(crate) fn preview(
    state: &GameState,
    context: EngineContext<'_>,
    query: CombatPreviewQuery<'_>,
) -> Result<CombatPreview, CommandRejectionCode> {
    prepare(
        state,
        context.with_world(state),
        PreparationMode::Direct {
            expected_revision: query.expected_revision,
        },
        query.attacker_unit_id,
        query.defender,
    )
    .map(|prepared| prepared.preview)
}

pub(crate) fn apply(
    state: &GameState,
    context: EngineContext<'_>,
    command: AttackHexCommand<'_>,
) -> Result<CombatUpdate, CombatApplyError> {
    let prepared = prepare(
        state,
        context.with_world(state),
        PreparationMode::Direct {
            expected_revision: command.expected_revision,
        },
        command.attacker_unit_id,
        command.defender,
    )
    .map_err(CombatApplyError::Rejected)?;
    resolve(
        state,
        context,
        prepared,
        command.city_conquest_action,
        RevisionMode::Advance,
    )
}

pub(crate) fn resolve_intended_attacks(
    state: GameState,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<CombatPhaseUpdate, CombatPhaseError> {
    let mut intended = state.combat().intended_attacks().to_vec();
    intended.sort_unstable_by(|left, right| {
        left.declared_at_tick()
            .cmp(&right.declared_at_tick())
            .then_with(|| left.attacker_unit_id().cmp(right.attacker_unit_id()))
    });
    let mut working = state;
    let mut events = Vec::new();
    let mut executions = Vec::new();
    for intent in intended {
        let actor = intent.declaring_player_id().clone();
        let context = EngineContext::canonical(&actor, map, ruleset);
        let Ok(prepared) = prepare(
            &working,
            context.with_world(&working),
            PreparationMode::Intended,
            intent.attacker_unit_id(),
            intent.defender(),
        ) else {
            continue;
        };
        let update = match resolve(
            &working,
            context,
            prepared,
            intent.city_conquest_action(),
            RevisionMode::Preserve,
        ) {
            Ok(value) => value,
            Err(CombatApplyError::Rejected(_)) => continue,
            Err(CombatApplyError::Diplomacy(error)) => {
                return Err(CombatPhaseError::Diplomacy(error));
            }
        };
        events.extend(update.events.iter().cloned());
        executions.push(update.evidence.clone());
        working = working
            .into_after_combat(aonw_domain::CombatStateUpdate {
                revision: update.revision,
                units: update.units,
                cities: update.cities,
                artifacts: update.artifacts,
                combat: update.combat,
                fog_of_war: update.fog_of_war,
                diplomacy: update.diplomacy,
            })
            .map_err(CombatPhaseError::State)?;
    }
    if !working.combat().intended_attacks().is_empty() {
        let revision = working.revision();
        let units = working.units().to_vec();
        let cities = working.cities().to_vec();
        let artifacts = working.artifacts().to_vec();
        let fog = working.fog_of_war().clone();
        let diplomacy = working.diplomacy().clone();
        working = working
            .into_after_combat(aonw_domain::CombatStateUpdate {
                revision,
                units,
                cities,
                artifacts,
                combat: CombatState::default(),
                fog_of_war: fog,
                diplomacy,
            })
            .map_err(CombatPhaseError::State)?;
    }
    Ok(CombatPhaseUpdate {
        state: working,
        events: events.into_boxed_slice(),
        executions: executions.into_boxed_slice(),
    })
}

fn prepare(
    state: &GameState,
    context: EngineContext<'_>,
    mode: PreparationMode,
    attacker_id: &aonw_domain::UnitId,
    defender_coordinate: HexCoord,
) -> Result<PreparedCombat, CommandRejectionCode> {
    if let PreparationMode::Direct { expected_revision } = mode
        && state.revision().get() != expected_revision
    {
        return Err(CommandRejectionCode::StaleRevision);
    }
    let attacker_index = state
        .units()
        .iter()
        .position(|unit| unit.id() == attacker_id)
        .ok_or(CommandRejectionCode::AttackerNotFound)?;
    let attacker = &state.units()[attacker_index];
    validate_attacker(state, context, mode, attacker)?;
    if !state.bounds().contains(defender_coordinate) {
        return Err(CommandRejectionCode::AttackTargetOutOfBounds);
    }
    let attacker_tile = context
        .map()
        .tile_at(attacker.position())
        .ok_or(CommandRejectionCode::AttackerOutOfBounds)?;
    let base_attacker = stats::for_unit(
        state,
        context.ruleset(),
        attacker,
        stats::UnitCombatSituation {
            opponent: None,
            defended_city: None,
            attacker: true,
            terrain_tags: attacker_tile.terrain_tags(),
            opponent_terrain_tags: &[],
        },
    )
    .ok_or(CommandRejectionCode::UnitDefinitionMissing)?;
    if base_attacker.attack <= 0 {
        return Err(CommandRejectionCode::AttackerCannotAttack);
    }
    if matches!(mode, PreparationMode::Direct { .. })
        && state
            .fog_of_war()
            .visibility(context.actor_player_id(), defender_coordinate)
            != FogVisibility::Visible
    {
        return Err(CommandRejectionCode::AttackTargetNotVisible);
    }
    let defender = prepare_defender(state, context, attacker, defender_coordinate)?;
    let defender_unit = match defender.target {
        PreparedTarget::Unit(index) => Some(&state.units()[index]),
        PreparedTarget::City(_) => None,
    };
    let defender_tile = context
        .map()
        .tile_at(defender_coordinate)
        .ok_or(CommandRejectionCode::AttackTargetOutOfBounds)?;
    let attacker_stats = stats::for_unit(
        state,
        context.ruleset(),
        attacker,
        stats::UnitCombatSituation {
            opponent: defender_unit,
            defended_city: None,
            attacker: true,
            terrain_tags: attacker_tile.terrain_tags(),
            opponent_terrain_tags: defender_tile.terrain_tags(),
        },
    )
    .ok_or(CommandRejectionCode::UnitDefinitionMissing)?;
    if attacker_stats.attack <= 0 {
        return Err(CommandRejectionCode::AttackerCannotAttack);
    }
    let distance =
        u32::try_from(attacker.position().distance_to(defender_coordinate)).unwrap_or(u32::MAX);
    if distance > attacker_stats.range {
        return Err(CommandRejectionCode::AttackTargetOutOfRange);
    }
    let variance = context.ruleset().combat().variance();
    let outgoing = damage_bounds(attacker_stats.attack, defender.stats.defense, variance);
    let retaliation =
        retaliation_percent(&defender.stats, distance, context.ruleset()).map(|percent| {
            scaled_bounds(
                damage_bounds(defender.stats.attack, attacker_stats.defense, variance),
                percent,
            )
        });
    Ok(PreparedCombat {
        attacker_index,
        target: defender.target,
        target_owner: defender.owner,
        preview: CombatPreview {
            attacker_unit_id: attacker.id().clone(),
            target: defender.identity,
            distance,
            attacker: attacker_stats,
            defender: defender.stats,
            outgoing_damage: outgoing,
            retaliation_damage: retaliation,
        },
    })
}

fn validate_attacker(
    state: &GameState,
    context: EngineContext<'_>,
    mode: PreparationMode,
    attacker: &Unit,
) -> Result<(), CommandRejectionCode> {
    if attacker.owner_player_id() != context.actor_player_id()
        || matches!(mode, PreparationMode::Direct { .. }) && !context.can_act()
    {
        return Err(CommandRejectionCode::AttackerNotControlled);
    }
    if matches!(mode, PreparationMode::Direct { .. })
        && attacker.activity().blocks_manual_movement()
    {
        return Err(CommandRejectionCode::AttackerUnavailable);
    }
    if matches!(mode, PreparationMode::Direct { .. })
        && attacker.movement_units() == MovementUnits::ZERO
    {
        return Err(CommandRejectionCode::AttackerExhausted);
    }
    if !state.bounds().contains(attacker.position()) {
        return Err(CommandRejectionCode::AttackerOutOfBounds);
    }
    Ok(())
}

fn prepare_defender(
    state: &GameState,
    context: EngineContext<'_>,
    attacker: &Unit,
    coordinate: HexCoord,
) -> Result<PreparedDefender, CommandRejectionCode> {
    let target = state
        .units()
        .iter()
        .enumerate()
        .find(|(_, unit)| unit.id() != attacker.id() && unit.position() == coordinate)
        .map(|(index, _)| PreparedTarget::Unit(index))
        .or_else(|| {
            state
                .cities()
                .iter()
                .enumerate()
                .find(|(_, city)| city.center() == coordinate)
                .map(|(index, _)| PreparedTarget::City(index))
        })
        .ok_or(CommandRejectionCode::AttackTargetNotFound)?;
    match target {
        PreparedTarget::Unit(index) => {
            let defender = &state.units()[index];
            if defender.owner_player_id() == attacker.owner_player_id() {
                return Err(CommandRejectionCode::AttackTargetNotEnemy);
            }
            require_attack_policy(state, attacker, defender.owner_player_id())?;
            let tile = context
                .map()
                .tile_at(defender.position())
                .ok_or(CommandRejectionCode::AttackTargetOutOfBounds)?;
            let attacker_tile = context
                .map()
                .tile_at(attacker.position())
                .ok_or(CommandRejectionCode::AttackerOutOfBounds)?;
            let defended_city = state.cities().iter().find(|city| {
                city.center() == defender.position()
                    && city.owner_player_id() == defender.owner_player_id()
            });
            let defender_stats = stats::for_unit(
                state,
                context.ruleset(),
                defender,
                stats::UnitCombatSituation {
                    opponent: Some(attacker),
                    defended_city,
                    attacker: false,
                    terrain_tags: tile.terrain_tags(),
                    opponent_terrain_tags: attacker_tile.terrain_tags(),
                },
            )
            .ok_or(CommandRejectionCode::UnitDefinitionMissing)?;
            Ok(PreparedDefender {
                target,
                owner: defender.owner_player_id().clone(),
                identity: CombatTarget::Unit(defender.id().clone()),
                stats: defender_stats,
            })
        }
        PreparedTarget::City(index) => {
            let city = &state.cities()[index];
            if city.owner_player_id() == attacker.owner_player_id() {
                return Err(CommandRejectionCode::AttackTargetNotEnemy);
            }
            require_attack_policy(state, attacker, city.owner_player_id())?;
            let city_stats = stats::for_city(state, context.ruleset(), city)
                .ok_or(CommandRejectionCode::UnitDefinitionMissing)?;
            Ok(PreparedDefender {
                target,
                owner: city.owner_player_id().clone(),
                identity: CombatTarget::City(city.id().clone()),
                stats: city_stats,
            })
        }
    }
}

fn require_attack_policy(
    state: &GameState,
    attacker: &Unit,
    defender_owner: &aonw_domain::PlayerId,
) -> Result<(), CommandRejectionCode> {
    let policy = DiplomacyPolicyQuery::between(state, attacker.owner_player_id(), defender_owner)
        .map_err(|_| CommandRejectionCode::AttackTargetProtectedByTreaty)?;
    if policy.can_attack() {
        Ok(())
    } else {
        Err(CommandRejectionCode::AttackTargetProtectedByTreaty)
    }
}

fn damage(attack: i32, defense: i32, variance: i32) -> u32 {
    if attack <= 0 {
        0
    } else {
        u32::try_from((attack - defense + variance).max(1)).unwrap_or(u32::MAX)
    }
}

fn damage_bounds(attack: i32, defense: i32, variance: u32) -> (u32, u32) {
    let variance = i32::try_from(variance).unwrap_or(i32::MAX);
    (
        damage(attack, defense, -variance),
        damage(attack, defense, variance),
    )
}

fn scaled_bounds(bounds: (u32, u32), percent: u32) -> (u32, u32) {
    (
        scale_damage(bounds.0, percent),
        scale_damage(bounds.1, percent),
    )
}

fn scale_damage(value: u32, percent: u32) -> u32 {
    if value == 0 || percent == 0 {
        0
    } else {
        value.saturating_mul(percent).saturating_div(100).max(1)
    }
}

fn retaliation_percent(
    stats: &EffectiveCombatStats,
    distance: u32,
    ruleset: &RulesetDefinition,
) -> Option<u32> {
    if stats.attack <= 0 || stats.range < distance {
        None
    } else if distance <= 1 {
        Some(100)
    } else {
        Some(ruleset.combat().ranged_retaliation_percent().min(100))
    }
}

#[cfg(test)]
mod tests;
