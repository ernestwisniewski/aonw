import 'package:aonw_core/game/domain/city/city_expansion_rules.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/city_technology_effect_rules.dart';
import 'package:aonw_core/game/domain/city/city_territory_rules.dart';
import 'package:aonw_core/game/domain/city/city_tile_yield_rules.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/technology/technology_effect_summary.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_data.dart';

class CityExpansionCandidate {
  final CityHex hex;
  final int score;
  final int distance;

  const CityExpansionCandidate({
    required this.hex,
    required this.score,
    required this.distance,
  });
}

abstract final class CityExpansionSelector {
  static CityHex? bestHex({
    required GameCity city,
    required MapData mapData,
    required Iterable<GameCity> cities,
    bool allowCoast = false,
    bool allowOcean = false,
    CityRuleset ruleset = CityRulesets.standard,
    TechnologyEffectSummary technologyEffects = TechnologyEffectSummary.empty,
  }) {
    final candidates = candidatesFor(
      city: city,
      mapData: mapData,
      cities: cities,
      allowCoast: allowCoast,
      allowOcean: allowOcean,
      ruleset: ruleset,
      technologyEffects: technologyEffects,
    );
    if (candidates.isEmpty) return null;
    candidates.sort(_compareCandidates);
    return candidates.first.hex;
  }

  static CityHex? preferredOrBestHex({
    required GameCity city,
    required MapData mapData,
    required Iterable<GameCity> cities,
    bool allowCoast = false,
    bool allowOcean = false,
    CityRuleset ruleset = CityRulesets.standard,
    TechnologyEffectSummary technologyEffects = TechnologyEffectSummary.empty,
  }) {
    final preferred = city.preferredExpansionHex;
    final candidates = candidatesFor(
      city: city,
      mapData: mapData,
      cities: cities,
      allowCoast: allowCoast,
      allowOcean: allowOcean,
      ruleset: ruleset,
      technologyEffects: technologyEffects,
    );
    if (candidates.isEmpty) return null;
    if (preferred != null) {
      for (final candidate in candidates) {
        if (candidate.hex == preferred) return preferred;
      }
    }
    candidates.sort(_compareCandidates);
    return candidates.first.hex;
  }

  static List<CityExpansionCandidate> candidatesFor({
    required GameCity city,
    required MapData mapData,
    required Iterable<GameCity> cities,
    bool allowCoast = false,
    bool allowOcean = false,
    CityRuleset ruleset = CityRulesets.standard,
    TechnologyEffectSummary technologyEffects = TechnologyEffectSummary.empty,
  }) {
    final maxHexes = CityTechnologyEffectRules.effectiveMaxHexes(
      city,
      ruleset: ruleset,
      effects: technologyEffects,
    );
    if (city.territoryHexCount >= maxHexes) return const [];

    final seen = <CityHex>{};
    final candidates = <CityExpansionCandidate>[];
    for (final owned in city.territoryHexes) {
      for (final neighbor in HexGridTopology.neighbors(
        col: owned.col,
        row: owned.row,
      )) {
        final hex = CityHex(col: neighbor.col, row: neighbor.row);
        if (!seen.add(hex)) continue;
        final tile = mapData.tileAt(hex.col, hex.row);
        if (!CityExpansionRules.canClaim(
          city: city,
          target: hex,
          tile: tile,
          cities: cities,
          allowCoast: allowCoast,
          allowOcean: allowOcean,
        )) {
          continue;
        }
        final distance = CityTerritoryRules.distance(
          from: city.center,
          to: hex,
          maxDistance: city.territoryRadius,
        );
        candidates.add(
          CityExpansionCandidate(
            hex: hex,
            score: score(tile!, ruleset: ruleset),
            distance: distance,
          ),
        );
      }
    }
    return candidates;
  }

  static int score(
    TileData tile, {
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final yield = CityTileYieldRules.forTile(tile, ruleset: ruleset);
    final river = CityTileYieldRules.hasRiver(tile) ? 1 : 0;
    final resource = tile.resources.isEmpty ? 0 : 1;
    return yield.food * 100 + yield.production * 30 + river * 10 + resource * 5;
  }

  static int _compareCandidates(
    CityExpansionCandidate a,
    CityExpansionCandidate b,
  ) {
    final score = b.score.compareTo(a.score);
    if (score != 0) return score;
    final distance = a.distance.compareTo(b.distance);
    if (distance != 0) return distance;
    final col = a.hex.col.compareTo(b.hex.col);
    if (col != 0) return col;
    return a.hex.row.compareTo(b.hex.row);
  }
}
