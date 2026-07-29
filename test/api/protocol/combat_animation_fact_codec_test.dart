import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('decodes recipient-projected combat animation facts', () {
    const codec = EventCodec();
    final wire = WireEvent(
      matchId: 'match_1',
      offset: 10,
      timestamp: DateTime.utc(2026, 7, 29),
      events: const [
        {'type': 'UnitAttacked'},
        {
          'type': 'CombatResolved',
          'attackerUnitId': 'attacker',
          'defenderUnitId': 'city',
          'outcome': {
            'attackerUnitId': 'attacker',
            'defenderUnitId': 'city',
            'attackerHpAfter': 5,
            'defenderHpAfter': 1,
            'attackerKilled': false,
            'defenderKilled': false,
            'defenderRetreated': false,
            'steps': [
              {'type': 'Attack', 'damage': 1, 'active': <String>[]},
            ],
          },
          'combatAnimation': {
            'attackerUnitId': 'attacker',
            'defenderId': 'city',
            'attackerFromCol': 2,
            'attackerFromRow': 3,
            'attackerToCol': 3,
            'attackerToRow': 3,
          },
        },
      ],
      movementExecutions: WireMovementExecutionList(const []),
    );

    expect(codec.combatAnimationFactsFromWire(wire), const [
      CombatAnimationFact(
        eventIndex: 1,
        attackerUnitId: 'attacker',
        defenderId: 'city',
        attackerFromCol: 2,
        attackerFromRow: 3,
        attackerToCol: 3,
        attackerToRow: 3,
      ),
    ]);
  });
}
