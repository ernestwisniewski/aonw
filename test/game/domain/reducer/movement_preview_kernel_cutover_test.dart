import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('preview confirmation projects the direct movement result', () {
    final mapView = WorldMapReadView(_lineMap());
    final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = _selectedMoveState(unit);
    final target = mapView.tileAt(2, 0)!;
    final previewed = MovementReducer.handleMoveTargetTile(
      state,
      target,
      mapView,
    );

    final direct = MovementReducer.moveUnit(
      previewed.state.copyWithInteraction(movePreview: null),
      MoveUnitCommand(unit.id, 2, 0),
      mapView,
    );
    final confirmed = MovementReducer.handleMoveTargetTile(
      previewed.state,
      target,
      mapView,
    );
    final directEvent = direct.events.single as UnitMovedEvent;
    final confirmedEvent = confirmed.events.single as UnitMovedEvent;
    final directAnimation = direct.uiEffects.single as AnimateUnitMoveEffect;
    final confirmedAnimation =
        confirmed.uiEffects.single as AnimateUnitMoveEffect;

    expect(confirmed.state.units, direct.state.units);
    expect(confirmed.state.fogOfWar, direct.state.fogOfWar);
    expect(confirmed.state.diplomacy, direct.state.diplomacy);
    expect(confirmed.state.selectedUnit, direct.state.selectedUnit);
    expect(
      (
        confirmed.state.selection?.tile?.col,
        confirmed.state.selection?.tile?.row,
      ),
      (direct.state.selection?.tile?.col, direct.state.selection?.tile?.row),
    );
    expect(confirmed.state.movePreview, direct.state.movePreview);
    expect(confirmed.state.moveCommandActive, direct.state.moveCommandActive);
    expect(
      (
        confirmedEvent.unitId,
        confirmedEvent.fromCol,
        confirmedEvent.fromRow,
        confirmedEvent.toCol,
        confirmedEvent.toRow,
      ),
      (
        directEvent.unitId,
        directEvent.fromCol,
        directEvent.fromRow,
        directEvent.toCol,
        directEvent.toRow,
      ),
    );
    expect(confirmedAnimation.unitId, directAnimation.unitId);
    expect(confirmedAnimation.fromCol, directAnimation.fromCol);
    expect(confirmedAnimation.fromRow, directAnimation.fromRow);
    expect(confirmedAnimation.steps, directAnimation.steps);
  });

  test('preview confirmation revalidates unit availability', () {
    final mapView = WorldMapReadView(_lineMap());
    final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = _selectedMoveState(unit);
    final target = mapView.tileAt(1, 0)!;
    final previewed = MovementReducer.handleMoveTargetTile(
      state,
      target,
      mapView,
    );
    final fortified = unit.copyWith(posture: UnitPosture.fortified);

    final confirmed = MovementReducer.handleMoveTargetTile(
      previewed.state.copyWith(units: [fortified]),
      target,
      mapView,
    );
    final unchanged = confirmed.state.units.single;

    expect((unchanged.col, unchanged.row), (0, 0));
    expect(unchanged.posture, UnitPosture.fortified);
    expect(unchanged.queuedPath, isNull);
    expect(confirmed.state.movePreview, isNull);
    expect(confirmed.state.moveCommandActive, isFalse);
    expect(confirmed.events, isEmpty);
    expect(confirmed.uiEffects, isEmpty);
  });

  test('preview confirmation does not queue a stale blocked route', () {
    final mapView = WorldMapReadView(_lineMap());
    final unit = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
    ).copyWith(movementPoints: 0);
    final state = _selectedMoveState(unit);
    final target = mapView.tileAt(2, 0)!;
    final previewed = MovementReducer.handleMoveTargetTile(
      state,
      target,
      mapView,
    );
    final blocker = GameUnit.startingWarrior(
      ownerPlayerId: 'player_1',
      col: 1,
      row: 0,
    );

    final confirmed = MovementReducer.handleMoveTargetTile(
      previewed.state.copyWith(units: [unit, blocker]),
      target,
      mapView,
    );
    final unchanged = confirmed.state.unitById(unit.id)!;

    expect(previewed.state.movePreview?.canMoveNow, isFalse);
    expect((unchanged.col, unchanged.row), (0, 0));
    expect(unchanged.queuedPath, isNull);
    expect(confirmed.state.movePreview, isNull);
    expect(confirmed.state.moveCommandActive, isFalse);
    expect(confirmed.events, isEmpty);
    expect(confirmed.uiEffects, isEmpty);
  });
}

GameState _selectedMoveState(GameUnit unit) => GameState(
  activePlayerId: unit.ownerPlayerId,
  units: [unit],
  interaction: GameInteractionState(
    selection: GameSelection.unit(unit),
    moveCommandActive: true,
  ),
);

WorldMap _lineMap() => WorldMap(
  cols: 3,
  rows: 1,
  tiles: [
    for (var col = 0; col < 3; col += 1)
      WorldTile(
        coordinate: HexCoord(col: col, row: 0),
        terrains: const [TerrainType.plains],
        resources: const [],
        height: 0,
      ),
  ],
);
