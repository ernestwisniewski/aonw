import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('StateHeuristicEvaluator', () {
    test('scores stronger rollout state above weaker state', () {
      const evaluator = StateHeuristicEvaluator();
      final strong = _state(
        PersistentGameState(
          playerGold: const {'player_1': 50},
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 1,
            ),
            GameUnit(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              name: 'Worker',
              col: 1,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 3,
              buildings: {CityBuildingType.granary},
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                unlockedTechnologyIds: {TechnologyId.agriculture},
                activeTechnologyId: TechnologyId.mining,
                progressByTechnologyId: const {TechnologyId.mining: 4},
              ),
            },
          ),
          fogOfWar: _visibleFog(),
        ),
      );
      final weak = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'enemy_1',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 1,
              row: 0,
            ),
          ],
          fogOfWar: _visibleFog(),
        ),
      );

      expect(
        evaluator.score(strong, 'player_1'),
        greaterThan(evaluator.score(weak, 'player_1')),
      );
    });

    test('keeps scores normalized', () {
      const evaluator = StateHeuristicEvaluator();
      final state = _state(
        PersistentGameState(
          playerGold: const {'player_1': 10000},
          units: [
            for (var i = 0; i < 20; i++)
              GameUnit(
                id: 'warrior_$i',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: 0,
                row: 0,
              ),
          ],
          cities: [
            for (var i = 0; i < 20; i++)
              GameCity(
                id: 'city_$i',
                ownerPlayerId: 'player_1',
                name: 'City',
                center: const CityHex(col: 0, row: 0),
                population: 10,
                buildings: CityBuildingType.values.toSet(),
              ),
          ],
          fogOfWar: _visibleFog(),
        ),
      );

      expect(evaluator.score(state, 'player_1'), inInclusiveRange(-1.0, 1.0));
    });

    test('preserves gradient for developed empires', () {
      const evaluator = StateHeuristicEvaluator();
      final fourCityState = _state(_developedEmpire(cityCount: 4));
      final fiveCityState = _state(_developedEmpire(cityCount: 5));

      final fourCityScore = evaluator.score(fourCityState, 'player_1');
      final fiveCityScore = evaluator.score(fiveCityState, 'player_1');

      expect(fiveCityScore, greaterThan(fourCityScore));
      expect(fiveCityScore, lessThan(1.0));
    });

    test('penalizes an over-sprawled empire that falls into unrest', () {
      const evaluator = StateHeuristicEvaluator();
      final mapData = _squareMap(cols: 40, rows: 1);
      final context = _context(mapData: mapData);

      PersistentGameState empire(List<int> cityCols) => PersistentGameState(
        cities: [
          for (var i = 0; i < cityCols.length; i++)
            GameCity(
              id: 'city_$i',
              ownerPlayerId: 'player_1',
              name: 'City $i',
              center: CityHex(col: cityCols[i], row: 0),
              population: 3,
            ),
        ],
        fogOfWar: _fogForHexes({
          for (var col = 0; col < 40; col++) HexCoordinate(col: col, row: 0),
        }),
      );

      // Same city count, population and buildings; only the spacing differs, so
      // the cohesion cost (and thus the stability band) is the isolated driver.
      final compact = _state(empire([0, 2, 3]), mapData: mapData);
      final sprawled = _state(empire([0, 20, 39]), mapData: mapData);

      expect(
        evaluator.score(compact, 'player_1', context: context),
        greaterThan(evaluator.score(sprawled, 'player_1', context: context)),
      );
    });
  });

  group('CommandSequenceEvaluator', () {
    test('rewards queued settlers while expansion is still desired', () {
      const evaluator = CommandSequenceEvaluator();
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 1,
            ),
            GameUnit(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              name: 'Worker',
              col: 1,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _visibleFog(),
        ),
      );
      final context = _context(
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
      );

      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
      final warriorState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );

      expect(
        evaluator.score(settlerState, 'player_1', context: context),
        greaterThan(
          evaluator.score(warriorState, 'player_1', context: context),
        ),
      );
    });

    test('devalues settler production before any military coverage', () {
      const evaluator = CommandSequenceEvaluator();
      final base = _state(
        PersistentGameState(
          units: const [],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _visibleFog(),
        ),
      );
      final context = _context(
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
        persona: AiPersona.aggressive,
      );

      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
      final workerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.worker),
        ),
      );

      expect(
        evaluator.score(settlerState, 'player_1', context: context),
        lessThan(evaluator.score(workerState, 'player_1', context: context)),
      );
    });

    test('rewards safe second-city settler before worker recovery', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _fogForHexes({
            for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
          }),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
      );

      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
      final workerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.worker),
        ),
      );

      expect(
        evaluator.score(settlerState, 'player_1', context: context),
        greaterThan(evaluator.score(workerState, 'player_1', context: context)),
      );
    });

    test('rewards reinforced second-city settler over projects', () {
      const evaluator = CommandSequenceEvaluator();
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'worker_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.worker,
              name: 'Worker',
              col: 0,
              row: 1,
            ),
            for (var index = 0; index < 3; index++)
              GameUnit(
                id: 'warrior_$index',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: index,
                row: 0,
              ),
            GameUnit(
              id: 'enemy_1',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Enemy',
              col: 3,
              row: 1,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 5,
              buildings: {CityBuildingType.granary},
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _visibleFog(),
        ),
      );
      final context = _context(
        strategicPlan: _strategicPlan(mode: StrategicMode.recover),
        persona: AiPersona.economic,
        civProfile: CivilizationProfiles.all[PlayerCountry.netherlands]!,
      );

      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
      final projectState = base.apply(
        const CommandMctsAction(
          StartCityProjectCommand('city_1', CityProjectType.research),
        ),
      );

      expect(
        evaluator.score(settlerState, 'player_1', context: context),
        greaterThan(
          evaluator.score(projectState, 'player_1', context: context),
        ),
      );
    });

    test('rewards escort production for an exposed active settler', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 5);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 5,
              row: 2,
            ),
            GameUnit(
              id: 'enemy_1',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Enemy',
              col: 6,
              row: 2,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _fogForHexes({
            for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
          }),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
      );

      final defenderState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );
      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );

      expect(
        evaluator.score(defenderState, 'player_1', context: context),
        greaterThan(
          evaluator.score(settlerState, 'player_1', context: context),
        ),
      );
    });

    test(
      'rewards core defender production for economic civs under pressure',
      () {
        const evaluator = CommandSequenceEvaluator();
        final base = _state(
          PersistentGameState(
            units: [
              GameUnit(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: 0,
                row: 0,
              ),
              GameUnit(
                id: 'enemy_1',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                name: 'Enemy',
                col: 1,
                row: 0,
              ),
            ],
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'City',
                center: CityHex(col: 0, row: 0),
                population: 4,
              ),
            ],
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
            fogOfWar: _visibleFog(),
          ),
        );
        final context = _context(
          persona: AiPersona.economic,
          civProfile: CivilizationProfiles.all[PlayerCountry.netherlands]!,
          strategicPlan: _strategicPlan(
            mode: StrategicMode.consolidate,
            defenses: {
              'city_1': StrategicDefenseAssignment(
                cityId: 'city_1',
                cityCenter: const CityHex(col: 0, row: 0),
                threatLevel: 8,
                assignedUnitIds: const ['warrior_1'],
                primaryThreatPlayerId: 'player_2',
              ),
            },
          ),
        );

        final defenderState = base.apply(
          const CommandMctsAction(
            StartUnitProductionCommand('city_1', GameUnitType.warrior),
          ),
        );
        final settlerState = base.apply(
          const CommandMctsAction(
            StartUnitProductionCommand('city_1', GameUnitType.settler),
          ),
        );

        expect(
          evaluator.score(defenderState, 'player_1', context: context),
          greaterThan(
            evaluator.score(settlerState, 'player_1', context: context),
          ),
        );
      },
    );

    test('rewards fortifying assigned garrisons near a threatened city', () {
      const evaluator = CommandSequenceEvaluator();
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
              hitPoints: 6,
            ),
            GameUnit(
              id: 'enemy_1',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Enemy',
              col: 1,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
          ],
          fogOfWar: _visibleFog(),
        ),
      );
      final context = _context(
        strategicPlan: _strategicPlan(
          defenses: {
            'city_1': StrategicDefenseAssignment(
              cityId: 'city_1',
              cityCenter: const CityHex(col: 0, row: 0),
              threatLevel: 6,
              assignedUnitIds: const ['warrior_1'],
              primaryThreatPlayerId: 'player_2',
            ),
          },
        ),
      );

      final fortifyState = base.apply(
        const CommandMctsAction(FortifyUnitCommand('warrior_1')),
      );

      expect(
        evaluator.score(fortifyState, 'player_1', context: context),
        greaterThan(0.05),
      );
    });

    test('devalues german opening settler before reserve defense', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _visibleFog(),
        ),
        mapData: mapData,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        persona: profile.defaultPersona,
        civProfile: profile,
      );

      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
      final defenderState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );

      expect(
        evaluator.score(defenderState, 'player_1', context: context),
        greaterThan(
          evaluator.score(settlerState, 'player_1', context: context),
        ),
      );
    });

    test('rewards stable third-city settlers despite military appetite', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 4,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 4, row: 0),
              population: 2,
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _visibleFog(),
        ),
        mapData: mapData,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        persona: profile.defaultPersona,
        civProfile: profile,
      );

      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
      final warriorState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );

      expect(
        evaluator.score(settlerState, 'player_1', context: context),
        greaterThan(
          evaluator.score(warriorState, 'player_1', context: context),
        ),
      );
    });

    test('holds third-city settlers when enemies pressure the core', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 4,
              row: 0,
            ),
            GameUnit(
              id: 'enemy_1',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Enemy',
              col: 1,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 4, row: 0),
              population: 2,
            ),
          ],
          fogOfWar: _visibleFog(),
        ),
        mapData: mapData,
      );
      final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        persona: profile.defaultPersona,
        civProfile: profile,
      );

      final settlerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.settler),
        ),
      );
      final warriorState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.warrior),
        ),
      );

      expect(
        evaluator.score(settlerState, 'player_1', context: context),
        lessThan(evaluator.score(warriorState, 'player_1', context: context)),
      );
    });

    test(
      'allows third-city settlers under pressure when escort reserves exist',
      () {
        const evaluator = CommandSequenceEvaluator();
        final mapData = _squareMap(cols: 8, rows: 8);
        final base = _state(
          PersistentGameState(
            units: [
              for (var i = 1; i <= 3; i++)
                GameUnit(
                  id: 'warrior_$i',
                  ownerPlayerId: 'player_1',
                  type: GameUnitType.warrior,
                  name: 'Warrior',
                  col: i == 1 ? 0 : 4,
                  row: i - 1,
                ),
              GameUnit(
                id: 'enemy_1',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                name: 'Enemy',
                col: 1,
                row: 0,
              ),
            ],
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
                population: 4,
              ),
              GameCity(
                id: 'city_2',
                ownerPlayerId: 'player_1',
                name: 'Second',
                center: CityHex(col: 4, row: 0),
                population: 2,
              ),
            ],
            fogOfWar: _visibleFog(),
          ),
          mapData: mapData,
        );
        final profile = CivilizationProfiles.all[PlayerCountry.germany]!;
        final context = _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
          persona: profile.defaultPersona,
          civProfile: profile,
        );

        final settlerState = base.apply(
          const CommandMctsAction(
            StartUnitProductionCommand('city_1', GameUnitType.settler),
          ),
        );
        final warriorState = base.apply(
          const CommandMctsAction(
            StartUnitProductionCommand('city_1', GameUnitType.warrior),
          ),
        );

        expect(
          evaluator.score(settlerState, 'player_1', context: context),
          greaterThan(
            evaluator.score(warriorState, 'player_1', context: context),
          ),
        );
      },
    );

    test('rewards worker production before background projects', () {
      const evaluator = CommandSequenceEvaluator();
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'City',
              center: CityHex(col: 0, row: 0),
              population: 4,
            ),
          ],
          research: ResearchState(
            players: {
              'player_1': PlayerResearchState(
                activeTechnologyId: TechnologyId.agriculture,
              ),
            },
          ),
          fogOfWar: _visibleFog(),
        ),
      );
      final context = _context(
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
      );

      final workerState = base.apply(
        const CommandMctsAction(
          StartUnitProductionCommand('city_1', GameUnitType.worker),
        ),
      );
      final projectState = base.apply(
        const CommandMctsAction(
          StartCityProjectCommand('city_1', CityProjectType.wealth),
        ),
      );

      expect(
        evaluator.score(workerState, 'player_1', context: context),
        greaterThan(
          evaluator.score(projectState, 'player_1', context: context),
        ),
      );
    });

    test(
      'rewards military recovery before workers for aggressive openings',
      () {
        const evaluator = CommandSequenceEvaluator();
        final base = _state(
          PersistentGameState(
            units: [
              GameUnit(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: 0,
                row: 0,
              ),
            ],
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_1',
                name: 'City',
                center: CityHex(col: 0, row: 0),
                population: 4,
              ),
            ],
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  activeTechnologyId: TechnologyId.agriculture,
                ),
              },
            ),
            fogOfWar: _visibleFog(),
          ),
        );
        final context = _context(
          strategicPlan: _strategicPlan(mode: StrategicMode.military),
          persona: AiPersona.aggressive,
        );

        final warriorState = base.apply(
          const CommandMctsAction(
            StartUnitProductionCommand('city_1', GameUnitType.warrior),
          ),
        );
        final workerState = base.apply(
          const CommandMctsAction(
            StartUnitProductionCommand('city_1', GameUnitType.worker),
          ),
        );

        expect(
          evaluator.score(warriorState, 'player_1', context: context),
          greaterThan(
            evaluator.score(workerState, 'player_1', context: context),
          ),
        );
      },
    );

    test('devalues low-impact melee skirmishes', () {
      const evaluator = CommandSequenceEvaluator();
      SimulatedState stateWithEnemy({int? enemyHitPoints}) {
        return _state(
          PersistentGameState(
            units: [
              GameUnit(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: 0,
                row: 0,
              ),
              GameUnit(
                id: 'enemy_1',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                name: 'Enemy',
                col: 1,
                row: 0,
                hitPoints: enemyHitPoints,
              ),
            ],
            fogOfWar: _visibleFog(),
          ),
        );
      }

      final context = _context();
      final lowImpactState = stateWithEnemy().apply(
        const CommandMctsAction(AttackHexCommand('warrior_1', 1, 0)),
      );
      final finishingState = stateWithEnemy(
        enemyHitPoints: 1,
      ).apply(const CommandMctsAction(AttackHexCommand('warrior_1', 1, 0)));

      expect(
        evaluator.score(lowImpactState, 'player_1', context: context),
        lessThan(0.08),
      );
      expect(
        evaluator.score(finishingState, 'player_1', context: context),
        greaterThan(
          evaluator.score(lowImpactState, 'player_1', context: context),
        ),
      );
    });

    test('does not score far defense anchors as war-goal attacks', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 5, rows: 1);
      final visibleHexes = {
        for (var col = 0; col < 5; col++) HexCoordinate(col: col, row: 0),
      };
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 3,
              row: 0,
            ),
            GameUnit(
              id: 'enemy_1',
              ownerPlayerId: 'player_2',
              type: GameUnitType.archer,
              name: 'Enemy',
              col: 4,
              row: 0,
            ),
          ],
          fogOfWar: _fogForHexes(visibleHexes),
        ),
        mapData: mapData,
      );
      final planned = SimulatedState(
        view: base.view,
        plannedActions: const [
          CommandMctsAction(AttackHexCommand('warrior_1', 4, 0)),
        ],
        maxPlanningDepth: 4,
      );

      final baselineScore = evaluator.score(
        planned,
        'player_1',
        context: _context(mapData: mapData),
      );
      final farDefensiveScore = evaluator.score(
        planned,
        'player_1',
        context: _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            warGoals: [
              WarGoal(
                targetPlayerId: 'player_2',
                kind: WarGoalKind.defend,
                targetHex: const HexCoordinate(col: 0, row: 0),
                turnsBudget: 4,
                assignedUnitIds: const ['warrior_1'],
                priority: 5,
              ),
            ],
          ),
        ),
      );
      final localDefensiveScore = evaluator.score(
        planned,
        'player_1',
        context: _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(
            warGoals: [
              WarGoal(
                targetPlayerId: 'player_2',
                kind: WarGoalKind.defend,
                targetHex: const HexCoordinate(col: 2, row: 0),
                turnsBudget: 4,
                assignedUnitIds: const ['warrior_1'],
                priority: 5,
              ),
            ],
          ),
        ),
      );

      expect(farDefensiveScore, closeTo(baselineScore, 0.0001));
      expect(localDefensiveScore, greaterThan(farDefensiveScore));
    });

    test('rewards settler moves that reveal assigned founding rings', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 5, rows: 5);
      final visibleHexes = {
        const HexCoordinate(col: 0, row: 0),
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 2, row: 2),
                  ) <
                  CityFoundingRules.minimumCenterDistance &&
              tile.col < 4)
            HexCoordinate.fromTile(tile),
      };
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 2,
              row: 2,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
          ],
          fogOfWar: _fogForHexes(visibleHexes),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.expand,
          settlerAssignments: const {'settler_1': CityHex(col: 2, row: 2)},
        ),
      );

      final revealState = base.apply(
        const CommandMctsAction(MoveUnitCommand('settler_1', 3, 2)),
      );
      final ordinaryState = base.apply(
        const CommandMctsAction(MoveUnitCommand('settler_1', 1, 2)),
      );

      expect(
        evaluator.score(revealState, 'player_1', context: context),
        greaterThan(
          evaluator.score(ordinaryState, 'player_1', context: context),
        ),
      );
    });

    test('rewards assigned settler progress before the reveal step', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 6, rows: 5);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 2,
              row: 2,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 0, row: 4),
            ),
          ],
          fogOfWar: _fogForHexes({
            for (var col = 0; col < 6; col++)
              for (var row = 0; row < 5; row++)
                HexCoordinate(col: col, row: row),
          }),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.military,
          settlerAssignments: const {'settler_1': CityHex(col: 5, row: 2)},
        ),
      );

      final towardState = base.apply(
        const CommandMctsAction(MoveUnitCommand('settler_1', 3, 2)),
      );
      final awayState = base.apply(
        const CommandMctsAction(MoveUnitCommand('settler_1', 1, 2)),
      );

      expect(
        evaluator.score(towardState, 'player_1', context: context),
        greaterThan(evaluator.score(awayState, 'player_1', context: context)),
      );
    });

    test('rewards unassigned settlers moving out of crowded city spacing', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 6, rows: 5);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 1,
              row: 0,
            ),
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
            GameUnit(
              id: 'warrior_2',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 4,
              row: 0,
            ),
            GameUnit(
              id: 'warrior_3',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 4,
              row: 1,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 4, row: 0),
            ),
          ],
          fogOfWar: _fogForHexes({
            for (var col = 0; col < 6; col++)
              for (var row = 0; row < 5; row++)
                HexCoordinate(col: col, row: row),
          }),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
      );

      final frontierState = base.apply(
        const CommandMctsAction(MoveUnitCommand('settler_1', 3, 4)),
      );
      final crampedState = base.apply(
        const CommandMctsAction(MoveUnitCommand('settler_1', 0, 1)),
      );

      expect(
        evaluator.score(frontierState, 'player_1', context: context),
        greaterThan(
          evaluator.score(crampedState, 'player_1', context: context),
        ),
      );
    });

    test('rewards incremental settler spacing progress near owned cities', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 5, rows: 5);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 0,
              row: 1,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 4, row: 4),
            ),
          ],
          fogOfWar: _fogForHexes({
            for (var col = 0; col < 5; col++)
              for (var row = 0; row < 5; row++)
                HexCoordinate(col: col, row: row),
          }),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
      );

      final spacingState = base.apply(
        const CommandMctsAction(MoveUnitCommand('settler_1', 0, 2)),
      );
      final idleState = base.apply(
        const CommandMctsAction(SkipUnitTurnCommand('settler_1')),
      );

      expect(
        evaluator.score(spacingState, 'player_1', context: context),
        greaterThan(evaluator.score(idleState, 'player_1', context: context)),
      );
    });

    test('rewards scout moves that reveal third-city site frontiers', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final visibleHexes = {
        for (final tile in mapData.tiles)
          if (HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 0, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 7, row: 0),
                  ) <=
                  2 ||
              HexDistance.between(
                    HexCoordinate.fromTile(tile),
                    const HexCoordinate(col: 3, row: 2),
                  ) <=
                  2)
            HexCoordinate.fromTile(tile),
      };
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 1,
              row: 0,
            ),
            GameUnit(
              id: 'scout_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.scout,
              name: 'Scout',
              col: 3,
              row: 2,
            ),
            GameUnit(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 0,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 7, row: 0),
            ),
          ],
          fogOfWar: _fogForHexes(visibleHexes),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.recover),
      );

      final discoveryState = base.apply(
        const CommandMctsAction(MoveUnitCommand('scout_1', 4, 4)),
      );
      final localState = base.apply(
        const CommandMctsAction(FortifyUnitCommand('scout_1')),
      );

      expect(
        evaluator.score(discoveryState, 'player_1', context: context),
        greaterThan(evaluator.score(localState, 'player_1', context: context)),
      );
    });

    test('rewards military moves toward assigned frontier blockers', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 4,
              row: 5,
            ),
            GameUnit(
              id: 'warrior_clearer',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 2,
              row: 4,
            ),
            GameUnit(
              id: 'blocker',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Enemy',
              col: 4,
              row: 4,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 7, row: 0),
            ),
          ],
          fogOfWar: _fogForHexes({
            for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
          }),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.expand,
          frontierClearingAssignments: const {
            'warrior_clearer': StrategicFrontierClearingAssignment(
              unitId: 'warrior_clearer',
              founderId: 'settler_1',
              targetPlayerId: 'player_2',
              targetHex: HexCoordinate(col: 4, row: 4),
              founderDistance: 1,
              priority: 4.5,
            ),
          },
        ),
      );

      final clearingMove = base.apply(
        const CommandMctsAction(MoveUnitCommand('warrior_clearer', 3, 4)),
      );
      final localMove = base.apply(
        const CommandMctsAction(MoveUnitCommand('warrior_clearer', 1, 4)),
      );

      expect(
        evaluator.score(clearingMove, 'player_1', context: context),
        greaterThan(evaluator.score(localMove, 'player_1', context: context)),
      );
    });

    test('rewards assigned attacks that clear settler blockers', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 4,
              row: 5,
            ),
            GameUnit(
              id: 'warrior_clearer',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 3,
              row: 4,
            ),
            GameUnit(
              id: 'blocker',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Enemy',
              col: 4,
              row: 4,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
            GameCity(
              id: 'second',
              ownerPlayerId: 'player_1',
              name: 'Second',
              center: CityHex(col: 7, row: 0),
            ),
          ],
          fogOfWar: _fogForHexes({
            for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
          }),
        ),
        mapData: mapData,
      );
      final genericContext = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.expand),
      );
      final clearingContext = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(
          mode: StrategicMode.expand,
          frontierClearingAssignments: const {
            'warrior_clearer': StrategicFrontierClearingAssignment(
              unitId: 'warrior_clearer',
              founderId: 'settler_1',
              targetPlayerId: 'player_2',
              targetHex: HexCoordinate(col: 4, row: 4),
              founderDistance: 1,
              priority: 4.5,
            ),
          },
        ),
      );
      final attackState = base.apply(
        const CommandMctsAction(AttackHexCommand('warrior_clearer', 4, 4)),
      );

      expect(
        evaluator.score(attackState, 'player_1', context: clearingContext),
        greaterThan(
          evaluator.score(attackState, 'player_1', context: genericContext),
        ),
      );
    });

    test('rewards attacks that protect active settlers without assignment', () {
      const evaluator = CommandSequenceEvaluator();
      final mapData = _squareMap(cols: 8, rows: 8);
      final base = _state(
        PersistentGameState(
          units: [
            GameUnit(
              id: 'settler_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.settler,
              name: 'Settler',
              col: 4,
              row: 5,
            ),
            GameUnit(
              id: 'warrior_clearer',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              name: 'Warrior',
              col: 3,
              row: 5,
            ),
            GameUnit(
              id: 'blocker',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              name: 'Enemy',
              col: 4,
              row: 6,
            ),
          ],
          cities: const [
            GameCity(
              id: 'capital',
              ownerPlayerId: 'player_1',
              name: 'Capital',
              center: CityHex(col: 0, row: 0),
            ),
          ],
          fogOfWar: _fogForHexes({
            for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
          }),
        ),
        mapData: mapData,
      );
      final context = _context(
        mapData: mapData,
        strategicPlan: _strategicPlan(mode: StrategicMode.recover),
      );
      final attackState = base.apply(
        const CommandMctsAction(AttackHexCommand('warrior_clearer', 4, 6)),
      );
      final fortifyState = base.apply(
        const CommandMctsAction(FortifyUnitCommand('warrior_clearer')),
      );

      expect(
        evaluator.score(attackState, 'player_1', context: context),
        greaterThan(
          evaluator.score(fortifyState, 'player_1', context: context),
        ),
      );
    });

    test(
      'rewards military moves that close escort distance to threatened settlers',
      () {
        const evaluator = CommandSequenceEvaluator();
        final mapData = _squareMap(cols: 6, rows: 6);
        final base = _state(
          PersistentGameState(
            units: [
              GameUnit(
                id: 'settler_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.settler,
                name: 'Settler',
                col: 4,
                row: 3,
              ),
              GameUnit(
                id: 'warrior_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.warrior,
                name: 'Warrior',
                col: 1,
                row: 3,
              ),
              GameUnit(
                id: 'enemy_1',
                ownerPlayerId: 'player_2',
                type: GameUnitType.warrior,
                name: 'Enemy',
                col: 4,
                row: 5,
              ),
            ],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: 'player_1',
                name: 'Capital',
                center: CityHex(col: 0, row: 0),
              ),
              GameCity(
                id: 'second',
                ownerPlayerId: 'player_1',
                name: 'Second',
                center: CityHex(col: 5, row: 0),
              ),
            ],
            fogOfWar: _fogForHexes({
              for (var col = 0; col < 6; col++)
                for (var row = 0; row < 6; row++)
                  HexCoordinate(col: col, row: row),
            }),
          ),
          mapData: mapData,
        );
        final context = _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.consolidate),
        );

        final escortState = base.apply(
          const CommandMctsAction(MoveUnitCommand('warrior_1', 3, 3)),
        );
        final distantState = base.apply(
          const CommandMctsAction(MoveUnitCommand('warrior_1', 0, 3)),
        );

        expect(
          evaluator.score(escortState, 'player_1', context: context),
          greaterThan(
            evaluator.score(distantState, 'player_1', context: context),
          ),
        );
      },
    );

    test(
      'penalizes one-city settler moves into remembered enemy city pressure',
      () {
        const evaluator = CommandSequenceEvaluator();
        final mapData = _squareMap(cols: 8, rows: 7);
        final visibleHexes = {
          for (final tile in mapData.tiles) HexCoordinate.fromTile(tile),
        };
        final base = _state(
          PersistentGameState(
            units: [
              GameUnit(
                id: 'settler_1',
                ownerPlayerId: 'player_1',
                type: GameUnitType.settler,
                name: 'Settler',
                col: 4,
                row: 1,
              ),
            ],
            cities: const [
              GameCity(
                id: 'capital',
                ownerPlayerId: 'player_1',
                name: 'Capital',
                center: CityHex(col: 4, row: 0),
              ),
              GameCity(
                id: 'enemy_city',
                ownerPlayerId: 'player_2',
                name: 'Enemy City',
                center: CityHex(col: 6, row: 5),
                controlledHexes: [CityHex(col: 6, row: 4)],
              ),
            ],
            fogOfWar: _fogForHexes(visibleHexes),
          ),
          mapData: mapData,
        );
        final context = _context(
          mapData: mapData,
          strategicPlan: _strategicPlan(mode: StrategicMode.expand),
        );

        final unsafeState = base.apply(
          const CommandMctsAction(MoveUnitCommand('settler_1', 6, 4)),
        );
        final saferState = base.apply(
          const CommandMctsAction(MoveUnitCommand('settler_1', 3, 1)),
        );

        expect(
          evaluator.score(unsafeState, 'player_1', context: context),
          lessThan(evaluator.score(saferState, 'player_1', context: context)),
        );
      },
    );
  });
}

