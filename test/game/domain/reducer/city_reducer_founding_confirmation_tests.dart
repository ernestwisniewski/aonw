part of 'city_reducer_test.dart';

void _registerCityFoundingConfirmationTests(
  MapData Function() mapDataProvider,
) {
  group('confirmCityFounding', () {
    late MapData mapData;

    setUp(() {
      mapData = mapDataProvider();
    });

    test('starts founding job for commander with settler troop', () {
      final settler = _settler();
      final stateWithDraft = _withCompleteFoundingDraft(
        CityFoundingReducer.startCityFounding(
          GameState(
            units: [settler],
            activePlayerId: 'player_1',
            interaction: GameInteractionState(
              selection: GameSelection.unit(settler),
            ),
          ),
          mapData,
        ),
      );
      expect(stateWithDraft.cityFoundingDraft, isNotNull);

      final result = CityFoundingReducer.confirmCityFounding(
        stateWithDraft,
        FoundCityCommand(
          settler.id,
          controlledHexes: stateWithDraft.cityFoundingDraft!.controlledHexes,
        ),
        mapData,
      );

      expect(result.events, isEmpty);
      expect(result.state.cities, isEmpty);
      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.units.single.hasSettlers, isTrue);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
      expect(result.state.units.single.movementPoints, 0);
    });

    test('starts founding job for standalone settler unit', () {
      final settler = _standaloneSettler();
      final stateWithDraft = _withCompleteFoundingDraft(
        CityFoundingReducer.startCityFounding(
          GameState(
            units: [settler],
            activePlayerId: 'player_1',
            interaction: GameInteractionState(
              selection: GameSelection.unit(settler),
            ),
          ),
          mapData,
        ),
      );
      expect(stateWithDraft.cityFoundingDraft, isNotNull);

      final result = CityFoundingReducer.confirmCityFounding(
        stateWithDraft,
        FoundCityCommand(
          settler.id,
          controlledHexes: stateWithDraft.cityFoundingDraft!.controlledHexes,
        ),
        mapData,
      );

      expect(result.events, isEmpty);
      expect(result.state.cities, isEmpty);
      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
      expect(result.state.selection?.unit?.cityFoundingJob, isNotNull);
    });

    test(
      'uses injected city ruleset progression when founding job completes',
      () {
        final ruleset = CityRulesets.standard.copyWith(
          progression: const CityProgression(
            startPopulation: 5,
            startStoredFood: 2,
            startMaxHexes: 9,
            midGameMaxHexes: 10,
            lateGameMaxHexes: 12,
            startTerritoryRadius: 4,
            expandedTerritoryRadius: 5,
            foodUpkeepPerPopulation: 1,
            growthBaseCost: 10,
            growthCostPerPopulation: 4,
            growthCostPerControlledHex: 3,
          ),
        );
        final settler = _settler();
        final stateWithDraft = _withCompleteFoundingDraft(
          CityFoundingReducer.startCityFounding(
            GameState(
              units: [settler],
              activePlayerId: 'player_1',
              interaction: GameInteractionState(
                selection: GameSelection.unit(settler),
              ),
            ),
            mapData,
          ),
        );
        final scheduled = CityFoundingReducer.confirmCityFounding(
          stateWithDraft,
          FoundCityCommand(
            settler.id,
            controlledHexes: stateWithDraft.cityFoundingDraft!.controlledHexes,
          ),
          mapData,
        );
        final result = CityFoundingJobProcessor.advanceForPlayer(
          playerId: 'player_1',
          units: scheduled.state.units,
          cities: scheduled.state.cities,
          mapTiles: mapData,
          countryForPlayer: scheduled.state.countryForPlayer,
          cityRuleset: ruleset,
        );

        final city = result.cities.single;
        expect(city.population, 5);
        expect(city.storedFood, 2);
        expect(city.maxHexes, 9);
        expect(city.territoryRadius, 4);
      },
    );

    test('rejects an empty controlled-hex payload without a draft', () {
      final settler = _settler();
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        interaction: GameInteractionState(
          selection: GameSelection.unit(settler),
        ),
      );

      final result = CityFoundingReducer.confirmCityFounding(
        state,
        FoundCityCommand(settler.id, controlledHexes: const []),
        mapData,
      );

      expect(result.state, same(state));
    });

    test('can finalise an explicit command without selection', () {
      final settler = _settler();
      final draft = CityFoundingDraft(
        unitId: settler.id,
        ownerPlayerId: 'player_1',
        center: CityHex(col: settler.col, row: settler.row),
        controlledHexes: [
          const CityHex(col: 3, row: 2),
          const CityHex(col: 4, row: 3),
        ],
      );
      final state = GameState(
        units: [settler],
        activePlayerId: 'player_1',
        interaction: GameInteractionState(cityFoundingDraft: draft),
      );

      final result = CityFoundingReducer.confirmCityFounding(
        state,
        FoundCityCommand(settler.id, controlledHexes: draft.controlledHexes),
        mapData,
      );

      expect(result.state.cityFoundingDraft, isNull);
      expect(result.state.cities, isEmpty);
      expect(result.state.units.single.cityFoundingJob, isNotNull);
    });
  });
}
