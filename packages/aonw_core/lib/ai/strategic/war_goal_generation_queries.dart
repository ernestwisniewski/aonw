part of 'war_goal_generator.dart';

abstract final class _WarGoalMapQueries {
  static HexCoordinate? targetHexForGoal({
    required _WarGoalGenerationRequest request,
    required String playerId,
    required WarGoalKind kind,
    GameCity? preferredCity,
  }) {
    if (kind == WarGoalKind.defend) {
      return _defenseAnchorFor(request.view, playerId);
    }
    return offensiveTargetHexFor(
      request.view,
      playerId,
      preferredCity: preferredCity,
    );
  }

  static HexCoordinate? offensiveTargetHexFor(
    GameView view,
    String playerId, {
    GameCity? preferredCity,
  }) {
    final city = preferredCity ?? nearestRememberedCityFor(view, playerId);
    if (city != null) return city.center.toCoordinate();

    final enemy = nearestVisibleUnitFor(view, playerId);
    if (enemy != null) return HexCoordinate(col: enemy.col, row: enemy.row);
    return null;
  }

  static GameCity? cityForGoal({
    required _WarGoalGenerationRequest request,
    required String playerId,
  }) {
    return request.boxedInExpansion
        ? nearestRememberedCityForBoxedExpansion(request.view, playerId)
        : nearestRememberedCityFor(request.view, playerId);
  }

  static GameCity? nearestRememberedCityForBoxedExpansion(
    GameView view,
    String playerId,
  ) {
    final cities =
        [
          for (final city in view.rememberedEnemyCities)
            if (city.ownerPlayerId == playerId &&
                view.canTargetPlayer(city.ownerPlayerId))
              city,
        ]..sort((a, b) {
          final distanceCompare =
              nearestExpansionAnchorDistance(
                view,
                a.center.toCoordinate(),
              ).compareTo(
                nearestExpansionAnchorDistance(view, b.center.toCoordinate()),
              );
          if (distanceCompare != 0) return distanceCompare;
          return a.id.compareTo(b.id);
        });
    return cities.isEmpty ? null : cities.first;
  }

  static GameCity? nearestRememberedCityFor(GameView view, String playerId) {
    final cities =
        [
          for (final city in view.rememberedEnemyCities)
            if (city.ownerPlayerId == playerId &&
                view.canTargetPlayer(city.ownerPlayerId))
              city,
        ]..sort((a, b) {
          final distanceCompare = nearestOwnAnchorDistance(
            view,
            a.center.toCoordinate(),
          ).compareTo(nearestOwnAnchorDistance(view, b.center.toCoordinate()));
          if (distanceCompare != 0) return distanceCompare;
          return a.id.compareTo(b.id);
        });
    return cities.isEmpty ? null : cities.first;
  }

  static GameUnit? nearestVisibleUnitFor(GameView view, String playerId) {
    final units =
        [
          for (final unit in view.visibleEnemyUnits)
            if (unit.ownerPlayerId == playerId &&
                view.canTargetPlayer(unit.ownerPlayerId))
              unit,
        ]..sort((a, b) {
          final distanceCompare =
              nearestOwnAnchorDistance(
                view,
                HexCoordinate(col: a.col, row: a.row),
              ).compareTo(
                nearestOwnAnchorDistance(
                  view,
                  HexCoordinate(col: b.col, row: b.row),
                ),
              );
          if (distanceCompare != 0) return distanceCompare;
          return a.id.compareTo(b.id);
        });
    return units.isEmpty ? null : units.first;
  }

  static int? nearestRememberedEnemyCityDistance(GameView view) {
    int? nearest;
    for (final city in view.rememberedTargetableEnemyCities) {
      final distance = nearestExpansionAnchorDistance(
        view,
        city.center.toCoordinate(),
      );
      if (nearest == null || distance < nearest) nearest = distance;
    }
    return nearest;
  }

  static int nearestExpansionAnchorDistance(
    GameView view,
    HexCoordinate target,
  ) {
    final anchors = <HexCoordinate>[
      for (final city in view.ownCities) city.center.toCoordinate(),
      for (final unit in view.ownUnits)
        if (CityFoundingRules.canFoundCityWith(unit) &&
            !unit.isWorking &&
            unit.queuedPath == null)
          HexCoordinate(col: unit.col, row: unit.row),
    ];
    return _nearestDistance(anchors, target);
  }

  static int nearestOwnAnchorDistance(GameView view, HexCoordinate target) {
    final anchors = <HexCoordinate>[
      for (final city in view.ownCities) city.center.toCoordinate(),
      for (final unit in view.ownUnits)
        HexCoordinate(col: unit.col, row: unit.row),
    ];
    return _nearestDistance(anchors, target);
  }

  static HexCoordinate? _defenseAnchorFor(GameView view, String playerId) {
    final visibleThreat = nearestVisibleUnitFor(view, playerId);
    final threatAnchor = visibleThreat == null
        ? nearestRememberedCityFor(view, playerId)?.center.toCoordinate()
        : HexCoordinate(col: visibleThreat.col, row: visibleThreat.row);

    if (view.ownCities.isNotEmpty) {
      final cities = [...view.ownCities]
        ..sort((a, b) {
          final distanceCompare =
              _distanceFromAnchor(
                a.center.toCoordinate(),
                threatAnchor,
              ).compareTo(
                _distanceFromAnchor(b.center.toCoordinate(), threatAnchor),
              );
          if (distanceCompare != 0) return distanceCompare;
          return a.id.compareTo(b.id);
        });
      return cities.first.center.toCoordinate();
    }

    final units = [...view.ownUnits]
      ..sort((a, b) {
        final aCoordinate = HexCoordinate(col: a.col, row: a.row);
        final bCoordinate = HexCoordinate(col: b.col, row: b.row);
        final distanceCompare = _distanceFromAnchor(
          aCoordinate,
          threatAnchor,
        ).compareTo(_distanceFromAnchor(bCoordinate, threatAnchor));
        if (distanceCompare != 0) return distanceCompare;
        return a.id.compareTo(b.id);
      });
    if (units.isEmpty) return null;
    return HexCoordinate(col: units.first.col, row: units.first.row);
  }

  static int _nearestDistance(
    Iterable<HexCoordinate> anchors,
    HexCoordinate target,
  ) {
    var nearest = 99;
    for (final anchor in anchors) {
      final distance = HexDistance.between(anchor, target);
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  static int _distanceFromAnchor(HexCoordinate source, HexCoordinate? target) {
    if (target == null) return 0;
    return HexDistance.between(source, target);
  }
}
