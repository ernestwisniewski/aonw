part of 'defensive_stance_planner.dart';

class _DefenseThreatProfileCollector {
  const _DefenseThreatProfileCollector({required this.threatRange});

  final int threatRange;

  List<_CityThreatProfile> collect({
    required GameView view,
    required AiContext context,
    required List<PlayerThreatScore> threats,
  }) {
    final threatScoreByPlayer = {
      for (final threat in threats) threat.playerId: threat.score,
    };
    final threatenedByVisibleEnemies = [
      for (final city in view.ownCities)
        _visibleThreatProfileForCity(
          city: city,
          view: view,
          context: context,
          threatScoreByPlayer: threatScoreByPlayer,
        ),
    ].nonNulls.toList();
    final existingProfiles = _mergeThreatProfiles([
      ..._pendingCityAttackProfiles(view),
      ...threatenedByVisibleEnemies,
    ]);
    final recentHostilityProfiles = _recentHostilityProfiles(
      view: view,
      threats: threats,
      existingCityIds: {
        for (final profile in existingProfiles) profile.city.id,
      },
    );
    return [...existingProfiles, ...recentHostilityProfiles]
      ..sort(_compareThreatProfiles);
  }

  List<_CityThreatProfile> _pendingCityAttackProfiles(GameView view) {
    if (view.pendingCityAttackThreats.isEmpty) return const [];
    final cityById = {for (final city in view.ownCities) city.id: city};
    final scoreByCityId = <String, int>{};
    final primaryPlayerByCityId = <String, String>{};

    for (final threat in view.pendingCityAttackThreats) {
      final city = cityById[threat.cityId];
      if (city == null) continue;
      final attackerDistance = HexDistance.between(
        city.center.toCoordinate(),
        threat.attackerHex,
      );
      final threatLevel = (28 + (3 - attackerDistance).clamp(0, 3) * 4)
          .clamp(24, 40)
          .toInt();
      final current = scoreByCityId[city.id] ?? 0;
      if (threatLevel > current) {
        scoreByCityId[city.id] = threatLevel;
        primaryPlayerByCityId[city.id] = threat.attackerPlayerId;
      }
    }

    return [
      for (final entry in scoreByCityId.entries)
        _CityThreatProfile(
          city: cityById[entry.key]!,
          threatLevel: entry.value,
          primaryThreatPlayerId: primaryPlayerByCityId[entry.key] ?? '',
          urgent: true,
        ),
    ];
  }

  List<_CityThreatProfile> _recentHostilityProfiles({
    required GameView view,
    required List<PlayerThreatScore> threats,
    required Set<String> existingCityIds,
  }) {
    if (view.ownCities.isEmpty) return const [];
    final recentThreats =
        [
          for (final threat in threats)
            if (threat.rival.recentlyHostile) threat,
        ]..sort((a, b) {
          final scoreCompare = b.score.compareTo(a.score);
          if (scoreCompare != 0) return scoreCompare;
          return a.playerId.compareTo(b.playerId);
        });
    if (recentThreats.isEmpty) return const [];

    final profiles = <_CityThreatProfile>[];
    final usedCityIds = {...existingCityIds};
    for (final threat in recentThreats.take(2)) {
      final city = _defenseAnchorCityFor(view, threat.rival);
      if (city == null || !usedCityIds.add(city.id)) continue;
      profiles.add(
        _CityThreatProfile(
          city: city,
          threatLevel: _recentHostilityThreatLevel(threat),
          primaryThreatPlayerId: threat.playerId,
        ),
      );
    }
    return profiles;
  }

  List<_CityThreatProfile> _mergeThreatProfiles(
    Iterable<_CityThreatProfile> profiles,
  ) {
    final byCityId = <String, _CityThreatProfile>{};
    for (final profile in profiles) {
      final existing = byCityId[profile.city.id];
      if (_profileOutranksExisting(profile, existing)) {
        byCityId[profile.city.id] = profile;
      }
    }
    return byCityId.values.toList(growable: false);
  }

  bool _profileOutranksExisting(
    _CityThreatProfile profile,
    _CityThreatProfile? existing,
  ) {
    if (existing == null) return true;
    if (profile.threatLevel != existing.threatLevel) {
      return profile.threatLevel > existing.threatLevel;
    }
    if (profile.urgent != existing.urgent) return profile.urgent;
    return profile.primaryThreatPlayerId.compareTo(
          existing.primaryThreatPlayerId,
        ) <
        0;
  }

  GameCity? _defenseAnchorCityFor(GameView view, RivalSnapshot rival) {
    if (view.ownCities.isEmpty) return null;
    final threatAnchor = _visibleThreatAnchorFor(view, rival.playerId);
    final cities = [...view.ownCities]
      ..sort((a, b) {
        final distanceCompare = _distanceFromAnchor(
          a.center.toCoordinate(),
          threatAnchor,
        ).compareTo(_distanceFromAnchor(b.center.toCoordinate(), threatAnchor));
        if (distanceCompare != 0) return distanceCompare;
        return a.id.compareTo(b.id);
      });
    return cities.first;
  }

