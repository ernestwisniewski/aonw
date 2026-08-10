part of 'city_management_overlay_layer.dart';

extension _CityManagementGrowthOverlay on CityManagementOverlayLayer {
  List<CityManagementOverlayHex> _cityExpansionHexes({
    required GameCity city,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final technologyEffects = TechnologyEffectSummary.forPlayer(
      playerId: city.ownerPlayerId,
      research: state.research,
      ruleset: TechnologyRulesets.standard,
    );
    final recommended = CityExpansionSelector.preferredOrBestHex(
      city: city,
      mapTiles: mapData,
      cities: state.cities,
      allowCoast: true,
      allowOcean: true,
      ruleset: cityRuleset,
      technologyEffects: technologyEffects,
    );
    final candidates =
        CityExpansionSelector.candidatesFor(
            city: city,
            mapTiles: mapData,
            cities: state.cities,
            allowCoast: true,
            allowOcean: true,
            ruleset: cityRuleset,
            technologyEffects: technologyEffects,
          ).where((candidate) {
            final visible = canShowHex?.call(candidate.hex) ?? true;
            return visible;
          }).toList()
          ..sort((a, b) {
            final aRecommended = a.hex == recommended;
            final bRecommended = b.hex == recommended;
            if (aRecommended != bRecommended) return aRecommended ? -1 : 1;
            final score = b.score.compareTo(a.score);
            if (score != 0) return score;
            final distance = a.distance.compareTo(b.distance);
            if (distance != 0) return distance;
            final col = a.hex.col.compareTo(b.hex.col);
            if (col != 0) return col;
            return a.hex.row.compareTo(b.hex.row);
          });

    return [
      for (final candidate in candidates)
        CityManagementOverlayHex(
          hex: candidate.hex,
          kind: candidate.hex == recommended
              ? CityManagementOverlayHexKind.growthRecommended
              : CityManagementOverlayHexKind.growthCandidate,
          label: candidate.hex == recommended ? 'N' : '+',
          tileYield: switch (mapData.tileAt(
            candidate.hex.col,
            candidate.hex.row,
          )) {
            final tile? => CityTileYieldRules.forTile(
              tile,
              ruleset: cityRuleset,
            ),
            _ => null,
          },
        ),
    ];
  }
}
