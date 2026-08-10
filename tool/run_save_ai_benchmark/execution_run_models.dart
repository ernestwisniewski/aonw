part of '../run_save_ai_benchmark.dart';

class _ProfileRun {
  const _ProfileRun({
    required this.profile,
    required this.durations,
    required this.plan,
    required this.humanPlayerIds,
    required this.view,
    required this.strategicPlan,
    required this.execution,
  });

  final _ProfileSelection profile;
  final List<Duration> durations;
  final AiTurnPlan plan;
  final Set<String> humanPlayerIds;
  final GameView view;
  final StrategicPlan strategicPlan;
  final _ExecutionRun execution;

  Duration get average {
    if (durations.isEmpty) return Duration.zero;
    final totalMicros = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    );
    return Duration(microseconds: totalMicros ~/ durations.length);
  }

  Duration get min => durations.reduce((a, b) => a < b ? a : b);

  Duration get max => durations.reduce((a, b) => a > b ? a : b);

  _CommandStats get commandStats => _CommandStats.fromPlan(
    plan,
    view: view,
    humanPlayerIds: humanPlayerIds,
    strategicPlan: strategicPlan,
  );

  Map<String, Object?> toJson() {
    return {
      'profile': profile.name,
      'durationsMs': [
        for (final duration in durations) duration.inMilliseconds,
      ],
      'averageMs': average.inMilliseconds,
      'minMs': min.inMilliseconds,
      'maxMs': max.inMilliseconds,
      'commands': commandStats.toJson(),
      'plannedCommands': [
        for (final command in plan.commands.take(12)) _describeCommand(command),
      ],
      'execution': execution.toJson(),
      'debug': {
        'strategyId': plan.debug?.strategyId,
        'notes': plan.debug?.notes ?? const [],
        'metrics': plan.debug?.metrics ?? const {},
      },
    };
  }
}

class _ExecutionRun {
  const _ExecutionRun({
    required this.plannedCommandCount,
    required this.dispatchedCommands,
    required this.rejectedCommands,
    required this.rejectedReasons,
    required this.skippedTerminalCommands,
    required this.skippedStaleCommands,
    required this.terminalCommand,
    required this.terminalChangedState,
    required this.totalDuration,
    required this.dispatchDuration,
    required this.terminalDuration,
    required this.eventCounts,
    required this.humanPlayerIds,
    required this.view,
  });

  final int plannedCommandCount;
  final List<DomainCommand> dispatchedCommands;
  final List<DomainCommand> rejectedCommands;
  final List<String> rejectedReasons;
  final List<DomainCommand> skippedTerminalCommands;
  final List<DomainCommand> skippedStaleCommands;
  final DomainCommand terminalCommand;
  final bool terminalChangedState;
  final Duration totalDuration;
  final Duration dispatchDuration;
  final Duration terminalDuration;
  final _ExecutionEventCountsSnapshot eventCounts;
  final Set<String> humanPlayerIds;
  final GameView view;

  _CommandStats get appliedCommandStats => _CommandStats.fromCommands(
    dispatchedCommands,
    view: view,
    humanPlayerIds: humanPlayerIds,
  );

  Map<String, Object?> toJson() {
    return {
      'planned': plannedCommandCount,
      'applied': dispatchedCommands.length,
      'rejected': rejectedCommands.length,
      'skippedTerminal': skippedTerminalCommands.length,
      'skippedStale': skippedStaleCommands.length,
      'durationMs': totalDuration.inMilliseconds,
      'dispatchMs': dispatchDuration.inMilliseconds,
      'terminalMs': terminalDuration.inMilliseconds,
      'terminal': {
        'command': _describeCommand(terminalCommand),
        'changedState': terminalChangedState,
      },
      'appliedCommands': appliedCommandStats.toJson(),
      'events': eventCounts.toJson(),
      'rejectedCommands': [
        for (final command in rejectedCommands.take(10))
          _describeCommand(command),
      ],
      'rejectedReasons': rejectedReasons.take(10).toList(),
    };
  }
}

class _ExecutionEventCounts {
  var total = 0;
  var commandRejected = 0;
  var unitAttacks = 0;
  var combatResolved = 0;
  var unitKills = 0;
  var cityCaptures = 0;
  var cityDestroyed = 0;
  var allPlayersSubmitted = 0;

  void add(GameStateTransition transition) => addEvents(transition.events);

  void addEvents(Iterable<GameEvent> events) {
    final eventsList = events.toList();
    total += eventsList.length;
    for (final event in eventsList) {
      switch (event) {
        case CommandRejectedEvent():
          commandRejected += 1;
        case UnitAttackedEvent():
          unitAttacks += 1;
        case CombatResolvedEvent():
          combatResolved += 1;
        case UnitKilledEvent():
          unitKills += 1;
        case CityCapturedEvent():
          cityCaptures += 1;
        case CityDestroyedEvent():
          cityDestroyed += 1;
        case AllPlayersSubmittedEvent():
          allPlayersSubmitted += 1;
        default:
          break;
      }
    }
  }

  _ExecutionEventCountsSnapshot snapshot() {
    return _ExecutionEventCountsSnapshot(
      total: total,
      commandRejected: commandRejected,
      unitAttacks: unitAttacks,
      combatResolved: combatResolved,
      unitKills: unitKills,
      cityCaptures: cityCaptures,
      cityDestroyed: cityDestroyed,
      allPlayersSubmitted: allPlayersSubmitted,
    );
  }
}

class _ExecutionEventCountsSnapshot {
  const _ExecutionEventCountsSnapshot({
    required this.total,
    required this.commandRejected,
    required this.unitAttacks,
    required this.combatResolved,
    required this.unitKills,
    required this.cityCaptures,
    required this.cityDestroyed,
    required this.allPlayersSubmitted,
  });

  final int total;
  final int commandRejected;
  final int unitAttacks;
  final int combatResolved;
  final int unitKills;
  final int cityCaptures;
  final int cityDestroyed;
  final int allPlayersSubmitted;

  Map<String, Object?> toJson() {
    return {
      'total': total,
      'commandRejected': commandRejected,
      'unitAttacks': unitAttacks,
      'combatResolved': combatResolved,
      'unitKills': unitKills,
      'cityCaptures': cityCaptures,
      'cityDestroyed': cityDestroyed,
      'allPlayersSubmitted': allPlayersSubmitted,
    };
  }
}
