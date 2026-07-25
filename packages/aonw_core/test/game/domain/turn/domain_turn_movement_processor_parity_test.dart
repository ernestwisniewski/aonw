import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:test/test.dart';

void main() {
  group('DomainTurnMovementProcessor parity', () {
    test('matches a mixed new-turn movement workload', () {
      final input = _complexInput();
      final result = _resolveBoth(input: input, playerIds: const ['p1']);

      expect(result.domain.changed, isTrue);
      expect(_unitIds(result.domain.state.units), _unitIds(input.units));
      expect(result.domain.state.units, result.persistent.state.units);
      expect(result.domain.state.fogOfWar, result.persistent.state.fogOfWar);

      final units = _unitsById(result.domain.state.units);
      expect(units['merchant_p1']?.col, 3);
      expect(units['queued_p1']?.col, 5);
      expect(units['fortified_p1']?.hitPoints, 8);
      expect(units['fortified_p1']?.movementPoints, 0);
      expect(units['scout_a_p1']?.occupies(1, 6), isFalse);
      expect(units['scout_b_p1']?.occupies(1, 8), isFalse);
      expect(units['foreign_p2'], input.units.first);
      expect(
        result.domain.state.fogOfWar.fogForPlayer('p1').discoveredHexes.length,
        greaterThan(input.fogOfWar.fogForPlayer('p1').discoveredHexes.length),
      );
    });

    test('preserves state identity for empty player ids', () {
      final input = _complexInput();
      final result = _resolveBoth(input: input, playerIds: const []);

      expect(result.domain.changed, isFalse);
      expect(identical(result.domain.state, result.domainInput), isTrue);
      expect(identical(result.persistent.state, input), isTrue);
    });

    test('preserves state identity when no unit needs movement work', () {
      final input = _idleInput();
      final result = _resolveBoth(input: input, playerIds: const ['p1']);

      expect(result.domain.changed, isFalse);
      expect(identical(result.domain.state, result.domainInput), isTrue);
      expect(identical(result.persistent.state, input), isTrue);
    });

    test('projects continuation interaction cleanup through both adapters', () {
      final scout = GameUnit(
        id: 'scout_p1',
        ownerPlayerId: 'p1',
        type: GameUnitType.scout,
        name: GameUnitType.scout.defaultNameToken,
        col: 0,
        row: 0,
        posture: UnitPosture.autoExploring,
      );
      final draft = CityFoundingDraft(
        unitId: 'other_unit',
        ownerPlayerId: 'p1',
        center: const CityHex(col: 0, row: 0),
      );
      const pending = PendingUnitTurnSkip(
        ownerPlayerId: 'p1',
        unitId: 'scout_p1',
        restoreMovementPoints: 2,
      );
      final input = PersistentGameState.snapshot(
        playerColors: const {'p1': 0xFF000001, 'p2': 0xFF000002},
        units: [scout],
        fogOfWar: FogOfWarState(
          players: {
            'p1': PlayerFogOfWar(
              playerId: 'p1',
              discoveredHexes: {const HexCoordinate(col: 0, row: 0)},
              visibleHexes: {const HexCoordinate(col: 0, row: 0)},
            ),
          },
        ),
        runtimeState: GameRuntimeState.snapshot(
          cityFoundingDraft: draft,
          pendingAction: pending,
        ),
      );
      final result = _resolveBoth(input: input, playerIds: const ['p1']);

      expect(result.domain.interaction.pendingAction, isNull);
      expect(result.domain.interaction.cityFoundingDraft, draft);
      expect(result.persistent.state.runtimeState.pendingAction, isNull);
      expect(result.persistent.state.runtimeState.cityFoundingDraft, draft);
      expect(
        result.domain.events.map((event) => event.runtimeType),
        result.persistent.events.map((event) => event.runtimeType),
      );
      expect(result.domain.executions, hasLength(1));
      expect(result.persistent.executions, hasLength(1));
    });
  });
}

_ParityResult _resolveBoth({
  required PersistentGameState input,
  required Iterable<String> playerIds,
}) {
  final domainSnapshot = _adapter.toCanonical(save: _save, state: input);
  final domainInput = domainSnapshot.domain;
  final persistent = PersistentTurnMovementProcessor.resetForPlayers(
    state: input,
    playerIds: playerIds,
    mapData: _mapView,
  );
  final domain = DomainTurnMovementProcessor.resetForPlayers(
    state: domainInput,
    interaction: domainSnapshot.interaction,
    playerIds: playerIds,
    mapData: _mapView,
  );
  final persistentSnapshot = _adapter.toCanonical(
    save: _save,
    state: persistent.state,
  );
  final persistentProjection = persistentSnapshot.domain;

  expect(domain.changed, persistent.changed);
  expect(domain.state, persistentProjection);
  expect(domain.state.units, persistent.state.units);
  expect(domain.state.fogOfWar, persistent.state.fogOfWar);
  expect(domain.interaction, persistentSnapshot.interaction);

  return _ParityResult(
    domainInput: domainInput,
    domain: domain,
    persistent: persistent,
  );
}

