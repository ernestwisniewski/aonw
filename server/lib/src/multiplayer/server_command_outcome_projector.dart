import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/server_command_application.dart';
import 'package:aonw_server/src/multiplayer/wire_player_domain_mapper.dart';

final class ServerCommandReduction {
  ServerCommandReduction({
    required this.accepted,
    this.nextSnapshot,
    Iterable<GameEvent> events = const [],
    Iterable<MovementCommandExecution> movementExecutions = const [],
    Iterable<CombatAnimationFact> combatAnimations = const [],
    this.outcome,
    this.reason,
  }) : events = List.unmodifiable(events),
       movementExecutions = List.unmodifiable(movementExecutions),
       combatAnimations = List.unmodifiable(combatAnimations),
       assert(
         !accepted || (nextSnapshot != null && outcome != null),
         'Accepted reductions must expose their canonical result.',
       );

  final bool accepted;
  final CanonicalGameSnapshot? nextSnapshot;
  final List<GameEvent> events;
  final List<MovementCommandExecution> movementExecutions;
  final List<CombatAnimationFact> combatAnimations;
  final GameOutcome? outcome;
  final String? reason;
}

/// Converts engine applications into the server's canonical reduction result.
final class ServerCommandOutcomeProjector {
  const ServerCommandOutcomeProjector();

  ServerCommandReduction accepted({
    required WireMatch match,
    required ServerCommandApplication application,
    required MapReadView mapView,
  }) {
    final nextSnapshot = application.snapshot;
    return ServerCommandReduction(
      accepted: true,
      nextSnapshot: nextSnapshot,
      events: application.events,
      movementExecutions: application.movementExecutions,
      combatAnimations: application.combatAnimations,
      outcome: const GameOutcomeDetector().evaluateCanonical(
        state: _reconcileParticipants(match, nextSnapshot.domain),
        mapData: mapView,
      ),
    );
  }

  ServerCommandReduction reject(String reason) =>
      ServerCommandReduction(accepted: false, reason: reason);
}

DomainState _reconcileParticipants(WireMatch match, DomainState domain) {
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
      domainPlayersById[wirePlayer.id] ?? domainPlayerFromWire(wirePlayer),
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
