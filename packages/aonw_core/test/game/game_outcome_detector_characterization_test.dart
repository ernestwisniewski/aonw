import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _players = ['p1', 'p2'];
const _turnLimit = 10;
const _requiredHoldTurns = 5;

final _allVictoryRules = MatchRules(
  gameLength: GameLengthConfig.standard60,
  victory: const VictoryRules(
    conquestEnabled: true,
    dominationEnabled: true,
    dominationControlPercent: 50,
    dominationHoldTurns: _requiredHoldTurns,
    scoreFallbackEnabled: true,
    turnLimit: _turnLimit,
    culturalEnabled: true,
    culturalRequiredArtifacts: 1,
    culturalHoldTurns: _requiredHoldTurns,
  ),
);

void main() {
  group('GameOutcomeDetector precedence characterization', () {
    const detector = GameOutcomeDetector();

    test('conquest wins over simultaneous domination, cultural, and score', () {
      final outcome = detector.evaluate(
        playerIds: _players,
        state: DomainState.snapshot(
          cities: [
            _city(ownerPlayerId: 'p1', col: 0, controlledCols: const [1]),
          ],
          artifacts: [_storedArtifact(ownerPlayerId: 'p1')],

          dominationHoldTurnsByPlayerId: {'p1': _requiredHoldTurns},
          culturalVictoryHoldTurnsByPlayerId: {'p1': _requiredHoldTurns},
        ),
        matchRules: _allVictoryRules,
        mapData: _mapData(2),
        turn: _turnLimit,
      );

      expect(outcome, const GameOutcome.conquest('p1'));
    });

    test('domination wins over simultaneous cultural and score victories', () {
      final outcome = detector.evaluate(
        playerIds: _players,
        state: DomainState.snapshot(
          cities: [
            _city(ownerPlayerId: 'p1', col: 0, controlledCols: const [1, 2]),
            _city(ownerPlayerId: 'p2', col: 3),
          ],
          artifacts: [_storedArtifact(ownerPlayerId: 'p2')],
          playerGold: const {'p2': 10000},

          dominationHoldTurnsByPlayerId: {'p1': _requiredHoldTurns},
          culturalVictoryHoldTurnsByPlayerId: {'p2': _requiredHoldTurns},
        ),
        matchRules: _allVictoryRules,
        mapData: _mapData(4),
        turn: _turnLimit,
      );

      expect(outcome, const GameOutcome.domination('p1'));
    });

    test('a map domination tie falls through to a unique cultural winner', () {
      final outcome = detector.evaluate(
        playerIds: _players,
        state: DomainState.snapshot(
          cities: [
            _city(ownerPlayerId: 'p1', col: 0, controlledCols: const [1]),
            _city(ownerPlayerId: 'p2', col: 2, controlledCols: const [3]),
          ],
          artifacts: [_storedArtifact(ownerPlayerId: 'p2')],

          dominationHoldTurnsByPlayerId: {
            'p1': _requiredHoldTurns,
            'p2': _requiredHoldTurns,
          },
          culturalVictoryHoldTurnsByPlayerId: {'p2': _requiredHoldTurns},
        ),
        matchRules: _allVictoryRules,
        mapData: _mapData(4),
        turn: _turnLimit,
      );

      expect(outcome, const GameOutcome.cultural('p2'));
    });

    test('cultural victory wins over a higher turn-cap score', () {
      final outcome = detector.evaluate(
        playerIds: _players,
        state: DomainState.snapshot(
          units: [_warrior('p2', col: 1)],
          cities: [_city(ownerPlayerId: 'p1', col: 0)],
          artifacts: [_storedArtifact(ownerPlayerId: 'p1')],
          playerGold: const {'p2': 10000},

          culturalVictoryHoldTurnsByPlayerId: {'p1': _requiredHoldTurns},
        ),
        matchRules: _allVictoryRules,
        turn: _turnLimit,
      );

      expect(outcome, const GameOutcome.cultural('p1'));
    });

    test('a cultural tie falls through to the exact score outcome', () {
      final outcome = detector.evaluate(
        playerIds: _players,
        state: DomainState.snapshot(
          cities: [
            _city(ownerPlayerId: 'p1', col: 0),
            _city(ownerPlayerId: 'p2', col: 1),
          ],
          artifacts: [
            _storedArtifact(ownerPlayerId: 'p1'),
            _storedArtifact(ownerPlayerId: 'p2'),
          ],
          playerGold: const {'p2': 100},

          culturalVictoryHoldTurnsByPlayerId: {
            'p1': _requiredHoldTurns,
            'p2': _requiredHoldTurns,
          },
        ),
        matchRules: _allVictoryRules,
        turn: _turnLimit,
      );

      expect(
        outcome,
        GameOutcome.score(
          winnerPlayerId: 'p2',
          scoreByPlayerId: const {'p1': 79, 'p2': 81},
        ),
      );
    });

    test('an equal turn-cap score is a draw with the complete score map', () {
      final outcome = detector.evaluate(
        playerIds: _players,
        state: DomainState.snapshot(
          units: [_warrior('p1', col: 0), _warrior('p2', col: 1)],
        ),
        matchRules: _allVictoryRules,
        turn: _turnLimit,
      );

      expect(
        outcome,
        GameOutcome.draw(scoreByPlayerId: const {'p1': 15, 'p2': 15}),
      );
    });

    test('the score fallback starts exactly at the configured turn limit', () {
      final state = DomainState.snapshot(
        units: [_warrior('p1', col: 0), _warrior('p2', col: 1)],
        playerGold: const {'p1': 100},
      );

      expect(
        detector.evaluate(
          playerIds: _players,
          state: state,
          matchRules: _allVictoryRules,
          turn: _turnLimit - 1,
        ),
        GameOutcome.ongoing,
      );
      expect(
        detector.evaluate(
          playerIds: _players,
          state: state,
          matchRules: _allVictoryRules,
          turn: _turnLimit,
        ),
        GameOutcome.score(
          winnerPlayerId: 'p1',
          scoreByPlayerId: const {'p1': 17, 'p2': 15},
        ),
      );
    });

    test('an equal runtime domination hold keeps the game ongoing', () {
      final outcome = detector.evaluate(
        playerIds: _players,
        state: DomainState.snapshot(
          units: [_warrior('p1', col: 0), _warrior('p2', col: 1)],

          dominationHoldTurnsByPlayerId: {
            'p1': _requiredHoldTurns,
            'p2': _requiredHoldTurns,
          },
        ),
        matchRules: _allVictoryRules,
        turn: _turnLimit - 1,
      );

      expect(outcome, GameOutcome.ongoing);
    });
  });
}

GameUnit _warrior(String ownerPlayerId, {required int col}) {
  return GameUnit.produced(
    id: 'warrior_$ownerPlayerId',
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.warrior,
    col: col,
    row: 0,
  );
}

GameCity _city({
  required String ownerPlayerId,
  required int col,
  List<int> controlledCols = const [],
}) {
  return GameCity(
    id: 'city_$ownerPlayerId',
    ownerPlayerId: ownerPlayerId,
    name: 'city_$ownerPlayerId',
    center: CityHex(col: col, row: 0),
    controlledHexes: [
      for (final controlledCol in controlledCols)
        CityHex(col: controlledCol, row: 0),
    ],
  );
}

WorldArtifact _storedArtifact({required String ownerPlayerId}) {
  return WorldArtifact(
    id: 'artifact_$ownerPlayerId',
    type: WorldArtifactType.ancientImperialCrown,
    location: WorldArtifactLocation.stored(cityId: 'city_$ownerPlayerId'),
  );
}

WorldMap _mapData(int validTiles) {
  return WorldMap(
    cols: validTiles,
    rows: 1,
    tiles: [
      for (var col = 0; col < validTiles; col++)
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
