import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/city_selection_view_model_factory.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/field_improvement_selection_view_model_factory.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/selection_view_model.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/tile_selection_view_model_factory.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models/unit_selection_view_model_factory.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';

abstract final class SelectionViewModelFactory {
  static SelectionViewModel from(
    GameSelection? selection, {
    GameState? gameState,
    MapData? mapData,
    CityRuleset cityRuleset = CityRulesets.standard,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    required AppLocalizations l10n,
    String Function(GameCity city)? cityName,
    String Function(GameUnit unit)? unitName,
    String Function(FieldImprovementType type)? improvementName,
    String Function(TechnologyId id)? technologyName,
    String Function(CityBuildingType type)? buildingName,
    int? currentTurn,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    String tileCityName(GameCity city) {
      if (cityName != null) return cityName(city);
      return GameDisplayNames.city(l10n, city);
    }

    String tileImprovementName(FieldImprovementType type) {
      if (improvementName != null) return improvementName(type);
      return GameDisplayNames.fieldImprovement(l10n, type);
    }

    String tileTechnologyName(TechnologyId id) {
      if (technologyName != null) return technologyName(id);
      return GameDisplayNames.technology(l10n, id);
    }

    return switch (selection?.type) {
      GameSelectionType.tile => TileSelectionViewModelFactory.from(
        selection!.tile,
        gameState: gameState,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        l10n: l10n,
        improvementName: tileImprovementName,
        technologyName: tileTechnologyName,
        resourceName: (resource) => GameDisplayNames.resource(l10n, resource),
        cityName: tileCityName,
        paceBalance: paceBalance,
      ),
      GameSelectionType.unit => UnitSelectionViewModelFactory.from(
        selection!,
        gameState: gameState,
        mapData: mapData,
        cityRuleset: cityRuleset,
        technologyRuleset: technologyRuleset,
        l10n: l10n,
        unitName: unitName,
        improvementName: tileImprovementName,
        paceBalance: paceBalance,
      ),
      GameSelectionType.fieldImprovement =>
        FieldImprovementSelectionViewModelFactory.from(
          selection!,
          gameState: gameState,
          cityRuleset: cityRuleset,
          technologyRuleset: technologyRuleset,
          l10n: l10n,
          improvementName: tileImprovementName,
          cityName: tileCityName,
          paceBalance: paceBalance,
        ),
      GameSelectionType.city => CitySelectionViewModelFactory.from(
        selection!,
        cityRuleset: cityRuleset,
        mapData: mapData,
        units: gameState == null ? const [] : gameState.units,
        artifacts: gameState == null ? const [] : gameState.artifacts,
        fieldImprovements: gameState == null
            ? const []
            : gameState.fieldImprovements,
        research: gameState == null ? ResearchState.empty : gameState.research,
        technologyRuleset: technologyRuleset,
        cityName: cityName,
        buildingName: buildingName,
        l10n: l10n,
        currentTurn: currentTurn,
        paceBalance: paceBalance,
      ),
      null => const SelectionViewModel.empty(),
    };
  }
}
