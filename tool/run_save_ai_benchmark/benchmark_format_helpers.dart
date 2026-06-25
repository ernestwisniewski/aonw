part of '../run_save_ai_benchmark.dart';

String _hexLabel(HexCoordinate hex) => '${hex.col},${hex.row}';

String _warGoalSummary(WarGoal goal) {
  return '${goal.kind.name}:${goal.targetPlayerId}@${_hexLabel(goal.targetHex)}'
      '#${goal.assignedUnitIds.length}';
}

Set<String> _defenseAssignedUnitIds(StrategicPlan plan) {
  return {
    for (final defense in plan.defenses.values) ...defense.assignedUnitIds,
  };
}

String _formatMetrics(Map<String, Object?> metrics) {
  final entries = metrics.entries.take(8).map((entry) {
    final value = entry.value;
    if (value is double) return '${entry.key}=${value.toStringAsFixed(2)}';
    return '${entry.key}=$value';
  });
  return entries.join(', ');
}

Map<String, int> _sortedIntMap(Map<String, int> values) {
  final entries = values.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return {for (final entry in entries) entry.key: entry.value};
}

String _formatIntMap(Map<String, int> values) {
  if (values.isEmpty) return 'none';
  return values.entries
      .map((entry) => '${entry.key}=${entry.value}')
      .join(', ');
}
