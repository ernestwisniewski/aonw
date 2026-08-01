import 'package:aonw_core/application.dart';
import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

const _playerId = 'player_1';
const _otherPlayerId = 'player_2';

void main() {
  group('movement engine parity truth table', () {
    test('valid movement applies one ordered move event', () {
      final snapshot = _snapshot(
        units: [_unit(id: 'mover', movementPoints: 4)],
      );

      final result = _apply(
        snapshot,
        const MoveUnitCommand('mover', 2, 0),
        mapView: _map(cols: 4),
      );

      final accepted = _expectAccepted(result);
      expect(
        (
          accepted.snapshot.domain.units.single.col,
          accepted.snapshot.domain.units.single.row,
        ),
        (2, 0),
      );
      expect(accepted.events, [
        isA<UnitMovedEvent>()
            .having((event) => event.unitId, 'unitId', 'mover')
            .having((event) => event.fromCol, 'fromCol', 0)
            .having((event) => event.toCol, 'toCol', 2),
      ]);
      expect(accepted.movementDelta.beforeUnits.single.col, 0);
      expect(accepted.movementDelta.afterUnits.single.col, 2);
      expect(accepted.movementDelta.executions, hasLength(1));
      expect(
        accepted.movementDelta.executions.single.steps.map((step) => step.col),
        [1, 2],
      );
      expect(
        () => accepted.movementDelta.executions.clear(),
        throwsUnsupportedError,
      );
    });

    test('invalid path rejects with input snapshot identity', () {
      final snapshot = _snapshot(
        units: [_unit(id: 'mover', movementPoints: 4)],
      );

      final result = _apply(
        snapshot,
        const MoveUnitCommand('mover', 1, 0),
        mapView: _map(cols: 2, blockedCols: const {1}),
      );

      _expectRejected(result, snapshot, 'move_path_not_found');
    });

    test('stale destination rejects with input snapshot identity', () {
      final snapshot = _snapshot(units: [_unit(id: 'mover')]);

      final result = _apply(
        snapshot,
        const MoveUnitCommand('mover', 0, 0),
        mapView: _map(cols: 2),
      );

      _expectRejected(result, snapshot, 'move_target_is_current_tile');
    });

    test('queued movement applies the reachable prefix', () {
      final snapshot = _snapshot(
        units: [_unit(id: 'mover', movementPoints: 1)],
      );

      final result = _apply(
        snapshot,
        const MoveUnitCommand('mover', 3, 0),
        mapView: _map(cols: 4),
      );

      final accepted = _expectAccepted(result);
      final moved = accepted.snapshot.domain.units.single;
      expect((moved.col, moved.row), (1, 0));
      expect(moved.queuedPath?.targetCol, 3);
      expect(accepted.events, hasLength(1));
      expect(accepted.movementDelta.executions.single.destination.col, 1);
    });

    test('cancel without action state is an accepted identity no-op', () {
      final snapshot = _snapshot(units: [_unit(id: 'mover')]);

      final result = _apply(
        snapshot,
        const CancelUnitActionCommand('mover'),
        mapView: _map(cols: 2),
      );

      final accepted = _expectAccepted(result);
      expect(accepted.snapshot, same(snapshot));
      expect(accepted.events, isEmpty);
      expect(accepted.movementDelta.executions, isEmpty);
      expect(
        accepted.movementDelta.beforeUnits,
        same(accepted.movementDelta.afterUnits),
      );
    });

    test('auto explore updates scout posture through the same engine', () {
      final snapshot = _snapshot(
        units: [
          _unit(id: 'scout', type: GameUnitType.scout, movementPoints: 3),
        ],
        fogOfWar: _fog(visibleCols: 1),
      );

      final result = _apply(
        snapshot,
        const AutoExploreUnitCommand('scout'),
        mapView: _map(cols: 4),
      );

      final accepted = _expectAccepted(result);
      final scout = accepted.snapshot.domain.units.single;
      expect(scout.posture, UnitPosture.autoExploring);
      expect(scourCoordinate(scout), isNot((0, 0)));
      expect(accepted.events, hasLength(1));
      expect(accepted.movementDelta.executions, hasLength(1));
    });

    test('merchant assignment uses canonical cities and map view', () {
      final snapshot = _snapshot(
        units: [
          _unit(id: 'merchant', type: GameUnitType.merchant, movementPoints: 3),
        ],
        cities: [_city('origin', 0), _city('destination', 3)],
      );

      final result = _apply(
        snapshot,
        const AssignMerchantTradeRouteCommand('merchant', 'destination'),
        mapView: _map(cols: 4),
      );

      final accepted = _expectAccepted(result);
      expect(
        accepted
            .snapshot
            .domain
            .units
            .single
            .merchantTradeRoute
            ?.destinationCityId,
        'destination',
      );
      expect(accepted.events, isEmpty);
    });

    test('merchant move queues a path to the destination city', () {
      final snapshot = _snapshot(
        units: [
          _unit(id: 'merchant', type: GameUnitType.merchant, movementPoints: 3),
        ],
        cities: [_city('origin', 0), _city('destination', 3)],
      );

      final result = _apply(
        snapshot,
        const MoveMerchantToCityCommand('merchant', 'destination'),
        mapView: _map(cols: 4),
      );

      final accepted = _expectAccepted(result);
      expect(accepted.snapshot.domain.units.single.queuedPath?.targetCol, 3);
      expect(accepted.events, isEmpty);
    });

    test('cancel clears unit action state and owned interaction', () {
      final snapshot = _snapshot(
        units: [
          _unit(id: 'mover', posture: UnitPosture.fortified, movementPoints: 0),
        ],
        interaction: DomainActionState(
          pendingAction: const PendingUnitTurnSkip(
            ownerPlayerId: _playerId,
            unitId: 'mover',
            restoreMovementPoints: 3,
          ),
        ),
      );

      final result = _apply(
        snapshot,
        const CancelUnitActionCommand('mover'),
        mapView: _map(cols: 2),
      );

      final accepted = _expectAccepted(result);
      expect(accepted.snapshot.domain.units.single.posture, UnitPosture.active);
      expect(accepted.snapshot.domain.units.single.movementPoints, 3);
      expect(accepted.snapshot.domain.actions, DomainActionState.empty);
    });

    test(
      'detachment updates only canonical movement-related domain slices',
      () {
        final snapshot = _snapshot(
          units: [
            _unit(
              id: 'commander',
              type: GameUnitType.commander,
              col: 1,
              row: 1,
              army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
            ),
          ],
          fogOfWar: _fogGrid(cols: 3, rows: 3),
        );

        final result = _apply(
          snapshot,
          const DetachTroopCommand('commander', TroopType.warrior),
          mapView: _map(cols: 3, rows: 3),
        );

        final accepted = _expectAccepted(result);
        expect(accepted.snapshot.domain.units, hasLength(2));
        expect(
          accepted.snapshot.domain.units.map((unit) => unit.id),
          contains('commander_warrior_1'),
        );
        expect(
          accepted.snapshot.domain.turnStatesByPlayerId,
          same(snapshot.domain.turnStatesByPlayerId),
        );
        expect(accepted.snapshot.metadata, same(snapshot.metadata));
        expect(accepted.events, isEmpty);
      },
    );
  });
}

