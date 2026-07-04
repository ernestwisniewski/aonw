import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';

abstract final class HudCityEconomyCalculator {
  static CityEconomyBreakdown forCity({
    required GameCity city,
    required GameState state,
    required MapData mapData,
    required CityRuleset cityRuleset,
    required TechnologyEffectSummary technologyEffects,
    required StabilityModifier stabilityModifier,
  }) {
    final cityYield = CityYieldCalculator.totalFor(
      city,
      mapData,
      fieldImprovements: state.fieldImprovements,
      units: state.units,
      artifacts: state.artifacts,
      ruleset: cityRuleset,
    );
    return CityEconomyBreakdown.from(
      city: city,
      tileYield: cityYield,
      mapData: mapData,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
      stabilityModifier: stabilityModifier,
    );
  }
}
