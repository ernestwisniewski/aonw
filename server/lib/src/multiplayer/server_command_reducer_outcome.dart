part of 'server_command_reducer.dart';

class ServerCommandReduction {
  ServerCommandReduction({
    required this.accepted,
    required this.snapshot,
    this.events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    this.turn,
    this.previousState,
    this.state,
    this.outcome,
    this.reason,
  }) : movementExecutions = _ownedList(movementExecutions),
       assert(
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
  final List<MovementCommandExecution> movementExecutions;
  final int? turn;
  final PersistentGameState? previousState;
  final PersistentGameState? state;
  final GameOutcome? outcome;
  final String? reason;
}

List<T> _ownedList<T>(Iterable<T> values) => List<T>.unmodifiable(values);

extension _ServerCommandReducerOutcome on ServerCommandReducer {
  ServerCommandReduction _acceptedReduction({
    required WireMatch match,
    required DecodedMatchSnapshot decodedSnapshot,
    required GameSave nextSave,
    required _CommandApplication result,
    required MapReadView mapView,
  }) {
    final previousState = decodedSnapshot.state;
    final canonicalSnapshot =
        result.canonicalSnapshot ??
        _canonicalSnapshot(
          save: nextSave,
          state: result.state,
          eventLogOffset: decodedSnapshot.eventLogOffset,
        );
    final nextSnapshot = _runningMatchSnapshotCodec.encode(
      decodedSnapshot,
      save: nextSave == decodedSnapshot.save ? null : nextSave,
      state: result.state == previousState ? null : result.state,
    );
    return ServerCommandReduction(
      accepted: true,
      snapshot: nextSnapshot,
      events: result.events,
      movementExecutions: result.movementExecutions,
      turn: nextSave.turn,
      previousState: previousState,
      state: result.state,
      outcome: _gameOutcome(
        match: match,
        domain: canonicalSnapshot.domain,
        session: canonicalSnapshot.session,
        mapView: mapView,
      ),
    );
  }

  GameOutcome _gameOutcome({
    required WireMatch match,
    required DomainState domain,
    required MatchSessionState session,
    required MapReadView mapView,
  }) {
    return const GameOutcomeDetector().evaluateCanonical(
      state: _reconcileOutcomeParticipants(match: match, domain: domain),
      session: session,
      mapData: mapView,
    );
  }

  ServerCommandReduction _reject(WireSnapshot snapshot, String reason) {
    return ServerCommandReduction(
      accepted: false,
      snapshot: snapshot,
      reason: reason,
    );
  }
}

DomainState _reconcileOutcomeParticipants({
  required WireMatch match,
  required DomainState domain,
}) {
  final authoritativePlayersById = <String, WirePlayer>{};
  for (final player in match.players) {
    if (player.id.isEmpty) continue;
    authoritativePlayersById.putIfAbsent(player.id, () => player);
  }
  final domainPlayersById = {
    for (final player in domain.participants) player.id: player,
  };
  final participants = [
    for (final wirePlayer in authoritativePlayersById.values)
      domainPlayersById[wirePlayer.id] ??
          InitialMultiplayerSnapshotFactory.domainPlayerFromWire(wirePlayer),
  ];
  if (_sameParticipants(domain.participants, participants)) return domain;
  return domain.copyWith(participants: participants);
}

bool _sameParticipants(List<Player> current, List<Player> reconciled) {
  if (current.length != reconciled.length) return false;
  for (var index = 0; index < current.length; index++) {
    if (!identical(current[index], reconciled[index])) return false;
  }
  return true;
}
