part of 'merchant_routing_command_resolver_parity_test.dart';

const _routingPlayerId = 'player_1';
const _routingOtherPlayerId = 'player_2';

typedef _RoutingStates = ({PersistentGameState persistent, DomainState domain});

_RoutingStates _routingStates({required GameUnit merchant}) {
  final units = [merchant, _routingGuard()];
  final cities = _routingCities();
  return (
    persistent: PersistentGameState.snapshot(
      playerColors: const {_routingPlayerId: 1, _routingOtherPlayerId: 2},
      playerCountries: const {
        _routingPlayerId: PlayerCountry.poland,
        _routingOtherPlayerId: PlayerCountry.france,
      },
      playerGold: const {_routingPlayerId: 17, _routingOtherPlayerId: 11},
      units: units,
      cities: cities,
      runtimeState: GameRuntimeState.snapshot(
        submittedPlayerIds: const {_routingOtherPlayerId},
        timeoutStreaksByPlayerId: const {_routingOtherPlayerId: 2},
        turnStartedAt: DateTime.utc(2026, 7, 18),
      ),
    ),
    domain: DomainState.snapshot(
      turn: 7,
      matchRules: MatchRules.standard,
      participants: const [
        Player(
          id: _routingPlayerId,
          name: 'One',
          colorValue: 1,
          country: PlayerCountry.poland,
        ),
        Player(
          id: _routingOtherPlayerId,
          name: 'Two',
          colorValue: 2,
          country: PlayerCountry.france,
        ),
      ],
      playerGold: const {_routingPlayerId: 17, _routingOtherPlayerId: 11},
      units: units,
      cities: cities,
    ),
  );
}

void _expectRoutingAcceptedParity(
  _RoutingStates before,
  PersistentMerchantTradeRouteResult persistent,
  DomainMerchantRoutingCommandResult domain,
) {
  expect(persistent.accepted, isTrue);
  expect(domain.accepted, isTrue);
  expect(persistent.reason, isNull);
  expect(domain.reason, isNull);
  expect(persistent.state.units, domain.state.units);
  expect(
    persistent.state,
    before.persistent.copyWith(units: persistent.state.units),
  );
  expect(domain.state, before.domain.copyWith(units: domain.state.units));
  expect(
    identical(persistent.state.runtimeState, before.persistent.runtimeState),
    isTrue,
  );
  expect(identical(persistent.state.cities, before.persistent.cities), isTrue);
  expect(identical(domain.state.cities, before.domain.cities), isTrue);
  expect(identical(domain.state.playerGold, before.domain.playerGold), isTrue);
}

GameUnit _routingMerchant({
  int col = 0,
  UnitPosture posture = UnitPosture.active,
  QueuedMovePath? queuedPath,
}) {
  return GameUnit(
    id: 'merchant',
    ownerPlayerId: _routingPlayerId,
    type: GameUnitType.merchant,
    name: GameUnitType.merchant.defaultNameToken,
    col: col,
    row: 0,
    posture: posture,
    queuedPath: queuedPath,
  );
}

GameUnit _routingGuard() {
  return GameUnit(
    id: 'guard',
    ownerPlayerId: _routingPlayerId,
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: 3,
    row: 0,
  );
}

QueuedMovePath _routingQueuedPath() {
  return QueuedMovePath(
    targetCol: 2,
    targetRow: 0,
    steps: const [
      UnitMovementStep(col: 0, row: 0, enterCost: 0, cumulativeCost: 0),
      UnitMovementStep(col: 1, row: 0, enterCost: 1, cumulativeCost: 1),
      UnitMovementStep(col: 2, row: 0, enterCost: 1, cumulativeCost: 2),
    ],
  );
}

List<GameCity> _routingCities() => [
  _routingCity('origin', 0),
  _routingCity('destination', 3),
];

GameCity _routingCity(String id, int col) {
  return GameCity(
    id: id,
    ownerPlayerId: _routingPlayerId,
    name: id,
    center: CityHex(col: col, row: 0),
    controlledHexes: [CityHex(col: col, row: 0)],
  );
}

MapTraversalView _routingMap() {
  return WorldMapReadView(
    WorldMap(
      cols: 4,
      rows: 1,
      tiles: [
        for (var col = 0; col < 4; col++)
          WorldTile(
            coordinate: HexCoord(col: col, row: 0),
            terrains: const [TerrainType.plains],
            resources: const [],
            height: 0,
          ),
      ],
    ),
  );
}
