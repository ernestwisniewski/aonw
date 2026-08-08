import 'package:aonw_core/game/application/engine/game_engine_context.dart';
import 'package:aonw_core/game/application/engine/game_engine_result.dart';
import 'package:aonw_core/game/application/engine/movement_execution_delta.dart';
import 'package:aonw_core/game/application/engine/system_command.dart';
import 'package:aonw_core/game/application/turn/canonical_turn_pipeline.dart';
import 'package:aonw_core/game/domain/command/game_command.dart';
import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/turn/domain_turn_movement_processor.dart';

final class TurnEngineHandler {
  const TurnEngineHandler();

  GameEngineResult _beginPlayerTurn({
    required CanonicalGameSnapshot snapshot,
    required List<String> playerIds,
    required GameEngineContext context,
  }) {
    final orderedPlayerIds = _orderedDistinct(playerIds);
    final known = {
      for (final participant in snapshot.domain.participants) participant.id,
    };
    if (orderedPlayerIds.isEmpty ||
        orderedPlayerIds.any((playerId) => !known.contains(playerId))) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'turn_player_not_active',
      );
    }
    final movement = DomainTurnMovementProcessor.resetForPlayers(
      state: snapshot.domain,
      playerIds: orderedPlayerIds,
      mapData: context.mapView,
      ruleset: context.ruleset.copyWith(
        paceBalance: snapshot.domain.matchRules.paceBalance,
      ),
    );
    final nextSnapshot = snapshot.copyWith(domain: movement.state);
    return GameEngineResult.accepted(
      snapshot: nextSnapshot == snapshot ? snapshot : nextSnapshot,
      events: movement.events.cast<DomainEvent>(),
      movementDelta: MovementExecutionDelta(
        beforeUnits: snapshot.domain.units,
        afterUnits: movement.state.units,
        executions: movement.executions,
      ),
    );
  }

  GameEngineResult apply({
    required CanonicalGameSnapshot snapshot,
    required DomainCommand command,
    required GameEngineContext context,
  }) {
    return switch (command) {
      SubmitTurnCommand() => _submit(snapshot, command, context),
      EndTurnCommand() => _end(snapshot, command, context),
      _ => GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'unsupported_turn_command',
      ),
    };
  }

  GameEngineResult applySystem({
    required CanonicalGameSnapshot snapshot,
    required SystemCommand command,
    required GameEngineContext context,
  }) {
    return switch (command) {
      FinalizeTimedOutTurn() => _finalize(
        snapshot: snapshot,
        playerIds: command.playerIds,
        skippedPlayerIds: command.skippedPlayerIds,
        context: context,
        trackTimeoutStreaks: true,
      ),
      KickParticipant() => _kick(snapshot, command),
    };
  }

  GameEngineResult _submit(
    CanonicalGameSnapshot snapshot,
    SubmitTurnCommand command,
    GameEngineContext context,
  ) {
    if (!_actorControls(context.actorPlayerId, command.playerId)) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'turn_player_not_controlled',
      );
    }
    final playerIds = _turnPlayerIds(snapshot, context);
    if (!playerIds.contains(command.playerId)) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'turn_player_not_active',
      );
    }
    if (snapshot.domain.hasSubmitted(command.playerId)) {
      return GameEngineResult.accepted(snapshot: snapshot);
    }

    final submitted = {...snapshot.domain.submittedPlayerIds, command.playerId};
    final submittedSnapshot = snapshot.copyWith(
      domain: snapshot.domain.copyWith(
        submittedPlayerIds: submitted,
        turnStatesByPlayerId: _finishedTurnStates(snapshot, command.playerId),
      ),
    );
    final required = context.requiredTurnSubmissionPlayerIds.isEmpty
        ? playerIds
        : _orderedDistinct(context.requiredTurnSubmissionPlayerIds);
    if (!required.every(submitted.contains)) {
      return GameEngineResult.accepted(snapshot: submittedSnapshot);
    }
    return _finalize(
      snapshot: submittedSnapshot,
      playerIds: playerIds,
      skippedPlayerIds: [
        for (final playerId in playerIds)
          if (!submitted.contains(playerId)) playerId,
      ],
      context: context,
      trackTimeoutStreaks: context.trackTimeoutStreaks,
    );
  }

  GameEngineResult _end(
    CanonicalGameSnapshot snapshot,
    EndTurnCommand command,
    GameEngineContext context,
  ) {
    if (!_actorControls(context.actorPlayerId, command.playerId)) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'turn_player_not_controlled',
      );
    }
    if (!_turnPlayerIds(snapshot, context).contains(command.playerId)) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'turn_player_not_active',
      );
    }
    final result = CanonicalTurnPipeline.sequentialEnd(
      snapshot: snapshot,
      playerId: command.playerId,
      savedAt: (context.savedAt ?? snapshot.metadata.savedAtUtc).toUtc(),
      mapView: context.mapView,
      ruleset: context.ruleset,
    );
    final endedSnapshot = _advanceSequentialRoundIfComplete(
      result.snapshot,
      context.turnPlayerIds,
    );
    final nextPlayerId = _nextActivePlayerId(
      endedSnapshot,
      context.turnPlayerIds,
      afterPlayerId: command.playerId,
    );
    if (nextPlayerId != null) {
      final movement = _beginPlayerTurn(
        snapshot: endedSnapshot,
        playerIds: [nextPlayerId],
        context: context,
      );
      if (movement case final GameEngineAccepted accepted) {
        return GameEngineResult.accepted(
          snapshot: accepted.snapshot,
          events: [...result.events.cast<DomainEvent>(), ...accepted.events],
          movementDelta: accepted.movementDelta,
        );
      }
    }
    return GameEngineResult.accepted(
      snapshot: endedSnapshot,
      events: result.events.cast<DomainEvent>(),
      movementDelta: MovementExecutionDelta(
        beforeUnits: result.movementDelta.beforeUnits,
        afterUnits: result.movementDelta.afterUnits,
        executions: result.movementDelta.executions,
      ),
    );
  }

  CanonicalGameSnapshot _advanceSequentialRoundIfComplete(
    CanonicalGameSnapshot snapshot,
    List<String> orderedPlayerIds,
  ) {
    final activePlayerIds = _orderedDistinct(orderedPlayerIds)
        .where((playerId) => !snapshot.domain.isKicked(playerId))
        .toList(growable: false);
    if (activePlayerIds.isEmpty ||
        activePlayerIds.any(
          (playerId) =>
              snapshot.domain.turnStatesByPlayerId[playerId] !=
              PlayerTurnState.finished,
        )) {
      return snapshot;
    }
    return snapshot.copyWith(
      domain: snapshot.domain.copyWith(
        turn: snapshot.domain.turn + 1,
        turnStatesByPlayerId: {
          for (final entry in snapshot.domain.turnStatesByPlayerId.entries)
            entry.key: snapshot.domain.isKicked(entry.key)
                ? PlayerTurnState.finished
                : PlayerTurnState.active,
        },
        submittedPlayerIds: const {},
        turnStartedAt: snapshot.metadata.savedAtUtc,
      ),
    );
  }

  String? _nextActivePlayerId(
    CanonicalGameSnapshot snapshot,
    List<String> orderedPlayerIds, {
    required String afterPlayerId,
  }) {
    final ordered = _orderedDistinct(orderedPlayerIds);
    if (ordered.isEmpty) return null;
    final start = ordered.indexOf(afterPlayerId);
    // Include the current player after a round wrap. Before the wrap that
    // player is finished, so this only matters when they are the sole active
    // participant (for example after every opponent has been kicked).
    for (var offset = 1; offset <= ordered.length; offset += 1) {
      final index = (start < 0 ? offset - 1 : start + offset) % ordered.length;
      final playerId = ordered[index];
      if (snapshot.domain.turnStatesByPlayerId[playerId] ==
              PlayerTurnState.active &&
          !snapshot.domain.isKicked(playerId)) {
        return playerId;
      }
    }
    return null;
  }

  GameEngineResult _finalize({
    required CanonicalGameSnapshot snapshot,
    required List<String> playerIds,
    required List<String> skippedPlayerIds,
    required GameEngineContext context,
    required bool trackTimeoutStreaks,
    bool? preserveNonParticipantTurnStates,
  }) {
    final result = CanonicalTurnPipeline.simultaneousFinalize(
      CanonicalTurnPipelineRequest.simultaneousFinalize(
        snapshot: snapshot,
        playerIds: _orderedDistinct(playerIds),
        skippedPlayerIds: _orderedDistinct(skippedPlayerIds),
        savedAt: (context.savedAt ?? snapshot.metadata.savedAtUtc).toUtc(),
        mapView: context.mapView,
        ruleset: context.ruleset,
        preserveNonParticipantPlayerStates:
            preserveNonParticipantTurnStates ??
            context.preserveNonParticipantTurnStates,
        trackTimeoutStreaks: trackTimeoutStreaks,
      ),
    );
    return GameEngineResult.accepted(
      snapshot: result.snapshot,
      events: result.events.cast<DomainEvent>(),
      movementDelta: MovementExecutionDelta(
        beforeUnits: result.movementDelta.beforeUnits,
        afterUnits: result.movementDelta.afterUnits,
        executions: result.movementDelta.executions,
      ),
    );
  }

  GameEngineResult _kick(
    CanonicalGameSnapshot snapshot,
    KickParticipant command,
  ) {
    final participantIds = {
      for (final participant in snapshot.domain.participants) participant.id,
    };
    if (command.playerId.isEmpty ||
        !participantIds.contains(command.playerId)) {
      return GameEngineResult.rejected(
        snapshot: snapshot,
        reason: 'turn_player_not_active',
      );
    }
    if (snapshot.domain.isKicked(command.playerId)) {
      return GameEngineResult.accepted(snapshot: snapshot);
    }
    final next = snapshot.copyWith(
      domain: snapshot.domain.copyWith(
        turnStatesByPlayerId: _finishedTurnStates(snapshot, command.playerId),
        submittedPlayerIds: snapshot.domain.submittedPlayerIds.difference({
          command.playerId,
        }),
        afkPlayerIds: {...snapshot.domain.afkPlayerIds, command.playerId},
        kickedPlayerIds: {...snapshot.domain.kickedPlayerIds, command.playerId},
      ),
    );
    return GameEngineResult.accepted(
      snapshot: next,
      events: [
        PlayerKickedEvent(
          turn: snapshot.domain.turn,
          playerId: command.playerId,
          reason: command.reason,
          timeoutStreak: command.timeoutStreak,
        ),
      ],
    );
  }
}

bool _actorControls(String actorPlayerId, String playerId) =>
    actorPlayerId.isEmpty || actorPlayerId == playerId;

List<String> _turnPlayerIds(
  CanonicalGameSnapshot snapshot,
  GameEngineContext context,
) {
  final source = context.turnPlayerIds.isEmpty
      ? snapshot.domain.participants.map((participant) => participant.id)
      : context.turnPlayerIds;
  return _orderedDistinct(source)
      .where((playerId) => !snapshot.domain.isKicked(playerId))
      .toList(growable: false);
}

List<String> _orderedDistinct(Iterable<String> values) {
  final seen = <String>{};
  return [
    for (final value in values)
      if (value.isNotEmpty && seen.add(value)) value,
  ];
}

Map<String, PlayerTurnState> _finishedTurnStates(
  CanonicalGameSnapshot snapshot,
  String playerId,
) {
  if (!snapshot.domain.turnStatesByPlayerId.containsKey(playerId)) {
    return snapshot.domain.turnStatesByPlayerId;
  }
  return {
    ...snapshot.domain.turnStatesByPlayerId,
    playerId: PlayerTurnState.finished,
  };
}
