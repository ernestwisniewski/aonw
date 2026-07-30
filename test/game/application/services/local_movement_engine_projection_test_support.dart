part of 'local_movement_engine_projection_test.dart';

LocalCommandResolver _resolver(MapReadView mapView) {
  return LocalCommandResolver(reducer: GameStateReducer(mapData: mapView));
}

SaveSnapshot _snapshot(GameState state) {
  return SaveSnapshot.fromGameState(save: _save(), state: state);
}

GameSave _save() => GameSave(
  id: 'save_1',
  name: 'Movement engine',
  mapName: 'verdantia',
  turn: 7,
  playerStates: const {_playerId: PlayerTurnState.active},
  savedAt: DateTime.utc(2026, 7, 29),
  camera: const CameraState(x: 4, y: 5, zoom: 1.25),
  players: const [
    Player(
      id: _playerId,
      name: 'One',
      colorValue: 0xFF010203,
      country: PlayerCountry.poland,
    ),
  ],
);

GameUnit _unit({
  required String id,
  GameUnitType type = GameUnitType.warrior,
  int col = 0,
  int row = 0,
  int movementPoints = 3,
  UnitPosture posture = UnitPosture.active,
  List<ArmyTroop> army = const [],
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: _playerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: row,
    movementPoints: movementPoints,
    posture: posture,
    army: army,
  );
}

GameCity _city(String id, int col) {
  return GameCity(
    id: id,
    ownerPlayerId: _playerId,
    name: id,
    center: CityHex(col: col, row: 0),
    controlledHexes: [CityHex(col: col, row: 0)],
  );
}

FogOfWarState _fog({required int visibleCols}) {
  final visible = {
    for (var col = 0; col < visibleCols; col++) HexCoordinate(col: col, row: 0),
  };
  return FogOfWarState(
    players: {
      _playerId: PlayerFogOfWar(
        playerId: _playerId,
        discoveredHexes: visible,
        visibleHexes: visible,
      ),
    },
  );
}

FogOfWarState _fogGrid({required int cols, required int rows}) {
  final visible = {
    for (var row = 0; row < rows; row++)
      for (var col = 0; col < cols; col++) HexCoordinate(col: col, row: row),
  };
  return FogOfWarState(
    players: {
      _playerId: PlayerFogOfWar(
        playerId: _playerId,
        discoveredHexes: visible,
        visibleHexes: visible,
      ),
    },
  );
}

MapReadView _map({
  required int cols,
  int rows = 1,
  Map<int, List<TerrainType>> terrainOverrides = const {},
}) {
  return WorldMapReadView(
    WorldMap(
      cols: cols,
      rows: rows,
      tiles: [
        for (var row = 0; row < rows; row++)
          for (var col = 0; col < cols; col++)
            WorldTile(
              coordinate: HexCoord(col: col, row: row),
              terrains: terrainOverrides[col] ?? const [TerrainType.grassland],
              resources: const [],
              height: 0,
            ),
      ],
    ),
  );
}

String _unreviewedMovementEnvelopeBytes(Map<String, dynamic> source) {
  final copy = jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  (copy['save'] as Map<String, dynamic>).remove('savedAt');
  copy
    ..remove('units')
    ..remove('fogOfWar');
  (copy['runtimeState'] as Map<String, dynamic>)
    ..remove('diplomacy')
    ..remove('cityFoundingDraft')
    ..remove('pendingAction');
  return jsonEncode(copy);
}
