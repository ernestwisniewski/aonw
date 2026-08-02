import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/server_command_application.dart';
import 'package:aonw_server/src/multiplayer/server_command_engine.dart';
import 'package:aonw_server/src/multiplayer/server_turn_policy.dart';

/// Routes command families to turn policy and the canonical engine.
final class ServerCommandDispatcher {
  const ServerCommandDispatcher({
    required ServerTurnPolicy turnPolicy,
    ServerCommandEngine engine = const ServerCommandEngine(),
  }) : _turnPolicy = turnPolicy,
       _engine = engine;

  final ServerTurnPolicy _turnPolicy;
  final ServerCommandEngine _engine;

  ServerCommandApplication apply({
    required CanonicalGameSnapshot snapshot,
    required WireMatch match,
    required DomainCommand command,
    required int commandTick,
    required String actorPlayerId,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    return switch (command) {
      SubmitTurnCommand(:final playerId) ||
      EndTurnCommand(:final playerId) => _applyTurnCommand(
        snapshot: snapshot,
        match: match,
        command: command is SubmitTurnCommand
            ? command
            : SubmitTurnCommand(playerId),
        actorPlayerId: actorPlayerId,
        commandTick: commandTick,
        now: now,
        mapView: mapView,
        ruleset: ruleset,
      ),
      _ => _engine.apply(
        snapshot: snapshot,
        command: command,
        actorPlayerId: actorPlayerId,
        commandTick: commandTick,
        mapView: mapView,
        ruleset: ruleset,
      ),
    };
  }

  ServerCommandApplication finalizeTimedOutTurn({
    required CanonicalGameSnapshot snapshot,
    required String actorPlayerId,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final playerIds = _turnPolicy.playerIds(snapshot);
    final submittedPlayerIds = snapshot.domain.submittedPlayerIds;
    return _engine.applySystem(
      snapshot: snapshot,
      command: FinalizeTimedOutTurn(
        playerIds: playerIds,
        skippedPlayerIds: playerIds
            .where((id) => !submittedPlayerIds.contains(id))
            .toList(),
      ),
      context: GameEngineContext(
        actorPlayerId: actorPlayerId,
        mapView: mapView,
        ruleset: ruleset,
        commandTick: snapshot.eventLogOffset,
        savedAt: now,
        preserveNonParticipantTurnStates: true,
        trackTimeoutStreaks: true,
      ),
    );
  }

  ServerCommandApplication _applyTurnCommand({
    required CanonicalGameSnapshot snapshot,
    required WireMatch match,
    required SubmitTurnCommand command,
    required String actorPlayerId,
    required int commandTick,
    required DateTime now,
    required MapReadView mapView,
    required GameRuleset ruleset,
  }) {
    final playerIds = _turnPolicy.playerIds(snapshot);
    final timedOut = _turnPolicy.hasTimedOut(snapshot, now);
    if (timedOut && snapshot.domain.hasSubmitted(command.playerId)) {
      return _engine.applySystem(
        snapshot: snapshot,
        command: FinalizeTimedOutTurn(
          playerIds: playerIds,
          skippedPlayerIds: [
            for (final id in playerIds)
              if (!snapshot.domain.hasSubmitted(id)) id,
          ],
        ),
        context: GameEngineContext(
          actorPlayerId: actorPlayerId,
          mapView: mapView,
          ruleset: ruleset,
          commandTick: commandTick,
          savedAt: now,
          preserveNonParticipantTurnStates: true,
          trackTimeoutStreaks: true,
        ),
      );
    }
    final requiredPlayerIds = timedOut
        ? [command.playerId]
        : _turnPolicy.requiredSubmissionPlayerIds(
            match: match,
            playerIds: playerIds,
          );
    return _engine.apply(
      snapshot: snapshot,
      command: command,
      actorPlayerId: actorPlayerId,
      commandTick: commandTick,
      mapView: mapView,
      ruleset: ruleset,
      turnPlayerIds: playerIds,
      requiredTurnSubmissionPlayerIds: requiredPlayerIds,
      savedAt: now,
      preserveNonParticipantTurnStates: true,
      trackTimeoutStreaks: true,
    );
  }
}
