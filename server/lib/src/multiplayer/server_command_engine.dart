import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';

import 'package:aonw_server/src/multiplayer/server_command_application.dart';

/// Applies player and system commands through the canonical game engine.
final class ServerCommandEngine {
  const ServerCommandEngine();

  ServerCommandApplication apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required String actorPlayerId,
    required int commandTick,
    required MapReadView mapView,
    required GameRuleset ruleset,
    List<String> turnPlayerIds = const [],
    List<String> requiredTurnSubmissionPlayerIds = const [],
    DateTime? savedAt,
    bool preserveNonParticipantTurnStates = false,
    bool trackTimeoutStreaks = false,
  }) {
    final result = const GameEngine().apply(
      snapshot: snapshot,
      command: command,
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: mapView,
        ruleset: ruleset,
        commandTick: commandTick,
        turnPlayerIds: turnPlayerIds,
        requiredTurnSubmissionPlayerIds: requiredTurnSubmissionPlayerIds,
        savedAt: savedAt,
        preserveNonParticipantTurnStates: preserveNonParticipantTurnStates,
        trackTimeoutStreaks: trackTimeoutStreaks,
      ),
    );
    return ServerCommandApplication.fromEngine(snapshot, result);
  }

  ServerCommandApplication applySystem({
    required CanonicalGameSnapshot snapshot,
    required SystemCommand command,
    required GameEngineContext context,
  }) {
    return ServerCommandApplication.fromEngine(
      snapshot,
      const GameEngine().applySystem(
        snapshot: snapshot,
        command: command,
        context: context,
      ),
    );
  }
}
