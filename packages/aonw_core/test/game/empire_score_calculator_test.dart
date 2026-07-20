import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('EmpireScoreCalculator', () {
    const calculator = EmpireScoreCalculator();

    test('scores cities, population, territory, buildings and units', () {
      final state = PersistentGameState(
        playerGold: const {'player_1': 75},
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ).copyWith(experiencePoints: 10),
          GameUnit.produced(
            id: 'worker_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.worker,
            col: 1,
            row: 0,
          ),
        ],
        cities: const [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Roma',
            population: 4,
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 0, row: 1)],
            buildings: {CityBuildingType.granary},
          ),
        ],
        fieldImprovements: const [
          FieldImprovement(
            hex: CityHex(col: 0, row: 1),
            type: FieldImprovementType.farm,
            builtByCityId: 'city_1',
          ),
        ],
        research: ResearchState(
          players: {
            'player_1': PlayerResearchState(
              unlockedTechnologyIds: {TechnologyId.trade},
            ),
          },
        ),
      );

      final score = calculator.scoreFor(playerId: 'player_1', state: state);

      expect(score.cityScore, 40);
      expect(score.populationScore, 48);
      expect(score.territoryScore, 6);
      expect(score.buildingScore, 8);
      expect(score.unitScore, 29);
      expect(score.technologyScore, 18);
      expect(score.improvementScore, 5);
      expect(score.goldScore, 1);
      expect(score.mapObjectiveScore, 0);
      expect(score.total, 155);
    });

    test(
      'caps large gold stockpiles so score fallback rewards economy shape',
      () {
        const state = PersistentGameState(playerGold: {'player_1': 20000});

        final score = calculator.scoreFor(playerId: 'player_1', state: state);

        expect(score.goldScore, EmpireScoreCalculator.maxGoldScore);
        expect(score.total, EmpireScoreCalculator.maxGoldScore);
      },
    );

    test('adds held map objective victory points to score', () {
      const objective = MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 0, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 7,
      );
      const state = PersistentGameState(
        cities: [
          GameCity(
            id: 'city_1',
            ownerPlayerId: 'player_1',
            name: 'Roma',
            center: CityHex(col: 0, row: 0),
          ),
        ],
        runtimeState: GameRuntimeState(
          mapObjectiveHoldStatesByObjectiveId: {
            'pass_1': MapObjectiveHoldState(
              objectiveId: 'pass_1',
              playerId: 'player_1',
              holdTurns: 2,
            ),
          },
        ),
      );

      final score = calculator.scoreFor(
        playerId: 'player_1',
        state: state,
        mapObjectives: const [objective],
      );

      expect(score.mapObjectiveScore, 7);
      expect(score.total, 86);
    });

    test('scores explicit collections and objective hold states', () {
      const objective = MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: HexCoord(col: 0, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 7,
      );
      const cities = [
        GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Roma',
          center: CityHex(col: 0, row: 0),
        ),
      ];
      final units = [
        GameUnit.produced(
          id: 'warrior_2',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 1,
          row: 0,
        ),
      ];
      const objectiveHolds = {
        'pass_1': MapObjectiveHoldState(
          objectiveId: 'pass_1',
          playerId: 'player_1',
          holdTurns: 2,
        ),
      };

      final score = calculator.scoreForCollections(
        playerId: 'player_1',
        cities: cities,
        units: units,
        fieldImprovements: const [],
        research: ResearchState.empty,
        playerGold: const {},
        mapObjectives: const [objective],
        mapObjectiveHoldStatesByObjectiveId: objectiveHolds,
      );
      final scores = calculator.scoresForCollections(
        playerIds: const ['player_2', 'player_1'],
        cities: cities,
        units: units,
        fieldImprovements: const [],
        research: ResearchState.empty,
        playerGold: const {},
        mapObjectives: const [objective],
        mapObjectiveHoldStatesByObjectiveId: objectiveHolds,
      );

      expect(score.mapObjectiveScore, 7);
      expect(score.total, 86);
      expect(scores, const {'player_1': 86, 'player_2': 15});
    });

    test('returns stable sorted scores for the requested roster only', () {
      final scores = calculator.scoresFor(
        playerIds: const ['player_2', 'outsider', 'player_1', 'player_2'],
        state: PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
            GameUnit.produced(
              id: 'tank_outsider',
              ownerPlayerId: 'ignored',
              type: GameUnitType.tank,
              col: 1,
              row: 0,
            ),
          ],
        ),
      );

      expect(scores.keys.toList(), ['outsider', 'player_1', 'player_2']);
      expect(scores['player_1'], 15);
      expect(scores['player_2'], 0);
      expect(scores['outsider'], 0);
    });
  });
}
