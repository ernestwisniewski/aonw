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
    var canonicalSnapshot = decodedSnapshot.toCanonical();
    canonicalSnapshot = staleSnapshot;
    decodedSnapshot.toCanonical();
    _selectTimeoutActorPlayerId(canonicalSnapshot: canonicalSnapshot);
    await _commandReducer.reduceTimedOutTurn(
      decodedSnapshot: decodedSnapshot,
    );
  }
}
''';

const _invalidDecodedCanonicalBridgeFixture = '''
final class DecodedMatchSnapshot {
  final CanonicalGameSnapshot _canonicalSnapshotValue = _canonicalSnapshot(
    save: otherSave,
    state: state,
    eventLogOffset: eventLogOffset,
  );

  CanonicalGameSnapshot toCanonical() => _canonicalSnapshot(
    save: save,
    state: state,
    eventLogOffset: eventLogOffset,
  );

  DecodedMatchSnapshot withState(PersistentGameState state) => this;
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
    CanonicalTurnPipelineRequest.simultaneousFinalize(
      snapshot: _canonicalSnapshot(
        save: save,
        state: state,
        eventLogOffset: eventLogOffset,
      ),
    );
  }
}
''';
