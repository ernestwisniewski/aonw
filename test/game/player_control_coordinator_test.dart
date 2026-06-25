import 'package:aonw/game/application/services/player_control_coordinator.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4a7fc4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFc45050);
const _player3 = Player(id: 'player_3', name: 'Cara', colorValue: 0xFF50a050);

GameSave _save({
  int turn = 1,
  Map<String, PlayerTurnState> playerStates = const {
    'player_1': PlayerTurnState.active,
    'player_2': PlayerTurnState.active,
    'player_3': PlayerTurnState.active,
  },
  List<Player> players = const [_player1, _player2, _player3],
}) {
  return GameSave(
    id: 'save',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: turn,
    playerStates: playerStates,
    savedAt: DateTime.utc(2026, 4, 16),
    camera: CameraState.zero,
    players: players,
  );
}

void main() {
  group('PlayerControlCoordinator', () {
    test('initial selects the first player from a save', () {
      final state = PlayerControlCoordinator.initial(_save());

      expect(state.activePlayerId, 'player_1');
      expect(state.canAct, isTrue);
    });

    test('initial keeps world unlocked without a save', () {
      final state = PlayerControlCoordinator.initial(null);

      expect(state.activePlayerId, isEmpty);
      expect(state.canAct, isTrue);
    });

    test('normalize keeps an existing player and refreshes canAct', () {
      final save = _save(
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
          'player_3': PlayerTurnState.active,
        },
      );

      final state = PlayerControlCoordinator.normalize(
        current: const PlayerControlState(activePlayerId: 'player_2'),
        save: save,
      );

      expect(state.activePlayerId, 'player_2');
      expect(state.canAct, isFalse);
    });

    test('normalize resets a missing player to the first save player', () {
      final state = PlayerControlCoordinator.normalize(
        current: const PlayerControlState(activePlayerId: 'missing'),
        save: _save(),
      );

      expect(state.activePlayerId, 'player_1');
      expect(state.canAct, isTrue);
    });

    test('selectPlayer marks a finished player as unable to act', () {
      final save = _save(
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
          'player_3': PlayerTurnState.active,
        },
      );

      final state = PlayerControlCoordinator.selectPlayer(
        current: const PlayerControlState(activePlayerId: 'player_1'),
        save: save,
        playerId: 'player_2',
      );

      expect(state.activePlayerId, 'player_2');
      expect(state.canAct, isFalse);
    });

    test('afterEndTurn stays on player while simultaneous turn continues', () {
      final previous = _save();
      final updated = _save(
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
          'player_3': PlayerTurnState.active,
        },
      );

      final state = PlayerControlCoordinator.afterEndTurn(
        current: const PlayerControlState(activePlayerId: 'player_2'),
        previousSave: previous,
        updatedSave: updated,
      );

      expect(state.activePlayerId, 'player_2');
      expect(state.canAct, isFalse);
    });

    test('afterEndTurn advances to the next active player on a new turn', () {
      final state = PlayerControlCoordinator.afterEndTurn(
        current: const PlayerControlState(activePlayerId: 'player_2'),
        previousSave: _save(),
        updatedSave: _save(turn: 2),
      );

      expect(state.activePlayerId, 'player_3');
      expect(state.canAct, isTrue);
    });

    test('nextActivePlayerId skips finished players', () {
      final save = _save(
        playerStates: const {
          'player_1': PlayerTurnState.active,
          'player_2': PlayerTurnState.finished,
          'player_3': PlayerTurnState.active,
        },
      );

      final playerId = PlayerControlCoordinator.nextActivePlayerId(
        save: save,
        afterPlayerId: 'player_1',
      );

      expect(playerId, 'player_3');
    });
  });
}
