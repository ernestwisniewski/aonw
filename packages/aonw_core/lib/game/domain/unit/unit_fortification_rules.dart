import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_balance.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_data.dart';

abstract final class UnitFortificationRules {
  static const int healingPerTurn = 1;

  static bool canHeal(
    GameUnit unit, {
    CombatRuleset ruleset = CombatRuleset.standard,
  }) {
    final stats = UnitCombatStats.derive(unit, ruleset: ruleset);
    if (stats.hp <= 0) return false;
    return UnitCombatHealth.currentHp(unit, effectiveStats: stats) < stats.hp;
  }

  static GameUnit fortify(GameUnit unit) {
    return unit
        .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
        .copyWithQueuedPath(null);
  }

  static GameUnit recoverForNewTurn({
    required GameUnit unit,
    MapData? mapData,
    Iterable<GameUnit>? units,
    FogRevealCalculator revealCalculator = const FogRevealCalculator(),
  }) {
    if (!unit.isFortified) return unit;

    if (!canHeal(unit)) {
      if (mapData == null || units == null) {
        return unit.copyWith(movementPoints: 0).copyWithQueuedPath(null);
      }
      if (!hasVisibleEnemy(
        unit: unit,
        mapData: mapData,
        units: units,
        revealCalculator: revealCalculator,
      )) {
        return unit.copyWith(movementPoints: 0).copyWithQueuedPath(null);
      }
      return unit
          .copyWith(
            movementPoints: UnitMovementBalance.maxMovementPointsFor(
              type: unit.type,
              carriedArtifactId: unit.carriedArtifactId,
            ),
            posture: UnitPosture.active,
          )
          .copyWithQueuedPath(null);
    }

    final healed = heal(unit, amount: healingPerTurn);
    return healed
        .copyWith(movementPoints: 0, posture: UnitPosture.fortified)
        .copyWithQueuedPath(null);
  }

  static GameUnit heal(GameUnit unit, {required int amount}) {
    if (amount <= 0 || unit.hitPoints == null) return unit;

    final stats = UnitCombatStats.derive(unit);
    final maxHp = stats.hp;
    if (maxHp <= 0) return unit.copyWithHitPoints(null);

    final currentHp = UnitCombatHealth.currentHp(unit, effectiveStats: stats);
    final nextHp = (currentHp + amount).clamp(0, maxHp).toInt();
    return nextHp >= maxHp
        ? unit.copyWithHitPoints(null)
        : unit.copyWithHitPoints(nextHp);
  }

  static bool hasVisibleEnemy({
    required GameUnit unit,
    required MapData mapData,
    required Iterable<GameUnit> units,
    FogRevealCalculator revealCalculator = const FogRevealCalculator(),
  }) {
    final source = FogOfWarService.unitRevealSource(
      playerId: unit.ownerPlayerId,
      unit: unit,
      mapData: mapData,
    );
    final visibleHexes = revealCalculator.visibleHexesFor(
      mapData: mapData,
      sources: [source],
    );
    if (visibleHexes.isEmpty) return false;

    for (final other in units) {
      if (other.id == unit.id || other.ownerPlayerId == unit.ownerPlayerId) {
        continue;
      }
      if (visibleHexes.contains(
        HexCoordinate(col: other.col, row: other.row),
      )) {
        return true;
      }
    }
    return false;
  }
}
