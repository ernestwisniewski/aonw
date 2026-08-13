import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:test/test.dart';

void main() {
  group('MovementPointScale', () {
    test('converts and formats fixed-point movement units', () {
      expect(MovementPointScale.unitsPerPoint, 2);
      expect(MovementPointScale.unitsFromWholePoints(3), 6);
      expect(MovementPointScale.pointsFromUnits(3), 1.5);
      expect(MovementPointScale.displayPointsFromUnits(6), 3);
      expect(MovementPointScale.displayPointsFromUnits(3), 1.5);
      expect(MovementPointScale.wholePointsFromUnits(7), 3);
      expect(MovementPointScale.formatUnits(6), '3');
      expect(MovementPointScale.formatUnits(7), '3.5');
      expect(
        UnitMovementBalance.maxMovementUnitsForType(GameUnitType.warrior),
        6,
      );
    });
  });

  group('MovementSnapshotMigration', () {
    test('scales persisted route and pending-action movement costs', () {
      final original = <String, dynamic>{
        'units': <Object?>[
          <String, dynamic>{
            'id': 'merchant_1',
            'queuedPath': <String, dynamic>{
              'steps': <Object?>[
                <String, dynamic>{
                  'col': 0,
                  'enterCost': 0,
                  'cumulativeCost': 0,
                },
                <String, dynamic>{
                  'col': 1,
                  'enterCost': 1.9,
                  'cumulativeCost': 2,
                },
                'unknown-step',
              ],
            },
            'merchantTradeRoute': <String, dynamic>{
              'steps': <Object?>[
                <String, dynamic>{'enterCost': 2, 'cumulativeCost': 3},
              ],
            },
          },
          'unknown-unit',
        ],
        'lifecycle': <String, dynamic>{
          'turn': 7,
          'pendingAction': <String, dynamic>{
            'type': 'unitTurnSkip',
            'restoreMovementPoints': 3,
          },
        },
      };

      final migrated = MovementSnapshotMigration.fromWholePointCosts(original);

      expect(migrated, <String, dynamic>{
        'units': <Object?>[
          <String, dynamic>{
            'id': 'merchant_1',
            'queuedPath': <String, dynamic>{
              'steps': <Object?>[
                <String, dynamic>{
                  'col': 0,
                  'enterCost': 0,
                  'cumulativeCost': 0,
                },
                <String, dynamic>{
                  'col': 1,
                  'enterCost': 2,
                  'cumulativeCost': 4,
                },
                'unknown-step',
              ],
            },
            'merchantTradeRoute': <String, dynamic>{
              'steps': <Object?>[
                <String, dynamic>{'enterCost': 4, 'cumulativeCost': 6},
              ],
            },
          },
          'unknown-unit',
        ],
        'lifecycle': <String, dynamic>{
          'turn': 7,
          'pendingAction': <String, dynamic>{
            'type': 'unitTurnSkip',
            'restoreMovementUnits': 6,
          },
        },
      });
      final originalUnit = (original['units'] as List).first as Map;
      final originalSteps =
          (originalUnit['queuedPath'] as Map)['steps'] as List;
      expect(originalSteps[1], <String, dynamic>{
        'col': 1,
        'enterCost': 1.9,
        'cumulativeCost': 2,
      });
      expect(
        (original['lifecycle'] as Map)['pendingAction'],
        containsPair('restoreMovementPoints', 3),
      );
    });

    test('preserves current and unrecognized snapshot shapes', () {
      final state = <String, dynamic>{
        'units': <Object?>[
          <String, dynamic>{
            'queuedPath': <String, dynamic>{'steps': 'unknown'},
            'merchantTradeRoute': 'unknown',
          },
        ],
        'lifecycle': <String, dynamic>{
          'pendingAction': <String, dynamic>{
            'restoreMovementPoints': 3,
            'restoreMovementUnits': 5,
          },
        },
      };

      expect(MovementSnapshotMigration.fromWholePointCosts(state), state);
      expect(
        MovementSnapshotMigration.fromWholePointCosts(<String, dynamic>{
          'units': 'unknown',
          'lifecycle': 'unknown',
        }),
        <String, dynamic>{'units': 'unknown', 'lifecycle': 'unknown'},
      );
    });
  });

  group('PendingUnitTurnSkip movement units', () {
    test('round-trips units and accepts legacy whole-point JSON', () {
      const current = PendingUnitTurnSkip(
        ownerPlayerId: 'player_1',
        unitId: 'unit_1',
        restoreMovementUnits: 5,
      );

      expect(PendingPlayerAction.fromJson(current.toJson()), current);
      expect(current.restoreMovementPoints, 2);
      expect(current.ownsUnit('unit_1'), isTrue);
      expect(
        PendingPlayerAction.fromJson(const <String, dynamic>{
          'type': 'unitSleep',
          'ownerPlayerId': 'player_1',
          'unitId': 'unit_1',
          'restoreMovementPoints': 3,
        }),
        const PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: 'unit_1',
          restoreMovementUnits: 6,
        ),
      );
    });
  });
}
