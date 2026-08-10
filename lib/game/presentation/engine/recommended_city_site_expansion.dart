part of 'recommended_city_site_planner.dart';

extension _RecommendedCitySiteExpansion on RecommendedCitySitePlanner {
  Iterable<WorldTile> _citySiteExpansionTiles({
    required CityHex center,
    required GameClientState state,
    required WorldMap mapData,
    required Set<CityHex> initialHexes,
  }) sync* {
    final draft = CityFoundingDraft(
      unitId: '_city_site_preview',
      ownerPlayerId: '_city_site_preview',
      center: center,
    );
    final candidates = <_CitySiteExpansionTile>[];
    final visibility = state.activePlayerVisibility;
    for (final candidate in _tilesInCitySiteRadius(center, mapData)) {
      if (visibility.isEnabled && !visibility.canInspectTile(candidate)) {
        continue;
      }
      final hex = CityHex(col: candidate.col, row: candidate.row);
      if (hex == center || initialHexes.contains(hex)) continue;
      if (!CityFoundingRules.isControlledHexCandidate(
        draft: draft,
        tile: candidate,
        mapTiles: mapData,
        cities: state.cities,
      )) {
        continue;
      }
      final distance = HexDistance.between(
        HexCoordinate(col: center.col, row: center.row),
        HexCoordinate(col: candidate.col, row: candidate.row),
      );
      candidates.add(
        _CitySiteExpansionTile(
          tile: candidate,
          distance: distance,
          score: CityExpansionSelector.score(
            candidate,
            ruleset: CityRulesets.standard,
          ),
        ),
      );
    }
    candidates.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;
      final distanceCompare = a.distance.compareTo(b.distance);
      if (distanceCompare != 0) return distanceCompare;
      final colCompare = a.tile.col.compareTo(b.tile.col);
      if (colCompare != 0) return colCompare;
      return a.tile.row.compareTo(b.tile.row);
    });
    for (final candidate in candidates) {
      yield candidate.tile;
    }
  }

  Iterable<WorldTile> _tilesInCitySiteRadius(
    CityHex center,
    WorldMap mapData,
  ) sync* {
    final visited = <CityHex>{center};
    var frontier = <CityHex>[center];
    for (
      var distance = 1;
      distance <= CityFoundingDraft.maxRadius;
      distance++
    ) {
      final next = <CityHex>[];
      for (final current in frontier) {
        for (final neighbor in HexGridTopology.neighbors(
          col: current.col,
          row: current.row,
        )) {
          final hex = CityHex(col: neighbor.col, row: neighbor.row);
          if (!visited.add(hex)) continue;
          final tile = mapData.tileAt(hex.col, hex.row);
          if (tile == null) continue;
          next.add(hex);
          yield tile;
        }
      }
      frontier = next;
    }
  }
}

class _CitySiteExpansionTile {
  const _CitySiteExpansionTile({
    required this.tile,
    required this.distance,
    required this.score,
  });

  final WorldTile tile;
  final int distance;
  final int score;
}
