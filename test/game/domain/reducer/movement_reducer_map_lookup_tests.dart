part of 'movement_reducer_map_view_test.dart';

typedef _UnitAction =
    GameStateTransition Function(
      GameState state,
      MapTileLookup mapTiles,
      GameUnit unit,
    );

void _registerCanonicalMapLookupActionTests() {
  final actions = <({String name, _UnitAction apply})>[
    (
      name: 'cancel',
      apply: (state, mapTiles, unit) => MovementReducer.cancelUnitAction(
        state,
        CancelUnitActionCommand(unit.id),
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
}

void _registerMissingCanonicalTileSelectionTest() {
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
