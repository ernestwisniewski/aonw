part of 'city_management_overlay_layer.dart';

extension _CityManagementWorkedHexOverlay on CityManagementOverlayLayer {
  List<CityManagementOverlayHex> _workedHexes({
    required GameCity city,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final manualWorked = _manualWorkedHexes(city, cityRuleset).toSet();
    final effectiveWorked = CityWorkedHexSelector.effectiveWorkedHexes(
      city: city,
      mapTiles: mapData,
      fieldImprovements: state.fieldImprovements,
      ruleset: cityRuleset,
    ).toSet();

    final candidates =
        CityWorkedHexSelector.candidatesFor(
            city: city,
            mapTiles: mapData,
            fieldImprovements: state.fieldImprovements,
            ruleset: cityRuleset,
          ).where((candidate) {
            final visible = canShowHex?.call(candidate.hex) ?? true;
            return visible;
          }).toList()
          ..sort((a, b) {
            final aKind = _workedKind(a.hex, manualWorked, effectiveWorked);
            final bKind = _workedKind(b.hex, manualWorked, effectiveWorked);
            final kind = _workedKindPriority(
              aKind,
            ).compareTo(_workedKindPriority(bKind));
            if (kind != 0) return kind;
            final score = b.score.compareTo(a.score);
            if (score != 0) return score;
            final col = a.hex.col.compareTo(b.hex.col);
            if (col != 0) return col;
            return a.hex.row.compareTo(b.hex.row);
          });

    return [
      for (final candidate in candidates)
        CityManagementOverlayHex(
          hex: candidate.hex,
          kind: _workedKind(candidate.hex, manualWorked, effectiveWorked),
          label: switch (_workedKind(
            candidate.hex,
            manualWorked,
            effectiveWorked,
          )) {
            CityManagementOverlayHexKind.workedManual => 'R',
            CityManagementOverlayHexKind.workedAuto => 'A',
            _ => '+',
          },
        ),
    ];
  }

  List<CityHex> _manualWorkedHexes(GameCity city, CityRuleset cityRuleset) {
    final limit = cityRuleset.progression.workedHexLimitForPopulation(
      city.population,
    );
    if (limit <= 0) return const [];

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

  CityManagementOverlayHexKind _workedKind(
    CityHex hex,
    Set<CityHex> manualWorked,
    Set<CityHex> effectiveWorked,
  ) {
    if (manualWorked.contains(hex)) {
      return CityManagementOverlayHexKind.workedManual;
    }
    if (effectiveWorked.contains(hex)) {
      return CityManagementOverlayHexKind.workedAuto;
    }
    return CityManagementOverlayHexKind.workedIdle;
  }

  int _workedKindPriority(CityManagementOverlayHexKind kind) => switch (kind) {
    CityManagementOverlayHexKind.workedManual => 0,
    CityManagementOverlayHexKind.workedAuto => 1,
    CityManagementOverlayHexKind.workedIdle => 2,
    _ => 3,
  };
}
