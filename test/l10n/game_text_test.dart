import 'package:aonw/l10n/game_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds game UI casing from natural localized text', () {
    expect(GameText.menuLabel('Load game'), 'LOAD GAME');
    expect(GameText.sectionLabel('shared world'), 'SHARED WORLD');
    expect(GameText.capitalize('harvest'), 'Harvest');
  });
}
