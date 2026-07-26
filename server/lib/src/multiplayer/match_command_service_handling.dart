part of 'match_command_service.dart';

extension MatchCommandServiceHandling on MatchCommandService {
  Future<MatchMutationOutcome<void>> _handleCommand({
    required MultiplayerMatchStore store,
    required String matchId,
    required String userIdentifier,
    required MultiplayerClientMessage message,
    required WireCommand command,
    required MatchMessageTarget caller,
  }) async {
    final state = await _stateAccess.requireMatch(store, matchId, lock: true);
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    if (command.actorPlayerId != player.id) {
      store.operationalEvents.commandRejected(
        matchId: state.match.id,
        reasonCode: 'actor_mismatch',
      );
      return _directOutcome(
        caller,
        _broadcaster.message(
          matchId: state.match.id,
          offset: state.offset,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: false,
            offset: state.offset,
            snapshot: state.snapshot,
            reason: 'Command actor does not match the authenticated player.',
            movementExecutions: WireMovementExecutionList(const []),
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
      if (!_isSameCommandDelivery(duplicate, command)) {
        store.operationalEvents.commandRejected(
          matchId: state.match.id,
          reasonCode: 'client_message_id_conflict',
        );
        return _directOutcome(
          caller,
          _broadcaster.message(
            matchId: state.match.id,
            offset: state.offset,
            ack: WireCommandAck(
              matchId: state.match.id,
              accepted: false,
              offset: state.offset,
              snapshot: state.snapshot,
              reason: 'client_message_id_conflict',
              movementExecutions: WireMovementExecutionList(const []),
            ),
          ),
        );
      }
      return _directOutcome(
        caller,
        _broadcaster.message(
          matchId: state.match.id,
          offset: duplicate.offset,
          match: state.match.state == 'running' ? null : state.match,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: true,
            offset: duplicate.offset,
            snapshot: state.snapshot,
            events: duplicate.events,
            movementExecutions: duplicate.movementExecutions,
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
      store.operationalEvents.commandRejected(
        matchId: state.match.id,
        reasonCode: reduction.reason ?? 'command_rejected',
      );
      return _directOutcome(
        caller,
        _broadcaster.message(
          matchId: state.match.id,
          offset: state.offset,
          ack: WireCommandAck(
            matchId: state.match.id,
            accepted: false,
            offset: state.offset,
            snapshot: reduction.snapshot,
            reason: reduction.reason ?? 'Command rejected.',
            movementExecutions: WireMovementExecutionList(const []),
          ),
        ),
      );
    }

    final nextOffset = state.nextOffset();
    final nextSnapshot = reduction.snapshot.copyWith(offset: nextOffset);
    final event = _acceptedCommandEventForStorage(
      state: state,
      reduction: reduction,
      command: command,
      actorPlayerId: player.id,
      offset: nextOffset,
      timestamp: now,
    );
    final updated = _stateAfterAcceptedReduction(
      state: state,
      reduction: reduction,
      snapshot: nextSnapshot,
      now: now,
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
        match: updated.match.state == state.match.state ? null : updated.match,
        snapshot: updated.snapshot,
        event: event,
      ),
      except: caller,
    );
    final ack = MatchNotificationPlan.directMessage(
      _broadcaster.message(
        matchId: state.match.id,
        offset: event.offset,
        match: updated.match.state == state.match.state ? null : updated.match,
        ack: WireCommandAck(
          matchId: state.match.id,
          accepted: true,
          offset: event.offset,
          snapshot: updated.snapshot,
          events: event.events,
          movementExecutions: event.movementExecutions,
        ),
      ),
      recipient: caller,
    );
    return _commandOutcome(broadcast, ack);
  }

  MatchMutationOutcome<void> _commandOutcome(
    MatchNotificationPlan broadcast,
    MatchNotificationPlan ack,
  ) => MatchMutationOutcome<void>(
    null,
    notifications: broadcast.followedBy(ack),
  );

  bool _isSameCommandDelivery(WireEvent event, WireCommand command) {
    final actorPlayerId = event.actorPlayerId;
    final tick = event.tick;
    final turn = event.turn;
    final payload = event.command;
    if (actorPlayerId == null ||
        tick == null ||
        turn == null ||
        payload == null) {
      return false;
    }

    return WireCommand(
          v: command.v,
          matchId: event.matchId,
          tick: tick,
          turn: turn,
          actorPlayerId: actorPlayerId,
          command: payload,
        ) ==
        command;
  }

  MatchMutationOutcome<void> _directOutcome(
    MatchMessageTarget recipient,
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
