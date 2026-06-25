import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/field_improvement.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/tile_yield/tile_yield.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class CityWorkedHexCandidate {
  final CityHex hex;
  final TileYield yield;
  final int score;

  const CityWorkedHexCandidate({
    required this.hex,
    required this.yield,
    required this.score,
  });
}

abstract final class CityWorkedHexSelector {
  static List<CityHex> effectiveWorkedHexes({
    required GameCity city,
    required MapData mapData,
    Iterable<FieldImprovement> fieldImprovements = const [],
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final limit = ruleset.progression.workedHexLimitForPopulation(
      city.population,
    );
    if (limit <= 0) return const [];

    final selected = _validManualHexes(city, limit);
    if (selected.length >= limit) return List.unmodifiable(selected);

    final fill = bestForCity(
      city: city,
      mapData: mapData,
      fieldImprovements: fieldImprovements,
      ruleset: ruleset,
      excludedHexes: selected,
      limit: limit - selected.length,
    );
    return List.unmodifiable([...selected, ...fill]);
  }

  static List<CityHex> bestForCity({
    required GameCity city,
    required MapData mapData,
    Iterable<FieldImprovement> fieldImprovements = const [],
    CityRuleset ruleset = CityRulesets.standard,
    Iterable<CityHex> excludedHexes = const [],
    int? limit,
  }) {
    final excluded = excludedHexes.toSet();
    final candidates =
        candidatesFor(
            city: city,
            mapData: mapData,
            fieldImprovements: fieldImprovements,
            ruleset: ruleset,
          ).where((candidate) => !excluded.contains(candidate.hex)).toList()
          ..sort(_compareCandidates);
    final count = limit == null || limit > candidates.length
        ? candidates.length
        : limit;
    return List.unmodifiable([
      for (var i = 0; i < count; i++) candidates[i].hex,
    ]);
  }

  static List<CityWorkedHexCandidate> candidatesFor({
    required GameCity city,
    required MapData mapData,
    Iterable<FieldImprovement> fieldImprovements = const [],
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final candidates = <CityWorkedHexCandidate>[];
    for (final hex in city.controlledHexes) {
      final tile = mapData.tileAt(hex.col, hex.row);
      final tileYield = CityTileYieldRules.forCityHex(
        city: city,
        hex: hex,
        tile: tile,
        fieldImprovements: fieldImprovements,
        ruleset: ruleset,
      );
      candidates.add(
        CityWorkedHexCandidate(
          hex: hex,
          yield: tileYield,
          score: _score(tileYield),
        ),
      );
    }
    return List.unmodifiable(candidates);
  }

  static List<CityHex> _validManualHexes(GameCity city, int limit) {
    final selected = <CityHex>[];
    final seen = <CityHex>{};
    for (final hex in city.workedHexes) {
      if (selected.length >= limit) break;
      if (hex == city.center) continue;
      if (!city.controlledHexes.contains(hex)) continue;
      if (!seen.add(hex)) continue;
      selected.add(hex);
    }
    return selected;
  }

  static int _score(TileYield value) {
    return value.food * 100 +
        value.production * 30 +
        value.gold * 10 +
        value.defense;
  }

  static int _compareCandidates(
    CityWorkedHexCandidate a,
    CityWorkedHexCandidate b,
  ) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final col = a.hex.col.compareTo(b.hex.col);
    if (col != 0) return col;
    return a.hex.row.compareTo(b.hex.row);
  }
}
