import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('unit detachment state adapters', () {
    test('persistent and domain adapters apply the exact same transition', () {
      final persistent = _persistentState();
      final domain = _domainState();
      const command = DetachTroopCommand('commander_1', TroopType.warrior);
      final persistentCounters = FogOfWarRecomputeCounters();
      final domainCounters = FogOfWarRecomputeCounters();

      final persistentResult =
          PersistentUnitDetachmentResolver(
            fogOfWarService: FogOfWarService(counters: persistentCounters),
          ).detachTroop(
            state: persistent,
            command: command,
            actorPlayerId: 'player_1',
            mapTiles: WorldMapReadView(_worldMap()),
          );
      final domainResult =
          DomainUnitDetachmentResolver(
            fogOfWarService: FogOfWarService(counters: domainCounters),
          ).detachTroop(
            state: domain,
            command: command,
            actorPlayerId: 'player_1',
            mapTiles: WorldMapReadView(_worldMap()),
          );

      expect(persistentResult.accepted, isTrue);
      expect(domainResult.accepted, isTrue);
      expect(persistentResult.reason, domainResult.reason);
      expect(persistentResult.state.units, domainResult.state.units);
      expect(persistentResult.state.fogOfWar, domainResult.state.fogOfWar);
      expect(
        persistentResult.state.runtimeState.diplomacy,
        domainResult.state.diplomacy,
      );
      expect(persistentCounters.playerRecomputeCount, 1);
      expect(domainCounters.playerRecomputeCount, 1);
      expect(
        domainResult.state,
        domain.copyWith(
          units: domainResult.state.units,
          fogOfWar: domainResult.state.fogOfWar,
          diplomacy: domainResult.state.diplomacy,
        ),
      );
      expect(
        persistentResult.state,
        persistent.copyWith(
          units: persistentResult.state.units,
          fogOfWar: persistentResult.state.fogOfWar,
          runtimeState: persistent.runtimeState.copyWith(
            diplomacy: persistentResult.state.runtimeState.diplomacy,
          ),
        ),
      );
      expect(
        domainResult.state.diplomacy.hasContact('player_1', 'player_2'),
        isTrue,
      );
    });

    for (final rejection in const [
      (
        name: 'wrong actor',
        actorPlayerId: 'player_2',
        troopType: TroopType.warrior,
        reason: 'unit_not_controlled',
      ),
      (
        name: 'unavailable troop',
        actorPlayerId: 'player_1',
        troopType: TroopType.archer,
        reason: 'troop_not_available',
      ),
    ]) {
      test('${rejection.name} preserves both state identities', () {
        final persistent = _persistentState();
        final domain = _domainState();
        final command = DetachTroopCommand('commander_1', rejection.troopType);
        final mapTiles = _FailOnReadMapTileLookup();

        final persistentResult = const PersistentUnitDetachmentResolver()
            .detachTroop(
              state: persistent,
              command: command,
              actorPlayerId: rejection.actorPlayerId,
              mapTiles: mapTiles,
            );
        final domainResult = const DomainUnitDetachmentResolver().detachTroop(
          state: domain,
          command: command,
          actorPlayerId: rejection.actorPlayerId,
          mapTiles: mapTiles,
        );

        expect(persistentResult.accepted, isFalse);
        expect(domainResult.accepted, isFalse);
        expect(persistentResult.reason, rejection.reason);
        expect(domainResult.reason, rejection.reason);
        expect(identical(persistentResult.state, persistent), isTrue);
        expect(identical(domainResult.state, domain), isTrue);
      });
    }

    test('source out of bounds has exact reason and preserves adapters', () {
      final persistent = _persistentState(sourceCol: 9, sourceRow: 9);
      final domain = _domainState(sourceCol: 9, sourceRow: 9);
      const command = DetachTroopCommand('commander_1', TroopType.warrior);
      final mapTiles = WorldMapReadView(_worldMap());

      final persistentResult = const PersistentUnitDetachmentResolver()
          .detachTroop(
            state: persistent,
            command: command,
            actorPlayerId: 'player_1',
            mapTiles: mapTiles,
          );
      final domainResult = const DomainUnitDetachmentResolver().detachTroop(
        state: domain,
        command: command,
        actorPlayerId: 'player_1',
        mapTiles: mapTiles,
      );

      expect(persistentResult.reason, 'detachment_source_out_of_bounds');
      expect(domainResult.reason, persistentResult.reason);
      expect(identical(persistentResult.state, persistent), isTrue);
      expect(identical(domainResult.state, domain), isTrue);
    });
  });
}

PersistentGameState _persistentState({int sourceCol = 0, int sourceRow = 0}) {
  return PersistentGameState.snapshot(
    playerColors: const {'player_1': 0xff000001, 'player_2': 0xff000002},
    playerCountries: const {
      'player_1': PlayerCountry.poland,
      'player_2': PlayerCountry.japan,
    },
    playerGold: const {'player_1': 7, 'player_2': 11},
    units: _units(sourceCol: sourceCol, sourceRow: sourceRow),
    cities: const [],
    fogOfWar: _fogOfWar(),
    runtimeState: GameRuntimeState(
      submittedPlayerIds: const {'player_2'},
      turnStartedAt: _turnStartedAt,
    ),
  );
}

DomainState _domainState({int sourceCol = 0, int sourceRow = 0}) {
  return DomainState.snapshot(
    turn: 7,
    matchRules: MatchRules.standard,
    participants: const [
      Player(id: 'player_1', name: 'P1', colorValue: 0xff000001),
      Player(
        id: 'player_2',
        name: 'P2',
        colorValue: 0xff000002,
        country: PlayerCountry.japan,
      ),
    ],
    playerGold: const {'player_1': 7, 'player_2': 11},
    units: _units(sourceCol: sourceCol, sourceRow: sourceRow),
    cities: const [],
    fogOfWar: _fogOfWar(),
  );
}

List<GameUnit> _units({required int sourceCol, required int sourceRow}) {
  return [
    GameUnit(
      id: 'commander_1',
      ownerPlayerId: 'player_1',
      type: GameUnitType.commander,
      name: GameUnitType.commander.defaultNameToken,
      col: sourceCol,
      row: sourceRow,
      army: const [ArmyTroop(type: TroopType.warrior, count: 1)],
    ),
    GameUnit(
      id: 'scout_2',
      ownerPlayerId: 'player_2',
      type: GameUnitType.scout,
      name: GameUnitType.scout.defaultNameToken,
      col: 3,
      row: 0,
    ),
  ];
}

FogOfWarState _fogOfWar() {
  final known = {
    const HexCoordinate(col: 0, row: 0),
    const HexCoordinate(col: 1, row: 0),
    const HexCoordinate(col: 2, row: 0),
  };
  return FogOfWarState(
    players: {
      'player_1': PlayerFogOfWar(
        playerId: 'player_1',
        discoveredHexes: known,
        visibleHexes: known,
      ),
    },
  );
}

WorldMap _worldMap() {
  return WorldMap(
    cols: 4,
    rows: 1,
    tiles: [
      for (var col = 0; col < 4; col++)
        WorldTile(
          coordinate: HexCoord(col: col, row: 0),
          terrains: const [TerrainType.grassland],
          resources: const [],
          height: 0,
        ),
    ],
  );
}

final class _FailOnReadMapTileLookup implements MapTileLookup {
  @override
  MapTileView? tileAt(int col, int row) {
    fail('early rejection must not read map tile ($col, $row)');
  }
}

final _turnStartedAt = DateTime.utc(2026, 7, 18);
