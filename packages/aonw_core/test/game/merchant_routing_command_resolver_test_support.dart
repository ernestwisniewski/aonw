part of 'merchant_routing_command_resolver_test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void _expectAssignRejected({
  required List<GameUnit> units,
  required List<GameCity> cities,
  required String destinationCityId,
  required String reason,
  String actorPlayerId = _playerId,
  MapTraversalView? mapData,
}) {
  final result = MerchantRoutingCommandResolver.assignRoute(
    units: units,
    cities: cities,
    command: AssignMerchantTradeRouteCommand('merchant', destinationCityId),
    actorPlayerId: actorPlayerId,
    mapData: mapData ?? _lineMap(),
  );

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.units, units), isTrue);
}

void _expectMoveRejected({
  required List<GameUnit> units,
  required List<GameCity> cities,
  required String destinationCityId,
  required String reason,
  String actorPlayerId = _playerId,
  MapTraversalView? mapData,
}) {
  final result = MerchantRoutingCommandResolver.moveToCity(
    units: units,
    cities: cities,
    command: MoveMerchantToCityCommand('merchant', destinationCityId),
    actorPlayerId: actorPlayerId,
    mapData: mapData ?? _lineMap(),
  );

  expect(result.accepted, isFalse);
  expect(result.reason, reason);
  expect(identical(result.units, units), isTrue);
}

GameUnit _merchant({
  int col = 0,
  UnitPosture posture = UnitPosture.active,
  MerchantTradeRoute? merchantTradeRoute,
}) {
  return _unit(
    col: col,
    type: GameUnitType.merchant,
    posture: posture,
    merchantTradeRoute: merchantTradeRoute,
  );
}

GameUnit _unit({
  String id = 'merchant',
  String ownerPlayerId = _playerId,
  GameUnitType type = GameUnitType.warrior,
  int col = 0,
  UnitPosture posture = UnitPosture.active,
  MerchantTradeRoute? merchantTradeRoute,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: type,
    name: type.defaultNameToken,
    col: col,
    row: 0,
    posture: posture,
    merchantTradeRoute: merchantTradeRoute,
  );
}

List<GameCity> _cities() => [_city('origin', 0), _city('destination', 3)];

GameCity _city(String id, int col, {String owner = _playerId}) {
  return GameCity(
    id: id,
    ownerPlayerId: owner,
    name: id,
    center: CityHex(col: col, row: 0),
    controlledHexes: [CityHex(col: col, row: 0)],
  );
}

MerchantTradeRoute _route() {
  return MerchantTradeRoute(
    originCityId: 'origin',
    destinationCityId: 'destination',
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
      UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
    ],
  );
}

MapTraversalView _lineMap({int? blockedCol}) {
  return WorldMap(
    cols: 4,
    rows: 1,
    tiles: [
      for (var col = 0; col < 4; col++)
        WorldTile.at(
          coordinate: HexCoord(col: col, row: 0),
          terrains: [
            if (col == blockedCol) TerrainType.ocean else TerrainType.plains,
          ],
          resources: const [],
          height: 0,
        ),
    ],
  );
}
