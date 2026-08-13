import 'package:aonw_core/game/domain/movement/movement_point_scale.dart';

/// Migrates persisted movement values from whole points to fixed-point units.
///
/// Unit balances remain encoded as visible whole points plus an optional
/// subpoint. Only values that historically represented route costs or a
/// pending movement balance need to be scaled.
abstract final class MovementSnapshotMigration {
  static Map<String, dynamic> fromWholePointCosts(Map<String, dynamic> state) {
    final migrated = Map<String, dynamic>.from(state);
    final units = state['units'];
    if (units is List) {
      migrated['units'] = [for (final unit in units) _migrateUnit(unit)];
    }

    final lifecycle = state['lifecycle'];
    if (lifecycle is Map) {
      final migratedLifecycle = Map<String, dynamic>.from(lifecycle);
      final pending = lifecycle['pendingAction'];
      if (pending is Map) {
        migratedLifecycle['pendingAction'] = _migratePendingAction(pending);
      }
      migrated['lifecycle'] = migratedLifecycle;
    }
    return migrated;
  }

  static Object? _migrateUnit(Object? value) {
    if (value is! Map) return value;
    final unit = Map<String, dynamic>.from(value);
    for (final field in const ['queuedPath', 'merchantTradeRoute']) {
      final route = value[field];
      if (route is Map) unit[field] = _migrateRoute(route);
    }
    return unit;
  }

  static Map<String, dynamic> _migrateRoute(Map<dynamic, dynamic> value) {
    final route = Map<String, dynamic>.from(value);
    final steps = value['steps'];
    if (steps is List) {
      route['steps'] = [for (final step in steps) _migrateStep(step)];
    }
    return route;
  }

  static Object? _migrateStep(Object? value) {
    if (value is! Map) return value;
    final step = Map<String, dynamic>.from(value);
    for (final field in const ['enterCost', 'cumulativeCost']) {
      final cost = value[field];
      if (cost is num) {
        step[field] = MovementPointScale.unitsFromWholePoints(cost.toInt());
      }
    }
    return step;
  }

  static Map<String, dynamic> _migratePendingAction(
    Map<dynamic, dynamic> value,
  ) {
    final pending = Map<String, dynamic>.from(value);
    final points = value['restoreMovementPoints'];
    if (pending['restoreMovementUnits'] == null && points is num) {
      pending
        ..remove('restoreMovementPoints')
        ..['restoreMovementUnits'] = MovementPointScale.unitsFromWholePoints(
          points.toInt(),
        );
    }
    return pending;
  }
}
