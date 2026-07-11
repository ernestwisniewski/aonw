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
    final players = [
      for (final matchPlayer in state.match.players)
        matchPlayer.userId == userIdentifier
            ? matchPlayer.copyWith(
                connectionState: WirePlayerConnectionState.offline,
              )
            : matchPlayer,
    ];
    final kickedPlayerIds = {
      ...persistentState.runtimeState.kickedPlayerIds,
      player.id,
    };
    final playerStates = {
      ...save.playerStates,
      if (save.playerStates.containsKey(player.id))
        player.id: PlayerTurnState.finished,
    };
    final nextSave = save.copyWith(playerStates: playerStates);
    final nextPersistentState = persistentState.copyWith(
      runtimeState: persistentState.runtimeState.copyWith(
        kickedPlayerIds: kickedPlayerIds,
        afkPlayerIds: {...persistentState.runtimeState.afkPlayerIds, player.id},
        submittedPlayerIds: persistentState.runtimeState.submittedPlayerIds
            .difference({player.id}),
      ),
    );
    final runningState = state.copyWith(
      match: state.match.copyWith(players: players),
      snapshot: state.snapshot.copyWith(
        save: nextSave.toJson(),
        state: nextPersistentState.toJson(),
      ),
    );
    final remainingPlayers = _remainingHumanPlayers(
      runningState.match,
      kickedPlayerIds,
    );
    final alivePlayerIds = const GameOutcomeDetector().alivePlayerIds(
      playerIds: remainingPlayers.map((player) => player.id),
      state: nextPersistentState,
    );
    if (alivePlayerIds.length == 1) {
      return _finishedStateAfterResignation(
        runningState,
        resignedUserIdentifier: userIdentifier,
        winnerPlayerId: alivePlayerIds.single,
        endedAt: endedAt,
      );
    }
    if (alivePlayerIds.isEmpty) {
      return _stateAccess.abandonedState(
        runningState,
        reason: remainingPlayers.isEmpty
            ? 'all_players_resigned'
            : 'no_alive_players_after_resignation',
        endedAt: endedAt,
        userIdentifier: userIdentifier,
      );
    }
    return runningState;
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

  List<WirePlayer> _remainingHumanPlayers(
    WireMatch match,
    Set<String> kickedPlayerIds,
  ) {
    return match.players
        .where(
          (player) =>
              player.kind == WirePlayerKind.human &&
              !kickedPlayerIds.contains(player.id),
        )
        .toList(growable: false);
  }
}
