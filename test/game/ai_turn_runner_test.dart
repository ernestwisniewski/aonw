import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/services/isolated_ai_plan_executor.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnRunner', () {
    tearDown(shutdownIsolatedAiPlanExecutorForTesting);

    test('dispatches planned commands and ends a hot-seat turn', () async {
      final transport = _RecordingCommandTransport();
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        delay: (_) async {},
      );

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _StaticStrategy([
          SkipUnitTurnCommand('commander_player_1'),
        ]),
        context: _context(turn: 3),
        initialState: const GameState(activePlayerId: 'player_1'),
        view: _view(),
        interCommandDelay: Duration.zero,
      );

      expect(transport.commands, [
        const SkipUnitTurnCommand('commander_player_1'),
        const EndTurnCommand('player_1'),
      ]);
      expect(transport.contexts.map((context) => context.actorPlayerId), [
        'player_1',
        'player_1',
      ]);
      expect(transport.contexts.first.combatSeedTurn, 3);
      expect(transport.contexts.first.ignoreFogOfWar, isTrue);
      expect(report.dispatchedCommands, [
        const SkipUnitTurnCommand('commander_player_1'),
      ]);
      expect(report.planningSource, AiPlanSource.fresh);
      expect(report.planningDuration.inMicroseconds, greaterThanOrEqualTo(0));
      expect(report.executionDuration.inMicroseconds, greaterThanOrEqualTo(0));
      expect(report.dispatchDuration.inMicroseconds, greaterThanOrEqualTo(0));
      expect(
        report.terminalDispatchDuration.inMicroseconds,
        greaterThanOrEqualTo(0),
      );
      expect(report.interCommandDelayDuration, Duration.zero);
      expect(
        report.totalDuration,
        greaterThanOrEqualTo(report.planningDuration),
      );
      expect(report.terminalCommand, const EndTurnCommand('player_1'));
    });

    test('pauses only after commands with UI effects', () async {
      var delayCalls = 0;
      final transport = _RecordingCommandTransport(
        uiEffectsForPlannedCommands: const [],
      );
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        delay: (_) async {
          delayCalls += 1;
        },
      );

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _StaticStrategy([
          StartCityProjectCommand('city_1', CityProjectType.wealth),
        ]),
        context: _context(turn: 3),
        initialState: const GameState(activePlayerId: 'player_1'),
        view: _view(),
        interCommandDelay: const Duration(milliseconds: 40),
      );

      expect(delayCalls, 0);
      expect(report.delayedCommandCount, 0);
      expect(report.dispatchedCommands, hasLength(1));
    });

    test('pauses after commands with UI effects', () async {
      var delayCalls = 0;
      final transport = _RecordingCommandTransport();
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        delay: (_) async {
          delayCalls += 1;
        },
      );

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _StaticStrategy([MoveUnitCommand('unit_1', 0, 1)]),
        context: _context(turn: 3),
        initialState: const GameState(activePlayerId: 'player_1'),
        view: _view(),
        interCommandDelay: const Duration(milliseconds: 40),
      );

      expect(delayCalls, 1);
      expect(report.delayedCommandCount, 1);
    });

    test('logs planned and executed AI command descriptions', () async {
      final transport = _RecordingCommandTransport();
      final logger = _RecordingGameLogger();
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        logger: logger,
        delay: (_) async {},
      );

      await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _StaticStrategy([MoveUnitCommand('unit_1', 2, 3)]),
        context: _context(turn: 3),
        initialState: const GameState(activePlayerId: 'player_1'),
        view: _view(),
        interCommandDelay: Duration.zero,
      );

      expect(
        logger.infoMessages,
        contains(
          predicate<String>((message) {
            return message.startsWith('AI: Planned 1 command(s) for player_1');
          }),
        ),
      );
      expect(
        logger.infoMessages,
        contains(
          'AI: Executing command 1/1 for player_1: '
          'move unit unit_1 to (2, 3)',
        ),
      );
      expect(
        logger.infoMessages,
        contains(
          'AI: Executing terminal command for player_1: '
          'end turn for player_1',
        ),
      );
    });

    test('owns terminal command and can submit multiplayer turns', () async {
      final transport = _RecordingCommandTransport();
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        delay: (_) async {},
      );

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_2',
        strategy: const _StaticStrategy([EndTurnCommand('player_2')]),
        context: _context(turn: 4),
        initialState: const GameState(activePlayerId: 'player_2'),
        view: _view(forPlayerId: 'player_2'),
        terminalCommand: AiTerminalCommand.submitTurn,
        interCommandDelay: Duration.zero,
      );

      expect(transport.commands, [const SubmitTurnCommand('player_2')]);
      expect(report.skippedTerminalCommands, [
        const EndTurnCommand('player_2'),
      ]);
      expect(report.terminalCommand, const SubmitTurnCommand('player_2'));
      expect(report.terminalUiEffects, contains(isA<JumpCameraEffect>()));
    });

    test('records rejected planned commands and still ends the turn', () async {
      final transport = _RecordingCommandTransport(rejectPlannedCommands: true);
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        delay: (_) async {},
      );
      const command = SkipUnitTurnCommand('commander_player_1');

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _StaticStrategy([command]),
        context: _context(turn: 5),
        initialState: const GameState(activePlayerId: 'player_1'),
        view: _view(),
        interCommandDelay: Duration.zero,
      );

      expect(report.dispatchedCommands, isEmpty);
      expect(report.rejectedCommands, [command]);
      expect(transport.commands.last, const EndTurnCommand('player_1'));
    });

    test('skips stale planned moves already at the unit position', () async {
      final transport = _RecordingCommandTransport();
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        delay: (_) async {},
      );
      const command = MoveUnitCommand('warrior_1', 0, 0);

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _StaticStrategy([command]),
        context: _context(turn: 5),
        initialState: GameState(
          activePlayerId: 'player_1',
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              name: 'Worker',
              col: 1,
              row: 0,
            ),
          ],
        ),
        view: _view(),
        interCommandDelay: Duration.zero,
      );

      expect(report.dispatchedCommands, isEmpty);
      expect(report.rejectedCommands, isEmpty);
      expect(report.skippedStaleCommands, [command]);
      expect(transport.commands, [const EndTurnCommand('player_1')]);
    });

    test(
      'dispatches occupied-target moves so the reducer can recover',
      () async {
        final transport = _RecordingCommandTransport();
        final runner = AiTurnRunner(
          dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
          delay: (_) async {},
        );
        const command = MoveUnitCommand('warrior_1', 1, 0);

        final report = await runner.run(
          saveId: 'save_1',
          playerId: 'player_1',
          strategy: const _StaticStrategy([command]),
          context: _context(turn: 5),
          initialState: GameState(
            activePlayerId: 'player_1',
            units: [
              GameUnit(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: 0,
                row: 0,
              ),
              GameUnit(
                id: 'enemy_1',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: 1,
                row: 0,
              ),
            ],
          ),
          view: _view(),
          interCommandDelay: Duration.zero,
        );

        expect(report.dispatchedCommands, [command]);
        expect(report.rejectedCommands, isEmpty);
        expect(report.skippedStaleCommands, isEmpty);
        expect(transport.commands, [command, const EndTurnCommand('player_1')]);
      },
    );

    test(
      'uses injected async plan executor before dispatching commands',
      () async {
        const command = SkipUnitTurnCommand('commander_player_1');
        var executorCalled = false;
        final transport = _RecordingCommandTransport();
        final runner = AiTurnRunner(
          dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
          delay: (_) async {},
          planExecutor:
              ({required strategy, required view, required context}) async {
                executorCalled = true;
                await Future<void>.delayed(Duration.zero);
                return AiTurnPlan(
                  commands: const [command],
                  debug: AiDebugInfo(
                    strategyId: 'async-test',
                    notes: const ['planned async'],
                  ),
                );
              },
        );

        final report = await runner.run(
          saveId: 'save_1',
          playerId: 'player_1',
          strategy: const _ThrowingStrategy(),
          context: _context(turn: 6),
          initialState: const GameState(activePlayerId: 'player_1'),
          view: _view(),
          interCommandDelay: Duration.zero,
        );

        expect(executorCalled, isTrue);
        expect(report.plannedCommands, const [command]);
        expect(report.planningSource, AiPlanSource.fresh);
        expect(report.debug?.strategyId, 'async-test');
        expect(report.debug?.notes, const ['planned async']);
        expect(transport.commands, [command, const EndTurnCommand('player_1')]);
      },
    );

    test('reports successful precomputed plan usage', () async {
      const command = SkipUnitTurnCommand('commander_player_1');
      final transport = _RecordingCommandTransport();
      final logger = _RecordingGameLogger();
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        logger: logger,
        delay: (_) async {},
        planExecutor: ({required strategy, required view, required context}) {
          throw StateError('fresh planner should not run');
        },
      );

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _ThrowingStrategy(),
        context: _context(turn: 6),
        initialState: const GameState(activePlayerId: 'player_1'),
        view: _view(),
        precomputedPlan: Future.value(AiTurnPlan(commands: const [command])),
        interCommandDelay: Duration.zero,
      );

      expect(report.planningSource, AiPlanSource.precomputed);
      expect(report.plannedCommands, const [command]);
      expect(transport.commands, [command, const EndTurnCommand('player_1')]);
      expect(
        logger.infoMessages,
        contains(
          predicate<String>((message) => message.contains('from precomputed')),
        ),
      );
      expect(
        logger.infoMessages,
        contains(
          predicate<String>(
            (message) =>
                message.contains('AI Runtime: turn player=player_1') &&
                message.contains('dispatch=') &&
                message.contains('delay=') &&
                message.contains('terminalDispatch='),
          ),
        ),
      );
    });

    test('falls back when precomputed plan fails', () async {
      const command = SkipUnitTurnCommand('commander_player_1');
      final transport = _RecordingCommandTransport();
      final logger = _RecordingGameLogger();
      final runner = AiTurnRunner(
        dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
        logger: logger,
        delay: (_) async {},
        planExecutor: ({required strategy, required view, required context}) {
          return Future.value(AiTurnPlan(commands: const [command]));
        },
      );

      final report = await runner.run(
        saveId: 'save_1',
        playerId: 'player_1',
        strategy: const _ThrowingStrategy(),
        context: _context(turn: 6),
        initialState: const GameState(activePlayerId: 'player_1'),
        view: _view(),
        precomputedPlan: Future<AiTurnPlan>.error(StateError('stale')),
        interCommandDelay: Duration.zero,
      );

      expect(report.plannedCommands, const [command]);
      expect(report.planningSource, AiPlanSource.freshAfterPrecomputeFailure);
      expect(transport.commands, [command, const EndTurnCommand('player_1')]);
      expect(
        logger.warnMessages,
        contains(
          'AI: Precomputed AI plan failed; falling back to fresh planning.',
        ),
      );
    });

    test('can execute planning through isolated executor', () async {
      const command = SkipUnitTurnCommand('commander_player_1');

      final plan = await isolatedAiPlanExecutor(
        strategy: const _StaticStrategy([command]),
        view: _view(),
        context: _context(turn: 7),
      );

      expect(plan.commands, const [command]);
    });

    test('isolated executor restarts after shutdown', () async {
      const command = SkipUnitTurnCommand('commander_player_1');

      final first = await isolatedAiPlanExecutor(
        strategy: const _StaticStrategy([command]),
        view: _view(),
        context: _context(turn: 8),
      );
      await shutdownIsolatedAiPlanExecutor();
      final second = await isolatedAiPlanExecutor(
        strategy: const _StaticStrategy([command]),
        view: _view(),
        context: _context(turn: 8),
      );

      expect(first.commands, const [command]);
      expect(second.commands, const [command]);
    });

    test('foreground executor is not blocked by precompute executor', () async {
      const command = SkipUnitTurnCommand('commander_player_1');
      final precompute = isolatedAiPlanPrecomputeExecutor(
        strategy: const _SpinningStrategy(Duration(seconds: 2)),
        view: _view(),
        context: _context(turn: 9),
      );

      await Future<void>.delayed(const Duration(milliseconds: 30));
      final foreground = await isolatedAiPlanExecutor(
        strategy: const _StaticStrategy([command]),
        view: _view(),
        context: _context(turn: 9),
      ).timeout(const Duration(milliseconds: 500));

      expect(foreground.commands, const [command]);
      await shutdownIsolatedAiPlanExecutor();
      await expectLater(precompute, throwsA(isA<StateError>()));
    });

    test(
      'isolated executor completes pending request when shut down',
      () async {
        final pending = isolatedAiPlanExecutor(
          strategy: const _SpinningStrategy(Duration(seconds: 5)),
          view: _view(),
          context: _context(turn: 9),
        );

        await Future<void>.delayed(const Duration(milliseconds: 30));
        await shutdownIsolatedAiPlanExecutor();

        await expectLater(pending, throwsA(isA<StateError>()));
      },
    );
  });
}

