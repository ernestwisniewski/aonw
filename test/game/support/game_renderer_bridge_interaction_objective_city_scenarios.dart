part of '../game_renderer_keyboard_test.dart';

void _registerRendererInteractionObjectiveCityScenarios() {
  test('occupied hex tap cycles unit, hex, terrain popup, and unit', () async {
    final map = _mapWithObjective();
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
    final inspectedArtifacts = <WorldArtifact>[];
    final inspectedObjectives = <MapObjectiveProgress>[];
    final inspectedTiles = <WorldTile>[];
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
    var state = GameClientState(
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
        final transition = resolveGameIntent(reducer, state, command);
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

    expect(inspectedTiles.map((tile) => '${tile.col}:${tile.row}'), ['1:1']);
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
  });
  test('hex tap cycles artifact, objective, then hex popup', () async {
    final map = _mapWithObjective();
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
    final inspectedArtifacts = <WorldArtifact>[];
    final inspectedObjectives = <MapObjectiveProgress>[];
    final inspectedTiles = <WorldTile>[];
    final artifact = WorldArtifact.placed(
      type: WorldArtifactType.queensMirror,
      col: 1,
      row: 1,
    );
    var state = GameClientState(
      activePlayerId: 'player_1',
      artifacts: [artifact],
      fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
    );
    late final GameRenderer game;
    game = GameRenderer(
      mapData: map,
      onCommand: (command) async {
        commands.add(command);
        final transition = resolveGameIntent(reducer, state, command);
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
    final commands = <GameIntent>[];
    final inspectedObjectives = <MapObjectiveProgress>[];
    const city = GameCity(
      id: 'city_1',
      ownerPlayerId: 'player_1',
      name: 'City',
      center: CityHex(col: 1, row: 1),
    );
    var state = GameClientState(activePlayerId: 'player_1', cities: [city]);
    late final GameRenderer game;
    game = GameRenderer(
      mapData: map,
      onCommand: (command) async {
        commands.add(command);
        final transition = resolveGameIntent(reducer, state, command);
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
      final commands = <GameIntent>[];
      final inspectedTiles = <WorldTile>[];
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
      var state = GameClientState(
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
          final transition = resolveGameIntent(reducer, state, command);
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

      expect(inspectedTiles.map((tile) => '${tile.col}:${tile.row}'), ['1:1']);
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
  test('tile tap during city expansion stays a renderer intent', () async {
    final map = _map(3, 3);
    final commands = <GameIntent>[];
    final game =
        GameRenderer(
          mapData: map,
          onCommand: (command) async {
            commands.add(command);
          },
        )..applyState(
          GameClientState(
            interaction: const InteractionState(
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

    expect(commands, [const TileTappedCommand(1, 2)]);
  });
}
