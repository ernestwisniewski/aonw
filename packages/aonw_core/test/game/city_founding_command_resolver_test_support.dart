part of 'city_founding_command_resolver_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';
const _founderId = 'settler_1';
const _controlledHexes = [CityHex(col: 2, row: 1), CityHex(col: 1, row: 2)];

CityFoundingCommandResult _resolve({
  required List<GameUnit> units,
  List<GameCity> cities = const [],
  CityFoundingDraft? cityFoundingDraft,
  List<CityHex> controlledHexes = _controlledHexes,
  String actorPlayerId = _playerId,
  MapTileLookup? mapTiles,
}) {
  return CityFoundingCommandResolver.foundCity(
    units: units,
    cities: cities,
    cityFoundingDraft: cityFoundingDraft,
    command: FoundCityCommand(_founderId, controlledHexes: controlledHexes),
    actorPlayerId: actorPlayerId,
    mapTiles: mapTiles ?? _map(),
  );
}

void _expectRejected({
  required List<GameUnit> units,
  required String reason,
  List<GameCity> cities = const [],
  CityFoundingDraft? cityFoundingDraft,
  List<CityHex> controlledHexes = _controlledHexes,
  String actorPlayerId = _playerId,
  MapTileLookup? mapTiles,
}) {
  final draft = cityFoundingDraft ?? _draft('draft_sentinel');
  final result = _resolve(
    units: units,
    cities: cities,
    cityFoundingDraft: draft,
    controlledHexes: controlledHexes,
    actorPlayerId: actorPlayerId,
    mapTiles: mapTiles,
  );

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.units, units), isTrue);
  expect(identical(result.cityFoundingDraft, draft), isTrue);
}

GameUnit _founder({
  String ownerPlayerId = _playerId,
  GameUnitType type = GameUnitType.settler,
  int movementPoints = 2,
  QueuedMovePath? queuedPath,
  bool busy = false,
}) {
  return GameUnit(
    id: _founderId,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.name,
    col: 1,
    row: 1,
    movementPoints: movementPoints,
    queuedPath: queuedPath,
    cityFoundingJob: busy
        ? CityFoundingJob(
            center: const CityHex(col: 4, row: 4),
            controlledHexes: const [],
            remainingTurns: 2,
            totalTurns: 2,
          )
        : null,
  );
}

GameUnit _sentinelUnit(String id) {
  return GameUnit(
    id: id,
    ownerPlayerId: _otherPlayerId,
    type: GameUnitType.scout,
    name: id,
    col: 7,
    row: 7,
    movementPoints: 1,
  );
}

GameCity _city({
  String id = 'city_1',
  required CityHex center,
  List<CityHex> controlledHexes = const [],
}) {
  return GameCity.snapshot(
    id: id,
    ownerPlayerId: _otherPlayerId,
    name: id,
    center: center,
    controlledHexes: controlledHexes,
  );
}

CityFoundingDraft _draft(
  String unitId, {
  List<CityHex> controlledHexes = const [],
}) {
  return CityFoundingDraft(
    unitId: unitId,
    ownerPlayerId: _playerId,
    center: const CityHex(col: 1, row: 1),
    controlledHexes: controlledHexes,
  );
}

QueuedMovePath _queuedPath() {
  return QueuedMovePath(
    targetCol: 2,
    targetRow: 1,
    steps: const [
      UnitMovementStep(col: 2, row: 1, enterCost: 1, cumulativeCost: 1),
    ],
  );
}

MapTileLookup _map({
  CityHex? missing,
  TerrainType centerTerrain = TerrainType.grassland,
}) {
  return WorldMap(
    cols: 8,
    rows: 8,
    tiles: [
      for (var row = 0; row < 8; row++)
        for (var col = 0; col < 8; col++)
          if (missing == null || !missing.occupies(col, row))
            WorldTile.at(
              coordinate: HexCoord(col: col, row: row),
              terrains: [
                if (col == 1 && row == 1)
                  centerTerrain
                else
                  TerrainType.grassland,
              ],
              resources: const [],
              height: 0,
            ),
    ],
  );
}
