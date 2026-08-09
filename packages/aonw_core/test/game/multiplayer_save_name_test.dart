import 'package:aonw_core/game/domain/save.dart';
import 'package:test/test.dart';

void main() {
  group('MultiplayerSaveName', () {
    test('prefixes a match name with the multiplayer marker', () {
      expect(
        MultiplayerSaveName.fromMatchName('Sunday duel'),
        'multi Sunday duel',
      );
    });

    test('normalizes an existing marker without duplicating it', () {
      expect(
        MultiplayerSaveName.fromMatchName('  MULTI   Sunday duel  '),
        'multi Sunday duel',
      );
      expect(MultiplayerSaveName.fromMatchName('multi'), 'multi');
    });

    test('uses the marker as the complete name when input is blank', () {
      expect(MultiplayerSaveName.fromMatchName('   '), 'multi');
    });
  });
}
