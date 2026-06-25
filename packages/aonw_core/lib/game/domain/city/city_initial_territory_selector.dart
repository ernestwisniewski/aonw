import 'package:aonw_core/game/domain/city/city_expansion_rules.dart';
import 'package:aonw_core/game/domain/city/city_expansion_selector.dart';
import 'package:aonw_core/game/domain/city/city_hex.dart';
import 'package:aonw_core/game/domain/city/city_ruleset.dart';
import 'package:aonw_core/game/domain/city/city_rulesets.dart';
import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class CityInitialTerritorySelector {
  static const requiredControlledHexes = 2;

  static List<CityHex> select({
    required CityHex center,
    required MapData mapData,
    required Iterable<GameCity> cities,
    int count = requiredControlledHexes,
    bool allowCoast = false,
    bool allowOcean = false,
    CityRuleset ruleset = CityRulesets.standard,
  }) {
    final temporaryCity = GameCity(
      id: '_draft_city_${center.col}_${center.row}',
      ownerPlayerId: '_draft',
      name: '_draft',
      center: center,
    );
    final candidates = <CityExpansionCandidate>[];
    for (final neighbor in HexGridTopology.neighbors(
      col: center.col,
      row: center.row,
    )) {
      final hex = CityHex(col: neighbor.col, row: neighbor.row);
      final tile = mapData.tileAt(hex.col, hex.row);
      if (tile == null) continue;
      if (!CityExpansionRules.canClaim(
        city: temporaryCity,
        target: hex,
        tile: tile,
        cities: cities,
        radius: 1,
        allowCoast: allowCoast,
        allowOcean: allowOcean,
      )) {
        continue;
      }
      candidates.add(
        CityExpansionCandidate(
          hex: hex,
          score: CityExpansionSelector.score(tile, ruleset: ruleset),
          distance: 1,
        ),
      );
    }
    candidates.sort((a, b) {
      final score = b.score.compareTo(a.score);
      if (score != 0) return score;
      final col = a.hex.col.compareTo(b.hex.col);
      if (col != 0) return col;
      return a.hex.row.compareTo(b.hex.row);
    });
    return candidates.take(count).map((candidate) => candidate.hex).toList();
  }
}
