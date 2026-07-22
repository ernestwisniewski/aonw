import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state/canonical_game_snapshot.dart';
import 'package:aonw_core/game/domain/state/persisted_interaction_unit_rules.dart';
import 'package:test/test.dart';

void main() {
  group('PersistedInteractionUnitRules.clearOwnedByUnit', () {
    test('clears pending action and city draft owned by the unit', () {
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_1'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'unit_1',
        ),
      );

      final result = PersistedInteractionUnitRules.clearOwnedByUnit(
        interaction,
        'unit_1',
      );

      expect(result, isNot(same(interaction)));
      expect(result, PersistedInteractionState.empty);
    });

    test('clears only the owned side of mixed interaction state', () {
      final pendingOwned = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_2'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'unit_1',
        ),
      );
      final pendingOwnedDraft = pendingOwned.cityFoundingDraft;

      final clearedPending = PersistedInteractionUnitRules.clearOwnedByUnit(
        pendingOwned,
        'unit_1',
      );

      expect(clearedPending, isNot(same(pendingOwned)));
      expect(clearedPending.pendingAction, isNull);
      expect(clearedPending.cityFoundingDraft, same(pendingOwnedDraft));

      final draftOwned = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_1'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'unit_2',
        ),
      );
      final draftOwnedPending = draftOwned.pendingAction;

      final clearedDraft = PersistedInteractionUnitRules.clearOwnedByUnit(
        draftOwned,
        'unit_1',
      );

      expect(clearedDraft, isNot(same(draftOwned)));
      expect(clearedDraft.cityFoundingDraft, isNull);
      expect(clearedDraft.pendingAction, same(draftOwnedPending));
    });

    test('preserves identity when every interaction belongs elsewhere', () {
      final interaction = PersistedInteractionState(
        cityFoundingDraft: _draft('unit_2'),
        pendingAction: const PendingAttackTargeting(
          ownerPlayerId: 'player_1',
          attackerUnitId: 'unit_2',
        ),
      );

      final result = PersistedInteractionUnitRules.clearOwnedByUnit(
        interaction,
        'unit_1',
      );

      expect(result, same(interaction));
    });

    test('preserves identity when both interaction slices are null', () {
      final interaction = PersistedInteractionState();

      final result = PersistedInteractionUnitRules.clearOwnedByUnit(
        interaction,
        'unit_1',
      );

      expect(result, same(interaction));
    });
  });
}

CityFoundingDraft _draft(String unitId) {
  return CityFoundingDraft(
    unitId: unitId,
    ownerPlayerId: 'player_1',
    center: const CityHex(col: 0, row: 0),
  );
}