  HexCoordinate? _visibleThreatAnchorFor(GameView view, String playerId) {
    final enemyUnits =
        [
          for (final unit in view.visibleEnemyUnits)
            if (unit.ownerPlayerId == playerId &&
                view.canTargetPlayer(unit.ownerPlayerId))
              unit,
        ]..sort((a, b) {
          final distanceCompare =
              _nearestOwnCityDistance(
                view,
                HexCoordinate(col: a.col, row: a.row),
              ).compareTo(
                _nearestOwnCityDistance(
                  view,
                  HexCoordinate(col: b.col, row: b.row),
                ),
              );
          if (distanceCompare != 0) return distanceCompare;
          return a.id.compareTo(b.id);
        });
    if (enemyUnits.isEmpty) return null;
    return HexCoordinate(col: enemyUnits.first.col, row: enemyUnits.first.row);
  }

  int _recentHostilityThreatLevel(PlayerThreatScore threat) {
    final score = (6 + threat.score * 4).ceil();
    return score.clamp(6, 18).toInt();
  }

  _CityThreatProfile? _visibleThreatProfileForCity({
    required GameCity city,
    required GameView view,
    required AiContext context,
    required Map<String, double> threatScoreByPlayer,
  }) {
    final cityCenter = city.center.toCoordinate();
    final scoreByPlayer = <String, double>{};
    var totalScore = 0.0;

    for (final enemy in view.visibleTargetableEnemyUnits) {
      if (!_isMilitaryUnit(enemy, context.ruleset.combat)) continue;
      final distance = HexDistance.between(
        cityCenter,
        HexCoordinate(col: enemy.col, row: enemy.row),
      );
      if (distance > threatRange) continue;

      final score = _visibleEnemyThreatScore(
        enemy: enemy,
        context: context,
        distance: distance,
        threatScoreByPlayer: threatScoreByPlayer,
      );
      totalScore += score;
      scoreByPlayer[enemy.ownerPlayerId] =
          (scoreByPlayer[enemy.ownerPlayerId] ?? 0.0) + score;
    }

    if (totalScore <= 0) return null;
    return _CityThreatProfile(
      city: city,
      threatLevel: totalScore.ceil(),
      primaryThreatPlayerId: _primaryThreatPlayer(scoreByPlayer),
    );
  }

  double _visibleEnemyThreatScore({
    required GameUnit enemy,
    required AiContext context,
    required int distance,
    required Map<String, double> threatScoreByPlayer,
  }) {
    final stats = UnitCombatStats.derive(
      enemy,
      ruleset: context.ruleset.combat,
    );
    final power = math.max(
      1.0,
      stats.attack * 0.45 + stats.defense * 0.25 + stats.range * 0.35,
    );
    final proximity = (threatRange + 1 - distance).toDouble();
    final strategicThreat = (threatScoreByPlayer[enemy.ownerPlayerId] ?? 0.0)
        .clamp(0.0, 4.0)
        .toDouble();
    return power * proximity * (1.0 + strategicThreat * 0.12);
  }

  String _primaryThreatPlayer(Map<String, double> scoreByPlayer) {
    final primaryThreat = scoreByPlayer.entries.toList()
      ..sort((a, b) {
        final scoreCompare = b.value.compareTo(a.value);
        if (scoreCompare != 0) return scoreCompare;
        return a.key.compareTo(b.key);
      });
    return primaryThreat.first.key;
  }

  int _nearestOwnCityDistance(GameView view, HexCoordinate target) {
    if (view.ownCities.isEmpty) return 99;
    var nearest = 99;
    for (final city in view.ownCities) {
      final distance = HexDistance.between(city.center.toCoordinate(), target);
      if (distance < nearest) nearest = distance;
    }
    return nearest;
  }

  int _distanceFromAnchor(HexCoordinate source, HexCoordinate? target) {
    if (target == null) return 0;
    return HexDistance.between(source, target);
  }

  int _compareThreatProfiles(_CityThreatProfile a, _CityThreatProfile b) {
    final threatCompare = b.threatLevel.compareTo(a.threatLevel);
    if (threatCompare != 0) return threatCompare;
    return a.city.id.compareTo(b.city.id);
  }
}

class _CityThreatProfile {
  final GameCity city;
  final int threatLevel;
  final String primaryThreatPlayerId;
  final bool urgent;

  const _CityThreatProfile({
    required this.city,
    required this.threatLevel,
    required this.primaryThreatPlayerId,
    this.urgent = false,
  });
}
