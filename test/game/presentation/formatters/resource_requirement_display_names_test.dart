import 'package:aonw/game/presentation/formatters/resource_requirement_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw/l10n/generated/app_localizations_pl.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResourceRequirementDisplayNames', () {
    test('uses localized conjunctions for resource alternatives', () {
      final resources = {ResourceType.coal, ResourceType.oil};

      expect(
        ResourceRequirementDisplayNames.alternatives(
          AppLocalizationsEn(),
          resources,
        ),
        'coal or oil',
      );
      expect(
        ResourceRequirementDisplayNames.alternatives(
          AppLocalizationsPl(),
          resources,
        ),
        contains(' lub '),
      );
    });

    test('falls back to generic technology text for empty alternatives', () {
      expect(
        ResourceRequirementDisplayNames.alternatives(
          AppLocalizationsEn(),
          const {},
        ),
        'Requires technology',
      );
    });
  });
}
