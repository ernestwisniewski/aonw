import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/presentation/providers/multiplayer_status_sheet_provider.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _player1 = Player(id: 'player_1', name: 'Alice', colorValue: 0xFF4A7FC4);
const _player2 = Player(id: 'player_2', name: 'Bob', colorValue: 0xFFC45050);

void main() {
  group('MultiplayerStatusSheetRequestController', () {
    test('deduplicates requests for the same save, turn, and player', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        multiplayerStatusSheetRequestProvider.notifier,
      );
      final save = _makeSave();

      notifier.request(save: save, activePlayerId: 'player_1');
      final first = container.read(multiplayerStatusSheetRequestProvider);

      notifier.request(save: save, activePlayerId: 'player_1');
      final second = container.read(multiplayerStatusSheetRequestProvider);

      expect(first, isNotNull);
      expect(second, same(first));
    });

    test('does not reopen the same request after it is consumed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        multiplayerStatusSheetRequestProvider.notifier,
      );
      final save = _makeSave();

      notifier.request(save: save, activePlayerId: 'player_1');
      final first = container.read(multiplayerStatusSheetRequestProvider)!;
      notifier
        ..consume(first.id)
        ..request(save: save, activePlayerId: 'player_1');

      expect(container.read(multiplayerStatusSheetRequestProvider), isNull);
    });

    test('allows a new request on the next turn', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(
        multiplayerStatusSheetRequestProvider.notifier,
      );
      final save = _makeSave();

      notifier.request(save: save, activePlayerId: 'player_1');
      final first = container.read(multiplayerStatusSheetRequestProvider)!;
      notifier
        ..consume(first.id)
        ..request(
          save: save.copyWith(turn: save.turn + 1),
          activePlayerId: 'player_1',
        );
      final next = container.read(multiplayerStatusSheetRequestProvider);

      expect(next, isNotNull);
      expect(next!.id, isNot(first.id));
    });
  });
}

GameSave _makeSave() {
  return GameSave(
    id: 'save',
    name: 'Test save',
    mapName: 'test_map',
    turn: 1,
    playerStates: const {
      'player_1': PlayerTurnState.finished,
      'player_2': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 5, 29),
    camera: CameraState.zero,
    players: const [_player1, _player2],
    gameMode: GameMode.multiplayer,
  );
}
