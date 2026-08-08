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
      return _rejectedCommandOutcome(
        store: store,
        state: state,
        caller: caller,
        reasonCode: 'actor_mismatch',
        reason: 'Command actor does not match the authenticated player.',
      );
    }

    final duplicate = await store.findEventByClientMessageId(
      state.match.id,
      actorPlayerId: player.id,
      clientMessageId: message.clientMessageId,
    );
    if (duplicate != null) {
      if (!_isSameCommandDelivery(duplicate, command)) {
        return _rejectedCommandOutcome(
          store: store,
          state: state,
          caller: caller,
          reasonCode: 'client_message_id_conflict',
          reason: 'client_message_id_conflict',
        );
      }
      return _directOutcome(
        caller,
        _broadcaster.message(
          matchId: state.match.id,
          offset: duplicate.offset,
          match: _matchUpdateUnlessRunning(state),
          ack: _acceptedCommandAck(state, duplicate),
        ),
      );
    }

    if (!_matchLifecycleStateAdapter.lifecycleOf(state).isRunning) {
      return _rejectedCommandOutcome(
        store: store,
        state: state,
        caller: caller,
        reasonCode: 'match_not_running',
        reason: 'match_not_running',
      );
    }

    final now = _nowUtc();
    final decodedSnapshot = _decodeRunningSnapshot(state);
    final previousSnapshot = decodedSnapshot.canonical;
    final reduction = await _commandReducer.reduce(
      match: state.match,
      snapshot: previousSnapshot,
      wireCommand: command,
      actorPlayerId: player.id,
      now: now,
    );
    if (!reduction.accepted) {
      return _rejectedCommandOutcome(
        store: store,
        state: state,
        caller: caller,
        reasonCode: reduction.reason ?? 'command_rejected',
        reason: reduction.reason ?? 'Command rejected.',
      );
    }

    final nextOffset = state.nextOffset();
    final nextSnapshot = _encodeReductionSnapshot(
      decoded: decodedSnapshot,
      reduction: reduction,
      offset: nextOffset,
    );
    final event = _acceptedCommandEventForStorage(
      state: state,
      previousSnapshot: previousSnapshot,
      reduction: reduction,
      command: command,
      actorPlayerId: player.id,
      offset: nextOffset,
      timestamp: now,
    );
    final updated = _stateAfterAcceptedPlayerReduction(
      state: state,
      reduction: reduction,
      snapshot: nextSnapshot,
      now: now,
    );
    await store._appendEventAndFinalizePresence(
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
        ack: _acceptedCommandAck(updated, event),
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

  MatchMutationOutcome<void> _rejectedCommandOutcome({
    required MultiplayerMatchStore store,
    required StoredMatchState state,
    required MatchMessageTarget caller,
    required String reasonCode,
    required String reason,
  }) {
    store.operationalEvents.commandRejected(
      matchId: state.match.id,
      reasonCode: reasonCode,
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
          reason: reason,
          movementExecutions: WireMovementExecutionList(const []),
        ),
      ),
    );
  }

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

WireCommandAck _acceptedCommandAck(StoredMatchState state, WireEvent event) {
  return WireCommandAck(
    matchId: state.match.id,
    accepted: true,
    offset: event.offset,
    tick: event.tick,
    timestamp: event.timestamp,
    snapshot: state.snapshot,
    events: event.events,
    movementExecutions: event.movementExecutions,
  );
}

WireMatch? _matchUpdateUnlessRunning(StoredMatchState state) =>
    _matchLifecycleStateAdapter.lifecycleOf(state).isRunning
    ? null
    : state.match;
