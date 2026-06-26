import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_turn_preparation_builder.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiTurnPreparationBuilder', () {
    test('builds a prepared turn without running the AI turn', () async {
      final strategy = _CapturingStrategy(
        commands: const [SkipUnitTurnCommand('commander_player_2')],
      );
      final snapshot = SaveSnapshot(
        save: _save(gameMode: GameMode.hotSeat),
        units: [
          GameUnit.startingCommander(ownerPlayerId: 'player_1', col: 0, row: 0),
          GameUnit.startingCommander(
            ownerPlayerId: 'player_2',
            col: 1,
            row: 0,
          ).copyWith(movementPoints: 0),
        ],
      );
      final builder = AiTurnPreparationBuilder(
        repository: _MemoryGameRepository(snapshot),
        strategyRegistry: AiStrategyRegistry({AiStrategyId.random: strategy}),
        ruleset: GameRuleset.defaults,
        mapData: _mapData,
      );

      final prepared = await builder.prepare(
        saveId: 'save_1',
        playerId: 'player_2',
      );

      expect(prepared, isNotNull);
      expect(prepared?.view.forPlayerId, 'player_2');
      expect(prepared?.context.persona, AiPersona.aggressive);
      expect(prepared?.view.pressureTargetPlayerIds, {'player_1'});

      final plan = prepared!.strategy.plan(prepared.view, prepared.context);

      expect(strategy.lastView, same(prepared.view));
      expect(plan.commands, [
        const ResetUnitMovementCommand(playerId: 'player_2'),
        const SkipUnitTurnCommand('commander_player_2'),
      ]);
    });
  });
}

class _CapturingStrategy implements AiStrategy {
  final List<GameCommand> commands;
  GameView? lastView;

  _CapturingStrategy({required this.commands});

  @override
  AiTurnPlan plan(GameView view, AiContext context) {
    lastView = view;
    return AiTurnPlan(commands: commands);
  }
}

class _MemoryGameRepository implements GameRepository {
  final SaveSnapshot snapshot;

  const _MemoryGameRepository(this.snapshot);

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
  Future<void> save(SaveSnapshot snapshot) async {}

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    throw UnimplementedError();
  }
}

GameSave _save({required GameMode gameMode}) {
  return GameSave(
    id: 'save_1',
    name: 'AI builder test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 2,
    playerStates: {
      for (final player in _players) player.id: PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 4, 27, 12),
    camera: CameraState.zero,
    players: _players,
    gameMode: gameMode,
  );
}

const _players = [
  Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
  Player(
    id: 'player_2',
    name: 'AI Random',
    colorValue: 0xFFDC2626,
    kind: PlayerKind.ai,
    ai: AiPlayer(
      strategyId: AiStrategyId.random,
      difficulty: AiDifficulty.normal,
      persona: AiPersona.aggressive,
      seed: 123,
    ),
  ),
];

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
