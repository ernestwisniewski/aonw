import 'package:aonw_core/ai/ai_context.dart';
import 'package:aonw_core/ai/game_view.dart';
import 'package:aonw_core/ai/strategic/war_front.dart';
import 'package:aonw_core/ai/strategic/war_goal.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';

final class MctsCombatCandidateCollector {
  const MctsCombatCandidateCollector();

  Iterable<GameCommand> priorityCommandsFor(GameView view, AiContext context) {
    final priorityTargetPlayerIds = _priorityTargetPlayerIds(view, context);
    if (priorityTargetPlayerIds.isEmpty) return const [];

    final enemies = _sortedEnemyUnits(
      view,
      include: (enemy) {
        final blockerHex = HexCoordinate(col: enemy.col, row: enemy.row);
        return priorityTargetPlayerIds.contains(enemy.ownerPlayerId) ||
            isOffensiveWarFrontBlocker(
              view: view,
              plan: context.strategicPlan,
              blockerHex: blockerHex,
            );
      },
    );
    final cities = _sortedEnemyCities(
      view,
      include: (city) => priorityTargetPlayerIds.contains(city.ownerPlayerId),
    );

    return _commandsForTargets(view, enemies: enemies, cities: cities);
  }

  Iterable<GameCommand> commandsFor(GameView view) {
    if (view.visibleTargetableEnemyUnits.isEmpty &&
        view.rememberedTargetableEnemyCities.isEmpty) {
      return const [];
    }

    return _commandsForTargets(
      view,
      enemies: _sortedEnemyUnits(view, include: (_) => true),
      cities: _sortedEnemyCities(view, include: (_) => true),
    );
  }

  Iterable<GameCommand> _commandsForTargets(
    GameView view, {
    required List<GameUnit> enemies,
    required List<GameCity> cities,
  }) sync* {
    if (enemies.isEmpty && cities.isEmpty) return;

    final units = [...view.ownUnits]..sort((a, b) => a.id.compareTo(b.id));
    for (final unit in units) {
      if (!unit.isReadyToAct) continue;
      final stats = UnitCombatStats.derive(unit, ruleset: view.ruleset.combat);
      if (stats.attack <= 0) continue;
      final origin = HexCoordinate(col: unit.col, row: unit.row);

      for (final enemy in enemies) {
        final target = HexCoordinate(col: enemy.col, row: enemy.row);
        if (HexDistance.between(origin, target) > stats.range) continue;
        yield AttackHexCommand(unit.id, enemy.col, enemy.row);
      }

      for (final city in cities) {
        final target = city.center.toCoordinate();
        if (HexDistance.between(origin, target) > stats.range) continue;
        yield AttackHexCommand(unit.id, city.center.col, city.center.row);
      }
    }
  }

  Set<String> _priorityTargetPlayerIds(GameView view, AiContext context) {
    return <String>{
      ...view.activeHostilePlayerIds,
      ...view.pressureTargetPlayerIds,
      for (final goal in context.strategicPlan?.warGoals ?? const <WarGoal>[])
        if (goal.kind != WarGoalKind.defend) goal.targetPlayerId,
    };
  }

  List<GameUnit> _sortedEnemyUnits(
    GameView view, {
    required bool Function(GameUnit enemy) include,
  }) {
    return [
      for (final enemy in view.visibleTargetableEnemyUnits)
        if (include(enemy)) enemy,
    ]..sort((a, b) {
      final col = a.col.compareTo(b.col);
      if (col != 0) return col;
      final row = a.row.compareTo(b.row);
      if (row != 0) return row;
      return a.id.compareTo(b.id);
    });
  }

  List<GameCity> _sortedEnemyCities(
    GameView view, {
    required bool Function(GameCity city) include,
  }) {
    return [
      for (final city in view.rememberedTargetableEnemyCities)
        if (include(city)) city,
    ]..sort((a, b) {
      final col = a.center.col.compareTo(b.center.col);
      if (col != 0) return col;
      final row = a.center.row.compareTo(b.center.row);
      if (row != 0) return row;
      return a.id.compareTo(b.id);
    });
  }
}
