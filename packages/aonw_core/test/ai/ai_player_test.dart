import 'package:aonw_core/ai.dart';
import 'package:test/test.dart';

void main() {
  group('AiPlayer', () {
    test('round-trips the persisted AI configuration', () {
      const player = AiPlayer(
        strategyId: AiStrategyId.mcts,
        difficulty: AiDifficulty.hard,
        persona: AiPersona.scientific,
        seed: 73,
      );

      final decoded = AiPlayer.fromJson(player.toJson());

      expect(decoded, player);
      expect(decoded.hashCode, player.hashCode);
      expect(decoded.toString(), contains('AiStrategyId.mcts'));
      expect(decoded.toString(), contains('seed: 73'));
    });

    test('keeps backwards-compatible defaults for optional fields', () {
      final player = AiPlayer.fromJson(const {
        'strategyId': 'random',
        'seed': 19,
      });

      expect(player, AiPlayer.random(seed: 19));
      expect(player.difficulty, AiDifficulty.normal);
      expect(player.persona, AiPersona.balanced);
    });

    test('copyWith changes only explicitly supplied configuration', () {
      final original = AiPlayer.random(seed: 1);

      final updated = original.copyWith(
        difficulty: AiDifficulty.hard,
        persona: AiPersona.aggressive,
      );

      expect(updated.strategyId, original.strategyId);
      expect(updated.seed, original.seed);
      expect(updated.difficulty, AiDifficulty.hard);
      expect(updated.persona, AiPersona.aggressive);
      expect(updated, isNot(original));
    });
  });
}
