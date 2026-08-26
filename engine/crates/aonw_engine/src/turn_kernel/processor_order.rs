use crate::TurnProcessor;

pub(super) const SEQUENTIAL_TURN_PROCESSORS: [TurnProcessor; 15] = [
    TurnProcessor::Lifecycle,
    TurnProcessor::CityFounding,
    TurnProcessor::WorkerJobs,
    TurnProcessor::Production,
    TurnProcessor::Artifacts,
    TurnProcessor::MovementReset,
    TurnProcessor::QueuedMovement,
    TurnProcessor::TradeRoutes,
    TurnProcessor::WorkerAutomation,
    TurnProcessor::AutoExplore,
    TurnProcessor::ReversibleSkipCleanup,
    TurnProcessor::Research,
    TurnProcessor::Diplomacy,
    TurnProcessor::Agreements,
    TurnProcessor::Objectives,
];

pub(super) const SIMULTANEOUS_TURN_PROCESSORS: [TurnProcessor; 17] = [
    TurnProcessor::Submission,
    TurnProcessor::Lifecycle,
    TurnProcessor::Combat,
    TurnProcessor::CityFounding,
    TurnProcessor::WorkerJobs,
    TurnProcessor::Production,
    TurnProcessor::Artifacts,
    TurnProcessor::MovementReset,
    TurnProcessor::QueuedMovement,
    TurnProcessor::TradeRoutes,
    TurnProcessor::WorkerAutomation,
    TurnProcessor::AutoExplore,
    TurnProcessor::ReversibleSkipCleanup,
    TurnProcessor::Research,
    TurnProcessor::Diplomacy,
    TurnProcessor::Agreements,
    TurnProcessor::Objectives,
];
