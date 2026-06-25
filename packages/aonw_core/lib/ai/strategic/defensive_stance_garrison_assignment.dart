part of 'defensive_stance_planner.dart';

class _GarrisonPool {
  final List<GameUnit> availableUnits;

  const _GarrisonPool(this.availableUnits);

  factory _GarrisonPool.fromView(GameView view) {
    final units = [
      for (final unit in view.ownUnits)
        if (_canServeAsGarrison(unit, view.ruleset.combat)) unit,
    ]..sort(_compareAvailableGarrisons);
    return _GarrisonPool(units);
  }

  List<GameUnit> nearestAvailable({
    required GameCity city,
    required Set<String> committedUnitIds,
    required int neededCount,
  }) {
    final cityCenter = city.center.toCoordinate();
    final units =
        [
          for (final unit in availableUnits)
            if (!committedUnitIds.contains(unit.id)) unit,
        ]..sort((a, b) {
          final reconCompare = _reconSortValue(
            a.type,
          ).compareTo(_reconSortValue(b.type));
          if (reconCompare != 0) return reconCompare;
          final aDistance = HexDistance.between(
            HexCoordinate(col: a.col, row: a.row),
            cityCenter,
          );
          final bDistance = HexDistance.between(
            HexCoordinate(col: b.col, row: b.row),
            cityCenter,
          );
          final distanceCompare = aDistance.compareTo(bDistance);
          if (distanceCompare != 0) return distanceCompare;
          return a.id.compareTo(b.id);
        });
    return units.take(neededCount).toList(growable: false);
  }

  static bool _canServeAsGarrison(GameUnit unit, CombatRuleset ruleset) {
    return !unit.isWorker &&
        unit.type != GameUnitType.settler &&
        !unit.hasSettlers &&
        !unit.isWorking &&
        unit.queuedPath == null &&
        _isMilitaryUnit(unit, ruleset);
  }
}

int _compareAvailableGarrisons(GameUnit a, GameUnit b) {
  final reconCompare = _reconSortValue(
    a.type,
  ).compareTo(_reconSortValue(b.type));
  if (reconCompare != 0) return reconCompare;
  return a.id.compareTo(b.id);
}

int _reconSortValue(GameUnitType type) {
  return switch (type) {
    GameUnitType.scout ||
    GameUnitType.scoutShip ||
    GameUnitType.reconPlane => 1,
    _ => 0,
  };
}
