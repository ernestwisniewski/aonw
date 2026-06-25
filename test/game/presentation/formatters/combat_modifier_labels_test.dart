import 'package:aonw/game/presentation/formatters/combat_modifier_labels.dart';
import 'package:aonw/l10n/generated/app_localizations_pl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsPl();

  group('CombatModifierLabels', () {
    test('maps cavalry open raid counter to localized copy', () {
      expect(
        CombatModifierLabels.rawLabel(l10n, 'counter.cavalryOpenRaid.attack'),
        'rajd kawalerii w otwartym terenie',
      );
    });
  });
}
