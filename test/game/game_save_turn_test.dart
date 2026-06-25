import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

GameSave _twoPlayerSave() => GameSave(
  id: 'test',
  name: 'Test',
  mapName: 'verdantia',
  mapSource: MapSource.asset,
  turn: 1,
  playerStates: {'p1': PlayerTurnState.active, 'p2': PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 1, 1),
  camera: CameraState.zero,
  players: const [
    Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
    Player(id: 'p2', name: 'Bob', colorValue: 0xFFc45050),
  ],
);

void main() {
  group('PlayerTurnState', () {
    test('values are active and finished', () {
      expect(
        PlayerTurnState.values,
        containsAll([PlayerTurnState.active, PlayerTurnState.finished]),
      );
    });
  });

  group('GameSave.withPlayerFinished', () {
    test('marks target player as finished', () {
      final save = _twoPlayerSave().withPlayerFinished('p1');
      expect(save.playerStates['p1'], PlayerTurnState.finished);
      expect(save.playerStates['p2'], PlayerTurnState.active);
    });

    test('does not increment turn when other players still active', () {
      final save = _twoPlayerSave().withPlayerFinished('p1');
      expect(save.turn, 1);
    });

    test(
      'increments turn and resets all to active when last player finishes',
      () {
        final save = _twoPlayerSave()
            .withPlayerFinished('p1')
            .withPlayerFinished('p2');
        expect(save.turn, 2);
        expect(save.playerStates['p1'], PlayerTurnState.active);
        expect(save.playerStates['p2'], PlayerTurnState.active);
      },
    );

    test('is a no-op for unknown playerId', () {
      final original = _twoPlayerSave();
      final save = original.withPlayerFinished('unknown');
      expect(save.turn, original.turn);
      expect(save.playerStates, original.playerStates);
    });
  });

  group('GameSave.withNewTurn', () {
    test('increments turn by 1', () {
      final save = _twoPlayerSave().withNewTurn();
      expect(save.turn, 2);
    });

    test('resets all playerStates to active', () {
      final withFinished = GameSave(
        id: 'test',
        name: 'Test',
        mapName: 'verdantia',
        mapSource: MapSource.asset,
        turn: 1,
        playerStates: {
          'p1': PlayerTurnState.finished,
          'p2': PlayerTurnState.finished,
        },
        savedAt: DateTime.utc(2026, 1, 1),
        camera: CameraState.zero,
        players: const [
          Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4),
          Player(id: 'p2', name: 'Bob', colorValue: 0xFFc45050),
        ],
      );
      final save = withFinished.withNewTurn();
      expect(save.playerStates['p1'], PlayerTurnState.active);
      expect(save.playerStates['p2'], PlayerTurnState.active);
    });
  });

  group('GameSave JSON round-trip', () {
    test('playerStates round-trips through JSON', () {
      final save = _twoPlayerSave().withPlayerFinished('p1');
      final json = save.toJson();
      final back = GameSave.fromJson(json);
      expect(back.playerStates['p1'], PlayerTurnState.finished);
      expect(back.playerStates['p2'], PlayerTurnState.active);
    });

    test('writes current schema version', () {
      expect(
        _twoPlayerSave().toJson()['schemaVersion'],
        gameSaveCurrentSchemaVersion,
      );
    });

    test('ruleset round-trips through JSON', () {
      final save = _twoPlayerSave().copyWith(
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
      );
      final back = GameSave.fromJson(save.toJson());
      expect(back.matchRules, save.matchRules);
      expect(back.toJson()['ruleset'], save.matchRules.toJson());
    });

    test('falls back to bundled map source for unknown values', () {
      final json = _twoPlayerSave().toJson()..['mapSource'] = 'future_source';
      final back = GameSave.fromJson(json);
      expect(back.mapSource, MapSource.asset);
    });

    test('gameMode round-trips through JSON', () {
      final save = _twoPlayerSave().copyWith(gameMode: GameMode.multiplayer);
      final back = GameSave.fromJson(save.toJson());
      expect(back.gameMode, GameMode.multiplayer);
    });

    test('savedAt serializes as UTC ISO timestamp', () {
      final save = _twoPlayerSave().copyWith(savedAt: DateTime(2026, 1, 1, 12));
      expect(save.toJson()['savedAt'], save.savedAt.toUtc().toIso8601String());
    });

    test('defaults missing optional save metadata', () {
      final json = _twoPlayerSave().toJson()
        ..remove('players')
        ..remove('gameMode');
      final back = GameSave.fromJson(json);
      expect(back.players, isEmpty);
      expect(back.gameMode, GameMode.hotSeat);
    });
  });
}
