part of '../run_save_ai_benchmark.dart';

class _RuntimeUseCaseSmokeRunner {
  const _RuntimeUseCaseSmokeRunner({
    required this.snapshot,
    required this.savePath,
    required this.mapData,
    required this.runtime,
  });

  final SaveSnapshot snapshot;
  final String savePath;
  final MapData mapData;
  final _BenchmarkRuntimeReport runtime;

  Future<_RuntimeUseCaseSmokeReport> run() async {
    final humanPlayerIds = {
      for (final player in snapshot.save.players)
        if (player.kind == PlayerKind.human) player.id,
    };
    final aiPlayers = [
      for (final player in snapshot.save.players)
        if (player.kind == PlayerKind.ai && player.ai != null) player,
    ];
    final repository = _RuntimeSmokeRepository(snapshot);
    final smokeRuleset = GameRuleset.defaults.copyWith(
      paceBalance: snapshot.save.matchRules.paceBalance,
    );
    final transport = _RuntimeSmokeCommandTransport(
      repository: repository,
      mapData: mapData,
      ruleset: smokeRuleset,
    );
    final runner = AiTurnRunner(
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
      delay: (_) async {},
    );
    final useCase = RunAiTurnUseCase(
      repository: repository,
      strategyRegistry: buildRuntimeAiStrategyRegistry(
        throttle: runtime.throttle,
      ),
      runner: runner,
      ruleset: smokeRuleset,
      mapData: mapData,
      strategicPlanProvider: AiStrategicPlanProvider(),
    );
    final playerReports = <_RuntimeUseCaseSmokePlayerReport>[];
    final findings = <_Finding>[];

    for (final player in aiPlayers) {
      final playerSnapshot = _unsubmitPlayer(repository.snapshot, player.id);
      repository.replace(playerSnapshot);
      final prepared = _PreparedPlayer.fromSnapshot(
        snapshot: playerSnapshot,
        player: player,
        humanPlayerIds: humanPlayerIds,
        mapData: mapData,
        includeDeadline: false,
      );
      final report = await useCase.execute(
        saveId: playerSnapshot.save.id,
        playerId: player.id,
        interCommandDelay: _singlePlayerDelay,
      );
      if (report == null) {
        findings.add(
          _Finding(
            severity: 'fail',
            message: 'Runtime use-case smoke returned null for ${player.id}.',
          ),
        );
        continue;
      }
      final commandStats = _CommandStats.fromCommands(
        report.plannedCommands,
        view: prepared.view,
        humanPlayerIds: humanPlayerIds,
        strategicPlan: prepared.strategicPlan,
      );
      final immediateHumanTargets = _immediateHumanAttackTargets(
        prepared.view,
        prepared.context,
        humanPlayerIds,
      );
      final playerReport = _RuntimeUseCaseSmokePlayerReport(
        player: player,
        report: report,
        commandStats: commandStats,
        immediateHumanAttackTargets: immediateHumanTargets,
      );
      playerReports.add(playerReport);
      findings.addAll(playerReport.findings);
    }

    if (aiPlayers.isNotEmpty && playerReports.isEmpty) {
      findings.add(
        const _Finding(
          severity: 'fail',
          message: 'Runtime use-case smoke did not execute any AI player.',
        ),
      );
    }

    final result = _RuntimeUseCaseSmokeReport(
      savePath: savePath,
      players: playerReports,
      findings: findings,
    );
    return result;
  }

  SaveSnapshot _unsubmitPlayer(SaveSnapshot source, String playerId) {
    final submitted = source.runtimeState.submittedPlayerIds;
    if (!submitted.contains(playerId)) return source;
    return source.copyWith(
      runtimeState: source.runtimeState.copyWith(
        submittedPlayerIds: {
          for (final submittedPlayerId in submitted)
            if (submittedPlayerId != playerId) submittedPlayerId,
        },
      ),
    );
  }
}

class _RuntimeUseCaseSmokeReport {
  const _RuntimeUseCaseSmokeReport({
    required this.savePath,
    required this.players,
    required this.findings,
  });

