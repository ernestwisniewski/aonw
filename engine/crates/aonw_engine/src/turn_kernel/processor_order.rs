use crate::TurnProcessor;

pub(super) const SEQUENTIAL_TURN_PROCESSORS: [TurnProcessor; 14] = [
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
];

pub(super) const SIMULTANEOUS_TURN_PROCESSORS: [TurnProcessor; 16] = [
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
];
