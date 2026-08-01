import 'package:aonw_core/application.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/ruleset.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

final class SimulationGameEngineResult {
  const SimulationGameEngineResult({
    required this.accepted,
    required this.state,
    required this.snapshot,
    this.events = const [],
    this.reason,
  });

  final bool accepted;
  final DomainState state;
  final CanonicalGameSnapshot snapshot;
  final List<GameEvent> events;
  final String? reason;
}

/// Projects state-only AI simulations through the authoritative game engine.
final class SimulationGameEngineAdapter {
  const SimulationGameEngineAdapter();

  /// Finalizes one simultaneous turn exclusively through player commands
  /// handled by [GameEngine].
  ///
  /// Simulation owns the sequencing of submissions, but it does not own a
  /// second implementation of combat, economy, movement reset, or turn
  /// advancement.
  SimulationGameEngineResult finalizeSimultaneousTurn({
    required CanonicalGameSnapshot snapshot,
    required DomainState state,
    required Iterable<String> playerIds,
    required int commandTick,
    required MapReadView mapView,
    required GameRuleset ruleset,
    DateTime? savedAt,
  }) {
    final orderedPlayerIds = _orderedDistinctPlayerIds(playerIds);
    if (orderedPlayerIds.isEmpty) {
      return SimulationGameEngineResult(
        accepted: false,
        state: state,
        snapshot: snapshot,
        reason: 'turn_player_not_active',
      );
    }

    var currentState = state;
    var currentSnapshot = snapshot;
    final events = <GameEvent>[];
    for (var index = 0; index < orderedPlayerIds.length; index += 1) {
      final playerId = orderedPlayerIds[index];
      final result = apply(
        snapshot: currentSnapshot,
        state: currentState,
        command: SubmitTurnCommand(playerId),
        actorPlayerId: playerId,
        commandTick: commandTick + index,
        mapView: mapView,
        ruleset: ruleset,
        turnPlayerIds: orderedPlayerIds,
        requiredTurnSubmissionPlayerIds: orderedPlayerIds,
        savedAt: savedAt ?? snapshot.metadata.savedAtUtc,
      );
      if (!result.accepted) {
        return SimulationGameEngineResult(
          accepted: false,
          state: state,
          snapshot: snapshot,
          reason: result.reason,
        );
      }
      currentState = result.state;
      currentSnapshot = result.snapshot;
      events.addAll(result.events);
    }
    return SimulationGameEngineResult(
      accepted: true,
      state: currentState,
      snapshot: currentSnapshot,
      events: List<GameEvent>.unmodifiable(events),
    );
  }

  SimulationGameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainState state,
    required DomainCommand command,
    required String actorPlayerId,
    required int commandTick,
    required MapReadView mapView,
    required GameRuleset ruleset,
    MovementCommandVisibilityMode movementVisibilityMode =
        MovementCommandVisibilityMode.authoritative,
    CombatCommandVisibilityMode combatVisibilityMode =
        CombatCommandVisibilityMode.authoritative,
    List<String> turnPlayerIds = const [],
    List<String> requiredTurnSubmissionPlayerIds = const [],
    DateTime? savedAt,
  }) {
    final engineInput = projectSnapshot(snapshot: snapshot, state: state);
    final result = const GameEngine().apply(
      snapshot: engineInput,
      command: command,
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: mapView,
        ruleset: ruleset,
        commandTick: commandTick,
        movementVisibilityMode: movementVisibilityMode,
        combatVisibilityMode: combatVisibilityMode,
        turnPlayerIds: turnPlayerIds,
        requiredTurnSubmissionPlayerIds: requiredTurnSubmissionPlayerIds,
        savedAt: savedAt,
      ),
    );
    if (result is GameEngineRejected) {
      return SimulationGameEngineResult(
        accepted: false,
        state: state,
        snapshot: result.snapshot,
        reason: result.reason,
      );
    }
    if (identical(result.snapshot, engineInput)) {
      return SimulationGameEngineResult(
        accepted: true,
        state: state,
        snapshot: result.snapshot,
        events: result.events,
      );
    }
    return SimulationGameEngineResult(
      accepted: true,
      state: result.snapshot.domain,
      snapshot: result.snapshot,
      events: result.events,
    );
  }

  CanonicalGameSnapshot projectSnapshot({
    required CanonicalGameSnapshot snapshot,
    required DomainState state,
    int? turn,
  }) {
    final domain = turn == null ? state : state.copyWith(turn: turn);
    return snapshot.copyWith(domain: domain);
  }
}

List<String> _orderedDistinctPlayerIds(Iterable<String> values) {
  final seen = <String>{};
  return [
    for (final value in values)
      if (value.isNotEmpty && seen.add(value)) value,
  ];
}
