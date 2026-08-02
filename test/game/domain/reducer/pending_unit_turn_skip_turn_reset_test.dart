import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'new-turn reset expires skip and reactivates selected unit movement',
    () {
      final skipped = GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 0,
        row: 0,
        movementPoints: 0,
      );
      final state = GameClientState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        units: [skipped],
        interaction: InteractionState(
          selection: GameSelection.unit(skipped),
          movePreview: _movePreview(skipped.id),
          pendingAction: const PendingUnitTurnSkip(
            ownerPlayerId: 'player_1',
            unitId: 'unit_1',
            restoreMovementPoints: 3,
          ),
        ),
      );

      final result = MovementReducer.resetUnitMovementForNewTurn(
        state,
        _map(),
        playerId: 'player_1',
      );

      expect(result.state.selectedUnitId, skipped.id);
      expect(result.state.selection?.unit, same(result.state.units.single));
      expect(result.state.units.single.movementPoints, greaterThan(0));
      expect(result.state.pendingAction, isNull);
      expect(result.state.movePreview, isNull);
      expect(result.state.moveCommandActive, isTrue);
    },
  );

  test('new-turn movement activation preserves other required actions', () {
    final spent = GameUnit(
      id: 'unit_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.warrior,
      name: GameUnitType.warrior.defaultNameToken,
      col: 0,
      row: 0,
      movementPoints: 0,
    );
    const requiredResearch = PendingResearchSelection(
      ownerPlayerId: 'player_1',
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      activePlayerCanAct: true,
      units: [spent],
      interaction: InteractionState(
        selection: GameSelection.unit(spent),
        pendingAction: requiredResearch,
      ),
    );

    final result = MovementReducer.resetUnitMovementForNewTurn(
      state,
      _map(),
      playerId: 'player_1',
    );

    expect(result.state.pendingAction, same(requiredResearch));
    expect(result.state.moveCommandActive, isTrue);
  });

  test('turn skip expires without a selected unit', () {
    final skipped = _unit();
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [skipped],
      interaction: InteractionState(
        movePreview: _movePreview(skipped.id),
        pendingAction: _turnSkip(),
        moveCommandActive: true,
      ),
    );

    final result = MovementReducer.resetUnitMovementForNewTurn(
      state,
      _map(),
      playerId: 'player_1',
    );

    expect(result.state.selection, isNull);
    expect(result.state.pendingAction, isNull);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  test('turn skip expires when the selected unit cannot enter move mode', () {
    final merchant = _unit(type: GameUnitType.merchant);
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [merchant],
      interaction: InteractionState(
        selection: GameSelection.unit(merchant),
        movePreview: _movePreview(merchant.id),
        pendingAction: _turnSkip(),
        moveCommandActive: true,
      ),
    );

    final result = MovementReducer.resetUnitMovementForNewTurn(
      state,
      _map(),
      playerId: 'player_1',
    );

    expect(result.state.pendingAction, isNull);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  test('scoped reset preserves another player turn skip', () {
    final selected = _unit();
    final foreignSkipped = _unit(
      id: 'unit_2',
      ownerPlayerId: 'player_2',
      col: 1,
    );
    final foreignPending = _turnSkip(
      ownerPlayerId: 'player_2',
      unitId: foreignSkipped.id,
    );
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [selected, foreignSkipped],
      interaction: InteractionState(
        selection: GameSelection.unit(selected),
        pendingAction: foreignPending,
      ),
    );

    final result = MovementReducer.resetUnitMovementForNewTurn(
      state,
      _map(),
      playerId: 'player_1',
    );

    expect(result.state.pendingAction, same(foreignPending));
    expect(result.state.moveCommandActive, isTrue);
    expect(
      result.state.units.singleWhere((unit) => unit.id == foreignSkipped.id),
      same(foreignSkipped),
    );
  });

  test('scoped reset preserves another player movement preview', () {
    final resetUnit = _unit();
    final foreignUnit = _unit(id: 'unit_2', ownerPlayerId: 'player_2', col: 1);
    final foreignPreview = _movePreview(foreignUnit.id);
    final state = GameClientState(
      activePlayerId: 'player_2',
      units: [resetUnit, foreignUnit],
      interaction: InteractionState(
        selection: GameSelection.unit(foreignUnit),
        movePreview: foreignPreview,
        moveCommandActive: true,
      ),
    );

    final result = MovementReducer.resetUnitMovementForNewTurn(
      state,
      _map(),
      playerId: 'player_1',
    );

    expect(result.state.movePreview, same(foreignPreview));
    expect(result.state.moveCommandActive, isTrue);
  });

  test('turn boundary clears a preview whose unit no longer exists', () {
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [_unit()],
      interaction: InteractionState(
        movePreview: _movePreview('missing_unit'),
        moveCommandActive: true,
      ),
    );

    final result = MovementReducer.resetUnitMovementForNewTurn(
      state,
      _map(),
      playerId: 'player_1',
    );

    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });

  test('turn boundary disables ownerless movement targeting', () {
    final state = GameClientState(
      activePlayerId: 'player_1',
      units: [_unit()],
      interaction: const InteractionState(moveCommandActive: true),
    );

    final result = MovementReducer.resetUnitMovementForNewTurn(
      state,
      _map(),
      playerId: 'player_1',
    );

    expect(result.state.selection, isNull);
    expect(result.state.movePreview, isNull);
    expect(result.state.moveCommandActive, isFalse);
  });
}

GameUnit _unit({
  String id = 'unit_1',
  String ownerPlayerId = 'player_1',
  int col = 0,
  GameUnitType type = GameUnitType.warrior,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: 0,
    movementPoints: 0,
  );
}

PendingUnitTurnSkip _turnSkip({
  String ownerPlayerId = 'player_1',
  String unitId = 'unit_1',
}) {
  return PendingUnitTurnSkip(
    ownerPlayerId: ownerPlayerId,
    unitId: unitId,
    restoreMovementPoints: 3,
  );
}

UnitMovementPlan _movePreview(String unitId) {
  return UnitMovementPlan(
    unitId: unitId,
    targetCol: 1,
    targetRow: 0,
    totalCost: 1,
    availableMovementPoints: 0,
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
