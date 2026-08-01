part of 'game_hud_test.dart';

const _hudQaScenarios = [
  (name: 'compact portrait', size: Size(678, 1442)),
  (name: 'tablet portrait', size: Size(840, 1436)),
  (name: 'desktop wide', size: Size(2592, 1438)),
];

GameClientState _hudQaState() {
  final city = GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City 4',
    center: const CityHex(col: 1, row: 1),
    population: 17,
    productionQueue: CityProductionQueue.building(
      buildingType: CityBuildingType.granary,
      investedProduction: 0,
    ),
  );
  return GameClientState(
    activePlayerId: 'player_1',
    cities: [city],
    playerGold: const {'player_1': 4496},
    interaction: InteractionState(
      selection: GameSelection.city(
        city,
        cityYield: const TileYield(
          food: 10,
          production: 35,
          gold: 0,
          defense: 0,
        ),
        playerColor: _player.colorValue,
      ),
    ),
  );
}

void _expectWarmPanelSurface(
  WidgetTester tester,
  Key key, {
  required String reason,
}) {
  final surface = tester.widget<DecoratedBox>(find.byKey(key));
  final decoration = surface.decoration;
  expect(decoration, isA<BoxDecoration>(), reason: reason);
  final box = decoration as BoxDecoration;
  expect(box.gradient, isA<LinearGradient>(), reason: reason);
  expect(box.color, isNull, reason: reason);
}
