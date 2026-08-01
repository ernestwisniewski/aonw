import 'package:aonw/game/application/services/game_intent_resolver.dart';
import 'package:aonw/game/application/services/multiplayer_interaction_reconciler.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

const _playerId = 'player_1';
final _turnOneStartedAt = DateTime.utc(2026, 7, 30, 12);
final _turnTwoStartedAt = DateTime.utc(2026, 7, 30, 12, 1);

void main() {
  group('PendingUnitTurnSkip interaction', () {
    test('does not block an active movement-targeting tile tap', () {
      final unit = _unit();
      final state = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        units: [unit],
        interaction: InteractionState(
          selection: GameSelection.unit(unit),
          moveCommandActive: true,
          pendingAction: PendingUnitTurnSkip(
            ownerPlayerId: _playerId,
            unitId: unit.id,
            restoreMovementPoints: unit.movementPoints,
          ),
        ),
      );
      final resolver = GameIntentResolver(
        reducer: GameStateReducer(mapData: _map()),
        context: const GameCommandContext(
          actorPlayerId: _playerId,
          ignoreFogOfWar: true,
        ),
      );

      final result = resolver.resolve(
        state.interaction,
        const TileTappedCommand(1, 0),
        state,
      );

      expect(result.domainCommand, isNull);
      expect(result.interaction.movePreview, isNotNull);
      expect(result.interaction.movePreview?.targetCol, 1);
      expect(result.interaction.movePreview?.targetRow, 0);
    });

    test(
      'new-turn snapshot expires turn skip and stale preview, then starts move',
      () {
        final skipped = _unit(movementPoints: 0);
        final ready = skipped.copyWith(movementPoints: 3);
        final preview = _preview(availableMovementPoints: 2);
        final pending = PendingUnitTurnSkip(
          ownerPlayerId: _playerId,
          unitId: skipped.id,
          restoreMovementPoints: 3,
        );
        final source = GameClientState(
          activePlayerId: _playerId,
          activePlayerCanAct: true,
          turnStartedAt: _turnOneStartedAt,
          units: [skipped],
          interaction: InteractionState(
            selection: GameSelection.unit(skipped),
            movePreview: preview,
            pendingAction: pending,
          ),
        );
        final authoritative = GameClientState(
          activePlayerId: _playerId,
          activePlayerCanAct: true,
          turnStartedAt: _turnTwoStartedAt,
          units: [ready],
          interaction: InteractionState(pendingAction: pending),
        );

        final result = MultiplayerInteractionReconciler.reconcile(
          authoritativeState: authoritative,
          interactionSource: source,
        );

        expect(result.selectedUnit, same(ready));
        expect(result.pendingAction, isNull);
        expect(result.movePreview, isNull);
        expect(result.moveCommandActive, isTrue);
      },
    );

    test('same-turn snapshot preserves a still-valid movement preview', () {
      final unit = _unit();
      final preview = _preview();
      final source = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        turnStartedAt: _turnOneStartedAt,
        units: [unit],
        interaction: InteractionState(
          selection: GameSelection.unit(unit),
          moveCommandActive: true,
          movePreview: preview,
        ),
      );
      final authoritative = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        turnStartedAt: _turnOneStartedAt,
        units: [unit],
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: authoritative,
        interactionSource: source,
      );

      expect(result.movePreview, same(preview));
      expect(result.moveCommandActive, isTrue);
    });

    test('materializing a missing turn start does not advance the turn', () {
      final skipped = _unit(movementPoints: 0);
      final preview = _preview(availableMovementPoints: 0);
      final pending = PendingUnitTurnSkip(
        ownerPlayerId: _playerId,
        unitId: skipped.id,
        restoreMovementPoints: 3,
      );
      final source = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        units: [skipped],
        interaction: InteractionState(
          selection: GameSelection.unit(skipped),
          movePreview: preview,
          pendingAction: pending,
        ),
      );
      final authoritative = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        turnStartedAt: _turnOneStartedAt,
        units: [skipped],
        interaction: InteractionState(pendingAction: pending),
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: authoritative,
        interactionSource: source,
      );

      expect(result.pendingAction, same(pending));
      expect(result.movePreview, same(preview));
      expect(result.moveCommandActive, isFalse);
    });

    test('restored skipped movement detects a turn without timestamps', () {
      final skipped = _unit(movementPoints: 0);
      final ready = skipped.copyWith(movementPoints: 3);
      final pending = PendingUnitTurnSkip(
        ownerPlayerId: _playerId,
        unitId: skipped.id,
        restoreMovementPoints: 3,
      );
      final source = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        units: [skipped],
        interaction: InteractionState(
          selection: GameSelection.unit(skipped),
          pendingAction: pending,
        ),
      );
      final authoritative = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        units: [ready],
        interaction: InteractionState(pendingAction: pending),
      );

      final result = MultiplayerInteractionReconciler.reconcile(
        authoritativeState: authoritative,
        interactionSource: source,
      );

      expect(result.pendingAction, isNull);
      expect(result.moveCommandActive, isTrue);
    });

    test('snapshot invalidates preview after relevant unit state changes', () {
      final sourceUnit = _unit();
      final preview = _preview();
      final source = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        turnStartedAt: _turnOneStartedAt,
        units: [sourceUnit],
        interaction: InteractionState(
          selection: GameSelection.unit(sourceUnit),
          moveCommandActive: true,
          movePreview: preview,
        ),
      );
      final queued = sourceUnit.copyWithQueuedPath(
        QueuedMovePath(
          targetCol: preview.targetCol,
          targetRow: preview.targetRow,
          steps: preview.steps,
        ),
      );
      final cases = <({String name, GameUnit unit, bool keepsMoveMode})>[
        (
          name: 'movement points',
          unit: sourceUnit.copyWith(movementPoints: 2),
          keepsMoveMode: true,
        ),
        (name: 'queued path', unit: queued, keepsMoveMode: false),
        (
          name: 'posture',
          unit: sourceUnit.copyWithPosture(UnitPosture.fortified),
          keepsMoveMode: false,
        ),
      ];

      for (final testCase in cases) {
        final authoritative = GameClientState(
          activePlayerId: _playerId,
          activePlayerCanAct: true,
          turnStartedAt: _turnOneStartedAt,
          units: [testCase.unit],
        );

        final result = MultiplayerInteractionReconciler.reconcile(
          authoritativeState: authoritative,
          interactionSource: source,
        );

        expect(result.movePreview, isNull, reason: testCase.name);
        expect(
          result.moveCommandActive,
          testCase.keepsMoveMode,
          reason: testCase.name,
        );
      }
    });

    test('snapshot invalidates preview after pathfinding inputs change', () {
      final selected = _unit();
      final other = GameUnit(
        id: 'unit_2',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 2,
        row: 0,
        movementPoints: 3,
      );
      final source = GameClientState(
        activePlayerId: _playerId,
        activePlayerCanAct: true,
        turnStartedAt: _turnOneStartedAt,
        units: [selected, other],
        interaction: InteractionState(
          selection: GameSelection.unit(selected),
          moveCommandActive: true,
          movePreview: _preview(),
        ),
      );
      final authoritativeBase = source.copyWith(
        interaction: InteractionState.empty,
      );
      final cases = <({String name, GameClientState state})>[
        (
          name: 'another unit',
          state: authoritativeBase.copyWith(
            units: [selected, other.copyWith(col: 1)],
          ),
        ),
        (
          name: 'fog of war',
          state: authoritativeBase.copyWith(
            fogOfWar: FogOfWarState(
              players: {
                _playerId: PlayerFogOfWar(
                  playerId: _playerId,
                  visibleHexes: {const HexCoordinate(col: 0, row: 0)},
                ),
              },
            ),
          ),
        ),
        (
          name: 'diplomacy',
          state: authoritativeBase.copyWith(
            diplomacy: DiplomacyState.empty.addContact(_playerId, 'player_2'),
          ),
        ),
        (
          name: 'cities',
          state: authoritativeBase.copyWith(
            cities: const [
              GameCity(
                id: 'city_1',
                ownerPlayerId: 'player_2',
                name: 'City',
                center: CityHex(col: 1, row: 0),
              ),
            ],
          ),
        ),
      ];

      for (final testCase in cases) {
        final result = MultiplayerInteractionReconciler.reconcile(
          authoritativeState: testCase.state,
          interactionSource: source,
        );

        expect(result.movePreview, isNull, reason: testCase.name);
        expect(result.moveCommandActive, isTrue, reason: testCase.name);
      }
    });
  });
}

GameUnit _unit({int movementPoints = 3}) {
  return GameUnit(
    id: 'unit_1',
    ownerPlayerId: _playerId,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: 0,
    row: 0,
    movementPoints: movementPoints,
  );
}

UnitMovementPlan _preview({int availableMovementPoints = 3}) {
  return UnitMovementPlan(
    unitId: 'unit_1',
    targetCol: 1,
    targetRow: 0,
    totalCost: 1,
    availableMovementPoints: availableMovementPoints,
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
    ],
  );
}

WorldMap _map() {
  return WorldMap(
    cols: 2,
    rows: 1,
    tiles: [
      WorldTile(
        col: 0,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
      WorldTile(
        col: 1,
        row: 0,
        terrains: [TerrainType.grassland],
        resources: [],
        height: 0,
      ),
    ],
  );
}
