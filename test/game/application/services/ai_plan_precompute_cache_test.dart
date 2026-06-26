import 'package:aonw/game/application/ports/command_transport.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_plan_precompute_cache.dart';
import 'package:aonw/game/application/services/ai_turn_runner.dart';
import 'package:aonw/game/application/use_cases/dispatch_command_use_case.dart';
import 'package:aonw/game/application/use_cases/run_ai_turn_use_case.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/domain/intended_attack.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnPlanPrecomputeCache', () {
    test('key ignores turn-flow metadata but changes when world changes', () {
      const player = _aiPlayer;
      final base = _snapshot(
        save: _save(),
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2')],
      );
      final afterHumanEnd = _snapshot(
        save: _save(
          savedAt: DateTime.utc(2026, 5, 16, 12, 5),
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        ),
        runtimeState: const GameRuntimeState(submittedPlayerIds: {'player_1'}),
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2')],
      );
      final changedWorld = _snapshot(
        save: _save(),
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2', col: 1)],
      );
      final afterAttackIntent = _snapshot(
        save: _save(),
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2')],
        runtimeState: const GameRuntimeState(
          intendedAttacks: [
            IntendedAttack(
              attackerUnitId: 'warrior_player_1',
              defenderCol: 0,
              defenderRow: 0,
              declaredAtTick: 3,
              declaringPlayerId: 'player_1',
            ),
          ],
        ),
      );

      final baseKey = AiTurnPlanPrecomputeKey.fromSnapshot(
        snapshot: base,
        player: player,
      );
      final afterHumanEndKey = AiTurnPlanPrecomputeKey.fromSnapshot(
        snapshot: afterHumanEnd,
        player: player,
      );
      final changedWorldKey = AiTurnPlanPrecomputeKey.fromSnapshot(
        snapshot: changedWorld,
        player: player,
      );
      final afterAttackIntentKey = AiTurnPlanPrecomputeKey.fromSnapshot(
        snapshot: afterAttackIntent,
        player: player,
      );

      expect(afterHumanEndKey, baseKey);
      expect(changedWorldKey, isNot(baseKey));
      expect(afterAttackIntentKey, isNot(baseKey));
    });

    test('RunAiTurnUseCase consumes matching precomputed plan', () async {
      final strategy = _CountingStrategy(const [
        SkipUnitTurnCommand('commander_player_2'),
      ]);
      final cache = AiTurnPlanPrecomputeCache();
      final repository = _MutableGameRepository(
        _snapshot(
          save: _save(),
          units: [GameUnit.startingCommander(ownerPlayerId: 'player_2')],
        ),
      );
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        repository: repository,
        strategy: strategy,
        cache: cache,
        transport: transport,
      );

      final handle = await useCase.precompute(
        saveId: 'save_1',
        playerId: 'player_2',
      );
      await handle?.plan;
      repository.snapshot = _snapshot(
        save: _save(
          savedAt: DateTime.utc(2026, 5, 16, 12, 5),
          playerStates: const {
            'player_1': PlayerTurnState.finished,
            'player_2': PlayerTurnState.active,
          },
        ),
        runtimeState: const GameRuntimeState(submittedPlayerIds: {'player_1'}),
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2')],
      );
      var staleDropped = false;

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
        onStalePrecomputeDropped: () async {
          staleDropped = true;
        },
      );

      expect(report, isNotNull);
      expect(staleDropped, isFalse);
      expect(strategy.planCalls, 1);
      expect(transport.commands, const [
        SkipUnitTurnCommand('commander_player_2'),
        SubmitTurnCommand('player_2'),
      ]);
      expect(cache.length, 0);
    });

    test('RunAiTurnUseCase replans when precomputed world is stale', () async {
      final strategy = _CountingStrategy(const [
        SkipUnitTurnCommand('commander_player_2'),
      ]);
      final cache = AiTurnPlanPrecomputeCache();
      final repository = _MutableGameRepository(
        _snapshot(
          save: _save(),
          units: [GameUnit.startingCommander(ownerPlayerId: 'player_2')],
        ),
      );
      final transport = _RecordingCommandTransport();
      final useCase = _useCase(
        repository: repository,
        strategy: strategy,
        cache: cache,
        transport: transport,
      );

      final handle = await useCase.precompute(
        saveId: 'save_1',
        playerId: 'player_2',
      );
      await handle?.plan;
      repository.snapshot = _snapshot(
        save: _save(),
        units: [GameUnit.startingCommander(ownerPlayerId: 'player_2', col: 1)],
      );
      var staleDropped = false;

      final report = await useCase.execute(
        saveId: 'save_1',
        playerId: 'player_2',
        interCommandDelay: Duration.zero,
        onStalePrecomputeDropped: () async {
          staleDropped = true;
        },
      );

      expect(report, isNotNull);
      expect(staleDropped, isTrue);
      expect(strategy.planCalls, 2);
      expect(cache.length, 0);
    });
  });
}

RunAiTurnUseCase _useCase({
  required _MutableGameRepository repository,
  required AiStrategy strategy,
  required AiTurnPlanPrecomputeCache cache,
  required _RecordingCommandTransport transport,
}) {
  return RunAiTurnUseCase(
    repository: repository,
    strategyRegistry: AiStrategyRegistry({AiStrategyId.basic: strategy}),
    runner: AiTurnRunner(
      dispatchCommand: DispatchCommandUseCase(commandTransport: transport),
      delay: (_) async {},
    ),
    ruleset: GameRuleset.defaults,
    mapData: _mapData,
    precomputeCache: cache,
  );
}

class _CountingStrategy implements AiStrategy {
  final List<GameCommand> commands;
  int planCalls = 0;

  _CountingStrategy(this.commands);

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    planCalls += 1;
    return AiTurnPlan(commands: commands);
  }
}

class _RecordingCommandTransport implements CommandTransport {
  final commands = <GameCommand>[];

  @override
  Future<CommandTransportResult> dispatch({
    required String saveId,
    required GameState currentState,
    required GameCommand command,
    GameCommandContext context = const GameCommandContext(),
  }) async {
    commands.add(command);
    return CommandTransportResult(
      state: currentState.copyWith(activePlayerCanAct: false),
      snapshot: SaveSnapshot(save: _save()),
      offset: commands.length,
    );
  }
}

class _MutableGameRepository implements GameRepository {
  SaveSnapshot snapshot;

  _MutableGameRepository(this.snapshot);

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
    throw UnimplementedError();
  }
}

SaveSnapshot _snapshot({
  required GameSave save,
  List<GameUnit> units = const [],
  GameRuntimeState runtimeState = GameRuntimeState.empty,
}) {
  return SaveSnapshot(save: save, units: units, runtimeState: runtimeState);
}

GameSave _save({
  DateTime? savedAt,
  Map<String, PlayerTurnState> playerStates = const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
  },
}) {
  return GameSave(
    id: 'save_1',
    name: 'AI precompute test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 4,
    playerStates: playerStates,
    savedAt: savedAt ?? DateTime.utc(2026, 5, 16, 12),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Human', colorValue: 0xFF2563EB),
      _aiPlayer,
    ],
    gameMode: GameMode.multiplayer,
  );
}

const _aiPlayer = Player(
  id: 'player_2',
  name: 'AI',
  colorValue: 0xFFDC2626,
  kind: PlayerKind.ai,
  ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 99),
);

final _mapData = MapData(
  cols: 2,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
