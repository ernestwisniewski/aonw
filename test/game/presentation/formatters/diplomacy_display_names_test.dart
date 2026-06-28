import 'package:aonw/game/presentation/formatters/diplomacy_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/l10n/generated/app_localizations_pl.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiplomacyDisplayNames', () {
    test('localizes every relation status', () {
      final localizations = [AppLocalizationsPl(), AppLocalizationsEn()];

      for (final l10n in localizations) {
        for (final status in DiplomaticRelationStatus.values) {
          expect(DiplomacyDisplayNames.relation(l10n, status), isNotEmpty);
          expect(DiplomacyDisplayNames.relationShort(l10n, status), isNotEmpty);
        }
      }
    });
  });
}
