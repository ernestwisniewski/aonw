import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';

abstract final class HudCityEconomyCalculator {
  static CityEconomyBreakdown forCity({
    required GameCity city,
    required GameClientState state,
    required WorldMap mapData,
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
      mapTiles: mapData,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
      stabilityModifier: stabilityModifier,
    );
  }
}
