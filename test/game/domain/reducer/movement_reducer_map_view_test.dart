import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/domain/reducer/movement/movement_reducer.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:aonw_core/map/domain/world_map_read_view.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _UnitAction =
    GameStateTransition Function(
      GameState state,
      MapTileLookup mapTiles,
      GameUnit unit,
    );

void main() {
  final actions = <({String name, _UnitAction apply})>[
    (
      name: 'cancel',
      apply: (state, mapTiles, unit) => MovementReducer.cancelUnitAction(
        state,
        CancelUnitActionCommand(unit.id),
        mapTiles,
      ),
    ),
    (
      name: 'skip',
      apply: (state, mapTiles, unit) => MovementReducer.skipUnitTurn(
        state,
        SkipUnitTurnCommand(unit.id),
        mapTiles,
      ),
    ),
    (
      name: 'fortify',
      apply: (state, mapTiles, unit) => MovementReducer.fortifyUnit(
        state,
        FortifyUnitCommand(unit.id),
        mapTiles,
      ),
    ),
  ];

  for (final action in actions) {
    test(
      '${action.name} refreshes selection through a canonical map lookup',
      () {
        final canonicalTile = WorldTile(
          coordinate: const HexCoord(col: 0, row: 0),
          terrains: const [TerrainType.plains],
          resources: const [ResourceType.oil, ResourceType.wheat],
          height: 0,
        );
        final mapTiles = WorldMapReadView(
          WorldMap(cols: 1, rows: 1, tiles: [canonicalTile]),
        );
        final unit = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
        final state = GameState(
          activePlayerId: 'player_1',
          units: [unit],
          interaction: GameInteractionState(
            selection: GameSelection.unit(unit),
          ),
        );

        final result = action.apply(state, mapTiles, unit);
        final updatedUnit = result.state.units.single;

        expect(result.state.selection?.unit, same(updatedUnit));
        expect(result.state.selection?.tile?.resources, const [
          ResourceType.wheat,
        ]);
        expect(canonicalTile.resources, const [
          ResourceType.oil,
          ResourceType.wheat,
        ]);
      },
    );
  }

  test('previews and confirms movement through a canonical traversal view', () {
    final world = _canonicalWorld(cols: 4);
    final MapTraversalView mapView = WorldMapReadView(world);
    final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = GameState(
      activePlayerId: 'player_1',
      units: [unit],
      fogOfWar: _originFog(),
      interaction: GameInteractionState(
        selection: GameSelection.unit(unit),
        moveCommandActive: true,
      ),
    );
    final targetTile = mapView.tileAt(2, 0)!;
    expect(
      state.fogOfWar.isVisible('player_1', const HexCoordinate(col: 2, row: 0)),
      isFalse,
    );

    final previewed = MovementReducer.handleMoveTargetTile(
      state,
      targetTile,
      mapView,
    );
    final confirmed = MovementReducer.handleMoveTargetTile(
      previewed.state,
      targetTile,
      mapView,
    );
    final movedUnit = confirmed.state.units.single;
    final animation = confirmed.uiEffects
        .whereType<AnimateUnitMoveEffect>()
        .single;

    expect(previewed.state.movePreview?.targetCol, 2);
    expect(previewed.state.movePreview?.totalCost, 2);
    expect(previewed.state.selection?.tile?.resources, const [
      ResourceType.wheat,
    ]);
    expect((movedUnit.col, movedUnit.row), (2, 0));
    expect(movedUnit.movementPoints, 3);
    expect(confirmed.state.selection?.unit, same(movedUnit));
    expect(confirmed.state.selection?.tile?.resources, const [
      ResourceType.wheat,
    ]);
    expect(confirmed.state.movePreview, isNull);
    expect(confirmed.state.moveCommandActive, isTrue);
    expect(animation.steps, hasLength(2));
    expect(
      confirmed.state.fogOfWar.isVisible(
        'player_1',
        const HexCoordinate(col: 2, row: 0),
      ),
      isTrue,
    );
    expect(world.tiles[2].resources, const [
      ResourceType.oil,
      ResourceType.wheat,
    ]);
  });

  test('executes a direct command through a canonical traversal view', () {
    final world = _canonicalWorld(cols: 3);
    final MapTraversalView mapView = WorldMapReadView(world);
    final unit = GameUnit.startingCommander(ownerPlayerId: 'player_1');
    final state = GameState(
      activePlayerId: 'player_1',
      units: [unit],
      fogOfWar: _originFog(),
      interaction: GameInteractionState(selection: GameSelection.unit(unit)),
    );
    expect(
      state.fogOfWar.isVisible('player_1', const HexCoordinate(col: 1, row: 0)),
      isFalse,
    );

    final result = MovementReducer.moveUnit(
      state,
      MoveUnitCommand(unit.id, 1, 0),
      mapView,
    );
    final movedUnit = result.state.units.single;
    final event = result.events.whereType<UnitMovedEvent>().single;
    final animation = result.uiEffects
        .whereType<AnimateUnitMoveEffect>()
        .single;

    expect((movedUnit.col, movedUnit.row), (1, 0));
    expect(movedUnit.movementPoints, 4);
    expect(result.state.selection?.unit, same(movedUnit));
    expect(result.state.selection?.tile?.resources, const [ResourceType.wheat]);
    expect((event.fromCol, event.fromRow), (0, 0));
    expect((event.toCol, event.toRow), (1, 0));
    expect((animation.fromCol, animation.fromRow), (0, 0));
    expect(animation.steps, hasLength(1));
    expect(
      result.state.fogOfWar.isVisible(
        'player_1',
        const HexCoordinate(col: 1, row: 0),
      ),
      isTrue,
    );
    expect(world.tiles[1].resources, const [
      ResourceType.oil,
      ResourceType.wheat,
    ]);
  });

  test('queues a canonical preview at zero movement without jumping', () {
    final world = _canonicalWorld(cols: 4);
    final MapTraversalView mapView = WorldMapReadView(world);
    final unit = GameUnit.startingCommander(
      ownerPlayerId: 'player_1',
    ).copyWith(movementPoints: 0);
    final state = GameState(
      activePlayerId: 'player_1',
      units: [unit],
      fogOfWar: _originFog(),
      interaction: GameInteractionState(
        selection: GameSelection.unit(unit),
        moveCommandActive: true,
      ),
    );
    final targetTile = mapView.tileAt(2, 0)!;

    final previewed = MovementReducer.handleMoveTargetTile(
      state,
      targetTile,
      mapView,
    );
    final confirmed = MovementReducer.handleMoveTargetTile(
      previewed.state,
      targetTile,
      mapView,
    );
    final queuedUnit = confirmed.state.units.single;

    expect((queuedUnit.col, queuedUnit.row), (0, 0));
    expect(queuedUnit.movementPoints, 0);
    expect(queuedUnit.queuedPath?.targetCol, 2);
    expect(queuedUnit.queuedPath?.targetRow, 0);
    expect(queuedUnit.queuedPath?.steps, hasLength(3));
    expect(confirmed.state.selection?.unit, same(queuedUnit));
    expect(confirmed.state.selection?.tile?.resources, const [
      ResourceType.wheat,
    ]);
    expect(confirmed.state.movePreview, isNull);
    expect(confirmed.state.moveCommandActive, isFalse);
    expect(confirmed.uiEffects.whereType<AnimateUnitMoveEffect>(), isEmpty);
    expect(confirmed.events, isEmpty);
    expect(world.tiles.first.resources, const [
      ResourceType.oil,
      ResourceType.wheat,
    ]);
  });

  test(
    'selection keeps the updated unit when its canonical tile is absent',
    () {
      final mapTiles = WorldMapReadView(
        WorldMap(cols: 1, rows: 1, tiles: const []),
      );
      final unit = GameUnit.startingWarrior(ownerPlayerId: 'player_1');
      final state = GameState(
        activePlayerId: 'player_1',
        units: [unit],
        interaction: GameInteractionState(selection: GameSelection.unit(unit)),
      );

      final result = MovementReducer.cancelUnitAction(
        state,
        CancelUnitActionCommand(unit.id),
        mapTiles,
      );

      expect(result.state.selection?.unit, same(result.state.units.single));
      expect(result.state.selection?.tile, isNull);
    },
  );
}

WorldMap _canonicalWorld({required int cols}) {
  return WorldMap(
    cols: cols,
    rows: 1,
    tiles: [
      for (var col = 0; col < cols; col += 1)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.plains],
          resources: const [ResourceType.oil, ResourceType.wheat],
          height: 0,
        ),
    ],
  );
}

FogOfWarState _originFog() {
  const origin = HexCoordinate(col: 0, row: 0);
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: {origin},
        visibleHexes: {origin},
      ),
    },
  );
}
