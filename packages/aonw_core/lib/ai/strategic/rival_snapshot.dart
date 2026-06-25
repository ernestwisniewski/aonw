import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

class RivalSnapshot {
  final String playerId;
  final int rememberedCityCount;
  final int visibleUnitCount;
  final int visibleMilitaryCount;
  final double militaryPower;
  final int nearestDistance;
  final bool isHostile;
  final bool recentlyHostile;

  const RivalSnapshot({
    required this.playerId,
    required this.rememberedCityCount,
    required this.visibleUnitCount,
    required this.visibleMilitaryCount,
    required this.militaryPower,
    required this.nearestDistance,
    required this.isHostile,
    this.recentlyHostile = false,
  });

  static List<RivalSnapshot> fromView(GameView view) {
    final discoveredPlayerIds = <String>{
      for (final city in view.rememberedTargetableEnemyCities)
        city.ownerPlayerId,
      for (final unit in view.visibleTargetableEnemyUnits) unit.ownerPlayerId,
      ...view.activeHostilePlayerIds,
      ...view.recentHostilePlayerIds,
      ...view.pressureTargetPlayerIds,
      for (final threat in view.pendingCityAttackThreats)
        threat.attackerPlayerId,
    };
    final playerIds = {
      for (final playerId in discoveredPlayerIds)
        if (view.canTargetPlayer(playerId)) playerId,
    };
    final snapshots = [
      for (final playerId in playerIds)
        RivalSnapshot(
          playerId: playerId,
          rememberedCityCount: view.rememberedTargetableEnemyCities
              .where((city) => city.ownerPlayerId == playerId)
              .length,
          visibleUnitCount: view.visibleTargetableEnemyUnits
              .where((unit) => unit.ownerPlayerId == playerId)
              .length,
          visibleMilitaryCount: _visibleMilitaryCount(view, playerId),
          militaryPower: _militaryPower(view, playerId),
          nearestDistance: _nearestDistance(view, playerId),
          isHostile:
              _isDiplomaticallyHostile(view, playerId) ||
              view.activeHostilePlayerIds.contains(playerId) ||
              _isHostile(view, playerId) ||
              view.recentHostilePlayerIds.contains(playerId),
          recentlyHostile: view.recentHostilePlayerIds.contains(playerId),
        ),
    ]..sort((a, b) => a.playerId.compareTo(b.playerId));
    return List.unmodifiable(snapshots);
  }

  @override
  bool operator ==(Object other) {
    return other is RivalSnapshot &&
        other.playerId == playerId &&
        other.rememberedCityCount == rememberedCityCount &&
        other.visibleUnitCount == visibleUnitCount &&
        other.visibleMilitaryCount == visibleMilitaryCount &&
        other.militaryPower == militaryPower &&
        other.nearestDistance == nearestDistance &&
        other.isHostile == isHostile &&
        other.recentlyHostile == recentlyHostile;
  }

  @override
  int get hashCode {
    return Object.hash(
      playerId,
      rememberedCityCount,
      visibleUnitCount,
      visibleMilitaryCount,
      militaryPower,
      nearestDistance,
      isHostile,
      recentlyHostile,
    );
  }
}

int _visibleMilitaryCount(GameView view, String playerId) {
  return view.visibleTargetableEnemyUnits
      .where(
        (unit) =>
            unit.ownerPlayerId == playerId &&
            _isMilitaryUnit(unit, view.ruleset.combat),
      )
      .length;
}

double _militaryPower(GameView view, String playerId) {
  var power = 0.0;
  for (final unit in view.visibleTargetableEnemyUnits) {
    if (unit.ownerPlayerId != playerId) continue;
    final stats = UnitCombatStats.derive(unit, ruleset: view.ruleset.combat);
    if (stats.attack <= 0 && stats.defense <= 0) continue;
    power += stats.attack * 0.7 + stats.defense * 0.5 + stats.range * 0.4;
  }
  return power;
}

int _nearestDistance(GameView view, String playerId) {
  final ownAnchors = <HexCoordinate>[
    for (final city in view.ownCities) city.center.toCoordinate(),
    for (final unit in view.ownUnits)
      HexCoordinate(col: unit.col, row: unit.row),
  ];
  final rivalAnchors = <HexCoordinate>[
    for (final city in view.rememberedTargetableEnemyCities)
      if (city.ownerPlayerId == playerId) city.center.toCoordinate(),
    for (final unit in view.visibleTargetableEnemyUnits)
      if (unit.ownerPlayerId == playerId)
        HexCoordinate(col: unit.col, row: unit.row),
  ];
  if (ownAnchors.isEmpty || rivalAnchors.isEmpty) return 99;

  var nearest = 99;
  for (final own in ownAnchors) {
    for (final rival in rivalAnchors) {
      final distance = HexDistance.between(own, rival);
      if (distance < nearest) nearest = distance;
    }
  }
  return nearest;
}

bool _isDiplomaticallyHostile(GameView view, String playerId) {
  final status = view.relationStatusFor(playerId);
  return status == DiplomaticRelationStatus.hostile ||
      status == DiplomaticRelationStatus.war;
}

bool _isHostile(GameView view, String playerId) {
  if (!view.canTargetPlayer(playerId)) return false;
  return view.visibleTargetableEnemyUnits.any(
    (unit) =>
        unit.ownerPlayerId == playerId &&
        _isMilitaryUnit(unit, view.ruleset.combat) &&
        _nearestDistance(view, playerId) <= 3,
  );
}

bool _isMilitaryUnit(GameUnit unit, CombatRuleset ruleset) {
  final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
  return stats.attack > 0 || stats.defense > 0;
}
