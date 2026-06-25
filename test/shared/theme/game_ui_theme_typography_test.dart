import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameUiTheme heading letterSpacing', () {
    test('brandTitle uses widest spacing', () {
      expect(GameUiTheme.brandTitle.letterSpacing, 1.2);
    });

    test('screenTitle uses 0.6 letterSpacing', () {
      expect(GameUiTheme.screenTitle.letterSpacing, 0.6);
    });

    test('cardTitle uses 0.5 letterSpacing', () {
      expect(GameUiTheme.cardTitle.letterSpacing, 0.5);
    });

    test('brandSubtitle uses 0.8 letterSpacing', () {
      expect(GameUiTheme.brandSubtitle.letterSpacing, 0.8);
    });

    test('sectionHeader uses 0.8 letterSpacing', () {
      expect(GameUiTheme.sectionHeader.letterSpacing, 0.8);
    });

    test('labelSmall uses 0.5 letterSpacing', () {
      expect(GameUiTheme.labelSmall.letterSpacing, 0.5);
    });

    test('toolbarLabel uses 0.4 letterSpacing', () {
      expect(GameUiTheme.toolbarLabel.letterSpacing, 0.4);
    });

    test('body styles keep zero letterSpacing', () {
      expect(GameUiTheme.body.letterSpacing, 0);
      expect(GameUiTheme.bodySmall.letterSpacing, 0);
      expect(GameUiTheme.bodyStrong.letterSpacing, 0);
      expect(GameUiTheme.chipLabel.letterSpacing, 0);
      expect(GameUiTheme.cardMeta.letterSpacing, 0);
      expect(GameUiTheme.actionLabel.letterSpacing, 0);
      expect(GameUiTheme.menuButton.letterSpacing, 0);
      expect(GameUiTheme.inputText.letterSpacing, 0);
    });
  });
}
