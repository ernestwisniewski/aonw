import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_runtime_mode.dart';
import 'package:aonw/game/application/services/ai_runtime_strategy_registry.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/application/use_cases/run_ai_turn_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement/unit_movement_visibility_rules.dart';
import 'package:aonw/game/domain/reducer/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/map_definition.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/turn.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

part 'run_save_ai_benchmark/report_models.dart';
part 'run_save_ai_benchmark/synthetic_suite.dart';
part 'run_save_ai_benchmark/runtime_smoke.dart';
part 'run_save_ai_benchmark/multi_turn_replay.dart';
part 'run_save_ai_benchmark/multi_turn_replay_report.dart';
part 'run_save_ai_benchmark/multi_turn_replay_cycle_models.dart';
part 'run_save_ai_benchmark/multi_turn_replay_player_report.dart';
part 'run_save_ai_benchmark/multi_turn_replay_execution_models.dart';
part 'run_save_ai_benchmark/execution_models.dart';
part 'run_save_ai_benchmark/cli_helpers.dart';
part 'run_save_ai_benchmark/benchmark_synthetic_helpers.dart';
part 'run_save_ai_benchmark/benchmark_target_helpers.dart';
part 'run_save_ai_benchmark/benchmark_target_pressure_helpers.dart';
part 'run_save_ai_benchmark/benchmark_command_diagnostics.dart';
part 'run_save_ai_benchmark/benchmark_format_helpers.dart';
part 'run_save_ai_benchmark/cli_argument_helpers.dart';

const _defaultMinTurn = 100;
const _singlePlayerDelay = Duration(milliseconds: 40);
const _comfortP95EstimatedVisibleCycleLimit = Duration(seconds: 2);
const _comfortMaxEstimatedVisibleCycleLimit = Duration(milliseconds: 3000);
const _comfortP95PlanningLimit = Duration(milliseconds: 300);

void main(List<String> args) async {
  if (_hasFlag(args, '--help') || _hasFlag(args, '-h')) {
    stdout.write(_usage);
    return;
  }

  try {
    final options = _Options.fromArgs(args);
    final saveFile = await _resolveSaveFile(options);
    final snapshot = await _loadSnapshot(saveFile);
    final mapData = await _loadMap(snapshot, options.mapPath);
    final report = await _SaveAiBenchmark(
      snapshot: snapshot,
      savePath: saveFile.path,
      mapData: mapData,
      profiles: options.profiles,
      repeats: options.repeats,
      includeDeadline: options.includeDeadline,
      strategyOverride: options.strategyOverride,
      multiTurnCycles: options.multiTurnCycles,
    ).run();

    final jsonReport = report.toJson();
    if (options.jsonOut != null) {
      final file = File(options.jsonOut!);
      await file.parent.create(recursive: true);
      await file.writeAsString(
        '${const JsonEncoder.withIndent('  ').convert(jsonReport)}\n',
      );
      stdout.writeln('Wrote ${file.path}');
    }
    if (options.markdownOut != null) {
      final file = File(options.markdownOut!);
      await file.parent.create(recursive: true);
      await file.writeAsString(report.toMarkdown());
      stdout.writeln('Wrote ${file.path}');
    }
    if (options.jsonOut == null && options.markdownOut == null) {
      stdout.write(report.toMarkdown());
    }
    if (options.failOnFinding && report.hasFailingFindings) {
      exitCode = 1;
    }
  } on _UsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln()
      ..write(_usage);
    exitCode = 64;
  }
}

class _SaveAiBenchmark {
  const _SaveAiBenchmark({
    required this.snapshot,
    required this.savePath,
    required this.mapData,
    required this.profiles,
    required this.repeats,
    required this.includeDeadline,
    required this.strategyOverride,
    required this.multiTurnCycles,
  });

  final SaveSnapshot snapshot;
  final String savePath;
  final MapData mapData;
  final List<_ProfileSelection> profiles;
  final int repeats;
  final bool includeDeadline;
  final AiStrategyId? strategyOverride;
  final int multiTurnCycles;

