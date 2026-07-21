part of '../timeout_actor_integration_test.dart';

const _invalidTimeoutSelectionFixture = '''
extension TimeoutSelection on MatchCommandService {
  String? _selectTimeoutActorPlayerId({
    required WireMatch match,
    required GameSave save,
    required CanonicalGameSnapshot canonicalSnapshot,
  }) {
    final activePlayerIds = {
      for (final player in save.players) player.id,
    };
    final ordered = match.players.map((player) => player.id).toList()..sort();
    TimeoutActorSelector.select(
      orderedParticipantPlayerIds: ordered,
      submittedPlayerIds:
          canonicalSnapshot.domain.runtimeState.submittedPlayerIds,
      kickedPlayerIds: canonicalSnapshot.session.kickedPlayerIds,
    );
    return ordered.first;
  }
}
''';

const _invalidTimeoutCanonicalFlowFixture = '''
extension TimeoutFlow on MatchCommandService {
  Future<void> advanceTimedOutTurn() async {
    final DecodedMatchSnapshot decodedSnapshot = _commandReducer.decodeSnapshot(
      match: staleMatch,
      snapshot: state.snapshot,
    );
    var canonicalSnapshot = decodedSnapshot.toCanonical();
    canonicalSnapshot = staleSnapshot;
    final current = decodedSnapshot.canonical;
    final duplicate = decodedSnapshot.canonical;
    _commandReducer.hasTurnTimedOut(
      decodedSnapshot: staleSnapshot,
      now: now,
    );
    _selectTimeoutActorPlayerId(canonicalSnapshot: canonicalSnapshot);
    await _commandReducer.reduceTimedOutTurn(
      decodedSnapshot: decodedSnapshot,
    );
  }
}
''';

const _invalidDecodedSnapshotAliasFixture = '''
final class DecodedMatchSnapshot {
  const DecodedMatchSnapshot(this.snapshot);
  final WireSnapshot snapshot;
}
''';

const _invalidReducerSnapshotDecodeFixture = '''
class ServerCommandReducer {
  DecodedMatchSnapshot decodeSnapshot(WireSnapshot snapshot) =>
      DecodedMatchSnapshot(
        GameSave.fromJson(snapshot.save),
        PersistentGameState.fromJson(snapshot.state),
        snapshot.offset,
      );

  Future<void> reduce({
    required WireMatch match,
    required WireSnapshot snapshot,
  }) async {
    final decodedSnapshot = decodeSnapshot(snapshot);
  }
}
''';

const _invalidTimeoutReducerFixture = '''
class ServerCommandReducer {
  Future<void> reduceTimedOutTurn({
    required WireMatch match,
    required WireSnapshot snapshot,
    required DecodedMatchSnapshot decodedSnapshot,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    _finalizeSimultaneousTurn(decodedSnapshot: staleSnapshot);
  }
}
''';

const _invalidTimeoutTurnsFixture = '''
extension ServerCommandReducerTurns on ServerCommandReducer {
  void _submitTurn() {
    _finalizeSimultaneousTurn(decodedSnapshot: decodedSnapshot);
  }

  void _finalizeSimultaneousTurn({
    required DecodedMatchSnapshot decodedSnapshot,
  }) {
    _canonicalSnapshot(
      save: save,
      state: state,
      eventLogOffset: eventLogOffset,
    );
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: decodedSnapshot.toCanonical(),
    );
  }
}
''';
