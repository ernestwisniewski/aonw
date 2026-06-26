import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/technology.dart';

abstract final class HudSelectionInfoModelFactory {
  static SelectionViewModel? from({
    required GameSelection? selection,
    required GameState? gameState,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyRuleset technologyRuleset,
    required AppLocalizations l10n,
    int? currentTurn,
    PaceBalance paceBalance = PaceBalance.unlimited,
  }) {
    if (selection == null) return null;

    return SelectionViewModelFactory.from(
      selection,
      gameState: gameState,
      mapData: mapData,
      cityRuleset: cityRuleset,
      technologyRuleset: technologyRuleset,
      l10n: l10n,
      cityName: (city) => GameDisplayNames.city(l10n, city),
      unitName: (unit) => GameDisplayNames.unit(l10n, unit),
      improvementName: (type) => GameDisplayNames.fieldImprovement(l10n, type),
      technologyName: (id) => GameDisplayNames.technology(l10n, id),
      buildingName: (type) => GameDisplayNames.cityBuilding(l10n, type),
      currentTurn: currentTurn,
      paceBalance: paceBalance,
    );
  }
}
