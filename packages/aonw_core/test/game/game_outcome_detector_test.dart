import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameOutcomeDetector', () {
    const detector = GameOutcomeDetector();
    const players = ['player_1', 'player_2'];

    test('keeps the game ongoing while multiple players have map presence', () {
      final outcome = detector.evaluate(
        playerIds: players,
        state: PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_2',
              ownerPlayerId: 'player_2',
              name: 'Antium',
              center: CityHex(col: 1, row: 1),
            ),
          ],
        ),
      );

      expect(outcome.finished, isFalse);
      expect(outcome.winnerPlayerId, isNull);
      expect(outcome.condition, GameOutcomeCondition.ongoing);
    });

    test('declares a winner when only one player has units or cities', () {
      final outcome = detector.evaluate(
        playerIds: players,
        state: PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.winnerPlayerId, 'player_1');
      expect(outcome.condition, GameOutcomeCondition.conquest);
    });

    test('keeps conquest priority over domination progress', () {
      final outcome = detector.evaluate(
        playerIds: players,
        mapData: _mapData(4),
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        state: const PersistentGameState(
          cities: [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [CityHex(col: 1, row: 0)],
            ),
          ],
          runtimeState: GameRuntimeState(
            dominationHoldTurnsByPlayerId: {'player_1': 2},
          ),
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.winnerPlayerId, 'player_1');
      expect(outcome.condition, GameOutcomeCondition.conquest);
    });

    test('respects disabled conquest victories', () {
      final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);
      final outcome = detector.evaluate(
        playerIds: players,
        turn: matchRules.victory.turnLimit,
        matchRules: matchRules.copyWith(
          victory: matchRules.victory.copyWith(conquestEnabled: false),
        ),
        state: PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_1',
              ownerPlayerId: 'player_1',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.condition, GameOutcomeCondition.score);
      expect(outcome.winnerPlayerId, 'player_1');
    });

    test('does not finish single-player or malformed player lists', () {
      final state = PersistentGameState(
        units: [
          GameUnit.produced(
            id: 'warrior_1',
            ownerPlayerId: 'player_1',
            type: GameUnitType.warrior,
            col: 0,
            row: 0,
          ),
        ],
      );

      expect(
        detector.evaluate(playerIds: const ['player_1'], state: state).finished,
        isFalse,
      );
      expect(
        detector.evaluate(playerIds: const [], state: state).finished,
        isFalse,
      );
    });

    test('ignores map presence for ids outside the match roster', () {
      final outcome = detector.evaluate(
        playerIds: players,
        state: PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'outsider_unit',
              ownerPlayerId: 'outsider',
              type: GameUnitType.warrior,
              col: 0,
              row: 0,
            ),
          ],
        ),
      );

      expect(outcome.finished, isFalse);
    });

    test('keeps unlimited games ongoing even after high turn counts', () {
      final outcome = detector.evaluate(
        playerIds: players,
        turn: 200,
        matchRules: MatchRules.standard,
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
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
          ],
        ),
      );

      expect(outcome.finished, isFalse);
      expect(outcome.condition, GameOutcomeCondition.ongoing);
    });

    test('declares domination winner after required hold turns', () {
      final outcome = detector.evaluate(
        playerIds: players,
        mapData: _mapData(4),
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        state: PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 3,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [
                CityHex(col: 1, row: 0),
                CityHex(col: 2, row: 0),
              ],
            ),
          ],
          runtimeState: const GameRuntimeState(
            dominationHoldTurnsByPlayerId: {'player_1': 10},
          ),
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.condition, GameOutcomeCondition.domination);
      expect(outcome.winnerPlayerId, 'player_1');
    });

    test('keeps domination ongoing before the hold requirement is met', () {
      final outcome = detector.evaluate(
        playerIds: players,
        mapData: _mapData(4),
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
        state: PersistentGameState(
          units: [
            GameUnit.produced(
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 3,
              row: 0,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              center: CityHex(col: 0, row: 0),
              controlledHexes: [
                CityHex(col: 1, row: 0),
                CityHex(col: 2, row: 0),
              ],
            ),
          ],
          runtimeState: const GameRuntimeState(
            dominationHoldTurnsByPlayerId: {'player_1': 9},
          ),
        ),
      );

      expect(outcome.finished, isFalse);
      expect(outcome.condition, GameOutcomeCondition.ongoing);
    });

    test('uses runtime domination holds when map data is unavailable', () {
      final outcome = detector.evaluate(
        playerIds: players,
        matchRules: MatchRules.forGameLength(GameLengthConfig.standard60),
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
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 3,
              row: 0,
            ),
          ],
          runtimeState: const GameRuntimeState(
            dominationHoldTurnsByPlayerId: {'player_1': 10},
          ),
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.condition, GameOutcomeCondition.domination);
      expect(outcome.winnerPlayerId, 'player_1');
    });

    test('declares a score winner when the configured turn cap is reached', () {
      final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);
      final outcome = detector.evaluate(
        playerIds: players,
        turn: matchRules.victory.turnLimit,
        matchRules: matchRules,
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
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
          ],
          cities: const [
            GameCity(
              id: 'city_1',
              ownerPlayerId: 'player_1',
              name: 'Roma',
              population: 3,
              center: CityHex(col: 0, row: 0),
              controlledHexes: [CityHex(col: 0, row: 1)],
            ),
          ],
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.condition, GameOutcomeCondition.score);
      expect(outcome.winnerPlayerId, 'player_1');
      expect(
        outcome.scoreByPlayerId['player_1'],
        greaterThan(outcome.scoreByPlayerId['player_2']!),
      );
    });

    test('returns draw when capped players have equal score', () {
      final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);
      final outcome = detector.evaluate(
        playerIds: players,
        turn: matchRules.victory.turnLimit,
        matchRules: matchRules,
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
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
              row: 1,
            ),
          ],
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.condition, GameOutcomeCondition.draw);
      expect(outcome.winnerPlayerId, isNull);
      expect(outcome.scoreByPlayerId, {'player_1': 15, 'player_2': 15});
    });

    test('uses held map objective victory points for score cap', () {
      const objective = MapObjectiveDefinition(
        id: 'pass_1',
        type: MapObjectiveType.strategicPass,
        hex: CityHex(col: 0, row: 0),
        requiredHoldTurns: 2,
        victoryPoints: 4,
      );
      final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);
      final outcome = detector.evaluate(
        playerIds: players,
        turn: matchRules.victory.turnLimit,
        matchRules: matchRules,
        mapData: _mapData(2, objectives: const [objective]),
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
              id: 'warrior_2',
              ownerPlayerId: 'player_2',
              type: GameUnitType.warrior,
              col: 1,
              row: 0,
            ),
          ],
          runtimeState: const GameRuntimeState(
            mapObjectiveHoldStatesByObjectiveId: {
              'pass_1': MapObjectiveHoldState(
                objectiveId: 'pass_1',
                playerId: 'player_1',
                holdTurns: 2,
              ),
            },
          ),
        ),
      );

      expect(outcome.finished, isTrue);
      expect(outcome.condition, GameOutcomeCondition.score);
      expect(outcome.winnerPlayerId, 'player_1');
      expect(outcome.scoreByPlayerId, {'player_1': 19, 'player_2': 15});
    });
  });
}

MapData _mapData(
  int validTiles, {
  Iterable<MapObjectiveDefinition> objectives = const [],
}) {
  return MapData(
    cols: validTiles,
    rows: 1,
    objectives: objectives,
    tiles: [
      for (var col = 0; col < validTiles; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