  final String savePath;
  final List<_RuntimeUseCaseSmokePlayerReport> players;
  final List<_Finding> findings;

  Duration get totalPlanning =>
      _sumDurations(players.map((player) => player.report.planningDuration));
  Duration get totalExecution =>
      _sumDurations(players.map((player) => player.report.executionDuration));
  Duration get totalEstimatedVisible =>
      _sumDurations(players.map((player) => player.estimatedVisibleDuration));
  int get totalPlannedCommands => players.fold(
    0,
    (total, player) => total + player.report.plannedCommands.length,
  );
  int get totalDispatchedCommands => players.fold(
    0,
    (total, player) => total + player.report.dispatchedCommands.length,
  );
  int get totalRejectedCommands => players.fold(
    0,
    (total, player) => total + player.report.rejectedCommands.length,
  );
  int get totalStaleCommands => players.fold(
    0,
    (total, player) => total + player.report.skippedStaleCommands.length,
  );
  int get totalDelayedCommands => players.fold(
    0,
    (total, player) => total + player.report.delayedCommandCount,
  );
  int get totalHumanAttacks => players.fold(
    0,
    (total, player) => total + player.commandStats.attackHumans,
  );
  int get totalPressureTargetAttacks => players.fold(
    0,
    (total, player) => total + player.commandStats.attackPressureTargets,
  );
  int get totalTerminalSubmitCommands =>
      players.where((player) => player.submittedAfterTerminal != null).length;
  int get totalSubmittedAfterTerminal =>
      players.where((player) => player.submittedAfterTerminal == true).length;

  Map<String, Object?> toJson() {
    return {
      'savePath': savePath,
      'players': [for (final player in players) player.toJson()],
      'summary': {
        'playerTurns': players.length,
        'totalPlanningMs': totalPlanning.inMilliseconds,
        'totalExecutionMs': totalExecution.inMilliseconds,
        'totalEstimatedVisibleMs': totalEstimatedVisible.inMilliseconds,
        'totalPlannedCommands': totalPlannedCommands,
        'totalDispatchedCommands': totalDispatchedCommands,
        'totalRejectedCommands': totalRejectedCommands,
        'totalStaleCommands': totalStaleCommands,
        'totalDelayedCommands': totalDelayedCommands,
        'totalHumanAttacks': totalHumanAttacks,
        'totalPressureTargetAttacks': totalPressureTargetAttacks,
        'totalTerminalSubmitCommands': totalTerminalSubmitCommands,
        'totalSubmittedAfterTerminal': totalSubmittedAfterTerminal,
      },
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}

class _RuntimeUseCaseSmokePlayerReport {
  const _RuntimeUseCaseSmokePlayerReport({
    required this.player,
    required this.report,
    required this.commandStats,
    required this.immediateHumanAttackTargets,
  });

  final Player player;
  final AiTurnReport report;
  final _CommandStats commandStats;
  final List<String> immediateHumanAttackTargets;

  Duration get estimatedVisibleDelayDuration =>
      _singlePlayerDelay * report.delayedCommandCount;

  Duration get estimatedVisibleDuration =>
      report.totalDuration + estimatedVisibleDelayDuration;

  bool? get submittedAfterTerminal {
    final terminal = report.terminalCommand;
    if (terminal is! SubmitTurnCommand) return null;
    return report.finalState.submittedPlayerIds.contains(terminal.playerId);
  }

  List<_Finding> get findings {
    final findings = <_Finding>[];
    if (submittedAfterTerminal == false) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Runtime use-case smoke terminal submit did not mark '
              '${player.id} as submitted.',
        ),
      );
    }
    if (report.rejectedCommands.isNotEmpty) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Runtime use-case smoke rejected ${report.rejectedCommands.length} '
              'command(s) for ${player.id}.',
        ),
      );
    }
    if (report.skippedStaleCommands.isNotEmpty) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Runtime use-case smoke skipped ${report.skippedStaleCommands.length} '
              'stale command(s) for ${player.id}.',
        ),
      );
    }
    if (immediateHumanAttackTargets.isNotEmpty &&
        commandStats.attackHumans == 0) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Runtime use-case smoke had ${immediateHumanAttackTargets.length} '
              'immediate human attack target(s) for ${player.id} but planned no '
              'human attack.',
        ),
      );
    }
    if (estimatedVisibleDuration > _comfortMaxEstimatedVisibleCycleLimit) {
      findings.add(
        _Finding(
          severity: 'fail',
          message:
              'Runtime use-case smoke for ${player.id} estimated '
              '${estimatedVisibleDuration.inMilliseconds}ms visible duration, '
              'above ${_comfortMaxEstimatedVisibleCycleLimit.inMilliseconds}ms.',
        ),
      );
    }
    return findings;
  }

  Map<String, Object?> toJson() {
    return {
      'playerId': player.id,
      'playerName': player.name,
      'planningSource': report.planningSource.name,
      'planningMs': report.planningDuration.inMilliseconds,
      'executionMs': report.executionDuration.inMilliseconds,
      'dispatchMs': report.dispatchDuration.inMilliseconds,
      'totalMs': report.totalDuration.inMilliseconds,
      'estimatedVisibleDelayMs': estimatedVisibleDelayDuration.inMilliseconds,
      'estimatedVisibleMs': estimatedVisibleDuration.inMilliseconds,
      'plannedCommands': report.plannedCommands.length,
      'dispatchedCommands': report.dispatchedCommands.length,
      'rejectedCommands': report.rejectedCommands.length,
      'staleCommands': report.skippedStaleCommands.length,
      'delayedCommands': report.delayedCommandCount,
      'terminalCommand': _describeCommand(report.terminalCommand),
      'submittedAfterTerminal': submittedAfterTerminal,
      'terminalUiEffects': report.terminalUiEffects.length,
      'commandStats': commandStats.toJson(),
      'immediateHumanAttackTargets': immediateHumanAttackTargets,
      'findings': [for (final finding in findings) finding.toJson()],
    };
  }
}

