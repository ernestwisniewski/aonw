part of 'server_command_reducer.dart';

final class ServerCommandReduction {
  ServerCommandReduction({
    required this.accepted,
    this.nextSnapshot,
    Iterable<GameEvent> events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    this.outcome,
    this.reason,
  }) : events = _ownedList(events),
       movementExecutions = _ownedList(movementExecutions),
       assert(
         !accepted || (nextSnapshot != null && outcome != null),
         'Accepted reductions must expose their canonical result.',
       );

  final bool accepted;
  final CanonicalGameSnapshot? nextSnapshot;
  final List<GameEvent> events;
  final List<MovementCommandExecution> movementExecutions;
  final GameOutcome? outcome;
  final String? reason;
}

List<T> _ownedList<T>(Iterable<T> values) => List<T>.unmodifiable(values);

extension _ServerCommandReducerOutcome on ServerCommandReducer {
  ServerCommandReduction _acceptedReduction({
    required WireMatch match,
    required _CommandApplication result,
    required MapReadView mapView,
  }) {
    final nextSnapshot = result.snapshot;
    return ServerCommandReduction(
      accepted: true,
      nextSnapshot: nextSnapshot,
      events: result.events,
      movementExecutions: result.movementExecutions,
      outcome: _gameOutcome(
        match: match,
        domain: nextSnapshot.domain,
        session: nextSnapshot.session,
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

  ServerCommandReduction _reject(String reason) {
    return ServerCommandReduction(accepted: false, reason: reason);
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
