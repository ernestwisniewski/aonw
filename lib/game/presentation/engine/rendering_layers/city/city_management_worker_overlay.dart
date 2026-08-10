part of 'city_management_overlay_layer.dart';

extension _CityManagementWorkerOverlay on CityManagementOverlayLayer {
  List<CityManagementOverlayHex> _selectedWorkerImprovementHexes({
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final worker = _selectedControllableWorker(state);
    if (worker == null) return const [];

    final result = <CityManagementOverlayHex>[];
    for (final tile in mapData.tiles) {
      final hex = CityHex(col: tile.col, row: tile.row);
      if (canShowHex?.call(hex) == false) continue;

      final workerOverlay = _workerImprovementOverlay(
        worker: worker,
        hex: hex,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
      );
      if (workerOverlay == null) continue;

      result.add(
        CityManagementOverlayHex(
          hex: hex,
          kind: workerOverlay.kind,
          label: workerOverlay.label,
          tileYield: workerOverlay.tileYield,
        ),
      );
    }

    result.sort((a, b) {
      final kind = _workerKindPriority(
        a.kind,
      ).compareTo(_workerKindPriority(b.kind));
      if (kind != 0) return kind;
      final col = a.hex.col.compareTo(b.hex.col);
      if (col != 0) return col;
      return a.hex.row.compareTo(b.hex.row);
    });
    return List.unmodifiable(result);
  }

  GameUnit? _selectedControllableWorker(GameClientState state) {
    final unit = state.selectedUnit;
    if (unit == null ||
        !unit.isWorker ||
        unit.isWorking ||
        !state.canControlUnit(unit)) {
      return null;
    }
    return unit;
  }

  ({CityManagementOverlayHexKind kind, String label, TileYield tileYield})?
  _workerImprovementOverlay({
    required GameUnit worker,
    required CityHex hex,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
  }) {
    if (_isOwnCityCenter(worker.ownerPlayerId, hex, state.cities)) {
      return null;
    }
    final tile = mapData.tileAt(hex.col, hex.row);
    final city = _controlledCityForHex(worker.ownerPlayerId, hex, state.cities);
    if (city != null) {
      if (_hasFieldImprovement(hex, state.fieldImprovements)) {
        final yield = CityTileYieldRules.forCityHex(
          city: city,
          hex: hex,
          tile: tile,
          fieldImprovements: state.fieldImprovements,
          ruleset: cityRuleset,
        );
        return (
          kind: CityManagementOverlayHexKind.workerImprovementExisting,
          label: _yieldLabel(yield),
          tileYield: yield,
        );
      }
      final yield =
          _bestImprovedYieldFor(
            worker: worker,
            hex: hex,
            state: state,
            mapData: mapData,
            cityRuleset: cityRuleset,
          ) ??
          (tile == null
              ? TileYield.zero
              : CityTileYieldRules.forTile(tile, ruleset: cityRuleset));
      return (
        kind: CityManagementOverlayHexKind.workerImprovementMissingInCity,
        label: _yieldLabel(yield),
        tileYield: yield,
      );
    }

    return null;
  }

  int _workerKindPriority(CityManagementOverlayHexKind kind) => switch (kind) {
    CityManagementOverlayHexKind.workerImprovementMissingInCity => 0,
    CityManagementOverlayHexKind.workerImprovementExisting => 1,
    _ => 3,
  };

  bool _isOwnCityCenter(
    String playerId,
    CityHex hex,
    Iterable<GameCity> cities,
  ) {
    for (final city in cities) {
      if (city.ownerPlayerId == playerId && city.center == hex) return true;
    }
    return false;
  }

  GameCity? _controlledCityForHex(
    String playerId,
    CityHex hex,
    Iterable<GameCity> cities,
  ) {
    for (final city in cities) {
      if (city.ownerPlayerId == playerId && city.controlsHex(hex)) {
        return city;
      }
    }
    return null;
  }

  bool _hasFieldImprovement(
    CityHex hex,
    Iterable<FieldImprovement> fieldImprovements,
  ) {
    for (final improvement in fieldImprovements) {
      if (improvement.hex == hex) return true;
    }
    return false;
  }

  TileYield? _bestImprovedYieldFor({
    required GameUnit worker,
    required CityHex hex,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
  }) {
    final tile = mapData.tileAt(hex.col, hex.row);
    if (tile == null) return null;

    TileYield? bestYield;
    var bestScore = -1;
    FieldImprovementType? bestType;
    for (final type in FieldImprovementType.values) {
      final legality = WorkerImprovementRules.evaluate(
        unit: worker,
        improvementType: type,
        cities: state.cities,
        fieldImprovements: state.fieldImprovements,
        mapTiles: mapData,
        research: state.research,
        targetHex: hex,
        requireReadyWorker: false,
        cityRuleset: cityRuleset,
      );
      if (!legality.allowed) continue;

      final yield = CityTileYieldRules.forTile(
        tile,
        improvement: type,
        ruleset: cityRuleset,
      );
      final score = _yieldScore(yield);
      if (bestYield == null ||
          score > bestScore ||
          (score == bestScore &&
              (bestType == null || type.index < bestType.index))) {
        bestYield = yield;
        bestScore = score;
        bestType = type;
      }
    }
    return bestYield;
  }

  int _yieldScore(TileYield yield) {
    return yield.food * 1000 +
        yield.production * 400 +
        yield.defense * 250 +
        yield.gold * 150;
  }

  String _yieldLabel(TileYield yield) {
    final parts = <String>[
      if (yield.food > 0) '${yield.food}F',
      if (yield.production > 0) '${yield.production}P',
      if (yield.defense > 0) '${yield.defense}D',
      if (yield.gold > 0) '${yield.gold}G',
    ];
    return parts.isEmpty ? '0' : parts.join(' ');
  }
}
