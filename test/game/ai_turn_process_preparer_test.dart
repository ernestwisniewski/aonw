import 'package:aonw/api/session/network_session.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_logger.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_runtime_strategy_registry.dart';
import 'package:aonw/game/application/services/ai_runtime_throttler.dart';
import 'package:aonw/game/application/services/ai_strategic_plan_provider.dart';
import 'package:aonw/game/application/services/game_session.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/services/ai_turn_process_preparer.dart';
import 'package:aonw/game/presentation/widgets/ai/game_ai_turn_auto_pilot_rules.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnProcessPreparer', () {
    test('builds a use case only for the current local AI session', () async {
      final mapData = _mapData();
      final save = _save();
      final repository = _FakeGameRepository(SaveSnapshot(save: save));
      final precomputeCache = AiTurnPlanPrecomputeCache();
      final strategicPlanProvider = AiStrategicPlanProvider();
      var strategyCalls = 0;

      final preparer = _preparer(
        repository: repository,
        sessionReader: () => _session(mapData: mapData),
        precomputeCache: precomputeCache,
        strategicPlanProvider: strategicPlanProvider,
        strategyRegistryFor:
            ({
              required playerId,
              required save,
              required gameState,
              required networkSession,
            }) {
              strategyCalls += 1;
              expect(playerId, 'ai_1');
              expect(gameState.activePlayerId, 'ai_1');
              expect(networkSession, isNull);
              return _strategyRegistry(
                playerId: playerId,
                save: save,
                gameState: gameState,
                networkSession: networkSession,
              );
            },
      );

      final process = await preparer.prepare(
        saveId: save.id,
        playerId: 'ai_1',
        scheduledTurn: save.turn,
      );

      expect(process, isNotNull);
      expect(process!.repository, same(repository));
      expect(process.snapshot.save, same(save));
      expect(process.saveId, save.id);
      expect(process.playerId, 'ai_1');
      expect(process.useCase.repository, same(repository));
      expect(process.useCase.mapData, same(mapData));
      expect(process.useCase.precomputeCache, same(precomputeCache));
      expect(
        process.useCase.strategicPlanProvider,
        same(strategicPlanProvider),
      );
      expect(repository.loadCount, 1);
      expect(strategyCalls, 1);
    });

    test('reuses the prepared snapshot for precompute and execution', () async {
      final repository = _FakeGameRepository(SaveSnapshot(save: _save()));
      final precomputeCache = AiTurnPlanPrecomputeCache();

      final preparer = _preparer(
        repository: repository,
        sessionReader: () => _session(),
        precomputeCache: precomputeCache,
      );

      final process = await preparer.prepare(
        saveId: 'save_1',
        playerId: 'ai_1',
      );
      expect(repository.loadCount, 1);

      final handle = await process!.precompute();
      await handle?.plan;
      expect(repository.loadCount, 1);

      final report = await process.execute(interCommandDelay: Duration.zero);

      expect(report, isNotNull);
      expect(repository.loadCount, 1);
    });

    test(
      'skips a scheduled AI turn when the loaded snapshot moved on',
      () async {
        final repository = _FakeGameRepository(
          SaveSnapshot(save: _save(turn: 2)),
        );
        final logger = _RecordingGameLogger();
        var strategyCalls = 0;

        final preparer = _preparer(
          repository: repository,
          logger: logger,
          sessionReader: () => _session(),
          strategyRegistryFor:
              ({
                required playerId,
                required save,
                required gameState,
                required networkSession,
              }) {
                strategyCalls += 1;
                return _strategyRegistry(
                  playerId: playerId,
                  save: save,
                  gameState: gameState,
                  networkSession: networkSession,
                );
              },
        );

        final process = await preparer.prepare(
          saveId: 'save_1',
          playerId: 'ai_1',
          scheduledTurn: 1,
        );

        expect(process, isNull);
        expect(repository.loadCount, 1);
        expect(strategyCalls, 0);
        expect(
          logger.infoMessages,
          contains(
            contains('scheduled AI turn skipped because snapshot changed'),
          ),
        );
      },
    );

    test('rechecks the active session after loading the snapshot', () async {
      GameSession? session = _session();
      final repository = _FakeGameRepository(SaveSnapshot(save: _save()))
        ..onLoad = () {
          session = null;
        };
      var strategyCalls = 0;

      final preparer = _preparer(
        repository: repository,
        sessionReader: () => session,
        strategyRegistryFor:
            ({
              required playerId,
              required save,
              required gameState,
              required networkSession,
            }) {
              strategyCalls += 1;
              return _strategyRegistry(
                playerId: playerId,
                save: save,
                gameState: gameState,
                networkSession: networkSession,
              );
            },
      );

      final process = await preparer.prepare(
        saveId: 'save_1',
        playerId: 'ai_1',
      );

      expect(process, isNull);
      expect(repository.loadCount, 1);
      expect(strategyCalls, 0);
    });

    test('does not load the save when local AI cannot own the mode', () async {
      final repository = _FakeGameRepository(SaveSnapshot(save: _save()));

      final preparer = _preparer(
        repository: repository,
        sessionReader: () => _session(),
        localAiRuntimeEnabled: false,
      );

      final process = await preparer.prepare(
        saveId: 'save_1',
        playerId: 'ai_1',
      );

      expect(process, isNull);
      expect(repository.loadCount, 0);
    });
  });
}

