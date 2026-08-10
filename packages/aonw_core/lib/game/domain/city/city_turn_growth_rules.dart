import 'package:aonw_core/game/domain/city/city_expansion_selector.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

abstract final class CityTurnGrowthRules {
  static ({GameCity city, CityHex? hex}) expandTerritoryAfterGrowth({
    required GameCity city,
    required List<GameCity> cities,
    required MapTileLookup mapData,
    required CityRuleset ruleset,
    required TechnologyEffectSummary technologyEffects,
  }) {
    final citiesWithCurrentCity = _replaceCity(cities, city);
    final hex = CityExpansionSelector.preferredOrBestHex(
      city: city,
      mapTiles: mapData,
      cities: citiesWithCurrentCity,
      allowCoast: true,
      allowOcean: true,
      ruleset: ruleset,
      technologyEffects: technologyEffects,
    );
    if (hex == null) return (city: city, hex: null);
    return (
      city: city.copyWith(
        controlledHexes: [...city.controlledHexes, hex],
        preferredExpansionHex: null,
      ),
      hex: hex,
    );
  }

  static GameCity applyPopulationTier(GameCity city, CityRuleset ruleset) {
    final progression = ruleset.progression;
    var maxHexes = city.maxHexes;
    var territoryRadius = city.territoryRadius;

    if (city.population >= 10) {
      if (maxHexes < progression.lateGameMaxHexes) {
        maxHexes = progression.lateGameMaxHexes;
      }
      if (territoryRadius < progression.expandedTerritoryRadius) {
        territoryRadius = progression.expandedTerritoryRadius;
      }
    } else if (city.population >= 6 && maxHexes < progression.midGameMaxHexes) {
      maxHexes = progression.midGameMaxHexes;
    }

    if (maxHexes == city.maxHexes && territoryRadius == city.territoryRadius) {
      return city;
    }
    return city.copyWith(maxHexes: maxHexes, territoryRadius: territoryRadius);
  }

  static List<GameCity> _replaceCity(List<GameCity> cities, GameCity city) => [
    for (final existing in cities)
      if (existing.id == city.id) city else existing,
  ];
}