class _RuntimeSmokeRepository implements GameRepository {
  _RuntimeSmokeRepository(this.snapshot);

  SaveSnapshot snapshot;

  void replace(SaveSnapshot next) {
    snapshot = next;
  }

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) => mapDisplayName;

  @override
  Future<String> create(NewGameRequest request) async => snapshot.save.id;

  @override
  Future<void> delete(String saveId) async {}

  @override
  Future<List<GameSaveIndex>> list() async => const [];

  @override
  Future<SaveSnapshot> load(String saveId) async => snapshot;

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    snapshot = snapshot.copyWith(
      save: snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt ?? snapshot.save.savedAt,
      ),
    );
    return snapshot;
  }
}

class _RuntimeSmokeCommandTransport implements CommandTransport {
  _RuntimeSmokeCommandTransport({
    required this.repository,
    required this.mapData,
    required this.ruleset,
  });

  final _RuntimeSmokeRepository repository;
  final MapData mapData;
  final GameRuleset ruleset;
  int _offset = 0;

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    final reducer = GameStateReducer(mapData: mapData, ruleset: ruleset);
    final transition = reducer.reduce(currentState, command, context: context);
    _offset += 1;
    final nextSnapshot = SaveSnapshot.fromGameState(
      save: repository.snapshot.save,
      state: transition.state,
      eventLogOffset: repository.snapshot.eventLogOffset + _offset,
    );
    repository.replace(nextSnapshot);
    return CommandTransportResult(
      state: transition.state,
      uiEffects: transition.uiEffects,
      events: transition.events,
      snapshot: nextSnapshot,
      offset: nextSnapshot.eventLogOffset,
    );
  }
}

Duration _sumDurations(Iterable<Duration> durations) {
  var total = Duration.zero;
  for (final duration in durations) {
    total += duration;
  }
  return total;
}

String _formatNullableBool(bool? value) {
  if (value == null) return 'n/a';
  return value ? 'yes' : 'no';
}
