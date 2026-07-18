import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('CityHitPointRecoveryProcessor parity', () {
    test(
      'matches recovery, attack suppression, artifacts, and player scope',
      () {
        const cities = [
          GameCity(
            id: 'recovering_p1',
            ownerPlayerId: 'p1',
            name: 'Recovering',
            center: CityHex(col: 0, row: 0),
            hitPoints: 10,
          ),
          GameCity(
            id: 'attacked_p1',
            ownerPlayerId: 'p1',
            name: 'Attacked',
            center: CityHex(col: 1, row: 0),
            hitPoints: 7,
          ),
          GameCity(
            id: 'artifact_p1',
            ownerPlayerId: 'p1',
            name: 'Artifact city',
            center: CityHex(col: 2, row: 0),
            hitPoints: 16,
          ),
          GameCity(
            id: 'foreign_p2',
            ownerPlayerId: 'p2',
            name: 'Foreign',
            center: CityHex(col: 3, row: 0),
            hitPoints: 5,
          ),
        ];
        const artifacts = [
          WorldArtifact(
            id: 'crown',
            type: WorldArtifactType.ancientImperialCrown,
            location: WorldArtifactLocation.stored(cityId: 'artifact_p1'),
          ),
        ];
        final events = [
          CombatResolvedEvent(
            attackerUnitId: 'attacker',
            defenderUnitId: 'attacked_p1',
            outcome: CombatOutcome(
              attackerUnitId: 'attacker',
              defenderUnitId: 'attacked_p1',
              attackerHpAfter: 8,
              defenderHpAfter: 7,
              attackerKilled: false,
              defenderKilled: false,
            ),
          ),
        ];

        final neutral = CityHitPointRecoveryProcessor.recoverForPlayer(
          cities: cities,
          artifacts: artifacts,
          events: events,
          combatRuleset: CombatRuleset.standard,
          playerId: 'p1',
        );
        final persistent =
            PersistentCityHitPointRecoveryProcessor.recoverForPlayer(
              cities: cities,
              artifacts: artifacts,
              events: events,
              combatRuleset: CombatRuleset.standard,
              playerId: 'p1',
            );
        final byId = {for (final city in neutral) city.id: city};

        expect(neutral, persistent);
        expect(byId['recovering_p1']?.hitPoints, 11);
        expect(byId['attacked_p1']?.hitPoints, 7);
        expect(
          byId['artifact_p1']?.hitPoints,
          isNull,
          reason: 'artifact-adjusted maximum HP remains represented by null',
        );
        expect(byId['foreign_p2']?.hitPoints, 5);
        expect(
          PersistentCityHitPointRecoveryProcessor.hitPointsPerTurn,
          CityHitPointRecoveryProcessor.hitPointsPerTurn,
        );
      },
    );
  });
}
