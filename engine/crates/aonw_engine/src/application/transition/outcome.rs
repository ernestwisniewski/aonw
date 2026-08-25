use crate::{
    AllPlayersSubmittedEvent, AutoExplorePlannedEvent, CityFoundedEvent, CombatEvent,
    CombatExecution, DiplomaticScoreChangedEvent, LogisticsExecution, MerchantRouteAssignedEvent,
    MerchantTravelQueuedEvent, PlayerKickedEvent, PlayerTimedOutEvent, TroopDetachedEvent,
    TurnEndedEvent, TurnKernelExecution, UnitMovedEvent, UnitMovementExecution,
    WorkerAutomationExecution, WorkerCompletedJobEvent,
};

/// Ordered event emitted by an accepted transition.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DomainEvent {
    /// One city-founding job completed.
    CityFounded(CityFoundedEvent),
    /// One unit changed map position.
    UnitMoved(UnitMovedEvent),
    /// Auto-exploration selected an engine-owned target.
    AutoExplorePlanned(AutoExplorePlannedEvent),
    /// A cyclic merchant route was assigned.
    MerchantRouteAssigned(MerchantRouteAssignedEvent),
    /// Explicit merchant travel was queued.
    MerchantTravelQueued(MerchantTravelQueuedEvent),
    /// One army troop became an independent unit.
    TroopDetached(TroopDetachedEvent),
    /// One participant completed its sequential turn.
    TurnEnded(TurnEndedEvent),
    /// Every required participant became ready for simultaneous finalization.
    AllPlayersSubmitted(AllPlayersSubmittedEvent),
    /// The trusted host finalized one participant on timeout.
    PlayerTimedOut(PlayerTimedOutEvent),
    /// The trusted host removed one participant from active lifecycle.
    PlayerKicked(PlayerKickedEvent),
    /// A visible attacker engaged a visible target.
    UnitAttacked(CombatEvent),
    /// A visible attacker engaged a visible city.
    CityAttacked(CombatEvent),
    /// Exact authoritative combat resolution occurred.
    CombatResolved(CombatEvent),
    /// A known observer applied a city-attack reputation penalty.
    DiplomaticScoreChanged(DiplomaticScoreChangedEvent),
    /// A surviving unit gained combat experience.
    UnitGainedExperience(CombatEvent),
    /// A defeated unit was removed.
    UnitKilled(CombatEvent),
    /// A surviving defender changed position.
    UnitRetreated(CombatEvent),
    /// A defeated city changed owner.
    CityCaptured(CombatEvent),
    /// A defeated city was removed.
    CityDestroyed(CombatEvent),
    /// One worker job completed successfully.
    WorkerCompletedJob(WorkerCompletedJobEvent),
}

/// Exact evidence used by clients for deterministic presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ExecutionEvidence {
    /// Exact movement steps executed by the engine.
    UnitMovement(UnitMovementExecution),
    /// Exact result of one movement-logistics command.
    Logistics(LogisticsExecution),
    /// Exact capability-gated processors executed by the T1 turn kernel.
    TurnKernel(TurnKernelExecution),
    /// Exact seed, rolls, modifiers, damage and retreat result for one attack.
    Combat(CombatExecution),
    /// Exact target, bounded counters, and movement selected by worker automation.
    WorkerAutomation(WorkerAutomationExecution),
}
