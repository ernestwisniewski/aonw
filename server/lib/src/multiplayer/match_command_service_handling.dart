part of 'match_command_service.dart';

extension MatchCommandServiceHandling on MatchCommandService {
  Future<MatchMutationOutcome<void>> _handleCommand({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required MultiplayerClientMessage message,
    required WireCommand command,
    required MatchServerMessageSink emitToCaller,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId, lock: true);
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    if (command.actorPlayerId != player.id) {
      return _directOutcome(
        emitToCaller,
        _broadcaster.message(
          matchId: state.match.id,
          offset: state.offset,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: false,
            offset: state.offset,
            snapshot: state.snapshot,
            reason: 'Command actor does not match the authenticated player.',
          ),
        ),
      );
    }

    final duplicate = await store.findEventByClientMessageId(
      state.match.id,
      actorPlayerId: player.id,
      clientMessageId: message.clientMessageId,
    );
    if (duplicate != null) {
      return _directOutcome(
        emitToCaller,
        _broadcaster.message(
          matchId: state.match.id,
          offset: duplicate.offset,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: true,
            offset: duplicate.offset,
            snapshot: state.snapshot,
            events: duplicate.events,
          ),
        ),
      );
    }

    final now = _nowUtc();
    final reduction = await _commandReducer.reduce(
      match: state.match,
      snapshot: state.snapshot,
      wireCommand: command,
      actorPlayerId: player.id,
      now: now,
    );
    if (!reduction.accepted) {
      return _directOutcome(
        emitToCaller,
        _broadcaster.message(
          matchId: state.match.id,
          offset: state.offset,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: false,
            offset: state.offset,
            snapshot: reduction.snapshot,
            reason: reduction.reason ?? 'Command rejected.',
          ),
        ),
      );
    }

    final nextOffset = state.nextOffset();
    final nextSnapshot = reduction.snapshot.copyWith(offset: nextOffset);
    final nextSave = GameSave.fromJson(nextSnapshot.save);
    final event = WireEvent(
      matchId: state.match.id,
      offset: nextOffset,
      timestamp: now,
      actorPlayerId: player.id,
      tick: command.tick,
      command: command.command,
      events: reduction.events.map(GameEventSerializer.toJson).toList(),
    );
    final updated = state.copyWith(
      match: state.match.copyWith(turn: nextSave.turn),
      snapshot: nextSnapshot,
    );
    await store.appendEvent(
      updated,
      event,
      actorPlayerId: player.id,
      clientMessageId: message.clientMessageId,
    );

    final broadcast = MatchNotificationPlan.broadcastMessage(
      _broadcaster.message(
        matchId: state.match.id,
        offset: event.offset,
        snapshot: updated.snapshot,
        event: event,
      ),
      except: emitToCaller,
    );
    final ack = MatchNotificationPlan.directMessage(
      _broadcaster.message(
        matchId: state.match.id,
        offset: event.offset,
        ack: WireCommandAck(
          matchId: state.match.id,
          accepted: true,
          offset: event.offset,
          snapshot: updated.snapshot,
          events: event.events,
        ),
      ),
      recipient: emitToCaller,
    );
    return MatchMutationOutcome<void>(
      null,
      notifications: broadcast.followedBy(ack),
    );
  }

  MatchMutationOutcome<void> _directOutcome(
    MatchServerMessageSink recipient,
    MultiplayerServerMessage message,
  ) {
    return MatchMutationOutcome<void>(
      null,
      notifications: MatchNotificationPlan.directMessage(
        message,
        recipient: recipient,
      ),
    );
  }
}
