import 'package:aonw_core/ai.dart';
import 'package:test/test.dart';

void main() {
  group('AiRng', () {
    test('is deterministic for the same turn player and base seed', () {
      final first = AiRng.fromTurn(turn: 7, playerId: 'player_2', baseSeed: 99);
      final second = AiRng.fromTurn(
        turn: 7,
        playerId: 'player_2',
        baseSeed: 99,
      );

      expect(first, second);
      expect(first.nextInt(100).value, second.nextInt(100).value);
    });

    test('changes stream by player and turn', () {
      final base = AiRng.fromTurn(turn: 7, playerId: 'player_2', baseSeed: 99);
      final otherPlayer = AiRng.fromTurn(
        turn: 7,
        playerId: 'player_3',
        baseSeed: 99,
      );
      final otherTurn = AiRng.fromTurn(
        turn: 8,
        playerId: 'player_2',
        baseSeed: 99,
      );

      expect(otherPlayer.state, isNot(base.state));
      expect(otherTurn.state, isNot(base.state));
    });

    test('draws bounded values and advances state', () {
      final rng = AiRng(42);
      final draw = rng.nextInt(3);

      expect(draw.value, inInclusiveRange(0, 2));
      expect(draw.rng, isNot(rng));
    });
  });
}
