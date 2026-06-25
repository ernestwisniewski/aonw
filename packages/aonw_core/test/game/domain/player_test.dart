import 'package:aonw_core/game/domain/player.dart';
import 'package:test/test.dart';

void main() {
  group('Player.palette', () {
    test('uses heraldic warm palette for four players', () {
      expect(Player.palette, [0xFF3D5FA8, 0xFFB83A3A, 0xFF6D4A8C, 0xFFC8741F]);
    });

    test('forIndex assigns palette colors round-robin', () {
      expect(Player.forIndex(0).colorValue, 0xFF3D5FA8);
      expect(Player.forIndex(1).colorValue, 0xFFB83A3A);
      expect(Player.forIndex(2).colorValue, 0xFF6D4A8C);
      expect(Player.forIndex(3).colorValue, 0xFFC8741F);
      expect(Player.forIndex(4).colorValue, 0xFF3D5FA8);
    });
  });
}
