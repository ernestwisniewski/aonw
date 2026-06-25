import 'package:aonw/game/presentation/widgets/selection/density.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SelectionDensitySpec', () {
    test('compact spec values are tighter than comfortable', () {
      final compact = SelectionDensitySpec.of(SelectionDensity.compact);
      final comfortable = SelectionDensitySpec.of(SelectionDensity.comfortable);

      expect(compact.chipFontSize, lessThan(comfortable.chipFontSize));
      expect(
        compact.chipPadding.horizontal,
        lessThanOrEqualTo(comfortable.chipPadding.horizontal),
      );
      expect(compact.actionChipSize, lessThan(comfortable.actionChipSize));
    });

    test('compact matches existing toolbar values', () {
      final compact = SelectionDensitySpec.of(SelectionDensity.compact);

      expect(compact.chipHeight, 28);
      expect(compact.chipPadding.horizontal, 16);
      expect(compact.actionChipSize, 36);
      expect(compact.tagHeight, 23);
      expect(compact.visibleTagCount, 1);
      expect(compact.yieldMetricHeight, 32);
      expect(compact.yieldMetricGap, 4);
      expect(compact.troopIconSize, 12);
      expect(compact.troopDetachButtonHeight, 26);
      expect(compact.selectionIconTileSize, 56);
    });

    test('comfortable matches existing sheet values', () {
      final comfortable = SelectionDensitySpec.of(SelectionDensity.comfortable);

      expect(comfortable.actionChipSize, 48);
      expect(comfortable.chipHeight, 36);
      expect(comfortable.tagHeight, 28);
      expect(comfortable.visibleTagCount, 2);
      expect(comfortable.yieldMetricHeight, 36);
      expect(comfortable.yieldMetricGap, 6);
      expect(comfortable.troopIconSize, 16);
      expect(comfortable.troopDetachButtonHeight, 28);
      expect(comfortable.selectionIconTileSize, 72);
    });

    test('exposes icon size per density', () {
      final compact = SelectionDensitySpec.of(SelectionDensity.compact);
      final comfortable = SelectionDensitySpec.of(SelectionDensity.comfortable);

      expect(compact.iconSize, GameIconSize.tiny);
      expect(comfortable.iconSize, GameIconSize.regular);
    });
  });
}