  Future<_BenchmarkReport> run() async {
    final runtime = _BenchmarkRuntimeReport.fromSnapshot(snapshot);
    final playerResults = <_PlayerBenchmarkResult>[];
    final humanPlayerIds = {
      for (final player in snapshot.save.players)
        if (player.kind == PlayerKind.human) player.id,
    };
    for (final player in snapshot.save.players) {
      if (player.kind != PlayerKind.ai || player.ai == null) continue;
      final prepared = _PreparedPlayer.fromSnapshot(
        snapshot: snapshot,
        player: player,
        humanPlayerIds: humanPlayerIds,
        mapData: mapData,
        includeDeadline: includeDeadline,
      );
      playerResults.add(
        prepared.run(
          profiles: profiles,
          repeats: repeats,
          strategyOverride: strategyOverride,
        ),
      );
    }
    final multiTurnReplay = multiTurnCycles <= 0
        ? null
        : _MultiTurnReplayRunner(
            snapshot: snapshot,
            savePath: savePath,
            mapData: mapData,
            cycles: multiTurnCycles,
            profiles: profiles,
            includeDeadline: includeDeadline,
            strategyOverride: strategyOverride,
          ).run();
    final syntheticScenarios = _SyntheticBenchmarkSuite(
      includeDeadline: includeDeadline,
      strategyOverride: strategyOverride,
    ).run();
    final runtimeSmoke = await _RuntimeUseCaseSmokeRunner(
      snapshot: snapshot,
      savePath: savePath,
      mapData: mapData,
      runtime: runtime,
    ).run();
    return _BenchmarkReport(
      savePath: savePath,
      snapshot: snapshot,
      mapData: mapData,
      runtime: runtime,
      playerResults: playerResults,
      repeats: repeats,
      profiles: profiles,
      includeDeadline: includeDeadline,
      strategyOverride: strategyOverride,
      multiTurnReplay: multiTurnReplay,
      syntheticScenarios: syntheticScenarios,
      runtimeSmoke: runtimeSmoke,
    );
  }
}

class _PreparedPlayer {
  const _PreparedPlayer({
    required this.snapshot,
    required this.player,
    required this.ai,
    required this.humanPlayerIds,
    required this.view,
    required this.context,
    required this.assessment,
    required this.strategicPlan,
    required this.mapData,
  });

  final SaveSnapshot snapshot;
  final Player player;
  final AiPlayer ai;
  final Set<String> humanPlayerIds;
  final GameView view;
  final AiContext context;
  final AiEmpireAssessment assessment;
  final StrategicPlan strategicPlan;
  final MapData mapData;

  factory _PreparedPlayer.fromSnapshot({
    required SaveSnapshot snapshot,
    required Player player,
    required Set<String> humanPlayerIds,
    required MapData mapData,
    required bool includeDeadline,
  }) {
    final ai = player.ai!;
    const civRegistry = CivilizationProfileRegistry();
    final civProfile = civRegistry.profileFor(player.country);
    final ruleset = GameRuleset.defaults.copyWith(
      paceBalance: snapshot.save.matchRules.paceBalance,
    );
    final pressureTargetPlayerIds = _pressureTargetPlayerIds(
      snapshot.save.players,
      playerId: player.id,
      diplomacy: snapshot.runtimeState.diplomacy,
    );
    final pendingCityAttackThreats = _pendingCityAttackThreats(
      snapshot: snapshot,
      playerId: player.id,
    );
    final view = GameView.fromPersistentState(
      snapshot.persistentState,
      forPlayerId: player.id,
      turn: snapshot.save.turn,
      mapData: mapData,
      ruleset: ruleset,
      activeHostilePlayerIds: _pendingHostilePlayerIds(
        snapshot: snapshot,
        playerId: player.id,
      ),
      pressureTargetPlayerIds: pressureTargetPlayerIds,
      defaultNeutralPlayerIds: _defaultNeutralPlayerIds(
        snapshot.save.players,
        playerId: player.id,
      ),
      pendingCityAttackThreats: pendingCityAttackThreats,
      forcedVisibleEnemyUnitIds: [
        for (final threat in pendingCityAttackThreats) threat.attackerUnitId,
      ],
      ignoreFogOfWar: true,
    );
    var context = AiContext(
      ruleset: ruleset,
      mapData: mapData,
      turn: snapshot.save.turn,
      rng: AiRng.fromTurn(
        turn: snapshot.save.turn,
        playerId: player.id,
        baseSeed: ai.seed,
      ),
      persona: ai.personaForProfile(civProfile),
      difficulty: ai.difficulty,
      civProfile: civProfile,
      deadline: includeDeadline
          ? _deadlineFor(snapshot.save, snapshot.runtimeState.turnStartedAt)
          : null,
    );
    final assessment = AiEmpireAssessment.fromView(view, context);
    final strategicPlan = const StrategicPlanner().build(
      view: view,
      context: context,
      assessment: assessment,
    );
    context = context.copyWith(strategicPlan: strategicPlan);

    return _PreparedPlayer(
      snapshot: snapshot,
      player: player,
      ai: ai,
      humanPlayerIds: humanPlayerIds,
      view: view,
      context: context,
      assessment: assessment,
      strategicPlan: strategicPlan,
      mapData: mapData,
    );
  }

