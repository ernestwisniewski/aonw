import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';

abstract final class CityProjectItemFactory {
  static List<CityProductionItem> build({
    required AppLocalizations l10n,
    required int productionPerTurn,
    required CitySpecializationType? specialization,
    required CityProjectType? activeProjectType,
  }) {
    return [
      for (final type in CityProjectType.values)
        CityProductionItem.project(
          type: type,
          productionPerTurn: CitySpecializationRules.productionPerTurnForTarget(
            productionPerTurn: productionPerTurn,
            target: ProjectProductionTarget(type),
            specialization: specialization,
          ),
          active: activeProjectType == type,
          l10n: l10n,
        ),
    ];
  }
}