class _StaticStrategy implements AiStrategy {
  final List<GameCommand> commands;

  const _StaticStrategy(this.commands);

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    return AiTurnPlan(commands: commands);
  }
}

class _ThrowingStrategy implements AiStrategy {
  const _ThrowingStrategy();

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    throw StateError('Plan executor should own strategy execution.');
  }
}

class _SpinningStrategy implements AiStrategy {
  final Duration duration;

  const _SpinningStrategy(this.duration);

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsed < duration) {}
    return AiTurnPlan(commands: const []);
  }
}

class _RecordingCommandTransport implements CommandTransport {
  final bool rejectPlannedCommands;
  final List<UiEffect> uiEffectsForPlannedCommands;
  final commands = <GameCommand>[];
  final contexts = <GameCommandContext>[];

  _RecordingCommandTransport({
    this.rejectPlannedCommands = false,
    this.uiEffectsForPlannedCommands = const [JumpCameraEffect(col: 0, row: 0)],
  });

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    commands.add(command);
    contexts.add(context);
    final nextState = switch (command) {
      EndTurnCommand() ||
      SubmitTurnCommand() => currentState.copyWith(activePlayerCanAct: false),
      _ when rejectPlannedCommands => currentState,
      _ => currentState.copyWithInteraction(moveCommandActive: true),
    };
    return CommandTransportResult(
      state: nextState,
      snapshot: SaveSnapshot(save: _save),
      offset: commands.length,
      uiEffects: switch (command) {
        EndTurnCommand() ||
        SubmitTurnCommand() => const [JumpCameraEffect(col: 0, row: 0)],
        _ => uiEffectsForPlannedCommands,
      },
      events: const [TurnEndedEvent(playerId: 'player_1')],
    );
  }
}

