import 'package:aonw_core/application.dart';

const rendererCombatAnimationFact = CombatAnimationFact(
  eventIndex: 0,
  attackerUnitId: 'attacker',
  defenderId: 'defender',
  attackerFromCol: 2,
  attackerFromRow: 3,
  attackerToCol: 4,
  attackerToRow: 5,
);

CombatAnimationFact combatAnimationFact({
  required String attackerId,
  required String defenderId,
  required int fromCol,
  required int fromRow,
  required int toCol,
  required int toRow,
  int eventIndex = 0,
}) {
  return CombatAnimationFact(
    eventIndex: eventIndex,
    attackerUnitId: attackerId,
    defenderId: defenderId,
    attackerFromCol: fromCol,
    attackerFromRow: fromRow,
    attackerToCol: toCol,
    attackerToRow: toRow,
  );
}
