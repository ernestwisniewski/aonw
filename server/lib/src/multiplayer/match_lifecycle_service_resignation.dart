part of 'match_lifecycle_service.dart';

extension MatchLifecycleServiceResignation on MatchLifecycleService {
  StoredMatchState _runningStateAfterParticipantResigned(
    StoredMatchState state, {
    required String userIdentifier,
    required DateTime endedAt,
  }) {
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    final persistentState = PersistentGameState.fromJson(state.snapshot.state);
    if (persistentState.runtimeState.isKicked(player.id)) {
      return state;
    }

    final save = GameSave.fromJson(state.snapshot.save);
    final canonicalSnapshot = _lifecycleSnapshotAdapter.toCanonical(
      save: save,
      state: persistentState,
      eventLogOffset: state.snapshot.offset,
    );
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
    final players = [
      for (final matchPlayer in state.match.players)
        matchPlayer.userId == userIdentifier
            ? matchPlayer.copyWith(
                connectionState: WirePlayerConnectionState.offline,
              )
            : matchPlayer,
    ];
    final nextSave = save.copyWith(
      playerStates: transition.session.turnStatesByPlayerId,
    );
    final nextPersistentState = persistentState.copyWith(
      runtimeState: persistentState.runtimeState.copyWith(
        submittedPlayerIds: transition.session.submittedPlayerIds,
        afkPlayerIds: transition.session.afkPlayerIds,
        kickedPlayerIds: transition.session.kickedPlayerIds,
      ),
    );
    final runningState = state.copyWith(
      match: state.match.copyWith(players: players),
      snapshot: state.snapshot.copyWith(
        save: nextSave.toJson(),
        state: nextPersistentState.toJson(),
      ),
    );
    return _stateAfterResignationTransition(
      originalState: state,
      runningState: runningState,
      transition: transition,
      userIdentifier: userIdentifier,
      endedAt: endedAt,
    );
  }

  StoredMatchState _stateAfterResignationTransition({
    required StoredMatchState originalState,
    required StoredMatchState runningState,
    required ParticipantResignationResult transition,
    required String userIdentifier,
    required DateTime endedAt,
  }) {
    return switch (transition.disposition) {
      ParticipantResignationDisposition.unchanged => originalState,
      ParticipantResignationDisposition.running => runningState,
      ParticipantResignationDisposition.finished =>
        _finishedStateAfterResignation(
          runningState,
          resignedUserIdentifier: userIdentifier,
          winnerPlayerId: transition.outcome!.winnerPlayerId!,
          endedAt: endedAt,
        ),
      ParticipantResignationDisposition.abandoned =>
        _stateAccess.abandonedState(
          runningState,
          reason: _resignationAbandonmentReason(transition.abandonmentReason!),
          endedAt: endedAt,
          userIdentifier: userIdentifier,
        ),
    };
  }

  StoredMatchState _finishedStateAfterResignation(
    StoredMatchState state, {
    required String resignedUserIdentifier,
    required String winnerPlayerId,
    required DateTime endedAt,
  }) {
    return state.copyWith(
      match: state.match.copyWith(
        state: 'finished',
        endedAt: endedAt.toUtc(),
        outcomeCondition: 'resignation',
        winnerPlayerId: winnerPlayerId,
        autoStartAt: null,
      ),
      snapshot: state.snapshot.copyWith(
        state: {
          ...state.snapshot.state,
          'phase': 'finished',
          'resignedUserIdentifier': resignedUserIdentifier,
        },
      ),
    );
  }
}

String _resignationAbandonmentReason(
  ParticipantResignationAbandonmentReason reason,
) {
  return switch (reason) {
    ParticipantResignationAbandonmentReason.allPlayersResigned =>
      'all_players_resigned',
    ParticipantResignationAbandonmentReason.noAlivePlayersAfterResignation =>
      'no_alive_players_after_resignation',
  };
}
