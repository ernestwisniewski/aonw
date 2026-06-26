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
      switch (event) {
        case UnitAttackedEvent(
          :final attackerOwnerPlayerId,
          :final defenderOwnerPlayerId,
        ):
          _mark(
            victimPlayerId: defenderOwnerPlayerId,
            hostilePlayerId: attackerOwnerPlayerId,
            turn: turn,
          );
        case CityCapturedEvent(
          :final previousOwnerPlayerId,
          :final newOwnerPlayerId,
        ):
          _mark(
            victimPlayerId: previousOwnerPlayerId,
            hostilePlayerId: newOwnerPlayerId,
            turn: turn,
          );
        case CityDestroyedEvent(
          :final previousOwnerPlayerId,
          :final attackerOwnerPlayerId,
        ):
          _mark(
            victimPlayerId: previousOwnerPlayerId,
            hostilePlayerId: attackerOwnerPlayerId,
            turn: turn,
          );
        case DiplomaticRelationChangedEvent(
          :final playerAId,
          :final playerBId,
          :final newStatus,
        ):
          if (newStatus == DiplomaticRelationStatus.war) {
            _mark(
              victimPlayerId: playerAId,
              hostilePlayerId: playerBId,
              turn: turn,
            );
            _mark(
              victimPlayerId: playerBId,
              hostilePlayerId: playerAId,
              turn: turn,
            );
          }
        default:
          break;
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