AiTurnProcessPreparer _preparer({
  required _FakeGameRepository repository,
  required AiTurnSessionReader sessionReader,
  _RecordingGameLogger? logger,
  bool localAiRuntimeEnabled = true,
  AiTurnPlanPrecomputeCache? precomputeCache,
  AiStrategicPlanProvider? strategicPlanProvider,
  AiTurnStrategyRegistryFactory strategyRegistryFor = _strategyRegistry,
}) {
  return AiTurnProcessPreparer(
    repository: repository,
    logger: logger ?? _RecordingGameLogger(),
    dispatch:
        ({
          required saveId,
          required GameState currentState,
          required command,
          required context,
        }) async {
          return DispatchCommandResult(state: currentState);
        },
    planExecutor: ({required strategy, required view, required context}) async {
      return AiTurnPlan.empty;
    },
    sessionReader: sessionReader,
    networkSessionReader: () => null,
    canContinue: () => true,
    shouldRunLocalAiForMode:
        ({required gameMode, required saveId, required networkSession}) {
          return localAiRuntimeEnabled;
        },
    canRunScheduledAiTurn: GameAiTurnAutoPilotRules.canRunScheduledAiTurn,
    strategyRegistryFor: strategyRegistryFor,
    rulesetReader: () => GameRuleset.defaults,
    eventLogReader: () => _FakeEventLog(),
    precomputeCache: precomputeCache ?? AiTurnPlanPrecomputeCache(),
    strategicPlanProvider: strategicPlanProvider ?? AiStrategicPlanProvider(),
  );
}

AiStrategyRegistry _strategyRegistry({
  required String playerId,
  required GameSave save,
  required GameState gameState,
  required NetworkSession? networkSession,
}) {
  return buildRuntimeAiStrategyRegistry(
    throttle: AiRuntimeThrottler().snapshot,
  );
}

GameSession _session({
  String saveId = 'save_1',
  GameMode gameMode = GameMode.hotSeat,
  MapData? mapData,
}) {
  return GameSession(
    mapData: mapData ?? _mapData(),
    viewMode: MapViewMode.tile,
    saveId: saveId,
    gameMode: gameMode,
  );
}

GameSave _save({int turn = 1}) {
  return GameSave(
    id: 'save_1',
    name: 'AI process preparer test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: const {
      'human': PlayerTurnState.finished,
      'ai_1': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 6, 2),
    camera: CameraState.zero,
    players: const [
      Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB),
      Player(
        id: 'ai_1',
        name: 'AI',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(
          strategyId: AiStrategyId.basic,
          difficulty: AiDifficulty.normal,
          persona: AiPersona.balanced,
          seed: 1001,
        ),
      ),
    ],
  );
}

MapData _mapData() {
  return MapData(
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
}

final class _FakeGameRepository implements GameRepository {
  SaveSnapshot snapshot;
  void Function()? onLoad;
  int loadCount = 0;

  _FakeGameRepository(this.snapshot);

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) {
    return 'Save';
  }

  @override
  Future<String> create(NewGameRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<List<GameSaveIndex>> list() {
    throw UnimplementedError();
  }

  @override
  Future<SaveSnapshot> load(String saveId) async {
    loadCount += 1;
    onLoad?.call();
    return snapshot;
  }

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> delete(String saveId) {
    throw UnimplementedError();
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) {
    throw UnimplementedError();
  }
}

final class _FakeEventLog implements EventLog {
  @override
  Future<void> append(String saveId, LoggedCommand command) async {}

  @override
  Future<int> latestOffset(String saveId) async => 0;

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) {
    return const Stream.empty();
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) {
    return const Stream.empty();
  }
}

final class _RecordingGameLogger implements GameLogger {
  final List<String> infoMessages = [];

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
  ]) {}
}
