import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Player', () {
    test('assigns deterministic palette colors by index', () {
      expect(Player.forIndex(0).id, 'player_1');
      expect(Player.forIndex(0).colorValue, Player.palette.first);
      expect(
        Player.forIndex(Player.palette.length).colorValue,
        Player.palette.first,
      );
    });

    test('round-trips through JSON', () {
      final player = Player.forIndex(1);

      expect(Player.fromJson(player.toJson()), player);
    });

    test('round-trips selected country through JSON', () {
      const player = Player(
        id: 'player_1',
        name: 'Alice',
        colorValue: 0xFF2563EB,
        country: PlayerCountry.japan,
      );

      final restored = Player.fromJson(player.toJson());

      expect(restored.country, PlayerCountry.japan);
      expect(restored, player);
    });

    test('defaults old JSON saves to human players', () {
      final player = Player.fromJson({
        'id': 'player_1',
        'name': 'Alice',
        'colorValue': 0xFF2563EB,
      });

      expect(player.kind, PlayerKind.human);
      expect(player.country, PlayerCountry.poland);
      expect(player.ai, isNull);
    });

    test('round-trips AI player configuration through JSON', () {
      const ai = AiPlayer(
        strategyId: AiStrategyId.random,
        difficulty: AiDifficulty.hard,
        persona: AiPersona.aggressive,
        seed: 12345,
      );
      const player = Player(
        id: 'player_2',
        name: 'AI Random',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: ai,
      );

      final restored = Player.fromJson(player.toJson());

      expect(restored, player);
      expect(restored.isAi, isTrue);
      expect(restored.ai?.seed, 12345);
    });
  });
}
