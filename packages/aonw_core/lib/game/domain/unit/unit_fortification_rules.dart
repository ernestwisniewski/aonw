import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

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

  static GameUnit recoverForNewTurn({required GameUnit unit}) {
    if (!unit.isFortified) return unit;

    if (!canHeal(unit)) {
      return unit.copyWith(movementPoints: 0).copyWithQueuedPath(null);
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
    required MapTileLookup mapData,
    required Iterable<GameUnit> units,
    FogRevealCalculator revealCalculator = const FogRevealCalculator(),
  }) {
    return visibleEnemies(
      unit: unit,
      mapData: mapData,
      units: units,
      revealCalculator: revealCalculator,
    ).isNotEmpty;
  }

  static List<GameUnit> visibleEnemies({
    required GameUnit unit,
    required MapTileLookup mapData,
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
    if (visibleHexes.isEmpty) return const [];

    final visibleEnemies = <GameUnit>[];
    for (final other in units) {
      if (other.id == unit.id || other.ownerPlayerId == unit.ownerPlayerId) {
        continue;
      }
      if (visibleHexes.contains(
        HexCoordinate(col: other.col, row: other.row),
      )) {
        visibleEnemies.add(other);
      }
    }
    visibleEnemies.sort((first, second) {
      final idOrder = first.id.compareTo(second.id);
      if (idOrder != 0) return idOrder;
      final colOrder = first.col.compareTo(second.col);
      return colOrder != 0 ? colOrder : first.row.compareTo(second.row);
    });
    return List.unmodifiable(visibleEnemies);
  }
}
