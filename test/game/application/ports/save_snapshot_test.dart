import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/combat.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SaveSnapshot', () {
    test('captures persistent GameState slices', () {
      final state =
          const GameState(
            playerColors: {'p1': 0xFF4a7fc4},
            playerCountries: {'p1': PlayerCountry.canada},
            playerGold: {'p1': 7},
            activePlayerId: 'p1',
            submittedPlayerIds: {'p1'},
            dominationHoldTurnsByPlayerId: {'p1': 2},
            intendedAttacks: [
              IntendedAttack(
                attackerUnitId: 'warrior_1',
                defenderCol: 4,
                defenderRow: 5,
                declaredAtTick: 7,
                declaringPlayerId: 'p1',
              ),
            ],
          ).copyWith(
            pendingAction: const PendingCityWorkedHexSelection(
              ownerPlayerId: 'p1',
              cityId: 'city_1',
            ),
          );

      final snapshot = SaveSnapshot.fromGameState(
        save: _save(),
        state: state,
        eventLogOffset: 12,
      );

      expect(snapshot.playerColors, state.playerColors);
      expect(snapshot.playerCountries, state.playerCountries);
      expect(snapshot.playerGold, state.playerGold);
      expect(snapshot.runtimeState.pendingAction, state.pendingAction);
      expect(snapshot.runtimeState.submittedPlayerIds, {'p1'});
      expect(snapshot.runtimeState.intendedAttacks, state.intendedAttacks);
      expect(snapshot.runtimeState.dominationHoldTurnsByPlayerId, {'p1': 2});
      expect(snapshot.eventLogOffset, 12);
      expect(snapshot.persistentState.playerGold, {'p1': 7});
      expect(snapshot.persistentState.playerCountries, {
        'p1': PlayerCountry.canada,
      });
    });

    test('builds snapshot from persistent state', () {
      final runtimeState = GameRuntimeState(
        submittedPlayerIds: const {'p1'},
        turnStartedAt: DateTime.utc(2026, 4, 27, 12),
      );

      final snapshot = SaveSnapshot.fromPersistentState(
        save: _save(),
        state: PersistentGameState(
          playerCountries: const {'p1': PlayerCountry.china},
          playerGold: const {'p1': 7},
          runtimeState: runtimeState,
        ),
        eventLogOffset: 9,
      );

      expect(snapshot.playerGold, {'p1': 7});
      expect(snapshot.playerCountries, {'p1': PlayerCountry.china});
      expect(snapshot.runtimeState, runtimeState);
      expect(snapshot.eventLogOffset, 9);
    });

    test(
      'restores GameState from persistent slices and caller runtime control',
      () {
        final snapshot = SaveSnapshot(
          save: _save(),
          playerColors: const {'p1': 0xFF4a7fc4},
          playerCountries: const {'p1': PlayerCountry.unitedStates},
          playerGold: const {'p1': 7},
          runtimeState: const GameRuntimeState(
            pendingAction: PendingCityWorkedHexSelection(
              ownerPlayerId: 'p1',
              cityId: 'city_1',
            ),
            submittedPlayerIds: {'p1'},
            dominationHoldTurnsByPlayerId: {'p1': 2},
            intendedAttacks: [
              IntendedAttack(
                attackerUnitId: 'warrior_1',
                defenderCol: 4,
                defenderRow: 5,
                declaredAtTick: 7,
                declaringPlayerId: 'p1',
              ),
            ],
          ),
        );

        final state = snapshot.toGameState(
          activePlayerId: 'p1',
          activePlayerCanAct: false,
        );

        expect(state.playerColors, snapshot.playerColors);
        expect(state.playerCountries, snapshot.playerCountries);
        expect(state.countryForPlayer('p1'), PlayerCountry.unitedStates);
        expect(state.playerGold, snapshot.playerGold);
        expect(state.activePlayerId, 'p1');
        expect(state.activePlayerCanAct, isFalse);
        expect(state.pendingAction, snapshot.runtimeState.pendingAction);
        expect(state.submittedPlayerIds, {'p1'});
        expect(state.intendedAttacks, snapshot.runtimeState.intendedAttacks);
        expect(state.dominationHoldTurnsByPlayerId, {'p1': 2});
      },
    );

    test('copyWith preserves event log offset unless replaced', () {
      final snapshot = SaveSnapshot(save: _save(), eventLogOffset: 4);

      expect(snapshot.copyWith().eventLogOffset, 4);
      expect(snapshot.copyWith(eventLogOffset: 5).eventLogOffset, 5);
    });
  });
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'p1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
  );
}