class _RecordingGameLogger implements GameLogger {
  final infoMessages = <String>[];
  final warnMessages = <String>[];

  @override
  void info(String tag, String message) {
    infoMessages.add('$tag: $message');
  }

  @override
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    warnMessages.add('$tag: $message');
  }
}

AiContext _context({required int turn}) {
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    turn: turn,
    rng: AiRng.fromTurn(turn: turn, playerId: 'player_1', baseSeed: 7),
  );
}

GameView _view({String forPlayerId = 'player_1'}) {
  return GameView(
    forPlayerId: forPlayerId,
    turn: 1,
    ownUnits: const [],
    ownCities: const [],
    ownResearch: PlayerResearchState.empty,
    ownImprovements: const [],
    visibleEnemyUnits: const [],
    rememberedEnemyCities: const [],
    visibility: FogVisibilityQuery(
      playerId: forPlayerId,
      state: FogOfWarState.empty,
    ),
    mapData: _mapData,
    ruleset: GameRuleset.defaults,
  );
}

final _mapData = MapData(
  cols: 1,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);

final _save = GameSave(
  id: 'save_1',
  name: 'AI test',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: const {'player_1': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 4, 27),
  camera: CameraState.zero,
  players: const [Player(id: 'player_1', name: 'AI', colorValue: 0xFF2563EB)],
);