AiContext _context({
  StrategicPlan? strategicPlan,
  MapData? mapData,
  AiPersona persona = AiPersona.balanced,
  CivilizationProfile civProfile = CivilizationProfiles.poland,
}) {
  final actualMapData = mapData ?? _mapData();
  return AiContext(
    ruleset: GameRuleset.defaults,
    mapData: actualMapData,
    turn: 1,
    rng: AiRng.fromTurn(turn: 1, playerId: 'player_1', baseSeed: 7),
    persona: persona,
    civProfile: civProfile,
    strategicPlan: strategicPlan,
  );
}

StrategicPlan _strategicPlan({
  StrategicMode mode = StrategicMode.consolidate,
  Map<String, CityHex> settlerAssignments = const {},
  Map<String, StrategicFrontierClearingAssignment> frontierClearingAssignments =
      const {},
  List<WarGoal> warGoals = const [],
  Map<String, StrategicDefenseAssignment> defenses = const {},
}) {
  return StrategicPlan(
    computedAtTurn: 1,
    mode: mode,
    expectations: const EconomyExpectations(
      expectedCityCount: 1,
      expectedWorkerCount: 1,
      expectedMilitaryCount: 1,
      goldReserveTarget: 8,
      minimumSciencePerTurn: 2,
    ),
    settlerAssignments: settlerAssignments,
    frontierClearingAssignments: frontierClearingAssignments,
    warGoals: warGoals,
    defenses: defenses,
  );
}

