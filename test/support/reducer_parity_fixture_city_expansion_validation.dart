part of 'reducer_parity_fixture.dart';

void _requireAcceptedParityCityExpansion(
  ReducerParityFixture fixture,
  DomainState state,
  List<GameEvent> events,
) {
  final command = fixture.command as SelectCityExpansionHexCommand;
  final beforeIndex = fixture.state.cities.indexWhere(
    (city) => city.id == command.cityId,
  );
  if (beforeIndex < 0 ||
      fixture.state.submittedPlayerIds.isEmpty ||
      events.isNotEmpty) {
    ReducerParityCorpus._fail(
      fixture,
      'must update an existing city, preserve a runtime sentinel, and emit no events',
    );
  }
  if (!jsonDeepEquals(fixture.expectedSave, reducerParitySave(fixture.save))) {
    ReducerParityCorpus._fail(
      fixture,
      'must preserve save metadata for city expansion selection',
    );
  }

  final beforeCity = fixture.state.cities[beforeIndex];
  final expectedCities = [...fixture.state.cities]
    ..[beforeIndex] = beforeCity.copyWith(
      preferredExpansionHex: CityHex(col: command.col, row: command.row),
    );
  final expectedState = fixture.state.copyWith(cities: expectedCities);
  if (!jsonDeepEquals(
    CanonicalGameSnapshotCodec.encodeDomainState(state),
    CanonicalGameSnapshotCodec.encodeDomainState(expectedState),
  )) {
    ReducerParityCorpus._fail(
      fixture,
      'must only select the reviewed city preferred expansion hex',
    );
  }
}
