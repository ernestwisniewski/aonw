import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/event.dart';

/// Explicit compatibility boundary for replay rows written before combat
/// animation facts were persisted or recomputed by the replay engine.
abstract final class HistoricalCombatAnimationFactUpcaster {
  static List<CombatAnimationFact> fromEvents({
    required Iterable<GameEvent> events,
    required GameState state,
    required GameState? previousState,
  }) {
    final orderedEvents = events.toList(growable: false);
    final before = previousState ?? state;
    return [
      for (var index = 0; index < orderedEvents.length; index++)
        if (orderedEvents[index] case final CombatResolvedEvent event)
          ?_fact(before, state, event, index),
    ];
  }

  static CombatAnimationFact? _fact(
    GameState before,
    GameState state,
    CombatResolvedEvent event,
    int eventIndex,
  ) {
    final attacker =
        before.unitById(event.attackerUnitId) ??
        state.unitById(event.attackerUnitId);
    final defender =
        before.unitById(event.defenderUnitId) ??
        state.unitById(event.defenderUnitId);
    final city =
        before.cityById(event.defenderUnitId) ??
        state.cityById(event.defenderUnitId);
    if (attacker == null || defender == null && city == null) return null;
    return CombatAnimationFact(
      eventIndex: eventIndex,
      attackerUnitId: event.attackerUnitId,
      defenderId: event.defenderUnitId,
      attackerFromCol: attacker.col,
      attackerFromRow: attacker.row,
      attackerToCol: defender?.col ?? city!.center.col,
      attackerToRow: defender?.row ?? city!.center.row,
    );
  }
}
