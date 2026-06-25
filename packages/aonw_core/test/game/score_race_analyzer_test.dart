import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('ScoreRaceAnalyzer', () {
    const analyzer = ScoreRaceAnalyzer();

    test('stays inactive when score fallback is disabled', () {
      final analysis = analyzer.analyzeForPlayer(
        playerId: 'player_1',
        playerIds: const ['player_1', 'player_2'],
        state: _state(
          cities: [
            _city('city_1', 'player_1', 0),
            _city('city_2', 'player_2', 1),
          ],
        ),
        turn: 10,
        turnLimit: 60,
        scoreFallbackEnabled: false,
      );

      expect(analysis, isNull);
    });

    test('targets a rival score leader before the final pressure window', () {
      final analysis = analyzer.analyzeForPlayer(
        playerId: 'player_1',
        playerIds: const ['player_1', 'player_2'],
        state: _state(
          cities: [
            _city('own_city', 'player_1', 0),
            _city('leader_city_a', 'player_2', 1),
            _city('leader_city_b', 'player_2', 2),
          ],
        ),
        turn: 12,
        turnLimit: 60,
        scoreFallbackEnabled: true,
      );

      expect(analysis, isNotNull);
      expect(analysis!.leaderPlayerId, 'player_2');
      expect(
        analysis.scoreGapToLeader,
        greaterThanOrEqualTo(EmpireScoreCalculator.cityWeight),
      );
      expect(analysis.urgency, 0);
      expect(analysis.pressureTargetPlayerIds(), {'player_2'});
    });

    test('protects lead instead of targeting itself', () {
      final analysis = analyzer.analyzeForPlayer(
        playerId: 'player_1',
        playerIds: const ['player_1', 'player_2'],
        state: _state(
          cities: [
            _city('leader_city_a', 'player_1', 0),
            _city('leader_city_b', 'player_1', 1),
            _city('rival_city', 'player_2', 2),
          ],
        ),
        turn: 12,
        turnLimit: 60,
        scoreFallbackEnabled: true,
      );

      expect(analysis, isNotNull);
      expect(analysis!.isLeader, isTrue);
      expect(
        analysis.leadOverRunnerUp,
        greaterThanOrEqualTo(EmpireScoreCalculator.cityWeight),
      );
      expect(analysis.pressureTargetPlayerIds(), isEmpty);
    });

    test('ramps urgency through the final fifteen percent of turns', () {
      final early = analyzer.analyzeForPlayer(
        playerId: 'player_1',
        playerIds: const ['player_1', 'player_2'],
        state: _state(
          cities: [
            _city('own_city', 'player_1', 0),
            _city('leader_city_a', 'player_2', 1),
            _city('leader_city_b', 'player_2', 2),
          ],
        ),
        turn: 52,
        turnLimit: 60,
        scoreFallbackEnabled: true,
      );
      final late = analyzer.analyzeForPlayer(
        playerId: 'player_1',
        playerIds: const ['player_1', 'player_2'],
        state: _state(
          cities: [
            _city('own_city', 'player_1', 0),
            _city('leader_city_a', 'player_2', 1),
            _city('leader_city_b', 'player_2', 2),
          ],
        ),
        turn: 59,
        turnLimit: 60,
        scoreFallbackEnabled: true,
      );

      expect(early?.pressureWindowTurns, 9);
      expect(early?.urgency, closeTo(1 / 9, 0.001));
      expect(late?.urgency, closeTo(8 / 9, 0.001));
    });
  });
}

PersistentGameState _state({required List<GameCity> cities}) {
  return PersistentGameState(cities: cities);
}

GameCity _city(String id, String ownerPlayerId, int col) {
  return GameCity(
    id: id,
    ownerPlayerId: ownerPlayerId,
    name: id,
    center: CityHex(col: col, row: 0),
  );
}