GameEngineResult _apply(
  CanonicalGameSnapshot snapshot,
  DomainCommand command, {
  required MapReadView mapView,
}) {
  return const GameEngine().apply(
    snapshot: snapshot,
    command: command,
    context: GameEngineContext(
      actorPlayerId: _playerId,
      mapView: mapView,
      ruleset: GameRuleset.defaults,
      commandTick: 17,
    ),
  );
}

GameEngineAccepted _expectAccepted(GameEngineResult result) {
  expect(result, isA<GameEngineAccepted>());
  return result as GameEngineAccepted;
}

void _expectRejected(
  GameEngineResult result,
  CanonicalGameSnapshot snapshot,
  String reason,
) {
  expect(result, isA<GameEngineRejected>());
  final rejected = result as GameEngineRejected;
  expect(rejected.snapshot, same(snapshot));
  expect(rejected.reason, reason);
  expect(rejected.events, isEmpty);
}

CanonicalGameSnapshot _snapshot({
  List<GameUnit> units = const [],
  List<GameCity> cities = const [],
  FogOfWarState fogOfWar = FogOfWarState.empty,
  DomainActionState interaction = DomainActionState.empty,
}) {
  return CanonicalGameSnapshot.snapshot(
    domain:
        ((DomainState.snapshot(
              turn: 7,
              matchRules: MatchRules.standard,
              participants: const [
                Player(
                  id: _playerId,
                  name: 'One',
                  colorValue: 1,
                  country: PlayerCountry.poland,
                ),
                Player(
                  id: _otherPlayerId,
                  name: 'Two',
                  colorValue: 2,
                  country: PlayerCountry.france,
                ),
              ],
              playerGold: const {_playerId: 17, _otherPlayerId: 11},
              units: units,
              cities: cities,
              fogOfWar: fogOfWar,
            )).copyWith(
              gameMode: GameMode.multiplayer,
              turnStatesByPlayerId: const {
                _playerId: PlayerTurnState.active,
                _otherPlayerId: PlayerTurnState.active,
              },
            ))
            .copyWith(actions: interaction),

    metadata: GameSnapshotMetadata(
      id: 'save_1',
      schemaVersion: 3,
      name: 'Movement fixture',
      world: const WorldReference(name: 'verdantia', source: MapSource.asset),
      savedAtUtc: DateTime.utc(2026, 7, 29),
      camera: GameSnapshotCamera.zero,
    ),

    eventLogOffset: 41,
  );
}

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
  Set<int> blockedCols = const {},
}) {
  return WorldMap(
    cols: cols,
    rows: rows,
    tiles: [
      for (var row = 0; row < rows; row++)
        for (var col = 0; col < cols; col++)
          WorldTile.at(
            coordinate: HexCoord(col: col, row: row),
            terrains: [
              if (blockedCols.contains(col))
                TerrainType.ocean
              else
                TerrainType.grassland,
            ],
            resources: const [],
            height: 0,
          ),
    ],
  );
}

(int, int) scourCoordinate(GameUnit unit) => (unit.col, unit.row);
