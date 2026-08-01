import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('TurnVictoryProgressResolver parity', () {
    test('matches persistent domination holds and threshold event', () {
      const players = ['p1', 'p2'];
      final state = DomainState.snapshot(
        cities: [
          const GameCity(
            id: 'city_p1',
            ownerPlayerId: 'p1',
            name: 'City one',
            center: CityHex(col: 0, row: 0),
            controlledHexes: [CityHex(col: 1, row: 0)],
          ),
          const GameCity(
            id: 'city_p2',
            ownerPlayerId: 'p2',
            name: 'City two',
            center: CityHex(col: 2, row: 0),
          ),
        ],
      );
      final map = _mapData(3);
      final rules = VictoryRules.standard.copyWith(
        dominationControlPercent: 60,
        dominationHoldTurns: 3,
        culturalEnabled: false,
      );
      const calculator = DominationProgressCalculator();
      final persistentHolds = calculator.advanceHoldTurns(
        playerIds: players,
        state: state,
        mapData: map,
        victoryRules: rules,
        previousHoldTurnsByPlayerId: const {},
      );
      final persistentEvents = calculator.thresholdReachedEvents(
        playerIds: players,
        state: state,
        mapData: map,
        victoryRules: rules,
        previousHoldTurnsByPlayerId: const {},
        nextHoldTurnsByPlayerId: persistentHolds,
      );

      final neutral = TurnVictoryProgressResolver.resolve(
        playerIds: players,
        cities: state.cities,
        artifacts: state.artifacts,
        previousDominationHoldTurnsByPlayerId: const {},
        previousCulturalHoldTurnsByPlayerId: const {'p2': 4},
        mapCatalog: map,
        victoryRules: rules,
      );

      expect(neutral.dominationHoldTurns, persistentHolds);
      expect(
        _eventJson(neutral.dominationEvents),
        _eventJson(persistentEvents),
      );
      expect(neutral.dominationEvents.single.playerId, 'p1');
      expect(neutral.culturalHoldTurns, {'p2': 4});
    });

    test('matches persistent cultural hold advancement', () {
      const players = ['p1', 'p2'];
      const previousCulturalHolds = {'p1': 2, 'p2': 3};
      final state = DomainState.snapshot(
        cities: [
          const GameCity(
            id: 'city_p1',
            ownerPlayerId: 'p1',
            name: 'City one',
            center: CityHex(col: 0, row: 0),
          ),
          const GameCity(
            id: 'city_p2',
            ownerPlayerId: 'p2',
            name: 'City two',
            center: CityHex(col: 1, row: 0),
          ),
        ],
        artifacts: [
          const WorldArtifact(
            id: 'artifact_1',
            type: WorldArtifactType.ancientImperialCrown,
            location: WorldArtifactLocation.stored(cityId: 'city_p1'),
          ),
          const WorldArtifact(
            id: 'artifact_2',
            type: WorldArtifactType.astronomersTablets,
            location: WorldArtifactLocation.stored(cityId: 'city_p1'),
          ),
        ],

        culturalVictoryHoldTurnsByPlayerId: previousCulturalHolds,
      );
      final rules = VictoryRules.standard.copyWith(
        dominationEnabled: false,
        culturalRequiredArtifacts: 2,
      );
      final persistent = CulturalVictoryProgressCalculator.advanceHoldTurns(
        playerIds: players,
        state: state,
        previousHoldTurnsByPlayerId: previousCulturalHolds,
        requiredArtifactCount: rules.culturalRequiredArtifacts,
      );

      final neutral = TurnVictoryProgressResolver.resolve(
        playerIds: players,
        cities: state.cities,
        artifacts: state.artifacts,
        previousDominationHoldTurnsByPlayerId: const {'p2': 2},
        previousCulturalHoldTurnsByPlayerId: previousCulturalHolds,
        mapCatalog: _mapData(2),
        victoryRules: rules,
      );

      expect(neutral.culturalHoldTurns, persistent);
      expect(neutral.culturalHoldTurns, {'p1': 3});
      expect(neutral.dominationHoldTurns, isEmpty);
      expect(neutral.dominationEvents, isEmpty);
    });
  });
}

List<Map<String, dynamic>> _eventJson(Iterable<GameEvent> events) =>
    events.map(GameEventSerializer.toJson).toList();

WorldMap _mapData(int cols) {
  return WorldMap(
    cols: cols,
    rows: 1,
    tiles: [
      for (var col = 0; col < cols; col++)
        WorldTile(
          col: col,
          row: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
