part of 'server_command_reducer.dart';

class ServerCommandReduction {
  const ServerCommandReduction({
    required this.accepted,
    required this.snapshot,
    this.events = const [],
    this.turn,
    this.previousState,
    this.state,
    this.outcome,
    this.reason,
  }) : assert(
         !accepted ||
             (turn != null &&
                 previousState != null &&
                 state != null &&
                 outcome != null),
         'Accepted reductions must expose their decoded transition.',
       );

  final bool accepted;
  final WireSnapshot snapshot;
  final List<GameEvent> events;
  final int? turn;
  final PersistentGameState? previousState;
  final PersistentGameState? state;
  final GameOutcome? outcome;
  final String? reason;
}

extension _ServerCommandReducerOutcome on ServerCommandReducer {
  GameOutcome _gameOutcome({
    required WireMatch match,
    required GameSave save,
    required PersistentGameState state,
    required MapReadView mapView,
  }) {
    final kickedPlayerIds = state.runtimeState.kickedPlayerIds;
    return const GameOutcomeDetector().evaluate(
      playerIds: match.players
          .map((player) => player.id)
          .where((playerId) => !kickedPlayerIds.contains(playerId)),
      state: state,
      matchRules: save.matchRules,
      mapData: mapView,
      turn: save.turn,
    );
  }
}
