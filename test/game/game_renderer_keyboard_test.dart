import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/domain/game_selection.dart';
import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_reducer.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine.dart';
import 'package:aonw/game/presentation/engine/artifact_marker_tap_cycle.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_view_mode.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

MapData _minimalMap() => MapData(
  cols: 2,
  rows: 2,
  tiles: [
    for (int r = 0; r < 2; r++)
      for (int c = 0; c < 2; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

MapData _map(int cols, int rows) => MapData(
  cols: cols,
  rows: rows,
  tiles: [
    for (int r = 0; r < rows; r++)
      for (int c = 0; c < cols; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

MapData _mapWithObjective() => MapData(
  cols: 3,
  rows: 3,
  objectives: const [
    MapObjectiveDefinition(
      id: 'pass_1',
      type: MapObjectiveType.strategicPass,
      hex: CityHex(col: 1, row: 1),
      requiredHoldTurns: 2,
    ),
  ],
  tiles: [
    for (int r = 0; r < 3; r++)
      for (int c = 0; c < 3; c++)
        TileData(
          col: c,
          row: r,
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
  ],
);

TileData _tile(MapData map, int col, int row) =>
    map.tiles.firstWhere((tile) => tile.col == col && tile.row == row);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameRenderer keyboard pan', () {
    late GameRenderer game;

    setUp(() {
      game = GameRenderer(mapData: _minimalMap(), onCommand: (_) async {});
    });

    test('keyboardPanDelta is zero when no keys pressed', () {
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, equals(0.0));
      expect(delta.y, equals(0.0));
    });

    test('W key produces upward pan delta (negative Y)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyW,
          logicalKey: LogicalKeyboardKey.keyW,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyW},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, lessThan(0));
      expect(delta.x, equals(0.0));
    });

    test('S key produces downward pan delta (positive Y)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyS,
          logicalKey: LogicalKeyboardKey.keyS,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyS},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, greaterThan(0));
      expect(delta.x, equals(0.0));
    });

    test('A key produces leftward pan delta (negative X)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyA,
          logicalKey: LogicalKeyboardKey.keyA,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyA},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, lessThan(0));
      expect(delta.y, equals(0.0));
    });

    test('D key produces rightward pan delta (positive X)', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.keyD,
          logicalKey: LogicalKeyboardKey.keyD,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.keyD},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, greaterThan(0));
      expect(delta.y, equals(0.0));
    });

    test('key released clears direction', () {
      game
        ..onKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyW,
            logicalKey: LogicalKeyboardKey.keyW,
            timeStamp: Duration.zero,
          ),
          {LogicalKeyboardKey.keyW},
        )
        ..onKeyEvent(
          const KeyUpEvent(
            physicalKey: PhysicalKeyboardKey.keyW,
            logicalKey: LogicalKeyboardKey.keyW,
            timeStamp: Duration.zero,
          ),
          {},
        );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.x, equals(0.0));
      expect(delta.y, equals(0.0));
    });

    test('diagonal: W+D produces both negative Y and positive X', () {
      game
        ..onKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyW,
            logicalKey: LogicalKeyboardKey.keyW,
            timeStamp: Duration.zero,
          ),
          {LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyD},
        )
        ..onKeyEvent(
          const KeyDownEvent(
            physicalKey: PhysicalKeyboardKey.keyD,
            logicalKey: LogicalKeyboardKey.keyD,
            timeStamp: Duration.zero,
          ),
          {LogicalKeyboardKey.keyW, LogicalKeyboardKey.keyD},
        );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, lessThan(0));
      expect(delta.x, greaterThan(0));
    });

    test('arrow keys work the same as WASD', () {
      game.onKeyEvent(
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.arrowUp,
          logicalKey: LogicalKeyboardKey.arrowUp,
          timeStamp: Duration.zero,
        ),
        {LogicalKeyboardKey.arrowUp},
      );
      final delta = game.keyboardPanDelta(dt: 1.0);
      expect(delta.y, lessThan(0));
    });
  });

  group('GameRenderer renderer bridge', () {
    test('applyState is ignored after renderer disposal', () {
      final game = GameRenderer(
        mapData: _minimalMap(),
        onCommand: (_) async {},
      );

      expect(
        () => game
          ..disposeRenderer()
          ..applyState(const GameState(activePlayerId: 'player_1')),
        returnsNormally,
      );
    });

    test('tile tap dispatches a TileTappedCommand in renderer mode', () async {
      final map = _map(3, 3);
      final commands = <GameCommand>[];
      await GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
        },
      ).handleTileTappedForTesting(_tile(map, 1, 2));
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 2)]);
    });

    test('artifact marker tap cycles artifact, hex, artifact', () async {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedArtifacts = <WorldArtifact>[];
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.queensMirror,
        col: 1,
        row: 1,
      );
      var state = GameState(artifacts: [artifact]);
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onArtifactInspected: (artifact, _) {
          inspectedArtifacts.add(artifact);
        },
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(state)
        ..handleArtifactMarkerTappedForTesting(artifact);

      expect(inspectedArtifacts, [artifact]);
      expect(commands, isEmpty);

      game.handleArtifactMarkerTappedForTesting(artifact);
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 1)]);
      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.tile?.col, 1);
      expect(state.selection?.tile?.row, 1);
      expect(inspectedArtifacts, [artifact]);

      game.handleArtifactMarkerTappedForTesting(artifact);

      expect(inspectedArtifacts, [artifact, artifact]);
      expect(commands, [const TileTappedCommand(1, 1)]);
    });

    test('second tap on artifact hex opens artifact popup', () async {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedArtifacts = <WorldArtifact>[];
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.queensMirror,
        col: 1,
        row: 1,
      );
      var state = GameState(activePlayerId: 'player_1', artifacts: [artifact]);
      state = state.copyWith(
        fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
      );
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onArtifactInspected: (artifact, _) {
          inspectedArtifacts.add(artifact);
        },
      );
      addTearDown(game.disposeRenderer);
      game.applyState(state);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 1)]);
      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.tile?.col, 1);
      expect(state.selection?.tile?.row, 1);
      expect(inspectedArtifacts, isEmpty);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));

      expect(commands, [const TileTappedCommand(1, 1)]);
      expect(inspectedArtifacts, [artifact]);
    });

    test('second tap on selected hex opens hex description popup', () async {
      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedTiles = <TileData>[];
      var state = GameState(
        activePlayerId: 'player_1',
        fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
      );
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onTileInspected: (tile, _) {
          inspectedTiles.add(tile);
        },
      );
      addTearDown(game.disposeRenderer);
      game.applyState(state);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 1)]);
      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.tile?.col, 1);
      expect(state.selection?.tile?.row, 1);
      expect(inspectedTiles, isEmpty);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));

      expect(commands, [const TileTappedCommand(1, 1)]);
      expect(inspectedTiles.map((tile) => '${tile.col}:${tile.row}'), ['1:1']);
    });

    test('occupied artifact unit marker taps follow hex priority', () async {
      final cycle = ArtifactMarkerTapCycle();
      expect(
        cycle.nextOccupiedTarget('artifact', unitAlreadySelected: false),
        ArtifactMarkerTapTarget.unit,
      );
      expect(
        cycle.nextOccupiedTarget('artifact', unitAlreadySelected: true),
        ArtifactMarkerTapTarget.artifact,
      );
      expect(
        cycle.nextOccupiedTarget('artifact', unitAlreadySelected: true),
        ArtifactMarkerTapTarget.hex,
      );

      final map = _map(3, 3);
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedArtifacts = <WorldArtifact>[];
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 1,
        row: 1,
      );
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.queensMirror,
        col: 1,
        row: 1,
      );
      var state = GameState(
        activePlayerId: 'player_1',
        units: [unit],
        artifacts: [artifact],
        fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
        interaction: GameInteractionState(
          selection: GameSelection.unit(unit, tile: _tile(map, 1, 1)),
        ),
      );
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onArtifactInspected: (artifact, _) {
          inspectedArtifacts.add(artifact);
        },
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(state)
        ..handleUnitMarkerTappedForTesting(unit.id);
      await Future<void>.delayed(Duration.zero);

      expect(inspectedArtifacts, isEmpty);
      expect(commands, [const TileTappedCommand(1, 1)]);
      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.tile?.col, 1);
      expect(state.selection?.tile?.row, 1);

      game.handleUnitMarkerTappedForTesting(unit.id);
      await Future<void>.delayed(Duration.zero);

      expect(commands, [
        const TileTappedCommand(1, 1),
        const TileTappedCommand(1, 1),
      ]);
      expect(state.selection?.type, GameSelectionType.unit);
      expect(state.selection?.unit?.id, unit.id);
    });

    test('map objective marker tap cycles objective popup and hex', () async {
      final map = _mapWithObjective();
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedObjectives = <MapObjectiveProgress>[];
      final progress = MapObjectiveRules.snapshot(
        objectives: map.objectives,
        cities: const [],
        units: const [],
        holdStatesByObjectiveId: const {},
      ).entryFor('pass_1')!;
      var state = const GameState(activePlayerId: 'player_1');
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onObjectiveInspected: (objective, _) {
          inspectedObjectives.add(objective);
        },
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(state)
        ..handleMapObjectiveMarkerTappedForTesting(progress);

      expect(inspectedObjectives.map((objective) => objective.definition.id), [
        'pass_1',
      ]);
      expect(commands, isEmpty);

      game.handleMapObjectiveMarkerTappedForTesting(progress);
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const SelectTileCommand(1, 1)]);
      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.tile?.col, 1);
      expect(state.selection?.tile?.row, 1);
      expect(inspectedObjectives, hasLength(1));

      game.handleMapObjectiveMarkerTappedForTesting(progress);

      expect(inspectedObjectives.map((objective) => objective.definition.id), [
        'pass_1',
        'pass_1',
      ]);
    });

    test('occupied objective hex tap cycles unit, objective, hex', () async {
      final map = _mapWithObjective();
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedObjectives = <MapObjectiveProgress>[];
      final unit = GameUnit(
        id: 'scout_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.scout,
        name: 'Scout',
        col: 1,
        row: 1,
      );
      final progress = MapObjectiveRules.snapshot(
        objectives: map.objectives,
        cities: const [],
        units: [unit],
        holdStatesByObjectiveId: const {},
      ).entryFor('pass_1')!;
      var state = GameState(
        activePlayerId: 'player_1',
        units: [unit],
        interaction: GameInteractionState(
          selection: GameSelection.unit(unit, tile: _tile(map, 1, 1)),
        ),
      );
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onObjectiveInspected: (objective, _) {
          inspectedObjectives.add(objective);
        },
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(state)
        ..handleMapObjectiveMarkerTappedForTesting(progress);

      expect(inspectedObjectives.map((objective) => objective.definition.id), [
        'pass_1',
      ]);
      expect(commands, isEmpty);

      game.handleMapObjectiveMarkerTappedForTesting(progress);
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const SelectTileCommand(1, 1)]);
      expect(state.selection?.type, GameSelectionType.tile);
      expect(state.selection?.tile?.col, 1);
      expect(state.selection?.tile?.row, 1);
    });

    test(
      'occupied hex tap cycles unit, hex, terrain popup, and unit',
      () async {
        final map = _mapWithObjective();
        final reducer = GameStateReducer(mapData: map);
        final commands = <GameCommand>[];
        final inspectedArtifacts = <WorldArtifact>[];
        final inspectedObjectives = <MapObjectiveProgress>[];
        final inspectedTiles = <TileData>[];
        final unit = GameUnit(
          id: 'scout_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.scout,
          name: 'Scout',
          col: 1,
          row: 1,
        );
        final artifact = WorldArtifact.placed(
          type: WorldArtifactType.queensMirror,
          col: 1,
          row: 1,
        );
        var state = GameState(
          activePlayerId: 'player_1',
          units: [unit],
          artifacts: [artifact],
          fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
        );
        late final GameRenderer game;
        game = GameRenderer(
          mapData: map,
          onCommand: (command) async {
            commands.add(command);
            final transition = reducer.reduce(state, command);
            state = transition.state;
            game.applyState(state);
          },
          onArtifactInspected: (artifact, _) {
            inspectedArtifacts.add(artifact);
          },
          onObjectiveInspected: (objective, _) {
            inspectedObjectives.add(objective);
          },
          onTileInspected: (tile, _) {
            inspectedTiles.add(tile);
          },
        );
        addTearDown(game.disposeRenderer);
        game.applyState(state);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 1)]);
        expect(state.selection?.type, GameSelectionType.unit);
        expect(state.selection?.unit?.id, 'scout_1');

        await game.handleTileTappedForTesting(_tile(map, 1, 1));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [
          const TileTappedCommand(1, 1),
          const SelectTileCommand(1, 1),
        ]);
        expect(state.selection?.type, GameSelectionType.tile);
        expect(state.selection?.tile?.col, 1);
        expect(state.selection?.tile?.row, 1);
        expect(inspectedArtifacts, isEmpty);
        expect(inspectedObjectives, isEmpty);
        expect(inspectedTiles, isEmpty);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));

        expect(inspectedTiles.map((tile) => '${tile.col}:${tile.row}'), [
          '1:1',
        ]);
        expect(inspectedArtifacts, isEmpty);
        expect(inspectedObjectives, isEmpty);
        expect(commands, [
          const TileTappedCommand(1, 1),
          const SelectTileCommand(1, 1),
        ]);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [
          const TileTappedCommand(1, 1),
          const SelectTileCommand(1, 1),
          const SelectUnitCommand('scout_1'),
        ]);
        expect(state.selection?.type, GameSelectionType.unit);
        expect(state.selection?.unit?.id, 'scout_1');
      },
    );

    test('hex tap cycles artifact, objective, then hex popup', () async {
      final map = _mapWithObjective();
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedArtifacts = <WorldArtifact>[];
      final inspectedObjectives = <MapObjectiveProgress>[];
      final inspectedTiles = <TileData>[];
      final artifact = WorldArtifact.placed(
        type: WorldArtifactType.queensMirror,
        col: 1,
        row: 1,
      );
      var state = GameState(
        activePlayerId: 'player_1',
        artifacts: [artifact],
        fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
      );
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onArtifactInspected: (artifact, _) {
          inspectedArtifacts.add(artifact);
        },
        onObjectiveInspected: (objective, _) {
          inspectedObjectives.add(objective);
        },
        onTileInspected: (tile, _) {
          inspectedTiles.add(tile);
        },
      );
      addTearDown(game.disposeRenderer);
      game.applyState(state);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 1)]);
      expect(state.selection?.type, GameSelectionType.tile);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));

      expect(inspectedArtifacts, [artifact]);
      expect(inspectedObjectives, isEmpty);
      expect(inspectedTiles, isEmpty);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));

      expect(inspectedObjectives.map((objective) => objective.definition.id), [
        'pass_1',
      ]);
      expect(inspectedTiles, isEmpty);

      await game.handleTileTappedForTesting(_tile(map, 1, 1));

      expect(inspectedTiles.map((tile) => '${tile.col}:${tile.row}'), ['1:1']);
      expect(commands, [const TileTappedCommand(1, 1)]);
    });

    test('city hex tap opens objective after selecting the city', () async {
      final map = _mapWithObjective();
      final reducer = GameStateReducer(mapData: map);
      final commands = <GameCommand>[];
      final inspectedObjectives = <MapObjectiveProgress>[];
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
      );
      var state = const GameState(activePlayerId: 'player_1', cities: [city]);
      late final GameRenderer game;
      game = GameRenderer(
        mapData: map,
        onCommand: (command) async {
          commands.add(command);
          final transition = reducer.reduce(state, command);
          state = transition.state;
          game.applyState(state);
        },
        onObjectiveInspected: (objective, _) {
          inspectedObjectives.add(objective);
        },
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(state)
        ..handleCityMarkerTappedForTesting(city);
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const CityTappedCommand('city_1')]);
      state = state.copyWithInteraction(
        selection: GameSelection.city(
          city,
          cityYield: TileYield.zero,
          playerColor: 0xFF4488CC,
        ),
      );
      game
        ..applyState(state)
        ..handleCityMarkerTappedForTesting(city);

      expect(inspectedObjectives.map((objective) => objective.definition.id), [
        'pass_1',
      ]);
    });

    test(
      'city hex with unit cycles city, unit, terrain popup, hex, and city',
      () async {
        final map = _map(3, 3);
        final reducer = GameStateReducer(mapData: map);
        final commands = <GameCommand>[];
        final inspectedTiles = <TileData>[];
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'City',
          center: CityHex(col: 1, row: 1),
        );
        final unit = GameUnit.produced(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        );
        var state = GameState(
          activePlayerId: 'player_1',
          units: [unit],
          cities: const [city],
          fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
        );
        late final GameRenderer game;
        game = GameRenderer(
          mapData: map,
          onCommand: (command) async {
            commands.add(command);
            final transition = reducer.reduce(state, command);
            state = transition.state;
            game.applyState(state);
          },
          onTileInspected: (tile, _) {
            inspectedTiles.add(tile);
          },
        );
        addTearDown(game.disposeRenderer);
        game.applyState(state);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 1)]);
        expect(state.selection?.type, GameSelectionType.city);
        expect(state.selection?.city?.id, city.id);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [
          const TileTappedCommand(1, 1),
          const TileTappedCommand(1, 1),
        ]);
        expect(state.selection?.type, GameSelectionType.unit);
        expect(state.selection?.unit?.id, unit.id);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));

        expect(inspectedTiles.map((tile) => '${tile.col}:${tile.row}'), [
          '1:1',
        ]);
        expect(commands, [
          const TileTappedCommand(1, 1),
          const TileTappedCommand(1, 1),
        ]);
        expect(state.selection?.type, GameSelectionType.unit);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [
          const TileTappedCommand(1, 1),
          const TileTappedCommand(1, 1),
          const SelectTileCommand(1, 1),
        ]);
        expect(state.selection?.type, GameSelectionType.tile);
        expect(state.selection?.tile?.col, 1);
        expect(state.selection?.tile?.row, 1);

        await game.handleTileTappedForTesting(_tile(map, 1, 1));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [
          const TileTappedCommand(1, 1),
          const TileTappedCommand(1, 1),
          const SelectTileCommand(1, 1),
          const TileTappedCommand(1, 1),
        ]);
        expect(state.selection?.type, GameSelectionType.city);
        expect(state.selection?.city?.id, city.id);
      },
    );

    test(
      'tile tap during city expansion dispatches expansion selection',
      () async {
        final map = _map(3, 3);
        final commands = <GameCommand>[];
        final game =
            GameRenderer(
              mapData: map,
              onCommand: (command) async {
                commands.add(command);
              },
            )..applyState(
              const GameState(
                interaction: GameInteractionState(
                  pendingAction: PendingCityExpansionSelection(
                    ownerPlayerId: 'player_1',
                    cityId: 'city_1',
                  ),
                ),
              ),
            );
        addTearDown(game.disposeRenderer);

        await game.handleTileTappedForTesting(_tile(map, 1, 2));
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const SelectCityExpansionHexCommand('city_1', 1, 2)]);
      },
    );

    test('applyState publishes renderer state to visual test accessors', () {
      final map = _map(3, 3);
      final commander = GameUnit.startingCommander(ownerPlayerId: 'player_1');
      final preview = UnitMovementPlan(
        unitId: commander.id,
        targetCol: 1,
        targetRow: 0,
        totalCost: 1,
        availableMovementPoints: commander.movementPoints,
        steps: const [
          UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
          UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        ],
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {})
        ..applyState(
          GameState(
            units: [commander],
            activePlayerId: 'player_1',
            interaction: GameInteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
              moveCommandActive: true,
              movePreview: preview,
            ),
          ),
        );

      expect(game.unitsForTesting, [commander]);
      expect(game.viewModelListenable.value.selection?.unit?.id, commander.id);
      expect(game.moveCommandActiveForTesting, isTrue);
      expect(game.movePreviewTargetForTesting, (col: 1, row: 0));
      expect(game.movePreviewCostForTesting, 1);
    });

    test('tile view marks city territory overlay as strategic', () async {
      final map = _map(3, 3);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final game = GameRenderer(
        mapData: map,
        initialViewMode: MapViewMode.graphic,
        onCommand: (_) async {},
      );
      addTearDown(game.disposeRenderer);

      game
        ..onGameResize(Vector2(800, 600))
        ..applyState(const GameState(cities: [city]));
      await game.onLoad();

      expect(game.cityTerritoryStrategicViewForTesting, isFalse);

      game.viewMode = MapViewMode.tile;

      expect(game.cityTerritoryStrategicViewForTesting, isTrue);
    });

    test('strengthens city territory overlay when zooming out', () async {
      final map = _map(3, 3);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'City',
        center: CityHex(col: 1, row: 1),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..onGameResize(Vector2(800, 600))
        ..applyState(const GameState(cities: [city]));
      await game.onLoad();

      game.setZoom(1);
      final closeEmphasis = game.cityTerritoryZoomEmphasisForTesting;

      game.setZoom(0.35);

      expect(closeEmphasis, 0);
      expect(game.cityTerritoryZoomEmphasisForTesting, 1);
    });

    test('publishes zoom changes for the performance debug overlay', () async {
      final map = _map(3, 3);
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game.onGameResize(Vector2(800, 600));
      await game.onLoad();

      game.setZoom(0.75);

      expect(game.zoomListenable.value, closeTo(0.75, 0.0001));
    });

    test(
      'skips marker density sync for tiny same-bucket zoom deltas',
      () async {
        final map = _map(3, 3);
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game.onGameResize(Vector2(800, 600));
        await game.onLoad();

        game
          ..setZoom(1.2)
          ..onGameResize(Vector2(800, 600));
        final initialSyncCount = game.markerDensitySyncCountForTesting;
        expect(game.markerDensityLastSyncedZoomForTesting, closeTo(1.2, 0.001));

        game.setZoom(1.19);

        expect(game.markerDensitySyncCountForTesting, initialSyncCount);

        game.setZoom(1.16);

        expect(game.markerDensitySyncCountForTesting, initialSyncCount + 1);
      },
    );

    test('uses fast image rendering while panning the camera', () async {
      final map = _map(3, 3);
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game.onGameResize(Vector2(800, 600));
      await game.onLoad();

      expect(game.imageLayerPrefersFastRenderingForTesting, isFalse);

      game.panByScreenDelta(Vector2(24, 0));
      expect(game.imageLayerPrefersFastRenderingForTesting, isTrue);

      game
        ..update(0)
        ..update(0.13);

      expect(game.imageLayerPrefersFastRenderingForTesting, isFalse);
    });

    test('queues renderer effects until the Flame world is ready', () async {
      final map = _map(3, 3);
      final game = GameRenderer(
        mapData: map,
        startCameraOffMap: true,
        onCommand: (_) async {},
      );
      addTearDown(game.disposeRenderer);

      await game.handleEffect(const JumpCameraEffect(col: 1, row: 1));
      game.onGameResize(Vector2(800, 600));
      await game.onLoad();

      expect(game.camera.viewfinder.position.x, isNot(-100000));
      expect(game.camera.viewfinder.position.y, isNot(-100000));
    });

    test('camera effects ignore remembered fog targets', () async {
      final map = _map(4, 1);
      final game = GameRenderer(mapData: map, onCommand: (_) async {})
        ..applyState(
          GameState(
            activePlayerId: 'player_1',
            fogOfWar: _fog(
              discovered: {const HexCoordinate(col: 3, row: 0)},
              visible: {const HexCoordinate(col: 0, row: 0)},
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      addTearDown(game.disposeRenderer);
      await game.onLoad();
      await game.handleEffect(const JumpCameraEffect(col: 0, row: 0));
      final before = _visibleCenter(game).clone();

      await game.handleEffect(const JumpCameraEffect(col: 3, row: 0));

      _expectVectorClose(_visibleCenter(game), before);
    });

    test('smooth camera effect animates toward the target tile', () async {
      final map = _map(4, 4);
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game.onGameResize(Vector2(800, 600));
      await game.onLoad();

      final start = _visibleCenter(game).clone();
      final target = UnitMarkerLayer.worldPositionFor(2, 2);
      final future = game.handleEffect(
        const SmoothCameraEffect(col: 2, row: 2, duration: 1),
      );
      await Future<void>.delayed(Duration.zero);

      game.update(0.25);
      final mid = _visibleCenter(game);
      expect((mid - start).length, greaterThan(0));
      expect((mid - target).length, greaterThan(1));
      expect(game.imageLayerPrefersFastRenderingForTesting, isTrue);

      game.update(1);
      await future;

      _expectVectorClose(_visibleCenter(game), target);

      game.update(0.13);

      expect(game.imageLayerPrefersFastRenderingForTesting, isFalse);
    });

    test(
      'transition-controlled animations suppress automatic selection camera focus',
      () async {
        final map = _map(4, 4);
        final attacker = GameUnit.produced(
          id: 'attacker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          col: 1,
          row: 1,
        );
        final defender = GameUnit.produced(
          id: 'defender_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          col: 2,
          row: 1,
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(GameState(units: [attacker, defender]))
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        game.camera.viewfinder
          ..zoom = 2
          ..position = Vector2(900, 700);
        final start = _visibleCenter(game).clone();

        final transition = game.applyTransition(
          GameState(
            units: [attacker, defender],
            interaction: GameInteractionState(
              selection: GameSelection.unit(attacker, tile: _tile(map, 1, 1)),
            ),
          ),
          const [
            PlayCombatAnimationEffect(
              attackerUnitId: 'attacker_1',
              defenderUnitId: 'defender_1',
            ),
          ],
        );
        await Future<void>.delayed(Duration.zero);

        game.update(0.2);

        _expectVectorClose(_visibleCenter(game), start);

        game
          ..update(0.4)
          ..update(0.4);
        await transition;
      },
    );

    test('unit move effect centers camera on start without tracking', () async {
      final map = _map(4, 1);
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameState(units: [unit]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      await game.handleEffect(const JumpCameraEffect(col: 3, row: 0));

      final moveFuture = game.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'warrior_1',
          fromCol: 0,
          fromRow: 0,
          steps: [
            UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
            UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      game.update(0.32);
      await Future<void>.delayed(Duration.zero);
      expect(game.animatingUnitIdsListenable.value, contains(unit.id));
      final cameraCenterAfterFocus = _visibleCenter(game).clone();

      game.update(0.3);
      final markerPosition = game.unitMarkerPositionForTesting(unit.id)!;
      _expectVectorClose(_visibleCenter(game), cameraCenterAfterFocus);
      expect((_visibleCenter(game) - markerPosition).length, greaterThan(8));

      game
        ..update(0.3)
        ..update(0.6)
        ..update(0.6);
      await Future<void>.delayed(Duration.zero);
      await moveFuture;

      _expectVectorClose(_visibleCenter(game), cameraCenterAfterFocus);
    });

    test('serializes overlapping unit move transitions', () async {
      final map = _map(4, 1);
      final unit = GameUnit.produced(
        id: 'warrior_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        col: 0,
        row: 0,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameState(units: [unit]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      var firstCompleted = false;
      var secondCompleted = false;
      final first = game
          .applyTransition(
            GameState(units: [unit.copyWith(col: 1, row: 0)]),
            const [
              AnimateUnitMoveEffect(
                unitId: 'warrior_1',
                fromCol: 0,
                fromRow: 0,
                steps: [
                  UnitMovementStep(
                    col: 1,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 1,
                  ),
                ],
              ),
            ],
          )
          .then((_) {
            firstCompleted = true;
          });
      final second = game
          .applyTransition(
            GameState(units: [unit.copyWith(col: 2, row: 0)]),
            const [
              AnimateUnitMoveEffect(
                unitId: 'warrior_1',
                fromCol: 1,
                fromRow: 0,
                steps: [
                  UnitMovementStep(
                    col: 2,
                    row: 0,
                    enterCost: 1,
                    cumulativeCost: 1,
                  ),
                ],
              ),
            ],
          )
          .then((_) {
            secondCompleted = true;
          });
      await Future<void>.delayed(Duration.zero);

      expect(firstCompleted, isFalse);
      expect(secondCompleted, isFalse);

      game.update(0.7);
      await first.timeout(const Duration(seconds: 1));

      expect(firstCompleted, isTrue);
      expect(secondCompleted, isFalse);
      expect(game.animatingUnitIdsListenable.value, contains(unit.id));

      game.update(0.7);
      await second.timeout(const Duration(seconds: 1));

      expect(secondCompleted, isTrue);
      _expectVectorClose(
        game.unitMarkerPositionForTesting(unit.id)!,
        UnitMarkerLayer.worldPositionFor(2, 0),
      );
    });

    test('hidden unit move effect does not move the camera', () async {
      final map = _map(5, 1);
      final hiddenEnemy = GameUnit.produced(
        id: 'enemy_1',
        ownerPlayerId: 'player_2',
        type: GameUnitType.warrior,
        col: 3,
        row: 0,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameState(units: [hiddenEnemy], activePlayerId: 'player_1'),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      await game.handleEffect(const JumpCameraEffect(col: 0, row: 0));
      final before = _visibleCenter(game).clone();

      await game.handleEffect(
        const AnimateUnitMoveEffect(
          unitId: 'enemy_1',
          fromCol: 3,
          fromRow: 0,
          steps: [
            UnitMovementStep(col: 4, row: 0, enterCost: 1, cumulativeCost: 1),
          ],
        ),
      );

      _expectVectorClose(_visibleCenter(game), before);
    });

    test('focuses the active player when the first state is applied', () async {
      final map = _map(3, 3);
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      final game = GameRenderer(
        mapData: map,
        focusActivePlayerOnFirstState: true,
        onCommand: (_) async {},
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameState(units: [commander], activePlayerId: 'player_1'))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      expect(game.camera.viewfinder.position.x, isNot(0));
      expect(game.camera.viewfinder.position.y, isNot(0));
    });

    test('can hand camera follow to a selected replay perspective', () async {
      final map = _map(5, 5);
      final playerOneUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
      );
      final playerTwoUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 3,
        row: 3,
      );
      final game = GameRenderer(
        mapData: map,
        focusActivePlayerOnFirstState: true,
        onCommand: (_) async {},
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameState(
            activePlayerId: 'player_1',
            units: [playerOneUnit, playerTwoUnit],
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      _expectVectorClose(
        _visibleCenter(game),
        UnitMarkerLayer.worldPositionFor(0, 0),
      );

      expect(game.followPlayerCamera('player_2', immediate: true), isTrue);
      _expectVectorClose(
        _visibleCenter(game),
        UnitMarkerLayer.worldPositionFor(3, 3),
      );

      final movedPlayerTwoUnit = playerTwoUnit.copyWith(col: 4, row: 4);
      game
        ..applyStateWithoutCameraFocus(
          GameState(
            activePlayerId: 'player_2',
            units: [playerOneUnit, movedPlayerTwoUnit],
          ),
        )
        ..update(0.5);

      _expectVectorClose(
        _visibleCenter(game),
        UnitMarkerLayer.worldPositionFor(4, 4),
        tolerance: 12,
      );
    });

    test(
      'keeps the initial active player centered when the viewport arrives late',
      () async {
        final map = _map(3, 3);
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 1,
          row: 1,
        );
        final game = GameRenderer(
          mapData: map,
          focusActivePlayerOnFirstState: true,
          initialCamera: CameraState.zero,
          onCommand: (_) async {},
        );
        addTearDown(game.disposeRenderer);
        expect(game.initialCameraFocusReadyListenable.value, isFalse);

        game
          ..applyState(
            GameState(units: [commander], activePlayerId: 'player_1'),
          )
          ..onGameResize(Vector2.zero());
        await game.onLoad();
        expect(game.initialCameraFocusReadyListenable.value, isFalse);
        game.onGameResize(Vector2(800, 600));
        expect(game.initialCameraFocusReadyListenable.value, isTrue);

        _expectVectorClose(
          _visibleCenter(game),
          UnitMarkerLayer.worldPositionFor(1, 1),
        );
      },
    );

    test(
      'applies new-game initial focus after restoring the zero camera',
      () async {
        final map = _map(3, 3);
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 1,
          row: 1,
        );
        final game = GameRenderer(
          mapData: map,
          focusActivePlayerOnFirstState: true,
          initialCamera: CameraState.zero,
          onCommand: (_) async {},
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(units: [commander], activePlayerId: 'player_1'),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        expect(game.initialCameraFocusReadyListenable.value, isTrue);
        _expectVectorClose(
          _visibleCenter(game),
          UnitMarkerLayer.worldPositionFor(1, 1),
        );
      },
    );

    test(
      'switches selection from a later unit to an earlier unit without key conflicts',
      () async {
        final map = _map(3, 3);
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 0,
          row: 0,
        );
        final settler = GameUnit(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          name: GameUnitType.settler.defaultNameToken,
          col: 1,
          row: 0,
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              units: [commander, settler],
              interaction: GameInteractionState(
                selection: GameSelection.unit(settler, tile: _tile(map, 1, 0)),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        game
          ..update(0)
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              units: [commander, settler],
              interaction: GameInteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 0, 0),
                ),
              ),
            ),
          );

        expect(() => game.update(0), returnsNormally);
      },
    );

    test(
      'smoothly focuses newly selected unit at marker center for current zoom',
      () async {
        final map = _map(3, 3);
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 1,
          row: 1,
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(GameState(units: [commander]))
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        game.camera.viewfinder
          ..zoom = 2
          ..position = Vector2(900, 700);
        final start = _visibleCenter(game).clone();
        final target = UnitMarkerLayer.worldPositionFor(1, 1);

        game.applyState(
          GameState(
            units: [commander],
            interaction: GameInteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 1, 1)),
            ),
          ),
        );

        _expectVectorClose(_visibleCenter(game), start);

        game.update(0.16);
        final mid = _visibleCenter(game);
        expect((mid - start).length, greaterThan(0));
        expect((mid - target).length, greaterThan(1));

        game.update(1);

        _expectVectorClose(_visibleCenter(game), target);
      },
    );

    test('can update selection without moving the camera', () async {
      final map = _map(3, 3);
      final commander = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 1,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameState(units: [commander]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      game.camera.viewfinder
        ..zoom = 2
        ..position = Vector2(900, 700);
      final start = _visibleCenter(game).clone();

      game.applyStateWithoutCameraFocus(
        GameState(
          units: [commander],
          interaction: GameInteractionState(
            selection: GameSelection.unit(commander, tile: _tile(map, 1, 1)),
          ),
        ),
      );

      _expectVectorClose(_visibleCenter(game), start);
    });

    test(
      'smoothly focuses newly selected city at city marker center for current zoom',
      () async {
        final map = _map(3, 3);
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 1, row: 1),
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(const GameState(cities: [city]))
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        game.camera.viewfinder
          ..zoom = 1.6
          ..position = Vector2(900, 700);
        final start = _visibleCenter(game).clone();
        final target = CityMarkerLayer.worldPositionFor(1, 1);

        game.applyState(
          GameState(
            cities: const [city],
            interaction: GameInteractionState(
              selection: GameSelection.city(
                city,
                cityYield: const TileYield(
                  food: 0,
                  production: 0,
                  gold: 0,
                  defense: 0,
                ),
                playerColor: 0xFF0000FF,
              ),
            ),
          ),
        );

        _expectVectorClose(_visibleCenter(game), start);

        game.update(0.16);
        final mid = _visibleCenter(game);
        expect((mid - start).length, greaterThan(0));
        expect((mid - target).length, greaterThan(1));

        game.update(1);

        _expectVectorClose(_visibleCenter(game), target);
      },
    );

    test('keeps persistent city labels visible when zoomed far out', () async {
      final map = _map(3, 3);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(const GameState(cities: [city]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);

      game.setZoom(0.4);

      expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);

      game.applyState(
        GameState(
          cities: const [city],
          interaction: GameInteractionState(
            selection: GameSelection.city(
              city,
              cityYield: const TileYield(
                food: 0,
                production: 0,
                gold: 0,
                defense: 0,
              ),
              playerColor: 0xFF0000FF,
            ),
          ),
        ),
      );

      expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);
    });

    test('hides peripheral unit marker details when zoomed far out', () async {
      final map = _map(3, 3);
      final warrior = GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 1,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameState(units: [warrior]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      game.setZoom(game.unitMarkerDetailsMinZoomForTesting + 0.01);

      expect(
        game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
        isTrue,
      );

      game.setZoom(game.unitMarkerDetailsMinZoomForTesting - 0.01);

      expect(
        game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
        isFalse,
      );
      expect(game.unitMarkerShowsOwnerColorForTesting(warrior.id), isTrue);
      expect(game.unitMarkerShowsHealthBarForTesting(warrior.id), isTrue);
      expect(game.unitMarkerShowsTypeBadgeForTesting(warrior.id), isTrue);
      expect(game.unitMarkerShowsStateBadgeForTesting(warrior.id), isTrue);

      game.setZoom(0.52);

      expect(
        game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
        isFalse,
      );
      expect(game.unitMarkerShowsOwnerColorForTesting(warrior.id), isTrue);
      expect(game.unitMarkerShowsHealthBarForTesting(warrior.id), isTrue);
      expect(game.unitMarkerShowsTypeBadgeForTesting(warrior.id), isTrue);
      expect(game.unitMarkerShowsStateBadgeForTesting(warrior.id), isFalse);
    });

    test('keeps city labels visible below very far zoom', () async {
      final map = _map(3, 3);
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final warrior = GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 2,
        row: 1,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameState(cities: [city], units: [warrior]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      game.setZoom(0.34);

      expect(game.cityMarkerPaintsLabelForTesting(city.id), isTrue);
      expect(game.unitMarkerPositionForTesting(warrior.id), isNotNull);
      expect(game.cityMarkerWorldScaleForTesting(city.id), greaterThan(1.0));
      expect(game.unitMarkerWorldScaleForTesting(warrior.id), greaterThan(1.0));
      expect(game.unitMarkerSpriteScaleForTesting(warrior.id), lessThan(1.0));
      expect(game.unitMarkerTacticalViewEmphasisForTesting(warrior.id), 1);
      expect(game.unitMarkerAnimateIdleForTesting(warrior.id), isFalse);
      expect(game.unitMarkerAnimatesSpriteForTesting(warrior.id), isFalse);
      expect(game.unitMarkerShowsHealthBarForTesting(warrior.id), isTrue);
      expect(game.unitMarkerShowsTypeBadgeForTesting(warrior.id), isTrue);
      expect(
        game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
        isFalse,
      );
    });

    test('recomputes marker density when viewport class changes', () async {
      final map = _map(3, 3);
      final warrior = GameUnit(
        id: 'unit_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 1,
        row: 1,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(GameState(units: [warrior]))
        ..onGameResize(Vector2(678, 1442));
      await game.onLoad();

      expect(game.compactMarkerDensityForTesting, isTrue);
      expect(game.unitMarkerDetailsMinZoomForTesting, 0.82);

      game.setZoom(0.75);

      expect(
        game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
        isFalse,
      );

      game.onGameResize(Vector2(840, 1436));

      expect(game.compactMarkerDensityForTesting, isFalse);
      expect(game.unitMarkerDetailsMinZoomForTesting, 0.72);
      expect(
        game.unitMarkerShowsPeripheralDetailsForTesting(warrior.id),
        isTrue,
      );
    });

    test('adds production particles only for active player cities', () async {
      final map = _map(3, 3);
      final playerCity = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: const CityHex(col: 1, row: 1),
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final enemyCity = GameCity(
        id: 'city_2',
        ownerPlayerId: 'player_2',
        name: 'Antium',
        center: const CityHex(col: 2, row: 1),
        productionQueue: CityProductionQueue.building(
          buildingType: CityBuildingType.granary,
          investedProduction: 0,
        ),
      );
      final knownCitiesFog = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {
              const HexCoordinate(col: 1, row: 1),
              const HexCoordinate(col: 2, row: 1),
            },
          ),
        },
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameState(
            activePlayerId: 'player_1',
            cities: [playerCity, enemyCity],
            fogOfWar: knownCitiesFog,
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      expect(game.cityProductionParticleEmitterCountForTesting, 1);
      expect(
        game.cityProductionParticleEmitterReduceMotionForTesting(playerCity.id),
        isFalse,
      );

      game.setZoom(0.54);

      expect(game.cityProductionParticleEmitterCountForTesting, 0);

      game.setZoom(0.56);

      expect(game.cityProductionParticleEmitterCountForTesting, 1);

      game.applyState(
        GameState(
          activePlayerId: 'player_1',
          cities: [playerCity, enemyCity],
          fogOfWar: knownCitiesFog,
          interaction: const GameInteractionState(
            pendingAction: PendingAttackTargeting(
              ownerPlayerId: 'player_1',
              attackerUnitId: 'unit_1',
            ),
          ),
        ),
      );

      expect(game.cityProductionParticleEmitterCountForTesting, 0);

      game.applyState(
        GameState(
          activePlayerId: 'player_1',
          cities: [playerCity, enemyCity],
          fogOfWar: knownCitiesFog,
        ),
      );

      expect(game.cityProductionParticleEmitterCountForTesting, 1);

      game.reduceMotion = true;

      expect(
        game.cityProductionParticleEmitterReduceMotionForTesting(playerCity.id),
        isTrue,
      );

      game.applyState(
        GameState(
          activePlayerId: 'player_1',
          cities: [playerCity.copyWith(productionQueue: null), enemyCity],
          fogOfWar: knownCitiesFog,
        ),
      );

      expect(game.cityProductionParticleEmitterCountForTesting, 0);
    });

    test(
      'tapping the active unit marker dispatches a tile tap without direct focus',
      () async {
        final map = _map(3, 3);
        final commands = <GameCommand>[];
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 1,
          row: 1,
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              units: [commander],
              interaction: GameInteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 1, 1),
                ),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        game.camera.viewfinder
          ..zoom = 2
          ..position = Vector2(900, 700);
        final start = _visibleCenter(game).clone();

        game.world.children.whereType<UnitMarker>().single.onTap?.call();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 1)]);
        _expectVectorClose(_visibleCenter(game), start);

        game.update(1);

        _expectVectorClose(_visibleCenter(game), start);
      },
    );

    test(
      'tapping an enemy marker during attack targeting selects the target',
      () async {
        final map = _map(3, 1);
        final commands = <GameCommand>[];
        final attacker = GameUnit(
          id: 'attacker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 0,
          row: 0,
        );
        final defender = GameUnit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: GameUnitType.warrior.defaultNameToken,
          col: 1,
          row: 0,
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              units: [attacker, defender],
              fogOfWar: FogOfWarState(
                players: {
                  'player_1': PlayerFogOfWar(
                    playerId: 'player_1',
                    visibleHexes: {
                      const HexCoordinate(col: 0, row: 0),
                      const HexCoordinate(col: 1, row: 0),
                    },
                  ),
                },
              ),
              interaction: GameInteractionState(
                selection: GameSelection.unit(attacker, tile: _tile(map, 0, 0)),
                pendingAction: const PendingAttackTargeting(
                  ownerPlayerId: 'player_1',
                  attackerUnitId: 'attacker_1',
                ),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        final defenderPosition = UnitMarkerLayer.worldPositionFor(1, 0);
        final defenderMarker = game.world.children
            .whereType<UnitMarker>()
            .singleWhere(
              (marker) => (marker.position - defenderPosition).length < 0.001,
            );

        defenderMarker.onTap?.call();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 0)]);
      },
    );

    test(
      'tapping a unit marker during move targeting dispatches a tile tap',
      () async {
        final map = _map(3, 2);
        final commands = <GameCommand>[];
        final commander = GameUnit.produced(
          id: 'commander_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.commander,
          col: 0,
          row: 0,
        );
        final unitOnTarget = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 0,
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [commander, unitOnTarget],
              fogOfWar: FogOfWarState(
                players: {
                  'player_1': PlayerFogOfWar(
                    playerId: 'player_1',
                    visibleHexes: {
                      const HexCoordinate(col: 0, row: 0),
                      const HexCoordinate(col: 1, row: 0),
                    },
                  ),
                },
              ),
              interaction: GameInteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 0, 0),
                ),
                moveCommandActive: true,
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        final targetPosition = UnitMarkerLayer.worldPositionFor(1, 0);
        final marker = game.world.children.whereType<UnitMarker>().singleWhere(
          (marker) => (marker.position - targetPosition).length < 0.001,
        );

        marker.onTap?.call();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 0)]);
      },
    );

    test(
      'tapping a unit marker during city founding dispatches a tile tap',
      () async {
        final map = _map(3, 2);
        final commands = <GameCommand>[];
        final settler = GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 0,
          row: 0,
        );
        final unitOnTarget = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 0,
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [settler, unitOnTarget],
              fogOfWar: FogOfWarState(
                players: {
                  'player_1': PlayerFogOfWar(
                    playerId: 'player_1',
                    visibleHexes: {
                      const HexCoordinate(col: 0, row: 0),
                      const HexCoordinate(col: 1, row: 0),
                    },
                  ),
                },
              ),
              interaction: GameInteractionState(
                selection: GameSelection.unit(settler, tile: _tile(map, 0, 0)),
                cityFoundingDraft: CityFoundingDraft(
                  unitId: 'settler_1',
                  ownerPlayerId: 'player_1',
                  center: const CityHex(col: 0, row: 0),
                ),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        final targetPosition = UnitMarkerLayer.worldPositionFor(1, 0);
        final marker = game.world.children.whereType<UnitMarker>().singleWhere(
          (marker) => (marker.position - targetPosition).length < 0.001,
        );

        marker.onTap?.call();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 0)]);
      },
    );

    test(
      'tapping a city marker during move targeting dispatches a tile tap',
      () async {
        final map = _map(3, 3);
        final commands = <GameCommand>[];
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 1, row: 1),
        );
        final commander = GameUnit.produced(
          id: 'commander_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.commander,
          col: 0,
          row: 0,
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [commander],
              cities: const [city],
              fogOfWar: FogOfWarState(
                players: {
                  'player_1': PlayerFogOfWar(
                    playerId: 'player_1',
                    visibleHexes: {
                      const HexCoordinate(col: 0, row: 0),
                      const HexCoordinate(col: 1, row: 1),
                    },
                  ),
                },
              ),
              interaction: GameInteractionState(
                selection: GameSelection.unit(
                  commander,
                  tile: _tile(map, 0, 0),
                ),
                moveCommandActive: true,
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        game.world.children.whereType<CityMarker>().single.onTap?.call();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 1)]);
      },
    );

    test(
      'tapping a city marker during worker action selection dispatches a tile tap',
      () async {
        final map = _map(3, 3);
        final commands = <GameCommand>[];
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 1, row: 1),
        );
        final worker = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 0,
          row: 0,
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [worker],
              cities: const [city],
              fogOfWar: FogOfWarState(
                players: {
                  'player_1': PlayerFogOfWar(
                    playerId: 'player_1',
                    visibleHexes: {
                      const HexCoordinate(col: 0, row: 0),
                      const HexCoordinate(col: 1, row: 1),
                    },
                  ),
                },
              ),
              interaction: GameInteractionState(
                selection: GameSelection.unit(worker, tile: _tile(map, 0, 0)),
                pendingAction: const PendingWorkerActionSelection(
                  ownerPlayerId: 'player_1',
                  unitId: 'worker_1',
                ),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        game.world.children.whereType<CityMarker>().single.onTap?.call();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [const TileTappedCommand(1, 1)]);
      },
    );

    test(
      'shows worker action palette during worker action selection',
      () async {
        final map = _map(3, 2);
        final worker = GameUnit.produced(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          col: 1,
          row: 0,
        );
        final game = GameRenderer(
          mapData: map,
          workerActionPaletteOptionsBuilder:
              ({
                required state,
                required worker,
                required pendingAction,
                required mapData,
              }) => const [
                ActionPaletteOption(
                  id: 'farm',
                  iconAtlasRow: 0,
                  iconAtlasColumn: 0,
                  label: 'Farm',
                  yieldChips: [
                    ActionPaletteYieldChip(
                      kind: ActionPaletteYieldKind.food,
                      value: 1,
                    ),
                  ],
                  turns: 2,
                  state: ActionPaletteOptionState.available,
                  ctaLabel: 'ZBUDUJ',
                ),
              ],
          onCommand: (_) async {},
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [worker],
              interaction: GameInteractionState(
                selection: GameSelection.unit(worker, tile: _tile(map, 1, 0)),
                pendingAction: const PendingWorkerActionSelection(
                  ownerPlayerId: 'player_1',
                  unitId: 'worker_1',
                ),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        expect(game.actionPaletteVisibleForTesting, isTrue);
        expect(
          game.actionPaletteComponentForTesting?.optionsForTesting.length,
          1,
        );
        _expectVectorClose(
          game.actionPalettePositionForTesting!,
          UnitMarkerLayer.worldPositionFor(1, 0) + Vector2(0, -82),
        );
      },
    );

    test('move preview pill confirms the selected target', () async {
      final map = _map(3, 2);
      final commands = <GameCommand>[];
      final commander = GameUnit.produced(
        id: 'commander_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.commander,
        col: 0,
        row: 0,
      );
      final preview = UnitMovementPlan(
        unitId: 'commander_1',
        targetCol: 1,
        targetRow: 0,
        totalCost: 1,
        availableMovementPoints: 2,
        steps: [
          const UnitMovementStep(
            col: 0,
            row: 0,
            enterCost: 0,
            cumulativeCost: 0,
          ),
          const UnitMovementStep(
            col: 1,
            row: 0,
            enterCost: 1,
            cumulativeCost: 1,
          ),
        ],
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [commander],
            interaction: GameInteractionState(
              selection: GameSelection.unit(commander, tile: _tile(map, 0, 0)),
              movePreview: preview,
              moveCommandActive: true,
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();
      await Future<void>.delayed(Duration.zero);
      game.update(0);

      final popup = game.movePreviewPillForTesting;
      expect(game.actionPaletteVisibleForTesting, isTrue);
      expect(game.actionPaletteComponentForTesting, isNull);
      expect(popup, isNotNull);
      expect(popup!.labelForTesting, 'Confirm (1 turn)');
      _expectVectorClose(
        popup.position,
        UnitMarkerLayer.worldPositionFor(1, 0),
      );

      popup.tapForTesting();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [const TileTappedCommand(1, 0)]);
    });

    test(
      'move preview pill shows turn cost when target unit is deselected',
      () async {
        final map = _map(3, 2);
        final commands = <GameCommand>[];
        final commander = GameUnit.produced(
          id: 'commander_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.commander,
          col: 0,
          row: 0,
        );
        final preview = UnitMovementPlan(
          unitId: 'commander_1',
          targetCol: 1,
          targetRow: 0,
          totalCost: 1,
          availableMovementPoints: 2,
          steps: [
            const UnitMovementStep(
              col: 0,
              row: 0,
              enterCost: 0,
              cumulativeCost: 0,
            ),
            const UnitMovementStep(
              col: 1,
              row: 0,
              enterCost: 1,
              cumulativeCost: 1,
            ),
          ],
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [commander],
              interaction: GameInteractionState(
                selection: GameSelection.tile(_tile(map, 2, 0)),
                movePreview: preview,
                moveCommandActive: true,
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        await Future<void>.delayed(Duration.zero);
        game.update(0);

        final popup = game.movePreviewPillForTesting;
        expect(game.actionPaletteVisibleForTesting, isTrue);
        expect(popup, isNotNull);
        expect(popup!.labelForTesting, '1 turn');

        popup.tapForTesting();
        await Future<void>.delayed(Duration.zero);

        expect(commands, isEmpty);
      },
    );

    test(
      'city founding waits for selected hexes before showing confirmation',
      () async {
        final map = _map(3, 3);
        final settler = GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 1,
          row: 1,
        );
        final draft = CityFoundingDraft(
          unitId: 'settler_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 1, row: 1),
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [settler],
              interaction: GameInteractionState(
                selection: GameSelection.unit(settler, tile: _tile(map, 1, 1)),
                cityFoundingDraft: draft,
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        expect(game.actionPaletteVisibleForTesting, isFalse);
      },
    );

    test(
      'city founding does not use the map action palette for confirmation',
      () async {
        final map = _map(3, 3);
        final settler = GameUnit.produced(
          id: 'settler_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.settler,
          col: 1,
          row: 1,
        );
        final draft = CityFoundingDraft(
          unitId: 'settler_1',
          ownerPlayerId: 'player_1',
          center: const CityHex(col: 1, row: 1),
          controlledHexes: const [
            CityHex(col: 1, row: 0),
            CityHex(col: 2, row: 1),
          ],
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              activePlayerCanAct: true,
              units: [settler],
              interaction: GameInteractionState(
                selection: GameSelection.unit(settler, tile: _tile(map, 1, 1)),
                cityFoundingDraft: draft,
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        expect(game.actionPaletteVisibleForTesting, isFalse);
        expect(game.actionPaletteComponentForTesting, isNull);
        expect(game.actionPalettePositionForTesting, isNull);
      },
    );

    test('worker action palette dispatches preview and confirm', () async {
      final map = _map(3, 2);
      final commands = <GameCommand>[];
      final worker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 1,
        row: 0,
      );
      final game = GameRenderer(
        mapData: map,
        workerActionPaletteOptionsBuilder:
            ({
              required state,
              required worker,
              required pendingAction,
              required mapData,
            }) => const [
              ActionPaletteOption(
                id: 'farm',
                iconAtlasRow: 0,
                iconAtlasColumn: 0,
                label: 'Farm',
                yieldChips: [
                  ActionPaletteYieldChip(
                    kind: ActionPaletteYieldKind.food,
                    value: 1,
                  ),
                ],
                turns: 2,
                state: ActionPaletteOptionState.available,
                ctaLabel: 'ZBUDUJ',
              ),
            ],
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      GameState state({FieldImprovementType? improvementType}) => GameState(
        activePlayerId: 'player_1',
        activePlayerCanAct: true,
        units: [worker],
        interaction: GameInteractionState(
          selection: GameSelection.unit(worker, tile: _tile(map, 1, 0)),
          pendingAction: PendingWorkerActionSelection(
            ownerPlayerId: 'player_1',
            unitId: 'worker_1',
            improvementType: improvementType,
          ),
        ),
      );

      game
        ..applyState(state())
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      game.actionPaletteComponentForTesting?.tapOptionForTesting('farm');
      await Future<void>.delayed(Duration.zero);

      expect(commands, [
        const SelectWorkerImprovementCommand(
          'worker_1',
          FieldImprovementType.farm,
        ),
      ]);

      game
        ..applyState(state(improvementType: FieldImprovementType.farm))
        ..actionPaletteComponentForTesting?.tapCtaForTesting();
      await Future<void>.delayed(Duration.zero);

      expect(commands.last, const ConfirmWorkerImprovementCommand('worker_1'));
    });

    test('worker action palette keeps blocked options local', () async {
      final map = _map(3, 2);
      final commands = <GameCommand>[];
      final worker = GameUnit.produced(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        col: 1,
        row: 0,
      );
      final game = GameRenderer(
        mapData: map,
        workerActionPaletteOptionsBuilder:
            ({
              required state,
              required worker,
              required pendingAction,
              required mapData,
            }) => const [
              ActionPaletteOption(
                id: 'mine',
                iconAtlasRow: 0,
                iconAtlasColumn: 0,
                label: 'Mine',
                yieldChips: [],
                turns: 3,
                state: ActionPaletteOptionState.blocked,
                ctaLabel: 'ZBUDUJ',
                blockedReason: 'Requires hills',
              ),
            ],
        onCommand: (command) async => commands.add(command),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameState(
            activePlayerId: 'player_1',
            activePlayerCanAct: true,
            units: [worker],
            interaction: GameInteractionState(
              selection: GameSelection.unit(worker, tile: _tile(map, 1, 0)),
              pendingAction: const PendingWorkerActionSelection(
                ownerPlayerId: 'player_1',
                unitId: 'worker_1',
              ),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      game.actionPaletteComponentForTesting?.tapOptionForTesting('mine');
      await Future<void>.delayed(Duration.zero);

      expect(commands, isEmpty);
      expect(
        game.actionPaletteComponentForTesting?.tooltipMessageForTesting,
        'Requires hills',
      );
    });

    test(
      'tapping the active city icon recenters even without selection change',
      () async {
        final map = _map(3, 3);
        final commands = <GameCommand>[];
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 1, row: 1),
        );
        final game = GameRenderer(
          mapData: map,
          onCommand: (command) async => commands.add(command),
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              cities: const [city],
              interaction: GameInteractionState(
                selection: GameSelection.city(
                  city,
                  cityYield: const TileYield(
                    food: 0,
                    production: 0,
                    gold: 0,
                    defense: 0,
                  ),
                  playerColor: 0xFF0000FF,
                ),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        game.camera.viewfinder
          ..zoom = 1.6
          ..position = Vector2(900, 700);
        final start = _visibleCenter(game).clone();
        final target = CityMarkerLayer.worldPositionFor(1, 1);

        game.world.children.whereType<CityMarker>().single.onTap?.call();
        await Future<void>.delayed(Duration.zero);

        expect(commands, [CityTappedCommand(city.id)]);
        _expectVectorClose(_visibleCenter(game), start);

        game.update(1);

        _expectVectorClose(_visibleCenter(game), target);
      },
    );

    test('quick double tapping a city opens its description detail', () async {
      final map = _map(3, 3);
      final commands = <GameCommand>[];
      final descriptionRequests = <String>[];
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 1, row: 1),
      );
      final game = GameRenderer(
        mapData: map,
        onCommand: (command) async => commands.add(command),
        onCityDescriptionRequested: (city) => descriptionRequests.add(city.id),
      );
      addTearDown(game.disposeRenderer);

      game
        ..applyState(const GameState(cities: [city]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final marker = game.world.children.whereType<CityMarker>().single;
      marker.onTap?.call();
      marker.onTap?.call();
      await Future<void>.delayed(Duration.zero);

      expect(commands, [
        CityTappedCommand(city.id),
        SelectCityCommand(city.id),
      ]);
      expect(descriptionRequests, [city.id]);
    });

    test(
      'combat animation retains killed defender marker until completion',
      () async {
        final map = _map(2, 1);
        final attacker = GameUnit(
          id: 'attacker',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        );
        final defender = GameUnit(
          id: 'defender',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: 'Enemy',
          col: 1,
          row: 0,
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(GameState(units: [attacker, defender]))
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        game.update(0);

        final future = game.applyTransition(
          GameState(units: [attacker.copyWith(movementPoints: 0)]),
          const [
            PlayCombatAnimationEffect(
              attackerUnitId: 'attacker',
              defenderUnitId: 'defender',
              defenderKilled: true,
            ),
          ],
        );
        await Future<void>.delayed(Duration.zero);

        expect(
          game.animatingUnitIdsListenable.value,
          containsAll(['attacker', 'defender']),
        );
        expect(
          game.unitMarkerActionForTesting('attacker'),
          UnitSpriteAction.attack,
        );

        game.update(0.4);
        expect(
          game.unitMarkerActionForTesting('defender'),
          UnitSpriteAction.die,
        );

        game.update(0.4);
        await future;
        expect(
          game.animatingUnitIdsListenable.value,
          isNot(contains('defender')),
        );
        expect(game.unitMarkerActionForTesting('defender'), isNull);
        expect(
          game.unitMarkerActionForTesting('attacker'),
          UnitSpriteAction.idle,
        );
      },
    );

    test('syncs city-site planning markers from current game state', () async {
      final map = MapData(
        cols: 4,
        rows: 2,
        tiles: [
          for (int r = 0; r < 2; r++)
            for (int c = 0; c < 4; c++)
              TileData(
                col: c,
                row: r,
                terrains: c == 2 && r == 1
                    ? const [TerrainType.ocean]
                    : const [TerrainType.grassland],
                resources: const [],
                height: 0,
              ),
        ],
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [CityHex(col: 1, row: 0)],
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(const GameState(cities: [city]))
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final center = game.tileMarkersForTesting(0, 0);
      final owned = game.tileMarkersForTesting(1, 0);
      final growthCandidate = game.tileMarkersForTesting(0, 1);
      final ocean = game.tileMarkersForTesting(2, 1);
      final territoryCandidate = game.tileMarkersForTesting(3, 1);

      expect(center.hasAny, isFalse);
      expect(owned.canFoundCity, isFalse);
      expect(owned.canGrowCity, isFalse);
      expect(growthCandidate.canFoundCity, isFalse);
      expect(growthCandidate.canGrowCity, isTrue);
      expect(ocean.canFoundCity, isFalse);
      expect(ocean.canGrowCity, isTrue);
      expect(territoryCandidate.canFoundCity, isTrue);
      expect(territoryCandidate.canGrowCity, isTrue);
    });

    test('selected settler forces city-site markers visible', () async {
      final map = _map(3, 2);
      final settler = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 0,
        row: 0,
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameState(
            units: [settler],
            interaction: GameInteractionState(
              selection: GameSelection.unit(settler),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final candidate = game.tileMarkersForTesting(1, 0);

      expect(candidate.canFoundCity, isTrue);
      expect(candidate.forceShowCitySite, isTrue);

      game.applyState(GameState(units: [settler]));

      expect(game.tileMarkersForTesting(1, 0).forceShowCitySite, isFalse);
    });

    test('selected settler highlights best city-site markers', () async {
      final map = MapData(
        cols: 5,
        rows: 1,
        tiles: const [
          TileData(
            col: 0,
            row: 0,
            terrains: [TerrainType.tundra],
            resources: [],
            height: 0,
          ),
          TileData(
            col: 1,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [ResourceType.wheat],
            height: 0,
          ),
          TileData(
            col: 2,
            row: 0,
            terrains: [TerrainType.hills],
            resources: [ResourceType.iron],
            height: 0,
          ),
          TileData(
            col: 3,
            row: 0,
            terrains: [TerrainType.grassland],
            resources: [ResourceType.deer],
            height: 0,
          ),
          TileData(
            col: 4,
            row: 0,
            terrains: [TerrainType.plains],
            resources: [ResourceType.rice],
            height: 0,
          ),
        ],
      );
      final settler = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 2,
        row: 0,
        army: const [ArmyTroop(type: TroopType.settler, count: 1)],
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);
      final visibleHexes = {
        for (final tile in map.tiles) HexCoordinate.fromTile(tile),
      };
      final fogOfWar = FogOfWarState.empty.updatePlayer(
        PlayerFogOfWar(playerId: 'player_1', visibleHexes: visibleHexes),
      );

      game
        ..applyState(
          GameState(
            activePlayerId: 'player_1',
            fogOfWar: fogOfWar,
            units: [settler],
            interaction: GameInteractionState(
              selection: GameSelection.unit(settler, tile: _tile(map, 2, 0)),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      final actualRecommended = {
        for (final tile in map.tiles)
          if (game
              .tileMarkersForTesting(tile.col, tile.row)
              .recommendedCitySite)
            (tile.col, tile.row),
      };

      expect(actualRecommended, hasLength(4));
      expect(actualRecommended, containsAll({(1, 0), (2, 0), (3, 0), (4, 0)}));
      for (final (col, row) in actualRecommended) {
        final marker = game.tileMarkersForTesting(col, row);
        expect(marker.canFoundCity, isTrue);
        expect(marker.forceShowCitySite, isTrue);
      }

      game.applyState(GameState(activePlayerId: 'player_1', units: [settler]));

      expect(game.tileMarkersForTesting(1, 0).recommendedCitySite, isFalse);
      expect(game.tileMarkersForTesting(1, 0).forceShowCitySite, isFalse);
    });

    test(
      'selected settler recommends city sites with nearby resources',
      () async {
        final map = MapData(
          cols: 9,
          rows: 4,
          tiles: [
            for (int row = 0; row < 4; row++)
              for (int col = 0; col < 9; col++)
                TileData(
                  col: col,
                  row: row,
                  terrains: const [TerrainType.plains],
                  resources: switch ((col, row)) {
                    (4, 0) => const [ResourceType.wheat],
                    (5, 1) => const [ResourceType.iron],
                    (4, 2) => const [ResourceType.deer],
                    _ => const [],
                  },
                  height: 0,
                ),
          ],
        );
        final settler = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 3,
          row: 1,
          army: const [ArmyTroop(type: TroopType.settler, count: 1)],
        );
        const ownCity = GameCity(
          id: 'city_player_1_0_1',
          ownerPlayerId: 'player_1',
          name: 'Home',
          center: CityHex(col: 0, row: 1),
        );
        const enemyCity = GameCity(
          id: 'city_player_2_8_2',
          ownerPlayerId: 'player_2',
          name: 'Enemy',
          center: CityHex(col: 8, row: 2),
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);
        final visibleHexes = {
          for (final tile in map.tiles) HexCoordinate.fromTile(tile),
        };
        final fogOfWar = FogOfWarState.empty.updatePlayer(
          PlayerFogOfWar(playerId: 'player_1', visibleHexes: visibleHexes),
        );

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              fogOfWar: fogOfWar,
              units: [settler],
              cities: [ownCity, enemyCity],
              interaction: GameInteractionState(
                selection: GameSelection.unit(settler, tile: _tile(map, 3, 1)),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        final recommended = {
          for (final tile in map.tiles)
            if (game
                .tileMarkersForTesting(tile.col, tile.row)
                .recommendedCitySite)
              (tile.col, tile.row),
        };

        expect(recommended, contains((4, 0)));
        expect(recommended, contains((5, 1)));
        expect(recommended.length, greaterThan(3));
        expect(game.tileMarkersForTesting(8, 2).canFoundCity, isFalse);
      },
    );

    test(
      'syncs attack target markers while attack targeting is active',
      () async {
        final map = _map(4, 1);
        final attacker = GameUnit(
          id: 'warrior_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.warrior,
          name: 'Warrior',
          col: 0,
          row: 0,
        );
        final defender = GameUnit(
          id: 'enemy_1',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: 'Enemy',
          col: 1,
          row: 0,
        );
        final distantEnemy = GameUnit(
          id: 'enemy_2',
          ownerPlayerId: 'player_2',
          type: GameUnitType.warrior,
          name: 'Distant enemy',
          col: 3,
          row: 0,
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              activePlayerId: 'player_1',
              units: [attacker, defender, distantEnemy],
              fogOfWar: FogOfWarState(
                players: {
                  'player_1': PlayerFogOfWar(
                    playerId: 'player_1',
                    visibleHexes: {
                      for (var col = 0; col < 4; col++)
                        HexCoordinate(col: col, row: 0),
                    },
                  ),
                },
              ),
              interaction: GameInteractionState(
                selection: GameSelection.unit(attacker),
                pendingAction: const PendingAttackTargeting(
                  ownerPlayerId: 'player_1',
                  attackerUnitId: 'warrior_1',
                ),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        expect(game.tileMarkersForTesting(1, 0).canAttackTarget, isTrue);
        expect(game.tileMarkersForTesting(3, 0).canAttackTarget, isFalse);
        expect(game.threatOverlayHexesForTesting, isNotEmpty);
        expect(game.isUnitMarkerAttackTargetForTesting(defender.id), isTrue);
        expect(
          game.unitMarkerHasAttackTargetTintForTesting(defender.id),
          isTrue,
        );
        expect(
          game.isUnitMarkerAttackTargetForTesting(distantEnemy.id),
          isFalse,
        );

        game.applyState(
          GameState(
            activePlayerId: 'player_1',
            units: [attacker, defender, distantEnemy],
            fogOfWar: FogOfWarState(
              players: {
                'player_1': PlayerFogOfWar(
                  playerId: 'player_1',
                  visibleHexes: {
                    for (var col = 0; col < 4; col++)
                      HexCoordinate(col: col, row: 0),
                  },
                ),
              },
            ),
            interaction: GameInteractionState(
              selection: GameSelection.unit(attacker),
            ),
          ),
        );

        expect(game.tileMarkersForTesting(1, 0).canAttackTarget, isFalse);
        expect(game.threatOverlayHexesForTesting, isEmpty);
        expect(game.isUnitMarkerAttackTargetForTesting(defender.id), isFalse);
      },
    );

    test('syncs worker improvement hints for selected worker', () async {
      final map = MapData(
        cols: 3,
        rows: 2,
        tiles: [
          for (int r = 0; r < 2; r++)
            for (int c = 0; c < 3; c++)
              TileData(
                col: c,
                row: r,
                terrains: c == 0 && r == 1
                    ? const [TerrainType.hills]
                    : const [TerrainType.grassland],
                resources: const [],
                height: 0,
              ),
        ],
      );
      const city = GameCity(
        id: 'city_1',
        ownerPlayerId: 'player_1',
        name: 'Capital',
        center: CityHex(col: 0, row: 0),
        controlledHexes: [
          CityHex(col: 1, row: 0),
          CityHex(col: 2, row: 0),
          CityHex(col: 0, row: 1),
        ],
      );
      final worker = GameUnit(
        id: 'worker_1',
        ownerPlayerId: 'player_1',
        type: GameUnitType.worker,
        name: GameUnitType.worker.defaultNameToken,
        col: 1,
        row: 0,
      );
      final game = GameRenderer(mapData: map, onCommand: (_) async {});
      addTearDown(game.disposeRenderer);

      game
        ..applyState(
          GameState(
            units: [worker],
            cities: const [city],
            fieldImprovements: const [
              FieldImprovement(
                hex: CityHex(col: 1, row: 0),
                type: FieldImprovementType.farm,
                builtByCityId: 'city_1',
              ),
            ],
            research: ResearchState(
              players: {
                'player_1': PlayerResearchState(
                  unlockedTechnologyIds: {TechnologyId.agriculture},
                ),
              },
            ),
            interaction: GameInteractionState(
              selection: GameSelection.unit(worker),
            ),
          ),
        )
        ..onGameResize(Vector2(800, 600));
      await game.onLoad();

      expect(game.tileMarkersForTesting(1, 0).workerBuildBlocked, isTrue);
      expect(game.tileMarkersForTesting(1, 0).workerBuildAvailable, isFalse);
      expect(
        game.tileMarkersForTesting(1, 0).workerImprovementCandidate,
        isFalse,
      );
      expect(game.tileMarkersForTesting(2, 0).canImproveNow, isTrue);
      expect(game.tileMarkersForTesting(2, 0).workerBuildAvailable, isTrue);
      expect(game.tileMarkersForTesting(2, 0).workerBuildBlocked, isFalse);
      expect(
        game.tileMarkersForTesting(2, 0).workerImprovementCandidate,
        isTrue,
      );
      expect(
        game.tileMarkersForTesting(0, 1).canImproveAfterTechnology,
        isTrue,
      );
      expect(game.tileMarkersForTesting(0, 1).workerBuildBlocked, isTrue);
      expect(
        game.tileMarkersForTesting(0, 1).workerImprovementCandidate,
        isFalse,
      );
      expect(game.tileMarkersForTesting(1, 1).workerBuildAvailable, isFalse);
      expect(game.tileMarkersForTesting(1, 1).workerBuildBlocked, isFalse);
      expect(
        _overlayKindFor(game, const CityHex(col: 1, row: 0)),
        CityManagementOverlayHexKind.workerImprovementExisting,
      );
      expect(_overlayFor(game, const CityHex(col: 1, row: 0))?.label, '3F');
      expect(
        _overlayFor(game, const CityHex(col: 1, row: 0))?.tileYield,
        const TileYield(food: 3, production: 0, gold: 0, defense: 0),
      );
      expect(
        _overlayKindFor(game, const CityHex(col: 2, row: 0)),
        CityManagementOverlayHexKind.workerImprovementMissingInCity,
      );
      expect(_overlayFor(game, const CityHex(col: 2, row: 0))?.label, '3F');
      expect(
        _overlayFor(game, const CityHex(col: 2, row: 0))?.tileYield,
        const TileYield(food: 3, production: 0, gold: 0, defense: 0),
      );
      expect(_overlayKindFor(game, const CityHex(col: 1, row: 1)), isNull);
      expect(
        _overlayKindFor(game, const CityHex(col: 0, row: 1)),
        CityManagementOverlayHexKind.workerImprovementMissingInCity,
      );
      expect(_overlayFor(game, const CityHex(col: 0, row: 1))?.label, '2P');
      expect(
        _overlayFor(game, const CityHex(col: 0, row: 1))?.tileYield,
        const TileYield(food: 0, production: 2, gold: 0, defense: 0),
      );
    });

    test(
      'marks current worker hex green when a build can start there',
      () async {
        final map = MapData(
          cols: 3,
          rows: 1,
          tiles: [
            for (int c = 0; c < 3; c++)
              TileData(
                col: c,
                row: 0,
                terrains: const [TerrainType.grassland],
                resources: const [],
                height: 0,
              ),
          ],
        );
        const city = GameCity(
          id: 'city_1',
          ownerPlayerId: 'player_1',
          name: 'Capital',
          center: CityHex(col: 0, row: 0),
          controlledHexes: [CityHex(col: 2, row: 0)],
        );
        final worker = GameUnit(
          id: 'worker_1',
          ownerPlayerId: 'player_1',
          type: GameUnitType.worker,
          name: GameUnitType.worker.defaultNameToken,
          col: 2,
          row: 0,
        );
        final game = GameRenderer(mapData: map, onCommand: (_) async {});
        addTearDown(game.disposeRenderer);

        game
          ..applyState(
            GameState(
              units: [worker],
              cities: const [city],
              research: ResearchState(
                players: {
                  'player_1': PlayerResearchState(
                    unlockedTechnologyIds: {TechnologyId.agriculture},
                  ),
                },
              ),
              interaction: GameInteractionState(
                selection: GameSelection.unit(worker),
              ),
            ),
          )
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();

        expect(game.tileMarkersForTesting(2, 0).workerBuildAvailable, isTrue);
        expect(game.tileMarkersForTesting(2, 0).workerBuildBlocked, isFalse);
        expect(
          game.tileMarkersForTesting(2, 0).workerImprovementCandidate,
          isTrue,
        );
      },
    );

    test(
      'tap movement animates and then allows the selected unit tile to cycle',
      () async {
        final map = _map(3, 3);
        final reducer = GameStateReducer(mapData: map);
        final commander = GameUnit.startingCommander(
          ownerPlayerId: 'player_1',
          col: 0,
          row: 0,
        );
        var state = GameState(units: [commander]);
        late final GameRenderer game;
        game = GameRenderer(
          mapData: map,
          onCommand: (command) async {
            final transition = reducer.reduce(state, command);
            state = transition.state;
            game.applyState(state);
            await game.handleEffects(transition.uiEffects.rendererEffects);
          },
        );
        addTearDown(game.disposeRenderer);

        game
          ..applyState(state)
          ..onGameResize(Vector2(800, 600));
        await game.onLoad();
        await Future<void>.delayed(Duration.zero);
        game.update(0);

        await game.handleTileTappedForTesting(_tile(map, 0, 0));
        expect(state.selection?.type, GameSelectionType.unit);
        expect(state.moveCommandActive, isTrue);

        await game.handleTileTappedForTesting(_tile(map, 1, 0));
        expect(state.movePreview?.targetCol, 1);
        expect(state.movePreview?.targetRow, 0);

        final moveFuture = game.handleTileTappedForTesting(_tile(map, 1, 0));
        await Future<void>.delayed(Duration.zero);
        game.update(0.32);
        await Future<void>.delayed(Duration.zero);
        expect(game.animatingUnitIdsListenable.value, contains(commander.id));

        game
          ..update(0.3)
          ..update(0.4);
        await moveFuture;
        expect(
          game.animatingUnitIdsListenable.value,
          isNot(contains(commander.id)),
        );
        expect(state.units.single.col, 1);
        expect(state.moveCommandActive, isTrue);

        await game.handleTileTappedForTesting(_tile(map, 1, 0));
        expect(state.selection?.type, GameSelectionType.tile);
        expect(state.moveCommandActive, isFalse);

        await game.handleTileTappedForTesting(_tile(map, 1, 0));
        expect(state.selection?.type, GameSelectionType.unit);
      },
    );
  });
}

CityManagementOverlayHexKind? _overlayKindFor(GameRenderer game, CityHex hex) {
  return _overlayFor(game, hex)?.kind;
}

CityManagementOverlayHex? _overlayFor(GameRenderer game, CityHex hex) {
  for (final overlayHex in game.cityManagementOverlayHexesForTesting) {
    if (overlayHex.hex == hex) return overlayHex;
  }
  return null;
}

Vector2 _visibleCenter(GameRenderer game) {
  final zoom = game.camera.viewfinder.zoom;
  return game.camera.viewfinder.position +
      game.camera.viewport.size / (2 * zoom);
}

FogOfWarState _fog({
  Set<HexCoordinate> discovered = const {},
  Set<HexCoordinate> visible = const {},
}) {
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: discovered,
        visibleHexes: visible,
      ),
    },
  );
}

void _expectVectorClose(
  Vector2 actual,
  Vector2 expected, {
  double tolerance = 0.0001,
}) {
  expect(actual.x, closeTo(expected.x, tolerance));
  expect(actual.y, closeTo(expected.y, tolerance));
}
