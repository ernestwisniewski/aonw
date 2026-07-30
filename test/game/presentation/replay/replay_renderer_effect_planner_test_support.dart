part of 'replay_renderer_effect_planner_test.dart';

MovementCommandExecution _movementExecution({
  required String unitId,
  required int fromCol,
  required int fromRow,
  required List<UnitMovementStep> steps,
}) {
  return MovementCommandExecution(
    unitId: unitId,
    fromCol: fromCol,
    fromRow: fromRow,
    steps: steps,
  );
}

GameUnit _scout({
  String id = 'scout_1',
  String ownerPlayerId = 'player_1',
  required int col,
  required int row,
}) {
  return GameUnit(
    id: id,
    ownerPlayerId: ownerPlayerId,
    type: GameUnitType.scout,
    name: GameUnitType.scout.defaultNameToken,
    col: col,
    row: row,
    posture: UnitPosture.autoExploring,
  );
}

GameUnit _merchantWithTradeRoute({required int col, required int row}) {
  return GameUnit(
    id: 'merchant_1',
    ownerPlayerId: 'player_1',
    type: GameUnitType.merchant,
    name: GameUnitType.merchant.defaultNameToken,
    col: col,
    row: row,
  ).copyWithMerchantTradeRoute(
    MerchantTradeRoute(
      originCityId: 'city_origin',
      destinationCityId: 'city_target',
      steps: const [
        UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
        UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
        UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
        UnitMovementStep(col: 3, row: 0, enterCost: 1, cumulativeCost: 3),
      ],
    ),
  );
}

FogOfWarState _fogForPlayer(String playerId, Set<HexCoordinate> visibleHexes) {
  return FogOfWarState(
    players: {
      playerId: PlayerFogOfWar(playerId: playerId, visibleHexes: visibleHexes),
    },
  );
}
