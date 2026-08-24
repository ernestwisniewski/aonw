use aonw_content::ContentHash;
use aonw_domain::{
    DiplomacyStateBuildError, GameState, GameStateBuildError, TurnLifecycleBuildError,
};

use super::{DomainEvent, DomainTransition, ExecutionEvidence};
use crate::movement::{merge_discovered_contacts, recompute_after_move};
use crate::unit_action::{UnitActionKind, apply_unit_action};
use crate::{
    AssignMerchantTradeRouteCommand, AttackHexCommand, AutoExploreUnitCommand, DetachTroopCommand,
    EngineContext, FoundCityCommand, GameEngine, MoveMerchantToCityCommand, MoveUnitCommand,
    SelectCityExpansionHexCommand, StateDigest, ToggleWorkedHexCommand, TurnCommand,
    UnitActionCommand,
};

mod canonical_transition;

use canonical_transition::{apply_city, apply_combat};

/// Authoritative command family available to player-facing adapters.
#[derive(Clone, Copy, Debug)]
pub enum PlayerCommand<'command> {
    /// Schedules a validated city-founding job.
    FoundCity(FoundCityCommand<'command>),
    /// Toggles one manually worked controlled coordinate.
    ToggleWorkedHex(ToggleWorkedHexCommand<'command>),
    /// Selects the preferred next territory expansion.
    SelectCityExpansionHex(SelectCityExpansionHexCommand<'command>),
    /// Resolves one visible unit or city attack.
    AttackHex(AttackHexCommand<'command>),
    /// Revision-bound manual unit movement.
    MoveUnit(MoveUnitCommand<'command>),
    /// Starts or continues deterministic scout auto-exploration.
    AutoExploreUnit(AutoExploreUnitCommand<'command>),
    /// Assigns a cyclic route between owned cities.
    AssignMerchantTradeRoute(AssignMerchantTradeRouteCommand<'command>),
    /// Queues explicit merchant travel to an owned city.
    MoveMerchantToCity(MoveMerchantToCityCommand<'command>),
    /// Detaches one troop from an army into a deterministic adjacent hex.
    DetachTroop(DetachTroopCommand<'command>),
    /// Clears every cancellable order owned by one unit.
    CancelUnitAction(UnitActionCommand<'command>),
    /// Consumes one unit's remaining movement for the current turn.
    SkipUnitTurn(UnitActionCommand<'command>),
    /// Places one idle unit in persistent fortification.
    FortifyUnit(UnitActionCommand<'command>),
    /// Completes one sequential participant turn.
    EndTurn(TurnCommand<'command>),
    /// Marks one simultaneous participant ready and finalizes when scope completes.
    SubmitTurn(TurnCommand<'command>),
}

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
    const NONE: Self = Self { maximum: 0 };
    const SINGLE: Self = Self { maximum: 1 };

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
            Self::AttackHex(_) => EventBudget::new(7),
            Self::AutoExploreUnit(_) => EventBudget::new(2),
            Self::MoveUnit(_)
            | Self::AssignMerchantTradeRoute(_)
            | Self::MoveMerchantToCity(_)
            | Self::DetachTroop(_) => EventBudget::SINGLE,
            Self::FoundCity(_)
            | Self::ToggleWorkedHex(_)
            | Self::SelectCityExpansionHex(_)
            | Self::CancelUnitAction(_)
            | Self::SkipUnitTurn(_)
            | Self::FortifyUnit(_) => EventBudget::NONE,
            Self::EndTurn(_) => {
                let units = u64::try_from(state.units().len()).unwrap_or(u64::MAX);
                EventBudget::new(units.saturating_add(1))
            }
            Self::SubmitTurn(_) => {
                let participants =
                    u64::try_from(state.match_lifecycle().identity().participants().len())
                        .unwrap_or(u64::MAX);
                let units = u64::try_from(state.units().len()).unwrap_or(u64::MAX);
                let combat = u64::try_from(state.combat().intended_attacks().len())
                    .unwrap_or(u64::MAX)
                    .saturating_mul(7);
                EventBudget::new(
                    participants
                        .saturating_add(units)
                        .saturating_add(combat)
                        .saturating_add(1),
                )
            }
        }
    }
}

/// Failure indicating corrupt internal state rather than a rejected command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum CanonicalEngineError {
    /// A referenced content identity could not be computed.
    ContentHash(Box<str>),
    /// Applying the result violates an aggregate invariant.
    State(GameStateBuildError),
    /// Applying a lifecycle result violates lifecycle invariants.
    TurnLifecycle(TurnLifecycleBuildError),
    /// Applying combat diplomacy violates diplomacy invariants.
    Diplomacy(DiplomacyStateBuildError),
    /// Technology content referenced by canonical city rules is incomplete.
    Technology(crate::TechnologyQueryError),
    /// A validated city-founding job could not construct canonical state.
    CityFounding(Box<str>),
}

impl core::fmt::Display for CanonicalEngineError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::ContentHash(source) => write!(formatter, "content hash failed: {source}"),
            Self::State(source) => source.fmt(formatter),
            Self::TurnLifecycle(source) => source.fmt(formatter),
            Self::Diplomacy(source) => source.fmt(formatter),
            Self::Technology(source) => source.fmt(formatter),
            Self::CityFounding(source) => write!(formatter, "city founding failed: {source}"),
        }
    }
}

impl std::error::Error for CanonicalEngineError {}

impl GameEngine {
    /// Applies a command while reusing owned canonical-state storage.
    ///
    /// # Errors
    ///
    /// Returns an error only when canonical state or an engine-produced update
    /// violates internal invariants.
    pub fn apply_player_owned(
        state: GameState,
        context: EngineContext<'_>,
        command: PlayerCommand<'_>,
    ) -> Result<DomainTransition, CanonicalEngineError> {
        let (map_hash, ruleset_hash) = content_hashes(context)?;
        let map = context.map();
        match command {
            PlayerCommand::FoundCity(command) => {
                let mutation = crate::city::apply_found_city(&state, context, command);
                apply_city(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::ToggleWorkedHex(command) => {
                let mutation = crate::city::apply_toggle_worked_hex(&state, context, command);
                apply_city(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::SelectCityExpansionHex(command) => {
                let mutation = crate::city::apply_select_expansion(&state, context, command);
                apply_city(state, mutation, map_hash, ruleset_hash)
            }
            PlayerCommand::AttackHex(command) => {
                let update = crate::combat::apply(&state, context, command);
                apply_combat(state, update, map_hash, ruleset_hash)
            }
            PlayerCommand::MoveUnit(command) => {
                let movement =
                    GameEngine::apply_move_unit(&state, context.with_world(&state), command);
                apply_move(state, map, movement, map_hash, ruleset_hash)
            }
            PlayerCommand::AutoExploreUnit(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_auto_explore,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::AssignMerchantTradeRoute(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_assign_route,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::MoveMerchantToCity(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_move_to_city,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::DetachTroop(command) => apply_movement_logistics(
                state,
                context,
                command,
                crate::movement::apply_detach_troop,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::CancelUnitAction(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Cancel,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::SkipUnitTurn(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Skip,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::FortifyUnit(command) => apply_canonical_unit_action(
                state,
                context,
                command,
                UnitActionKind::Fortify,
                map_hash,
                ruleset_hash,
            ),
            PlayerCommand::EndTurn(command) => {
                crate::turn_kernel::apply_end_turn(state, context, command, map_hash, ruleset_hash)
            }
            PlayerCommand::SubmitTurn(command) => crate::turn_kernel::apply_submit_turn(
                state,
                context,
                command,
                map_hash,
                ruleset_hash,
            ),
        }
    }

    /// Computes canonical state identity.
    #[must_use]
    pub fn state_digest(state: &GameState) -> StateDigest {
        crate::state_digest::digest_state(state)
    }
}

fn apply_movement_logistics<Command>(
    state: GameState,
    context: EngineContext<'_>,
    command: Command,
    apply: impl FnOnce(
        &GameState,
        EngineContext<'_>,
        Command,
    ) -> Result<
        crate::movement::MovementLogisticsUpdate,
        crate::MovementLogisticsError,
    >,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let update = match apply(&state, context.with_world(&state), command) {
        Ok(update) => update,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let next_state = state
        .into_after_movement_logistics(
            update.revision,
            update.units,
            update.fog_of_war,
            update.diplomacy,
            update.interaction,
        )
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next_state,
        update.events,
        Some(ExecutionEvidence::Logistics(update.evidence)),
        map_hash,
        ruleset_hash,
    ))
}

fn content_hashes(
    context: EngineContext<'_>,
) -> Result<(ContentHash, ContentHash), CanonicalEngineError> {
    if let Some(compiled) = context.compiled_movement_map() {
        return Ok((compiled.map_hash(), compiled.ruleset_hash()));
    }
    let map_hash = context
        .map()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    let ruleset_hash = context
        .ruleset()
        .content_hash()
        .map_err(|error| CanonicalEngineError::ContentHash(error.to_string().into()))?;
    Ok((map_hash, ruleset_hash))
}

fn apply_canonical_unit_action(
    state: GameState,
    context: EngineContext<'_>,
    command: UnitActionCommand<'_>,
    kind: UnitActionKind,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let update = match apply_unit_action(&state, context, command, kind) {
        Ok(update) => update,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let next_state = state
        .into_after_unit_action(
            update.revision,
            update.unit,
            update.interaction,
            update.cancelled_excavation,
        )
        .map_err(CanonicalEngineError::State)?;
    Ok(DomainTransition::accepted(
        next_state,
        Box::new([]),
        None,
        map_hash,
        ruleset_hash,
    ))
}

fn apply_move(
    state: GameState,
    map: &aonw_content::MapDefinition,
    movement: Result<crate::movement::MovementTransition, crate::MoveUnitError>,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
) -> Result<DomainTransition, CanonicalEngineError> {
    let movement = match movement {
        Ok(value) => value,
        Err(rejection) => {
            return Ok(DomainTransition::rejected(
                state,
                rejection.code(),
                map_hash,
                ruleset_hash,
            ));
        }
    };
    let updated_unit = movement.unit().clone();
    let unit_id = updated_unit.id().clone();
    let next_revision = movement.revision();
    let mut fog = state.fog_of_war().clone();
    let mut diplomacy = state.diplomacy().clone();
    if movement.event().is_some() {
        let updated_index = state
            .units()
            .iter()
            .position(|unit| unit.id() == &unit_id)
            .expect("canonical unit exists");
        let units = state
            .units()
            .iter()
            .enumerate()
            .map(|(index, unit)| {
                if index == updated_index {
                    &updated_unit
                } else {
                    unit
                }
            })
            .collect::<Vec<_>>();
        fog = recompute_after_move(
            &fog,
            map,
            updated_unit.owner_player_id(),
            &units,
            state.cities(),
        );
        diplomacy = merge_discovered_contacts(&diplomacy, &fog, &units, state.cities());
    }
    let next_state = state
        .into_after_movement(next_revision, updated_unit, fog, diplomacy)
        .map_err(CanonicalEngineError::State)?;
    let events = movement
        .event()
        .cloned()
        .map(DomainEvent::UnitMoved)
        .into_iter()
        .collect::<Vec<_>>()
        .into_boxed_slice();
    let evidence = movement
        .execution()
        .cloned()
        .map(ExecutionEvidence::UnitMovement);
    Ok(DomainTransition::accepted(
        next_state,
        events,
        evidence,
        map_hash,
        ruleset_hash,
    ))
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        DiplomacyStateBuildError, GameState, GameStateBuildError, HexCoord, HexGridBounds,
        PlayerId, StateRevision, TurnLifecycleBuildError, UnitId, UnitOccupancyPolicy,
    };

    use super::{CanonicalEngineError, EventBudget, PlayerCommand};
    use crate::{MoveUnitCommand, UnitActionCommand};

    #[test]
    fn player_commands_publish_reviewed_event_budgets() {
        let unit_id = UnitId::new("unit-1").expect("unit id");
        let state = GameState::try_new(
            StateRevision::INITIAL,
            1,
            HexGridBounds::new(1, 1).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [],
        )
        .expect("state");

        assert_eq!(
            PlayerCommand::MoveUnit(MoveUnitCommand::new(0, &unit_id, HexCoord::new(1, 0)))
                .event_budget(&state),
            EventBudget::SINGLE
        );
        assert_eq!(
            PlayerCommand::FortifyUnit(UnitActionCommand::new(0, &unit_id)).event_budget(&state),
            EventBudget::NONE
        );
    }

    #[test]
    fn canonical_engine_error_formats_every_current_source_family() {
        let player = PlayerId::new("player").expect("player id");
        let unit = UnitId::new("unit").expect("unit id");
        for error in [
            CanonicalEngineError::ContentHash("hash".into()),
            CanonicalEngineError::State(GameStateBuildError::UnitNotFound(unit)),
            CanonicalEngineError::TurnLifecycle(TurnLifecycleBuildError::UnknownPlayer(player)),
            CanonicalEngineError::Diplomacy(DiplomacyStateBuildError::EmptyId),
        ] {
            assert!(!error.to_string().is_empty());
        }
    }
}
