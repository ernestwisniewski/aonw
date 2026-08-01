import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/domain/state/domain_action_unit_rules.dart';
import 'package:test/test.dart';

void main() {
  group('DomainActionUnitRules.clearOwnedByUnit', () {
    test('preserves identity when the unit owns no action', () {
      const actions = DomainActionState.empty;

      expect(
        DomainActionUnitRules.clearOwnedByUnit(actions, 'unit'),
        same(actions),
      );
    });

    test('clears an owned pending action', () {
      final actions = DomainActionState(
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: 'player',
          unitId: 'unit',
          restoreMovementPoints: 1,
        ),
      );

      final result = DomainActionUnitRules.clearOwnedByUnit(actions, 'unit');

      expect(result.pendingAction, isNull);
    });

    test('clears an owned city founding draft', () {
      final actions = DomainActionState(
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'unit',
          ownerPlayerId: 'player',
          center: const CityHex(col: 1, row: 2),
        ),
      );

      final result = DomainActionUnitRules.clearOwnedByUnit(actions, 'unit');

      expect(result.cityFoundingDraft, isNull);
    });

    test('clears both actions when they belong to the unit', () {
      final actions = DomainActionState(
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'unit',
          ownerPlayerId: 'player',
          center: const CityHex(col: 1, row: 2),
        ),
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: 'player',
          unitId: 'unit',
          restoreMovementPoints: 1,
        ),
      );

      final result = DomainActionUnitRules.clearOwnedByUnit(actions, 'unit');

      expect(result, DomainActionState.empty);
    });
  });
}
