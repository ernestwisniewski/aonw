part of 'turn_reducer_test.dart';

void _registerTurnReducerActionTargetFocusTests(WorldMap Function() mapData) {
  test('focusTurnStartAction always starts from first ranked action', () {
    final unit = GameUnit.produced(
      id: 'warrior_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      col: 1,
      row: 1,
    );
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 2, row: 2),
      controlledHexes: [CityHex(col: 2, row: 2)],
      productionQueue: null,
    );
    final state = GameClientState(
      units: [unit],
      cities: [city],
      activePlayerId: 'player_1',
      interaction: InteractionState(
        selection: GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0xFF4a7fc4,
        ),
      ),
    );

    final result = TurnReducer.focusTurnStartAction(
      state,
      'player_1',
      mapData(),
    );

    expect(result.state.selection?.unit?.id, unit.id);
    expect(result.state.moveCommandActive, isTrue);
    final jump = result.uiEffects.whereType<JumpCameraEffect>().single;
    expect(jump.col, 1);
    expect(jump.row, 1);
    _expectActionTargetFocus(result, unitId: unit.id, col: 1, row: 1);
  });

  test('focusTurnStartAction marks a selected city hex', () {
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 3, row: 2),
      controlledHexes: [CityHex(col: 3, row: 2)],
      population: 1,
      productionQueue: null,
    );
    final state = GameClientState(
      cities: const [city],
      activePlayerId: 'player_1',
      research: ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      ),
    );

    final result = TurnReducer.focusTurnStartAction(
      state,
      'player_1',
      mapData(),
    );

    expect(result.state.selection?.city?.id, city.id);
    _expectActionTargetFocus(result, col: 3, row: 2);
  });
}

void _expectActionTargetFocus(
  GameStateTransition result, {
  String? unitId,
  required int col,
  required int row,
}) {
  final focus = result.uiEffects
      .whereType<ShowActionTargetFocusEffect>()
      .single;
  expect(focus.unitId, unitId);
  expect(focus.col, col);
  expect(focus.row, row);
  expect(focus.duration, const Duration(seconds: 2));
}
