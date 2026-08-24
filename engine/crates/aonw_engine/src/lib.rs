//! Pure entry point for deterministic game rules and queries.
//!
//! Authoritative transitions are added only with reviewed parity fixtures so
//! an incomplete Rust rule cannot accidentally replace Dart.

#![forbid(unsafe_code)]

mod application;
mod city;
mod combat;
mod context;
mod diplomacy_policy;
mod movement;
mod state_digest;
mod technology_unlock;
mod turn_kernel;
mod unit_action;

use aonw_domain::GameState;

pub use application::{
    AllPlayersSubmittedEvent, AutoExplorePlannedEvent, CanonicalEngineError, CanonicalQueryError,
    CityFoundedEvent, CombatEvent, CommandRejectionCode, DiplomaticScoreChangedEvent, DomainEvent,
    DomainRejection, DomainTransition, DomainTransitionParts, EventBudget, ExecutionEvidence,
    FinalizeTimedOutTurnCommand, GameQuery, KickParticipantCommand, LogisticsExecution,
    MerchantRouteAssignedEvent, MerchantTravelQueuedEvent, PlayerCommand, PlayerKickedEvent,
    PlayerTimedOutEvent, QueryResult, SystemCommand, TroopDetachedEvent, TurnCommand,
    TurnEndedEvent, TurnKernelCapabilities, TurnKernelExecution, TurnProcessor,
};
pub use city::{
    CityExpansionCandidate, CityExpansionOptions, CityExpansionOptionsQuery, CityFoundingOptions,
    CityFoundingOptionsQuery, CityWorkedHexOptions, CityWorkedHexOptionsQuery, FoundCityCommand,
    SelectCityExpansionHexCommand, ToggleWorkedHexCommand,
};
pub use combat::{
    AttackHexCommand, CombatExecution, CombatModifier, CombatModifierKind, CombatOutcome,
    CombatPreview, CombatPreviewQuery, CombatRng, CombatRoll, CombatStatTarget, CombatTarget,
    EffectiveCombatStats,
};
pub use context::{EngineContext, SystemContext};
pub use diplomacy_policy::{
    DiplomacyDisclosure, DiplomacyPolicy, DiplomacyPolicyError, DiplomacyPolicyPlayerRole,
    DiplomacyPolicyQuery,
};
pub use movement::{
    AssignMerchantTradeRouteCommand, AutoExploreOption, AutoExploreUnitCommand,
    CompiledMovementMap, CompiledMovementMapError, DetachTroopCommand, DetachmentOption,
    MerchantDestinationOption, MoveMerchantToCityCommand, MoveUnitCommand, MoveUnitError,
    MovementCost, MovementLogisticsError, MovementSearchMetrics, MovementSearchWorkspace,
    MovementVisibility, ReachableMovement, ReachableMovementQuery, ReachableMovementTile,
    TerrainMovementPlan, TerrainMovementQuery, TerrainMovementQueryError, UnitLogisticsOptions,
    UnitLogisticsOptionsQuery, UnitMovedEvent, UnitMovementExecution, maximum_movement_units,
    terrain_entry_cost,
};
pub use state_digest::StateDigest;
pub use technology_unlock::{
    TechnologyAvailability, TechnologyCombatModifier, TechnologyCombatStat,
    TechnologyEffectSummary, TechnologyQueryError, TechnologyUnlockQuery,
};
pub use unit_action::{UnitActionCommand, UnitActionError};

/// Stateless deterministic engine facade.
#[derive(Clone, Copy, Debug, Default)]
pub struct GameEngine;

impl GameEngine {
    pub(crate) fn plan_terrain_route(
        state: &GameState,
        context: EngineContext<'_>,
        query: TerrainMovementQuery<'_>,
    ) -> Result<TerrainMovementPlan, TerrainMovementQueryError> {
        movement::plan_terrain_route(state, context, query)
    }

    pub(crate) fn reachable_movement_with_workspace(
        state: &GameState,
        context: EngineContext<'_>,
        query: ReachableMovementQuery<'_>,
        workspace: &mut MovementSearchWorkspace,
    ) -> Result<ReachableMovement, TerrainMovementQueryError> {
        movement::find_reachable_tiles_with_workspace(state, context, query, workspace)
    }

    pub(crate) fn apply_move_unit(
        state: &GameState,
        context: EngineContext<'_>,
        command: MoveUnitCommand<'_>,
    ) -> Result<movement::MovementTransition, MoveUnitError> {
        movement::apply_move_unit(state, context, command)
    }
}

#[cfg(test)]
mod tests;
