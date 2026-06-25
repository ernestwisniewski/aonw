import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BorderEmphasis', () {
    test('alpha levels match the UI unification spec', () {
      expect(BorderEmphasis.subtle.alpha, 60);
      expect(BorderEmphasis.regular.alpha, 110);
      expect(BorderEmphasis.strong.alpha, 160);
      expect(BorderEmphasis.active.alpha, 220);
    });

    test('border() returns a border using the emphasis alpha', () {
      final border = BorderEmphasis.regular.border(HudPalette.gold);

      expect(border.top.color, HudPalette.gold.withAlpha(110));
      expect(border.top.width, 1);
    });

    test('side() supports custom width', () {
      final side = BorderEmphasis.active.side(HudPalette.gold, width: 1.5);

      expect(side.color, HudPalette.gold.withAlpha(220));
      expect(side.width, 1.5);
    });
  });
}
