part of 'economy_simulation.dart';

final class _EconomySimulationHostilityMemory {
  static const _memoryTurns = 4;

  final Map<String, Map<String, int>> _byPlayerId = {};

  Set<String> recentFor({required String playerId, required int turn}) {
    final hostiles = _byPlayerId[playerId];
    if (hostiles == null || hostiles.isEmpty) return const {};

    final active = <String>{};
    final stale = <String>[];
    for (final entry in hostiles.entries) {
      if (turn - entry.value <= _memoryTurns) {
        active.add(entry.key);
      } else {
        stale.add(entry.key);
      }
    }
    for (final hostilePlayerId in stale) {
      hostiles.remove(hostilePlayerId);
    }
    return active;
  }

  void record({required Iterable<GameEvent> events, required int turn}) {
    for (final event in events) {
      final descriptor = GameEventDomainDescriptor.forEvent(event);
      for (final hostility in descriptor.hostilities) {
        _mark(
          victimPlayerId: hostility.victimPlayerId,
          hostilePlayerId: hostility.hostilePlayerId,
          turn: turn,
        );
      }
    }
  }

  void _mark({
    required String victimPlayerId,
    required String hostilePlayerId,
    required int turn,
  }) {
    if (victimPlayerId == hostilePlayerId) return;
    (_byPlayerId[victimPlayerId] ??= {})[hostilePlayerId] = turn;
  }
}
