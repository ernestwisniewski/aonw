import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameRuntimeState', () {
    test('empty json restores empty runtime state', () {
      final runtimeState = GameRuntimeState.fromJson(const {});
      expect(runtimeState, GameRuntimeState.empty);
    });

    test('round-trips city founding draft and pending action', () {
      final runtimeState = GameRuntimeState(
        cityFoundingDraft: CityFoundingDraft(
          unitId: 'commander_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 2, row: 3),
          controlledHexes: const [
            CityHex(col: 2, row: 4),
            CityHex(col: 3, row: 3),
          ],
        ),
        pendingAction: const PendingWorkerActionSelection(
          ownerPlayerId: 'player_1',
          unitId: 'worker_1',
          improvementType: FieldImprovementType.mine,
        ),
        submittedPlayerIds: const {'player_2', 'player_1'},
        timeoutStreaksByPlayerId: const {'player_2': 2},
        afkPlayerIds: const {'player_2'},
        kickedPlayerIds: const {'player_3'},
        intendedAttacks: const [
          IntendedAttack(
            attackerUnitId: 'warrior_1',
            defenderCol: 4,
            defenderRow: 5,
            declaredAtTick: 7,
            declaringPlayerId: 'player_1',
          ),
        ],
        diplomacy: DiplomacyState.empty.registerUnitAttack(
          attackerPlayerId: 'player_1',
          defenderPlayerId: 'player_2',
          turn: 3,
        ),
        dominationHoldTurnsByPlayerId: const {'player_2': 1, 'player_1': 3},
      );

      final restored = GameRuntimeState.fromJson(runtimeState.toJson());
      expect(restored, runtimeState);
      expect(restored.submittedPlayerIds, {'player_1', 'player_2'});
      expect(restored.timeoutStreaksByPlayerId, {'player_2': 2});
      expect(restored.afkPlayerIds, {'player_2'});
      expect(restored.kickedPlayerIds, {'player_3'});
      expect(restored.toJson()['submittedPlayerIds'], ['player_1', 'player_2']);
      expect(restored.toJson()['dominationHoldTurnsByPlayerId'], {
        'player_1': 3,
        'player_2': 1,
      });
      expect(
        restored.diplomacy.statusBetween('player_1', 'player_2'),
        DiplomaticRelationStatus.hostile,
      );
      expect(restored.intendedAttacks.single.attackerUnitId, 'warrior_1');
    });
  });

  group('GameState interaction mode', () {
    test('defaults to standard mode', () {
      const state = GameState();
      expect(state.interactionMode, GameInteractionMode.standard);
    });

    test('prefers city founding over other mode flags', () {
      final state =
          GameState(
            interaction: GameInteractionState(
              moveCommandActive: true,
              cityFoundingDraft: CityFoundingDraft(
                unitId: 'commander_1',
                ownerPlayerId: 'player_1',
                center: const CityHex(col: 2, row: 3),
              ),
            ),
          ).copyWithInteraction(
            pendingAction: const PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'commander_1',
            ),
          );

      expect(state.interactionMode, GameInteractionMode.cityFounding);
    });

    test('uses pending action mode when present', () {
      final state = const GameState().copyWithInteraction(
        pendingAction: const PendingCommanderMergeSelection(
          ownerPlayerId: 'player_1',
          commanderUnitId: 'commander_1',
        ),
      );

      expect(state.interactionMode, GameInteractionMode.commanderMerge);
    });

    test('uses city worked hex pending action mode', () {
      final state = const GameState().copyWithInteraction(
        pendingAction: const PendingCityWorkedHexSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
      );

      expect(state.interactionMode, GameInteractionMode.cityWorkedHexSelection);
      expect(
        PendingPlayerAction.fromJson(state.pendingAction!.toJson()),
        state.pendingAction,
      );
    });

    test('uses city expansion pending action mode', () {
      final state = const GameState().copyWithInteraction(
        pendingAction: const PendingCityExpansionSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
      );

      expect(state.interactionMode, GameInteractionMode.cityExpansionSelection);
      expect(
        PendingPlayerAction.fromJson(state.pendingAction!.toJson()),
        state.pendingAction,
      );
    });

    test('uses research selection pending action mode', () {
      final state = const GameState().copyWithInteraction(
        pendingAction: const PendingResearchSelection(
          ownerPlayerId: 'player_1',
        ),
      );

      expect(state.interactionMode, GameInteractionMode.researchSelection);
      expect(
        PendingPlayerAction.fromJson(state.pendingAction!.toJson()),
        state.pendingAction,
      );
    });

    test('uses merchant move-to-city pending action mode', () {
      final state = const GameState().copyWithInteraction(
        pendingAction: const PendingMerchantMoveToCitySelection(
          ownerPlayerId: 'player_1',
          unitId: 'merchant_1',
        ),
      );

      expect(
        state.interactionMode,
        GameInteractionMode.merchantMoveToCitySelection,
      );
      expect(
        PendingPlayerAction.fromJson(state.pendingAction!.toJson()),
        state.pendingAction,
      );
    });

    test('uses unit turn skip pending action mode', () {
      final state = const GameState().copyWithInteraction(
        pendingAction: const PendingUnitTurnSkip(
          ownerPlayerId: 'player_1',
          unitId: 'warrior_1',
          restoreMovementPoints: 2,
        ),
      );

      expect(state.interactionMode, GameInteractionMode.unitTurnSkip);
      expect(
        PendingPlayerAction.fromJson(state.pendingAction!.toJson()),
        state.pendingAction,
      );
    });

    test('runtimeState getter exposes persistent interaction slice', () {
      final state = const GameState().copyWithInteraction(
        pendingAction: const PendingCityWorkedHexSelection(
          ownerPlayerId: 'player_1',
          cityId: 'city_1',
        ),
      );

      expect(state.runtimeState.pendingAction, state.pendingAction);
      expect(state.runtimeState.submittedPlayerIds, isEmpty);
    });

    test('runtimeState getter exposes submitted players', () {
      const state = GameState(submittedPlayerIds: {'player_1'});

      expect(state.hasSubmittedTurn('player_1'), isTrue);
      expect(state.runtimeState.hasSubmitted('player_1'), isTrue);
    });

    test('runtimeState getter exposes intended attacks', () {
      const attack = IntendedAttack(
        attackerUnitId: 'warrior_1',
        defenderCol: 4,
        defenderRow: 5,
        declaredAtTick: 7,
        declaringPlayerId: 'player_1',
      );
      const state = GameState(intendedAttacks: [attack]);

      expect(state.runtimeState.intendedAttacks, [attack]);
    });

    test('runtimeState getter exposes diplomacy', () {
      final diplomacy = DiplomacyState.empty.registerCityAttack(
        attackerPlayerId: 'player_1',
        defenderPlayerId: 'player_2',
      );
      final state = GameState(diplomacy: diplomacy);

      expect(state.runtimeState.diplomacy, diplomacy);
    });

    test('runtimeState getter exposes domination hold turns', () {
      const state = GameState(dominationHoldTurnsByPlayerId: {'player_1': 2});

      expect(state.runtimeState.dominationHoldTurnsByPlayerId, {'player_1': 2});
    });
  });
}
