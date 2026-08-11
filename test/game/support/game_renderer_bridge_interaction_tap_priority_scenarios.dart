part of '../game_renderer_keyboard_test.dart';

void _registerRendererInteractionTapPriorityScenarios() {
  test('applyState is ignored after renderer disposal', () {
    final game = GameRenderer(mapData: kbMinimalMap(), onCommand: (_) async {});

    expect(
      () => game
        ..disposeRenderer()
        ..applyState(GameClientState(activePlayerId: 'player_1')),
      returnsNormally,
    );
  });
  test('tile tap dispatches a TileTappedCommand in renderer mode', () async {
    final map = kbMap(3, 3);
    final commands = <GameIntent>[];
    await GameRenderer(
      mapData: map,
      onCommand: (command) async {
        commands.add(command);
      },
    ).handleTileTappedForTesting(kbTile(map, 1, 2));
    await Future<void>.delayed(Duration.zero);

    expect(commands, [const TileTappedCommand(1, 2)]);
  });
  test('artifact marker tap cycles artifact, hex, artifact', () async {
    final map = kbMap(3, 3);
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
    final inspectedArtifacts = <WorldArtifact>[];
    final artifact = WorldArtifact.placed(
      type: WorldArtifactType.queensMirror,
      col: 1,
      row: 1,
    );
    var state = GameClientState(artifacts: [artifact]);
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
    final map = kbMap(3, 3);
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
    final inspectedArtifacts = <WorldArtifact>[];
    final artifact = WorldArtifact.placed(
      type: WorldArtifactType.queensMirror,
      col: 1,
      row: 1,
    );
    var state = GameClientState(
      activePlayerId: 'player_1',
      artifacts: [artifact],
    );
    state = state.copyWith(
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
    );
    addTearDown(game.disposeRenderer);
    game.applyState(state);

    await game.handleTileTappedForTesting(kbTile(map, 1, 1));
    await Future<void>.delayed(Duration.zero);

    expect(commands, [const TileTappedCommand(1, 1)]);
    expect(state.selection?.type, GameSelectionType.tile);
    expect(state.selection?.tile?.col, 1);
    expect(state.selection?.tile?.row, 1);
    expect(inspectedArtifacts, isEmpty);

    await game.handleTileTappedForTesting(kbTile(map, 1, 1));

    expect(commands, [const TileTappedCommand(1, 1)]);
    expect(inspectedArtifacts, [artifact]);
  });
  test('second tap on selected hex opens hex description popup', () async {
    final map = kbMap(3, 3);
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
    final inspectedTiles = <WorldTile>[];
    var state = GameClientState(
      activePlayerId: 'player_1',
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

    await game.handleTileTappedForTesting(kbTile(map, 1, 1));
    await Future<void>.delayed(Duration.zero);

    expect(commands, [const TileTappedCommand(1, 1)]);
    expect(state.selection?.type, GameSelectionType.tile);
    expect(state.selection?.tile?.col, 1);
    expect(state.selection?.tile?.row, 1);
    expect(inspectedTiles, isEmpty);

    await game.handleTileTappedForTesting(kbTile(map, 1, 1));

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

    final map = kbMap(3, 3);
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
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
    var state = GameClientState(
      activePlayerId: 'player_1',
      units: [unit],
      artifacts: [artifact],
      fogOfWar: _fog(visible: {const HexCoordinate(col: 1, row: 1)}),
      interaction: InteractionState(
        selection: GameSelection.unit(unit, tile: kbTile(map, 1, 1)),
      ),
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
    final map = kbObjectiveMap();
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
    final inspectedObjectives = <MapObjectiveProgress>[];
    final progress = MapObjectiveRules.snapshot(
      objectives: map.objectives,
      cities: const [],
      units: const [],
      holdStatesByObjectiveId: const {},
    ).entryFor('pass_1')!;
    var state = GameClientState(activePlayerId: 'player_1');
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
    final map = kbObjectiveMap();
    final reducer = GameStateReducer(mapData: map);
    final commands = <GameIntent>[];
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
    var state = GameClientState(
      activePlayerId: 'player_1',
      units: [unit],
      interaction: InteractionState(
        selection: GameSelection.unit(unit, tile: kbTile(map, 1, 1)),
      ),
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
}
