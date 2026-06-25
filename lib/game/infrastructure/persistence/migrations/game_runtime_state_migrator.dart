import 'package:aonw/game/domain/city.dart';

abstract final class GameRuntimeStateMigrator {
  static const _pendingActionTypes = {
    'cityWorkedHexSelection',
    'cityExpansionSelection',
    'workerActionSelection',
    'attackTargeting',
    'commanderMergeSelection',
    'researchSelection',
  };

  static final _fieldImprovementTypes = FieldImprovementType.values
      .map((type) => type.name)
      .toSet();

  static Map<String, dynamic> migrate(Map<String, dynamic>? json) {
    final migrated = Map<String, dynamic>.from(json ?? const {});
    _migratePendingAction(migrated);
    _migrateSubmittedPlayerIds(migrated);
    _migrateIntendedAttacks(migrated);
    _migrateDiplomacy(migrated);
    _migrateTurnStartedAt(migrated);
    return migrated;
  }

  static void _migratePendingAction(Map<String, dynamic> runtimeState) {
    final pendingAction = runtimeState['pendingAction'];
    if (pendingAction == null) return;
    if (pendingAction is! Map) {
      runtimeState.remove('pendingAction');
      return;
    }

    final action = Map<String, dynamic>.from(pendingAction);
    final type = action['type'];
    if (type is! String || !_pendingActionTypes.contains(type)) {
      runtimeState.remove('pendingAction');
      return;
    }

    if (type == 'workerActionSelection') {
      _migrateWorkerActionSelection(action);
    }
    runtimeState['pendingAction'] = action;
  }

  static void _migrateWorkerActionSelection(Map<String, dynamic> action) {
    final improvementType = action['improvementType'];
    if (improvementType == null) return;
    if (improvementType is String &&
        _fieldImprovementTypes.contains(improvementType)) {
      return;
    }
    action.remove('improvementType');
  }

  static void _migrateSubmittedPlayerIds(Map<String, dynamic> runtimeState) {
    final submitted = runtimeState['submittedPlayerIds'];
    if (submitted == null) return;
    if (submitted is! List) {
      runtimeState.remove('submittedPlayerIds');
      return;
    }

    runtimeState['submittedPlayerIds'] = [
      for (final playerId in submitted)
        if (playerId is String && playerId.isNotEmpty) playerId,
    ];
  }

  static void _migrateIntendedAttacks(Map<String, dynamic> runtimeState) {
    final attacks = runtimeState['intendedAttacks'];
    if (attacks == null) return;
    if (attacks is! List) {
      runtimeState.remove('intendedAttacks');
      return;
    }

    runtimeState['intendedAttacks'] = [
      for (final attack in attacks)
        if (attack is Map && _isValidIntendedAttack(attack))
          Map<String, dynamic>.from(attack),
    ];
  }

  static bool _isValidIntendedAttack(Map<Object?, Object?> attack) {
    return attack['attackerUnitId'] is String &&
        (attack['attackerUnitId'] as String).isNotEmpty &&
        attack['defenderCol'] is int &&
        attack['defenderRow'] is int &&
        attack['declaredAtTick'] is int &&
        attack['declaringPlayerId'] is String &&
        (attack['declaringPlayerId'] as String).isNotEmpty;
  }

  static void _migrateDiplomacy(Map<String, dynamic> runtimeState) {
    final diplomacy = runtimeState['diplomacy'];
    if (diplomacy == null) return;
    if (diplomacy is! Map) {
      runtimeState.remove('diplomacy');
      return;
    }
    runtimeState['diplomacy'] = Map<String, dynamic>.from(diplomacy);
  }

  static void _migrateTurnStartedAt(Map<String, dynamic> runtimeState) {
    final turnStartedAt = runtimeState['turnStartedAt'];
    if (turnStartedAt == null) return;
    if (turnStartedAt is String && DateTime.tryParse(turnStartedAt) != null) {
      return;
    }
    runtimeState.remove('turnStartedAt');
  }
}
