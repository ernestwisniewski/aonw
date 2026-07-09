import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameCommandContext', () {
    test('copyWith can clear nullable actor id', () {
      const context = GameCommandContext(actorPlayerId: 'player_1');

      final cleared = context.copyWith(actorPlayerId: null);

      expect(cleared.actorPlayerId, isNull);
      expect(cleared.hasActor, isFalse);
    });
  });
}
