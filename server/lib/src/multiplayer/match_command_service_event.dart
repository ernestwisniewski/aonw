part of 'match_command_service.dart';

WireEvent _acceptedCommandEventForStorage({
  required StoredMatchState state,
  required ServerCommandReduction reduction,
  required WireCommand command,
  required String actorPlayerId,
  required int offset,
  required DateTime timestamp,
}) {
  final participantPlayerIds = state.match.players.map((player) => player.id);
  final previous = reduction.previousState!;
  final next = reduction.state!;
  return WireEvent(
    matchId: state.match.id,
    offset: offset,
    timestamp: timestamp,
    actorPlayerId: actorPlayerId,
    tick: command.tick,
    turn: state.match.turn,
    command: command.command,
    events: _eventAudienceForStorage(
      events: reduction.events,
      participantPlayerIds: participantPlayerIds,
      previous: previous,
      next: next,
    ),
    movementExecutions: PlayerMatchMovementAudience.annotateForStorage(
      executions: reduction.movementExecutions,
      participantPlayerIds: participantPlayerIds,
      previousUnits: previous.units,
      nextUnits: next.units,
      previousFog: previous.fogOfWar,
      nextFog: next.fogOfWar,
    ),
  );
}

WireEvent _acceptedTimeoutEventForStorage({
  required StoredMatchState state,
  required ServerCommandReduction reduction,
  required String actorPlayerId,
  required int offset,
  required DateTime timestamp,
}) {
  return _acceptedCommandEventForStorage(
    state: state,
    reduction: reduction,
    command: WireCommand(
      matchId: state.match.id,
      tick: offset,
      turn: state.match.turn,
      actorPlayerId: actorPlayerId,
      command: GameCommandSerializer.toJson(SubmitTurnCommand(actorPlayerId)),
    ),
    actorPlayerId: actorPlayerId,
    offset: offset,
    timestamp: timestamp,
  );
}
