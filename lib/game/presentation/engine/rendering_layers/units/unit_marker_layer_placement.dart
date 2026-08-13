part of 'unit_marker_layer.dart';

extension _UnitMarkerLayerPlacement on UnitMarkerLayer {
  Vector2 _unitWorldPosition(
    GameUnit unit, {
    required _CityUnitMarkerPlacement cityPlacement,
  }) {
    return UnitMarkerLayer.worldPositionFor(
      unit.col,
      unit.row,
      onCity: cityPlacement != _CityUnitMarkerPlacement.none,
      cityCompanionSide: cityPlacement == _CityUnitMarkerPlacement.companion,
    );
  }

  Vector2 _unitHexAnchorOffset(_CityUnitMarkerPlacement cityPlacement) {
    return switch (cityPlacement) {
      _CityUnitMarkerPlacement.none => Vector2.zero(),
      _CityUnitMarkerPlacement.primary => Vector2(26, 26),
      _CityUnitMarkerPlacement.companion => Vector2(-26, 26),
    };
  }

  Map<String, _CityUnitMarkerPlacement> _cityUnitPlacements(
    List<GameUnit> units,
    Set<({int col, int row})> cityTiles,
  ) {
    if (cityTiles.isEmpty) return const {};
    final unitsByCityTile = <({int col, int row}), List<GameUnit>>{};
    for (final unit in units) {
      final tile = (col: unit.col, row: unit.row);
      if (!cityTiles.contains(tile)) continue;
      (unitsByCityTile[tile] ??= []).add(unit);
    }
    if (unitsByCityTile.isEmpty) return const {};

    final placements = <String, _CityUnitMarkerPlacement>{};
    for (final cityUnits in unitsByCityTile.values) {
      final hasCompanionMerchant =
          cityUnits.length > 1 &&
          cityUnits.any((unit) => unit.type == GameUnitType.merchant);
      for (final unit in cityUnits) {
        placements[unit.id] =
            hasCompanionMerchant && unit.type == GameUnitType.merchant
            ? _CityUnitMarkerPlacement.companion
            : _CityUnitMarkerPlacement.primary;
      }
    }
    return placements;
  }

  void _applyPriority(UnitMarker marker, GameUnit unit) {
    final priority = _priorityFor(unit);
    if (marker.priority != priority) {
      marker.priority = priority;
    }
  }

  void _syncWorkState(
    UnitMarker marker,
    GameUnit unit,
    int? artifactExcavationTurns,
  ) {
    if (unit.workerJob case final job?) {
      marker
        ..workBadgeLabel = '${job.remainingTurns}t'
        ..compactWorkVisual = true
        ..playWork();
      return;
    }
    if (unit.cityFoundingJob case final job?) {
      marker
        ..workBadgeLabel = '${job.remainingTurns}t'
        ..compactWorkVisual = true
        ..playWork();
      return;
    }
    if (unit.excavatingArtifactId != null) {
      marker
        ..workBadgeLabel = '${artifactExcavationTurns ?? 1}t'
        ..compactWorkVisual = true
        ..playWork();
      return;
    }
    if (unit.workerAssignment != null) {
      marker
        ..workBadgeLabel = '+50%'
        ..compactWorkVisual = true
        ..playWork();
      return;
    }
    marker
      ..workBadgeLabel = null
      ..compactWorkVisual = false
      ..playIdle();
  }

  int _priorityFor(GameUnit unit) => MapPriority.perTileUnit(
    mapRows: mapData.rows,
    col: unit.col,
    row: unit.row,
  );

  bool _isExhausted(GameUnit unit) => !unit.hasMovementRemaining;
}
