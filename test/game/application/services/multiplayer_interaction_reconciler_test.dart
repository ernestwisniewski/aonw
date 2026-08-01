import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MultiplayerInteractionReconciler', () {
    test('preserves targeting preview for a still-fortified unit', () {
      final fortified = _unit(
        'warrior_1',
        GameUnitType.warrior,
      ).copyWith(movementPoints: 0, posture: UnitPosture.fortified);
      final preview = UnitMovementPlan(
        unitId: fortified.id,
        targetCol: 1,
        targetRow: 0,
        totalCost: 1,
        availableMovementPoints:
            UnitManualMovementRules.availableMovementPoints(fortified),
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final source = GameClientState(
        activePlayerId: 'player_1',
        units: [fortified],
        interaction: InteractionState(
          selection: GameSelection.unit(fortified, tile: _tile),
          moveCommandActive: true,
          movePreview: preview,
        ),
      );
      final authoritative = GameClientState(
        activePlayerId: 'player_1',
        units: [fortified],
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: authoritative,
        interactionSource: source,
      );

      expect(result.moveCommandActive, isTrue);
      expect(result.movePreview, same(preview));
      expect(result.selectedUnit?.posture, UnitPosture.fortified);
    });

    test('preserves a valid local worker draft over a network snapshot', () {
      final worker = _unit('worker_1', GameUnitType.worker);
      final updatedWorker = worker.copyWith(movementPoints: 1);
      final source = GameClientState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: InteractionState(
          selection: GameSelection.unit(worker, tile: _tile),
          pendingAction: const PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: FieldImprovementType.farm,
          ),
        ),
      );
      final authoritative = GameClientState(
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
        final foundingSource = GameClientState(
          activePlayerId: 'player_1',
          units: [settler, warrior],
          interaction: InteractionState(cityFoundingDraft: draft),
        );

        final foundingResult = MultiplayerInteractionReconciler.reconcile(
          authoritativeState: GameClientState(
            activePlayerId: 'player_1',
            units: [settler, warrior],
          ),
          interactionSource: foundingSource,
        );
        expect(foundingResult.cityFoundingDraft, draft);

        final targetingSource = foundingSource.copyWith(
          interaction: const InteractionState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'warrior_1',
            ),
          ),
        );
        final targetingResult = MultiplayerInteractionReconciler.reconcile(
          authoritativeState: GameClientState(
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
      final source = GameClientState(
        activePlayerId: 'player_1',
        units: [warrior],
        interaction: InteractionState(
          selection: GameSelection.unit(warrior, tile: _tile),
          pendingAction: const PendingAttackTargeting(
            ownerPlayerId: 'player_1',
            attackerUnitId: 'warrior_1',
          ),
        ),
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: GameClientState(activePlayerId: 'player_1'),
        interactionSource: source,
      );

      expect(result.selection, isNull);
      expect(result.pendingAction, isNull);
    });

    test('prefers server-owned pending state', () {
      final worker = _unit('worker_1', GameUnitType.worker);
      final source = GameClientState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: const InteractionState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
          ),
        ),
      );
      final authoritative = GameClientState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: const InteractionState(
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
      final source = GameClientState(
        activePlayerId: 'player_1',
        units: [worker],
        interaction: const InteractionState(
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
          ),
        ),
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: GameClientState(
          activePlayerId: 'player_1',
          activePlayerCanAct: false,
          units: [worker],
        ),
        interactionSource: source,
      );

      expect(result.pendingAction, isNull);
    });

    test('rebinds the city while preserving its cached economy projection', () {
      const sourceCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Before snapshot',
        center: CityHex(col: 0, row: 0),
      );
      const authoritativeCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'After snapshot',
        population: 2,
        center: CityHex(col: 0, row: 0),
      );
      const rawYield = TileYield(food: 2, production: 7, gold: 7, defense: 0);
      const cachedTileBreakdown = CityTileYieldBreakdown(
        center: CityTileYieldContribution(
          kind: CityTileYieldContributionKind.center,
          hex: CityHex(col: 0, row: 0),
          yield: rawYield,
        ),
      );
      const cachedEconomy = CityEconomyBreakdown(
        city: sourceCity,
        tileYield: rawYield,
        buildingYield: TileYield.zero,
        stabilityModifier: StabilityModifier(
          productionMultiplier: 0.75,
          goldMultiplier: 0.75,
          foodBonus: 0,
          haltsGrowth: true,
        ),
        populationUpkeep: 1,
        netFood: 1,
        foodDeposit: 0,
        growthCost: 10,
      );
      final source = GameClientState(
        activePlayerId: 'player_1',
        cities: const [sourceCity],
        interaction: InteractionState(
          selection: GameSelection.city(
            sourceCity,
            cityYield: rawYield,
            cityTileYieldBreakdown: cachedTileBreakdown,
            cityEconomy: cachedEconomy,
            playerColor: 0xFF112233,
          ),
        ),
      );

      final authoritativeState = GameClientState(
        activePlayerId: 'player_1',
        cities: [authoritativeCity],
        playerStabilityNet: {'player_1': 4},
      );
      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: authoritativeState,
        interactionSource: source,
      );

      expect(result.selection?.city, same(authoritativeState.cities.single));
      expect(
        result.selection?.cityTileYieldBreakdown,
        same(cachedTileBreakdown),
      );
      expect(result.selection?.cityEconomy, same(cachedEconomy));
      expect(
        result.selection?.cityEconomy?.stabilityModifier,
        cachedEconomy.stabilityModifier,
      );
    });
  });
}

final _tile = WorldTile(
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
