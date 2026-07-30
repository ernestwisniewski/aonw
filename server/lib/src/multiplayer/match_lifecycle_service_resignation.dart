part of 'match_lifecycle_service.dart';

extension MatchLifecycleServiceResignation on MatchLifecycleService {
  StoredMatchState _runningStateAfterParticipantResigned(
    StoredMatchState state, {
    required String userIdentifier,
    required DateTime endedAt,
  }) {
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    final decodedSnapshot = _runningMatchSnapshotCodec.decode(
      match: state.match,
      snapshot: state.snapshot,
    );
    final canonicalSnapshot = _runningMatchSnapshotCodec
        .canonicalWithValidatedRoster(decodedSnapshot, match: state.match);
    if (canonicalSnapshot.session.isKicked(player.id)) {
      return state;
    }

    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
    final nextSnapshot = _snapshotAfterResignationKick(
      canonicalSnapshot,
      player.id,
    );
    final players = [
      for (final matchPlayer in state.match.players)
        matchPlayer.userId == userIdentifier
            ? matchPlayer.copyWith(
                connectionState: WirePlayerConnectionState.offline,
              )
            : matchPlayer,
    ];
    final runningState = state.copyWith(
      match: state.match.copyWith(players: players),
      snapshot: _runningMatchSnapshotCodec.encodeCanonical(
        decodedSnapshot,
        nextSnapshot,
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
    final transition = _matchLifecycleStateAdapter.apply(
      state,
      const FinishMatchLifecycle(MatchCompletionReason.resignation),
      endedAt: endedAt,
      winnerPlayerId: winnerPlayerId,
    );
    if (transition.rejection case final rejection?) {
      throw StateError(
        'Finish resignation lifecycle rejected: ${rejection.code}.',
      );
    }
    return transition.state.copyWith(
      snapshot: transition.state.snapshot.copyWith(
        state: {
          ...transition.state.snapshot.state,
          'resignedUserIdentifier': resignedUserIdentifier,
        },
      ),
    );
  }
}

CanonicalGameSnapshot _snapshotAfterResignationKick(
  CanonicalGameSnapshot snapshot,
  String playerId,
) {
  final result = const GameEngine().applySystem(
    snapshot: snapshot,
    command: KickParticipant(
      playerId: playerId,
      reason: 'resignation',
      timeoutStreak: snapshot.session.timeoutStreaksByPlayerId[playerId] ?? 0,
    ),
    context: GameEngineContext(
      actorPlayerId: 'server',
      mapView: const _LifecycleMapReadView(),
      ruleset: GameRuleset.defaults,
      commandTick: snapshot.eventLogOffset,
    ),
  );
  if (result is GameEngineRejected) {
    throw StateError(
      'Resignation system transition rejected: ${result.reason}',
    );
  }
  return (result as GameEngineAccepted).snapshot;
}

final class _LifecycleMapReadView implements MapReadView {
  const _LifecycleMapReadView();

  @override
  int get cols => 0;

  @override
  int get rows => 0;

  @override
  MapTileLookup get mapTiles => this;

  @override
  Iterable<MapObjectiveDefinition> get objectives => const [];

  @override
  String? get mapName => null;

  @override
  int get tileCount => 0;

  @override
  Iterable<Iterable<TerrainType>> get tileTerrains => const [];

  @override
  Iterable<MapTileView> get tileViews => const [];

  @override
  MapTileView? tileAt(int col, int row) => null;
}

MatchAbandonmentReason _resignationAbandonmentReason(
  ParticipantResignationAbandonmentReason reason,
) {
  return switch (reason) {
    ParticipantResignationAbandonmentReason.allPlayersResigned =>
      MatchAbandonmentReason.allPlayersResigned,
    ParticipantResignationAbandonmentReason.noAlivePlayersAfterResignation =>
      MatchAbandonmentReason.noAlivePlayersAfterResignation,
  };
}
