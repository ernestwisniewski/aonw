import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_info_item.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/stability.dart';

/// Builds the cohesion row of the city selection panel: core / integrated /
/// frontier status with the cohesion cost, using the same core-city choice
/// ([CoreCityLocator]) as the stability calculation itself.
abstract final class CityCohesionSelectionItem {
  static SelectionInfoItem? build(
    GameCity city,
    List<GameCity> cities,
    AppLocalizations l10n,
  ) {
    final coreCity = CoreCityLocator.coreCityFor(
      playerId: city.ownerPlayerId,
      cities: cities,
    );
    if (coreCity == null) return null;
    if (city.id == coreCity.id) {
      return SelectionInfoItem(
        icon: GameIcons.defense,
        label: l10n.citySelectionCohesionLabel,
        value: l10n.citySelectionCohesionCore,
        color: GameUiTheme.success,
      );
    }

    final distance = HexDistance.between(
      city.center.toCoordinate(),
      coreCity.center.toCoordinate(),
    );
    final cohesionCost = CohesionCalculator.cityCohesionCost(
      cityCenter: city.center.toCoordinate(),
      nearestCoreCenter: coreCity.center.toCoordinate(),
      isConnected: CityTerritoryRules.isConnected(
        center: city.center,
        controlledHexes: city.controlledHexes,
      ),
      ruleset: StabilityRuleset.standard,
    );
    return SelectionInfoItem(
      icon: GameIcons.defense,
      label: l10n.citySelectionCohesionLabel,
      value: cohesionCost == 0
          ? l10n.citySelectionCohesionIntegrated(distance)
          : l10n.citySelectionCohesionFrontier(distance, cohesionCost),
      color: cohesionCost == 0 ? GameUiTheme.success : GameUiTheme.warning,
    );
  }
}
