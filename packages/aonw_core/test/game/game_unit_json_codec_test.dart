import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('GameUnit JSON codec', () {
    test('round-trips fixed-point movement and optional unit state', () {
      final unit = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 2,
        movementUnits: 5,
        army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
        queuedPath: QueuedMovePath(
          targetCol: 2,
          targetRow: 2,
          steps: const [
            UnitMovementStep(col: 2, row: 2, enterCost: 1, cumulativeCost: 1),
          ],
        ),
        merchantTradeRoute: MerchantTradeRoute(
          originCityId: 'city_1',
          destinationCityId: 'city_2',
          transportNetworkFingerprint: '0123456789abcdef',
          steps: const [
            UnitMovementStep(col: 2, row: 2, enterCost: 1, cumulativeCost: 1),
          ],
        ),
        workerJob: const WorkerJob.roadConstruction(
          targetHex: CityHex(col: 1, row: 2),
          remainingTurns: 1,
          totalTurns: 2,
        ),
        workerBuildCharges: 3,
        cityFoundingJob: CityFoundingJob(
          center: const CityHex(col: 2, row: 2),
          controlledHexes: const [CityHex(col: 2, row: 2)],
          remainingTurns: 1,
          totalTurns: 3,
        ),
        workerAssignment: const WorkerAssignment(
          targetHex: CityHex(col: 2, row: 1),
        ),
        hitPoints: 7,
        experiencePoints: 3,
        posture: UnitPosture.autoWorking,
        carriedArtifactId: 'artifact_1',
        excavatingArtifactId: 'artifact_2',
      );

      final json = unit.toJson();
      final restored = GameUnit.fromJson(json);

      expect(json['movementPoints'], 2);
      expect(json['movementSubpoints'], 1);
      expect(
        (json['merchantTradeRoute'] as Map)['transportNetworkFingerprint'],
        '0123456789abcdef',
      );
      expect(unit.exactMovementPoints, 2.5);
      expect(restored, unit);
      expect(
        restored.merchantTradeRoute.hashCode,
        unit.merchantTradeRoute.hashCode,
      );
      expect(unit.copyWithMovementUnits(1).exactMovementPoints, 0.5);
      expect(unit.copyWith(movementPoints: 3).movementUnits, 6);
    });

    test('validates fixed-point movement and artifact JSON fields', () {
      final base = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      ).toJson();

      expect(
        GameUnit.fromJson({...base}..remove('movementPoints')).movementUnits,
        UnitMovementBalance.maxMovementUnitsForType(GameUnitType.warrior),
      );
      for (final subpoints in [-1, MovementPointScale.unitsPerPoint]) {
        expect(
          () => GameUnit.fromJson({...base, 'movementSubpoints': subpoints}),
          throwsArgumentError,
        );
      }
      for (final value in ['', 1]) {
        expect(
          () => GameUnit.fromJson({...base, 'carriedArtifactId': value}),
          throwsArgumentError,
        );
      }
    });
  });
}
