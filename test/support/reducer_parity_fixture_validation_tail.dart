part of 'reducer_parity_fixture.dart';

void _requireCanonicalDomainStateJson(
  String id,
  DomainState state,
  Map<String, dynamic> stateJson,
) {
  _requireCanonicalJson(
    id,
    'state',
    CanonicalGameSnapshotCodec.encodeDomainState(state),
    stateJson,
  );
}

void _requireAcceptedParityResourceTrade(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  if (!jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save))) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata for resource trade',
    );
  }
  requireAcceptedResourceTrade(
    fixtureId: fixture.id,
    command: fixture.command,
    before: fixture.state,
    after: state,
    events: events,
  );
}

void _requireAcceptedParityTurn(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  requireAcceptedTurnSubmission(
    fixtureId: fixture.id,
    command: fixture.command as SubmitTurnCommand,
    inputTurn: fixture.save.turn,
    playerIds: fixture.save.players.map((player) => player.id),
    expectedTurn: fixture.expectedSave['turn'],
    expectedPlayerStates: _asMap(
      fixture.expectedSave['playerStates'],
      '${fixture.id}.expected.save.playerStates',
    ),
    before: fixture.state,
    after: state,
    now: fixture.now,
    events: events,
  );
}
