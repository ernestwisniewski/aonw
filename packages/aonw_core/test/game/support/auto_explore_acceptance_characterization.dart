part of '../persistent_auto_explore_characterization_test.dart';

void _registerAutoExploreAcceptanceCharacterizationTests() {
  group('auto-explore accepted state transitions', () {
    test('moves immediately and preserves every unrelated slice', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = _autoExploreState(
        units: [_autoExploreScout()],
        fogOfWar: _autoExploreActorFog(visible: {origin}, discovered: {origin}),
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 2));

      _expectImmediateAutoExplore(result, state);
    });

    test('moves a reachable prefix and queues the manual distant route', () {
      final known = {
        for (var col = 0; col <= 3; col++) HexCoordinate(col: col, row: 0),
      };
      final state = _autoExploreState(
        units: [_autoExploreScout(movementPoints: 1)],
        fogOfWar: _autoExploreActorFog(visible: known, discovered: known),
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 5));

      _expectPartialAutoExplore(result, state);
    });

    test('hidden foreign city is an accepted privacy-preserving no-op', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = _autoExploreState(
        units: [_autoExploreScout(movementPoints: 1)],
        cities: const [
          GameCity(
            id: 'hidden_foreign_city',
            ownerPlayerId: _autoExploreOpponentId,
            name: 'Hidden foreign city',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        fogOfWar: _autoExploreActorFog(visible: {origin}, discovered: {origin}),
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 5));

      _expectHiddenAcceptedNoOp(result, state);
    });

    test('persistent result exposes events but no movement execution', () {
      const origin = HexCoordinate(col: 0, row: 0);
      final state = _autoExploreState(
        units: [_autoExploreScout()],
        fogOfWar: _autoExploreActorFog(visible: {origin}, discovered: {origin}),
      );

      final result = _resolveAutoExplore(state, _autoExploreMap(cols: 2));
      final dynamic currentSurface = result;

      expect(result.accepted, isTrue);
      expect(result.events.single, isA<UnitMovedEvent>());
      // Deliberately probe the pre-kernel public surface being characterized.
      // ignore: avoid_dynamic_calls
      expect(() => currentSurface.execution, throwsNoSuchMethodError);
    });
  });
}
