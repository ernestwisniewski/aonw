import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiplayerInteractionReconciler', () {
    test('preserves a valid local worker draft over a network snapshot', () {
      final worker = _unit('worker_1', GameUnitType.worker);
      final updatedWorker = worker.copyWith(movementPoints: 1);
      final source = GameState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: GameInteractionState(
          selection: GameSelection.unit(worker, tile: _tile),
          pendingAction: const PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      );
      final authoritative = GameState(
        activePlayerId: 'player_1',
        units: [updatedWorker],
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: authoritative,
        interactionSource: source,
      );

      expect(result.pendingAction, source.pendingAction);
      expect(result.selectedUnit, same(updatedWorker));
      expect(result.units, [updatedWorker]);
    });

    test(
      'preserves city founding and attack targeting across remote actions',
      () {
        final settler = _unit('settler_1', GameUnitType.settler);
        final warrior = _unit('warrior_1', GameUnitType.warrior, col: 1);
        final draft = CityFoundingDraft(
          unitId: settler.id,
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 0, row: 0),
        );
        final foundingSource = GameState(
          activePlayerId: 'player_1',
          units: [settler, warrior],
          interaction: GameInteractionState(cityFoundingDraft: draft),
        );

        final foundingResult = MultiplayerInteractionReconciler.reconcile(
          authoritativeState: GameState(
            activePlayerId: 'player_1',
            units: [settler, warrior],
          ),
          interactionSource: foundingSource,
        );
        expect(foundingResult.cityFoundingDraft, draft);

        final targetingSource = foundingSource.copyWith(
          interaction: const GameInteractionState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'warrior_1',
            ),
          ),
        );
        final targetingResult = MultiplayerInteractionReconciler.reconcile(
          authoritativeState: GameState(
            activePlayerId: 'player_1',
            units: [settler, warrior],
          ),
          interactionSource: targetingSource,
        );
        expect(targetingResult.pendingAction, targetingSource.pendingAction);
      },
    );

    test('drops transient actions whose entity disappeared', () {
      final warrior = _unit('warrior_1', GameUnitType.warrior);
      final source = GameState(
        activePlayerId: 'player_1',
        units: [warrior],
        interaction: GameInteractionState(
          selection: GameSelection.unit(warrior, tile: _tile),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'warrior_1',
          ),
        ),
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: const GameState(activePlayerId: 'player_1'),
        interactionSource: source,
      );

      expect(result.selection, isNull);
      expect(result.pendingAction, isNull);
    });

    test('prefers server-owned pending state', () {
      final worker = _unit('worker_1', GameUnitType.worker);
      final source = GameState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: const GameInteractionState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
          ),
        ),
      );
      final authoritative = GameState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: const GameInteractionState(
          pendingAction: PendingUnitTurnSkip(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            restoreMovementPoints: 2,
          ),
        ),
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: authoritative,
        interactionSource: source,
      );

      expect(result.pendingAction, authoritative.pendingAction);
    });

    test('drops local action drafts after the player submits the turn', () {
      final worker = _unit('worker_1', GameUnitType.worker);
      final source = GameState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: const GameInteractionState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
          ),
        ),
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: GameState(
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          units: [worker],
        ),
        interactionSource: source,
      );

      expect(result.pendingAction, isNull);
    });
  });
}

const _tile = TileData(
  col: 0,
  row: 0,
  terrains: [TerrainType.plains],
  resources: [],
  height: 0,
);

GameUnit _unit(String id, GameUnitType type, {int col = 0}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'player_1',
    type: type,
    name: id,
    col: col,
    row: 0,
  );
}