SimulatedState _state(PersistentGameState state, {MapData? mapData}) {
  final actualMapData = mapData ?? _mapData();
  return SimulatedState.fromView(
    GameView.fromPersistentState(
      state,
      forPlayerId: 'player_1',
      turn: 1,
      mapData: actualMapData,
      ruleset: GameRuleset.defaults,
    ),
    maxPlanningDepth: 4,
  );
}

FogOfWarState _visibleFog() {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: {
          const HexCoordinate(col: 0, row: 0),
          const HexCoordinate(col: 1, row: 0),
        },
      ),
    },
  );
}

FogOfWarState _fogForHexes(Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        visibleHexes: visibleHexes,
      ),
    },
  );
}

MapData _mapData() {
  return _squareMap(cols: 2, rows: 1);
}

PersistentGameState _developedEmpire({required int cityCount}) {
  return PersistentGameState(
    playerGold: const {'player_1': 500},
    units: [
      for (var i = 0; i < cityCount * 2; i++)
        GameUnit(
          id: 'warrior_$i',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        ),
    ],
    cities: [
      for (var i = 0; i < cityCount; i++)
        GameCity(
          id: 'city_$i',
          ownerPlayerId: 'player_1',
          name: 'City $i',
          center: const CityHex(col: 0, row: 0),
          population: 8,
          buildings: CityBuildingType.values.toSet(),
        ),
    ],
    research: ResearchState(
      players: {
        'player_1': PlayerResearchState(
          unlockedTechnologyIds: TechnologyId.values.take(6).toSet(),
          activeTechnologyId: TechnologyId.mining,
          progressByTechnologyId: const {TechnologyId.mining: 12},
        ),
      },
    ),
    fogOfWar: _visibleFog(),
  );
}

MapData _squareMap({required int cols, required int rows}) {
  return MapData(
    cols: cols,
    rows: rows,
    tiles: [
      for (var col = 0; col < cols; col++)
        for (var row = 0; row < rows; row++)
          TileData(
            col: col,
            row: row,
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
    ],
  );
}