  _PlayerBenchmarkResult run({
    required List<_ProfileSelection> profiles,
    required int repeats,
    required AiStrategyId? strategyOverride,
  }) {
    final profileRuns = <_ProfileRun>[];
    final strategyId = strategyOverride ?? ai.strategyId;
    for (final profile in profiles) {
      final durations = <Duration>[];
      AiTurnPlan? lastPlan;
      for (var index = 0; index < repeats; index++) {
        final strategy = _strategyFor(strategyId, profile);
        final stopwatch = Stopwatch()..start();
        final plan = strategy.plan(view, context);
        stopwatch.stop();
        durations.add(stopwatch.elapsed);
        lastPlan = plan;
      }
      final plan = lastPlan ?? AiTurnPlan.empty;
      profileRuns.add(
        _ProfileRun(
          profile: profile,
          durations: durations,
          plan: plan,
          humanPlayerIds: humanPlayerIds,
          view: view,
          strategicPlan: strategicPlan,
          execution: _executePlan(plan),
        ),
      );
    }
    return _PlayerBenchmarkResult(
      player: player,
      ai: ai,
      effectiveStrategyId: strategyId,
      view: view,
      context: context,
      assessment: assessment,
      strategicPlan: strategicPlan,
      profileRuns: profileRuns,
      humanPlayerIds: humanPlayerIds,
    );
  }

  _ExecutionRun _executePlan(AiTurnPlan plan) {
    final reducer = GameStateReducer(
      mapData: mapData,
      ruleset: context.ruleset,
    );
    var state = _executionInitialState();
    final dispatched = <GameCommand>[];
    final rejected = <GameCommand>[];
    final rejectedReasons = <String>[];
    final skippedTerminals = <GameCommand>[];
    final skippedStale = <GameCommand>[];
    final eventCounts = _ExecutionEventCounts();
    var dispatchDuration = Duration.zero;

    final totalStopwatch = Stopwatch()..start();
    for (final command in plan.commands) {
      if (_isTerminal(command)) {
        skippedTerminals.add(command);
        continue;
      }
      if (command case final MoveUnitCommand moveCommand
          when _isUnitAlreadyAtTarget(moveCommand, state)) {
        skippedStale.add(command);
        continue;
      }

      final dispatchStopwatch = Stopwatch()..start();
      final transition = reducer.reduce(
        state,
        command,
        context: _commandContext(playerId: player.id, aiContext: context),
      );
      dispatchStopwatch.stop();
      dispatchDuration += dispatchStopwatch.elapsed;
      eventCounts.add(transition);

      if (transition.state == state) {
        if (command is MoveUnitCommand &&
            _rejectionReasons(transition).isEmpty &&
            _staleMoveDiagnostic(command, state) != null) {
          skippedStale.add(command);
          continue;
        }
        rejected.add(command);
        rejectedReasons.addAll(_rejectionReasons(transition));
        continue;
      }

      state = transition.state;
      dispatched.add(command);
    }

    final terminalCommand = _terminalFor(snapshot.save.gameMode, player.id);
    final terminalStopwatch = Stopwatch()..start();
    final terminalTransition = reducer.reduce(
      state,
      terminalCommand,
      context: _commandContext(playerId: player.id, aiContext: context),
    );
    terminalStopwatch.stop();
    dispatchDuration += terminalStopwatch.elapsed;
    eventCounts.add(terminalTransition);
    final terminalChangedState = terminalTransition.state != state;
    totalStopwatch.stop();

    return _ExecutionRun(
      plannedCommandCount: plan.commands.length,
      dispatchedCommands: dispatched,
      rejectedCommands: rejected,
      rejectedReasons: rejectedReasons,
      skippedTerminalCommands: skippedTerminals,
      skippedStaleCommands: skippedStale,
      terminalCommand: terminalCommand,
      terminalChangedState: terminalChangedState,
      totalDuration: totalStopwatch.elapsed,
      dispatchDuration: dispatchDuration,
      terminalDuration: terminalStopwatch.elapsed,
      eventCounts: eventCounts.snapshot(),
      humanPlayerIds: humanPlayerIds,
      view: view,
    );
  }

  GameState _executionInitialState() {
    final state = snapshot.toGameState(
      activePlayerId: player.id,
      activePlayerCanAct: true,
    );
    if (snapshot.save.gameMode != GameMode.multiplayer ||
        !state.submittedPlayerIds.contains(player.id)) {
      return state;
    }
    return state.copyWith(
      submittedPlayerIds: {
        for (final submittedPlayerId in state.submittedPlayerIds)
          if (submittedPlayerId != player.id) submittedPlayerId,
      },
    );
  }

  AiStrategy _strategyFor(AiStrategyId strategyId, _ProfileSelection profile) {
    return switch (strategyId) {
      AiStrategyId.random => const RandomStrategy(),
      AiStrategyId.basic => const BasicStrategy(),
      AiStrategyId.mcts => MctsStrategy(runtimeProfile: profile.resolve(view)),
      AiStrategyId.scripted || AiStrategyId.utility => const BasicStrategy(),
    };
  }
}
