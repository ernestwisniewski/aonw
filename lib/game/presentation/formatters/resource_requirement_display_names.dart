import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/terrain_type.dart';

abstract final class ResourceRequirementDisplayNames {
  static String alternatives(
    AppLocalizations l10n,
    Set<ResourceType> resources,
  ) {
    final names =
        resources
            .map((resource) => GameDisplayNames.resource(l10n, resource))
            .toList()
          ..sort();
    if (names.isEmpty) return l10n.requirementTechnology;
    if (names.length == 1) return names.single;
    final leading = names.take(names.length - 1).join(', ');
    return l10n.requirementResourceAnyOf(leading, names.last);
  }
}
