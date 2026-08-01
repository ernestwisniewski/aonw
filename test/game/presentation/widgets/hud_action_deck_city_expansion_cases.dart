part of 'hud_action_deck_test.dart';

void _registerHudActionDeckCityExpansionCases() {
  testWidgets(
    'city expansion confirm action appears above the bottom toolbar',
    (tester) async {
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 0, row: 0),
        preferredExpansionHex: CityHex(col: 1, row: 0),
      );

      await _pumpDeck(
        tester,
        gameState: GameClientState(
          cities: [city],
          interaction: const InteractionState(
            pendingAction: PendingCityExpansionSelection(
              ownerPlayerId: 'player_1',
              cityId: 'city_1',
            ),
          ),
        ),
      );

      final confirmFinder = find.byKey(
        const Key('hudActionDeck.cityExpansionConfirm'),
      );
      final cancelFinder = find.byKey(
        const Key('hudActionDeck.cityExpansionCancel'),
      );
      final commandLineFinder = find.byKey(
        const Key('hudActionDeck.line.commands'),
      );

      expect(confirmFinder, findsOneWidget);
      expect(cancelFinder, findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(
        tester.getRect(confirmFinder).bottom,
        lessThan(tester.getRect(commandLineFinder).top),
      );
      expect(
        tester.getRect(cancelFinder).bottom,
        lessThan(tester.getRect(commandLineFinder).top),
      );
    },
  );

  testWidgets('city expansion confirm waits for a chosen preferred hex', (
    tester,
  ) async {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 0, row: 0),
    );

    await _pumpDeck(
      tester,
      gameState: GameClientState(
        cities: [city],
        interaction: const InteractionState(
          pendingAction: PendingCityExpansionSelection(
            ownerPlayerId: 'player_1',
            cityId: 'city_1',
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key('hudActionDeck.cityExpansionConfirm')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('hudActionDeck.cityExpansionCancel')),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
  });
}