PersistentGameState _complexInput() {
  final foreign = GameUnit(
    id: 'foreign_p2',
    ownerPlayerId: 'p2',
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: 11,
    row: 9,
    movementPoints: 0,
  );
  final merchant = GameUnit(
    id: 'merchant_p1',
    ownerPlayerId: 'p1',
    type: GameUnitType.merchant,
    name: GameUnitType.merchant.defaultNameToken,
    col: 0,
    row: 0,
    movementPoints: 0,
    merchantTradeRoute: MerchantTradeRoute(
      originCityId: 'origin_p1',
      destinationCityId: 'destination_p1',
      steps: _lineSteps(row: 0, throughCol: 4),
    ),
  );
  final queued = GameUnit(
    id: 'queued_p1',
    ownerPlayerId: 'p1',
    type: GameUnitType.commander,
    name: GameUnitType.commander.defaultNameToken,
    col: 0,
    row: 2,
    movementPoints: 0,
    queuedPath: QueuedMovePath(
      targetCol: 8,
      targetRow: 2,
      steps: _lineSteps(row: 2, throughCol: 8),
    ),
  );
  final fortified = GameUnit(
    id: 'fortified_p1',
    ownerPlayerId: 'p1',
    type: GameUnitType.warrior,
    name: GameUnitType.warrior.defaultNameToken,
    col: 0,
    row: 4,
    movementPoints: 0,
    hitPoints: 7,
    posture: UnitPosture.fortified,
  );

  return PersistentGameState.snapshot(
    playerColors: const {'p1': 0xFF000001, 'p2': 0xFF000002},
    units: [
      foreign,
      merchant,
      queued,
      fortified,
      _autoScout(id: 'scout_a_p1', row: 6),
      _autoScout(id: 'scout_b_p1', row: 8),
    ],
    cities: const [
      GameCity(
        id: 'origin_p1',
        ownerPlayerId: 'p1',
        name: 'Origin',
        center: CityHex(col: 0, row: 0),
      ),
      GameCity(
        id: 'destination_p1',
        ownerPlayerId: 'p1',
        name: 'Destination',
        center: CityHex(col: 4, row: 0),
      ),
      GameCity(
        id: 'foreign_city_p2',
        ownerPlayerId: 'p2',
        name: 'Foreign city',
        center: CityHex(col: 10, row: 9),
      ),
    ],
    fogOfWar: FogOfWarState(
      players: {
        'p1': PlayerFogOfWar(
          playerId: 'p1',
          discoveredHexes: {
            const HexCoordinate(col: 0, row: 0),
            const HexCoordinate(col: 0, row: 2),
            const HexCoordinate(col: 0, row: 4),
            const HexCoordinate(col: 1, row: 6),
            const HexCoordinate(col: 1, row: 8),
          },
        ),
        'p2': PlayerFogOfWar(
          playerId: 'p2',
          discoveredHexes: {const HexCoordinate(col: 11, row: 9)},
        ),
      },
    ),
  );
}

PersistentGameState _idleInput() {
  return PersistentGameState.snapshot(
    playerColors: const {'p1': 0xFF000001, 'p2': 0xFF000002},
    units: [
      GameUnit.startingCommander(ownerPlayerId: 'p1'),
      GameUnit(
        id: 'foreign_p2',
        ownerPlayerId: 'p2',
        type: GameUnitType.warrior,
        name: GameUnitType.warrior.defaultNameToken,
        col: 11,
        row: 9,
        movementPoints: 0,
      ),
    ],
  );
}

GameUnit _autoScout({required String id, required int row}) {
  return GameUnit(
    id: id,
    ownerPlayerId: 'p1',
    type: GameUnitType.scout,
    name: GameUnitType.scout.defaultNameToken,
    col: 1,
    row: row,
    movementPoints: 0,
    posture: UnitPosture.autoExploring,
  );
}

List<UnitMovementStep> _lineSteps({required int row, required int throughCol}) {
  return [
    for (var col = 0; col <= throughCol; col++)
      UnitMovementStep(
        col: col,
        row: row,
        enterCost: col == 0 ? 0 : 1,
        cumulativeCost: col,
      ),
  ];
}

List<String> _unitIds(Iterable<GameUnit> units) {
  return [for (final unit in units) unit.id];
}

Map<String, GameUnit> _unitsById(Iterable<GameUnit> units) {
  return {for (final unit in units) unit.id: unit};
}

MapTraversalView get _mapView => MapData(
  cols: 12,
  rows: 10,
  tiles: [
    for (var row = 0; row < 10; row++)
      for (var col = 0; col < 12; col++)
        TileData(
          col: col,
          row: row,
          terrains: const [TerrainType.plains],
          resources: const [],
          height: 0,
        ),
  ],
);

final class _ParityResult {
  const _ParityResult({
    required this.domainInput,
    required this.domain,
    required this.persistent,
  });

  final DomainState domainInput;
  final DomainTurnMovementResult domain;
  final PersistentTurnMovementResult persistent;
}

const _adapter = LegacyGameSnapshotAdapter();
final _save = GameSave(
  id: 'movement_parity',
  name: 'Movement parity',
  mapName: 'movement_map',
  turn: 6,
  playerStates: const {
    'p1': PlayerTurnState.finished,
    'p2': PlayerTurnState.finished,
  },
  savedAt: DateTime.utc(2026, 7, 17),
  camera: CameraState.zero,
  players: const [
    Player(id: 'p1', name: 'Player one', colorValue: 0xFF000001),
    Player(id: 'p2', name: 'Player two', colorValue: 0xFF000002),
  ],
);
