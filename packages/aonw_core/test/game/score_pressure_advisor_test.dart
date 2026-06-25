import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/outcome.dart';
import 'package:test/test.dart';

void main() {
  group('ScorePressureAdvisor', () {
    const advisor = ScorePressureAdvisor();

    test('protects a sole score leader', () {
      final advice = advisor.adviceFor(
        playerId: 'player_1',
        breakdownByPlayerId: {
          'player_1': _score(
            playerId: 'player_1',
            cityScore: 80,
            populationScore: 24,
            territoryScore: 12,
            buildingScore: 16,
            unitScore: 30,
            technologyScore: 36,
            improvementScore: 10,
            goldScore: 2,
          ),
          'player_2': _score(
            playerId: 'player_2',
            cityScore: 40,
            populationScore: 12,
            territoryScore: 6,
            buildingScore: 8,
            unitScore: 15,
            technologyScore: 18,
            improvementScore: 5,
            goldScore: 0,
          ),
        },
      );

      expect(advice, GameObjectiveAdvice.protectLead);
    });

    test('selects the largest missing score component against the leader', () {
      final advice = advisor.adviceFor(
        playerId: 'player_1',
        breakdownByPlayerId: {
          'player_1': _score(
            playerId: 'player_1',
            cityScore: 40,
            populationScore: 12,
            territoryScore: 6,
            buildingScore: 8,
            unitScore: 15,
            technologyScore: 0,
            improvementScore: 5,
            goldScore: 0,
          ),
          'player_2': _score(
            playerId: 'player_2',
            cityScore: 40,
            populationScore: 12,
            territoryScore: 6,
            buildingScore: 8,
            unitScore: 15,
            technologyScore: 36,
            improvementScore: 5,
            goldScore: 0,
          ),
        },
      );

      expect(advice, GameObjectiveAdvice.unlockTechnology);
    });

    for (final scenario in [
      _AdviceScenario(
        name: 'unit positioning pressure',
        leader: _score(playerId: 'player_2', unitScore: 30),
        expected: GameObjectiveAdvice.trainUnit,
      ),
      _AdviceScenario(
        name: 'production pressure',
        leader: _score(playerId: 'player_2', buildingScore: 24),
        expected: GameObjectiveAdvice.constructBuilding,
      ),
      _AdviceScenario(
        name: 'research pressure',
        leader: _score(playerId: 'player_2', technologyScore: 36),
        expected: GameObjectiveAdvice.unlockTechnology,
      ),
      _AdviceScenario(
        name: 'economy pressure',
        leader: _score(playerId: 'player_2', goldScore: 9),
        expected: GameObjectiveAdvice.collectGold,
      ),
    ]) {
      test('selects ${scenario.name} when it is the only score gap', () {
        final advice = advisor.adviceFor(
          playerId: 'player_1',
          breakdownByPlayerId: {
            'player_1': _score(playerId: 'player_1'),
            'player_2': scenario.leader,
          },
        );

        expect(advice, scenario.expected);
      });
    }

    test('breaks equal score gaps toward the most immediate action type', () {
      final advice = advisor.adviceFor(
        playerId: 'player_1',
        breakdownByPlayerId: {
          'player_1': _score(playerId: 'player_1'),
          'player_2': _score(
            playerId: 'player_2',
            buildingScore: 18,
            technologyScore: 18,
            goldScore: 18,
          ),
        },
      );

      expect(advice, GameObjectiveAdvice.constructBuilding);
    });

    test(
      'uses quick unit pressure as fallback when a score tie has no gap',
      () {
        final advice = advisor.adviceFor(
          playerId: 'player_1',
          breakdownByPlayerId: {
            'player_1': _score(
              playerId: 'player_1',
              cityScore: 40,
              populationScore: 0,
              territoryScore: 0,
              buildingScore: 0,
              unitScore: 0,
              technologyScore: 0,
              improvementScore: 0,
              goldScore: 0,
            ),
            'player_2': _score(
              playerId: 'player_2',
              cityScore: 40,
              populationScore: 0,
              territoryScore: 0,
              buildingScore: 0,
              unitScore: 0,
              technologyScore: 0,
              improvementScore: 0,
              goldScore: 0,
            ),
          },
        );

        expect(advice, GameObjectiveAdvice.trainUnit);
      },
    );
  });
}

EmpireScoreBreakdown _score({
  required String playerId,
  int cityScore = 40,
  int populationScore = 12,
  int territoryScore = 6,
  int buildingScore = 0,
  int unitScore = 0,
  int technologyScore = 0,
  int improvementScore = 0,
  int goldScore = 0,
}) {
  return EmpireScoreBreakdown(
    playerId: playerId,
    cityScore: cityScore,
    populationScore: populationScore,
    territoryScore: territoryScore,
    buildingScore: buildingScore,
    unitScore: unitScore,
    technologyScore: technologyScore,
    improvementScore: improvementScore,
    goldScore: goldScore,
  );
}

class _AdviceScenario {
  final String name;
  final EmpireScoreBreakdown leader;
  final GameObjectiveAdvice expected;

  const _AdviceScenario({
    required this.name,
    required this.leader,
    required this.expected,
  });
}
