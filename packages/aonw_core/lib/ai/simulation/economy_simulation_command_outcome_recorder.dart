part of 'economy_simulation.dart';

final class _EconomySimulationCommandOutcomeRecorder {
  const _EconomySimulationCommandOutcomeRecorder({
    required this.appliedCommands,
    required this.appliedCommandRecords,
    required this.rejectedCommands,
    required this.rejectedCommandRecords,
    required this.hostilityMemory,
  });

  final List<DomainCommand> appliedCommands;
  final List<EconomySimulationAppliedCommand> appliedCommandRecords;
  final List<DomainCommand> rejectedCommands;
  final List<EconomySimulationRejectedCommand> rejectedCommandRecords;
  final _EconomySimulationHostilityMemory hostilityMemory;

  DomainState record({
    required _ApplyCommandResult result,
    required DomainState currentState,
    required DomainCommand command,
    required int turn,
    required int tick,
    required String playerId,
    required List<GameEvent> turnEvents,
    required EconomySimulationCommandStats commandStats,
  }) {
    if (result.accepted) {
      turnEvents.addAll(result.events);
      hostilityMemory.record(events: result.events, turn: turn);
      appliedCommands.add(command);
      appliedCommandRecords.add(
        EconomySimulationAppliedCommand(
          turn: turn,
          tick: tick,
          playerId: playerId,
          command: command,
        ),
      );
      commandStats.addApplied(command);
      return result.state;
    }
    rejectedCommands.add(command);
    rejectedCommandRecords.add(
      EconomySimulationRejectedCommand(
        turn: turn,
        tick: tick,
        playerId: playerId,
        command: command,
        reason: result.reason,
      ),
    );
    commandStats.rejected += 1;
    return currentState;
  }
}
