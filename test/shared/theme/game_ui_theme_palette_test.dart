import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameUiTheme palette', () {
    test('uses warm dark navy surface tones', () {
      expect(GameUiTheme.bg, const Color(0xFF0A0A0E));
      expect(GameUiTheme.surface, const Color(0xFF101620));
      expect(GameUiTheme.surfaceDeep, const Color(0xFF1A2030));
      expect(GameUiTheme.chipSurface, const Color(0xFF1E2738));
      expect(GameUiTheme.chipSurfaceDim, const Color(0xFF27384C));
      expect(GameUiTheme.card, const Color(0xFF131B26));
      expect(GameUiTheme.cardAccent, const Color(0xFF1E2738));
    });

    test('uses warmer gold tones', () {
      expect(GameUiTheme.gold, const Color(0xFFD2A856));
      expect(GameUiTheme.goldLight, const Color(0xFFF0DCAE));
      expect(GameUiTheme.goldDark, const Color(0xFF8C6926));
      expect(GameUiTheme.border, GameUiTheme.gold);
      expect(GameUiTheme.sectionLabel, GameUiTheme.goldDark);
    });

    test('exposes copper accent tokens', () {
      expect(GameUiTheme.copper, const Color(0xFFB47A4E));
      expect(GameUiTheme.copperDeep, const Color(0xFF7A4A28));
    });

    test('panelSurfaceGradient runs from cool top to warm bottom', () {
      final gradient = GameUiTheme.panelSurfaceGradient();
      expect(gradient.colors.first, const Color(0xFF101620));
      expect(gradient.colors.last, const Color(0xFF1A1A1F));
      expect(gradient.begin, Alignment.topCenter);
      expect(gradient.end, Alignment.bottomCenter);
    });
  });
}
