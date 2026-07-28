part of '../participant_resignation_integration_test.dart';

const _invalidFlowFixture = '''
extension Resignation on MatchLifecycleService {
  StoredMatchState _runningStateAfterParticipantResigned(
    StoredMatchState state, {
    required String userIdentifier,
    required DateTime endedAt,
  }) {
    final decodedSnapshot = _runningMatchSnapshotCodec.decode(
      match: state.match,
      snapshot: unvalidatedSnapshot,
    );
    final player = _stateAccess.requireParticipant(state, userIdentifier);
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
    if (canonicalSnapshot.session.isKicked(player.id)) return state;
    final nextSnapshot = canonicalSnapshot.copyWith(
      session: transition.session,
    );
    final runningState = state.copyWith(
      snapshot: _runningMatchSnapshotCodec.encodeCanonical(
        decodedSnapshot,
        nextSnapshot,
      ),
    );
    return runningState;
  }
}
''';

const _invalidValidationFixture = '''
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
    final canonicalSnapshot = decodedSnapshot.canonical;
    if (canonicalSnapshot.session.isKicked(player.id)) return state;
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
    final nextSnapshot = canonicalSnapshot.copyWith(
      session: transition.session,
    );
    final runningState = state.copyWith(
      snapshot: _runningMatchSnapshotCodec.encodeCanonical(
        decodedSnapshot,
        nextSnapshot,
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
    final canonicalSnapshot =
        _runningMatchSnapshotCodec.canonicalWithValidatedRoster(
          decodedSnapshot,
          match: state.match,
        );
    if (canonicalSnapshot.session.isKicked(player.id)) return state;
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
    final nextSnapshot = canonicalSnapshot.copyWith(
      domain: canonicalSnapshot.domain,
      session: transition.session,
    );
    final encodedSnapshot = _runningMatchSnapshotCodec.encodeCanonical(
      otherDecodedSnapshot,
      canonicalSnapshot,
    );
    final runningState = state.copyWith(snapshot: state.snapshot);
    return runningState;
  }
}
''';

const _invalidLegacyFixture = '''
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
    final canonicalSnapshot =
        _runningMatchSnapshotCodec.canonicalWithValidatedRoster(
          decodedSnapshot,
          match: state.match,
        );
    if (canonicalSnapshot.session.isKicked(player.id)) return state;
    final transition = ParticipantResignationTransition.apply(
      domain: canonicalSnapshot.domain,
      session: canonicalSnapshot.session,
      actorPlayerId: player.id,
      orderedHumanPlayerIds: [
        for (final matchPlayer in state.match.players)
          if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id,
      ],
    );
    final GameSave save = decodedSnapshot.save;
    final PersistentGameState persistentState = decodedSnapshot.state;
    final canonicalAgain = adapter.toCanonical(
      save: GameSave.fromJson(save.toJson()),
      state: persistentState,
      eventLogOffset: decodedSnapshot.wire.offset,
    );
    final legacy = adapter.toLegacy(canonicalAgain);
    final GameRuntimeState runtimeState = persistentState.runtimeState;
    final nextSnapshot = canonicalSnapshot.copyWith(
      session: transition.session,
    );
    final runningState = state.copyWith(
      snapshot: _runningMatchSnapshotCodec.encode(
        decodedSnapshot,
        save: legacy.save,
        state: persistentState.copyWith(runtimeState: runtimeState),
      ),
    );
    const GameOutcomeDetector().alivePlayerIds(
      playerIds: const [],
      state: persistentState,
    );
    return runningState;
  }
}
''';
