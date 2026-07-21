part of '../participant_resignation_integration_test.dart';

const _invalidFlowFixture = '''
extension Resignation on MatchLifecycleService {
  StoredMatchState _runningStateAfterParticipantResigned(
    StoredMatchState state, {
    required String userIdentifier,
    required DateTime endedAt,
  }) {
    final player = _stateAccess.requireParticipant(state, userIdentifier);
    final persistentState = PersistentGameState.fromJson(state.snapshot.state);
    final save = GameSave.fromJson(state.snapshot.save);
    final canonicalSnapshot = _lifecycleSnapshotAdapter.toCanonical(
      save: save,
      state: persistentState,
      eventLogOffset: state.snapshot.offset,
    );
    if (persistentState.runtimeState.isKicked(player.id)) return state;
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: save.players.map((player) => player.id),
    );
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
    final encodedSnapshot = _runningMatchSnapshotCodec.encode(
      otherDecodedSnapshot,
      save: nextSave,
    );
    final runningState = state.copyWith(
      snapshot: state.snapshot.copyWith(
        save: nextSave.toJson(),
        state: nextPersistentState.toJson(),
      ),
    );
    return runningState;
  }
}
''';

const _invalidEncodeFixture = '''
extension Resignation on MatchLifecycleService {
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
    final persistentState = decodedSnapshot.state;
    if (persistentState.runtimeState.isKicked(player.id)) return state;
    final save = decodedSnapshot.save;
    final canonicalSnapshot = decodedSnapshot.canonical;
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
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
    final encodedSnapshot = _runningMatchSnapshotCodec.encode(
      otherDecodedSnapshot,
      save: nextSave,
    );
    final runningState = state.copyWith(snapshot: state.snapshot);
    return runningState;
  }
}
''';

const _invalidPatchFixture = '''
extension Resignation on MatchLifecycleService {
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
    final persistentState = decodedSnapshot.state;
    if (persistentState.runtimeState.isKicked(player.id)) return state;
    final save = decodedSnapshot.save;
    final canonicalSnapshot = decodedSnapshot.canonical;
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
    final nextSave = save.copyWith(
      players: canonicalSnapshot.domain.participants,
      playerStates: transition.session.turnStatesByPlayerId,
    );
    final nextPersistentState = persistentState.copyWith(
      runtimeState: persistentState.runtimeState.copyWith(
        submittedPlayerIds: transition.session.submittedPlayerIds,
        timeoutStreaksByPlayerId: transition.session.timeoutStreaksByPlayerId,
        afkPlayerIds: transition.session.afkPlayerIds,
        kickedPlayerIds: transition.session.kickedPlayerIds,
      ),
    );
    final encodedSnapshot = _runningMatchSnapshotCodec.encode(
      decodedSnapshot,
      save: nextSave,
      state: nextPersistentState,
    );
    final runningState = state.copyWith(snapshot: encodedSnapshot);
    const GameOutcomeDetector().alivePlayerIds(
      playerIds: const [],
      state: nextPersistentState,
    );
    return runningState;
  }
}
''';
