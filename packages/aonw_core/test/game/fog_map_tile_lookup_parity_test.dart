import 'package:aonw_core/domain.dart';
import 'package:test/test.dart';

void main() {
  group('fog MapTileLookup parity', () {
    test(
      'FogRevealCalculator preserves sparse mountain and elevation behavior',
      () {
        final mapData = _sparseFogMap();
        final worldMapLookup = _worldMapLookup(mapData);

        final legacyVisible = _visibleHexes(mapData);
        final worldMapVisible = _visibleHexes(worldMapLookup);

        expect(worldMapVisible, legacyVisible);
        expect(
          legacyVisible,
          containsAll(const [
            HexCoordinate(col: 1, row: 2),
            HexCoordinate(col: 2, row: 2),
            HexCoordinate(col: 1, row: 3),
            HexCoordinate(col: 1, row: 1),
            HexCoordinate(col: 1, row: 0),
          ]),
        );
        expect(
          legacyVisible,
          isNot(contains(const HexCoordinate(col: 3, row: 2))),
          reason: 'the mountain must block propagation',
        );
        expect(
          legacyVisible,
          isNot(contains(const HexCoordinate(col: 1, row: 4))),
          reason: 'the elevated ridge must block a low observer',
        );
        expect(
          legacyVisible,
          isNot(contains(const HexCoordinate(col: 4, row: 4))),
          reason: 'an isolated sparse tile must remain hidden',
        );
      },
    );

    test('FogOfWarService preserves recompute and moved-unit results', () {
      final mapData = _sparseFogMap();
      final worldMapLookup = _worldMapLookup(mapData);
      final previousUnit = GameUnit.startingCommander(
        ownerPlayerId: 'player_1',
        col: 1,
        row: 2,
      );
      final movedUnit = previousUnit.copyWith(col: 1, row: 3);
      final opponent = GameUnit.startingCommander(
        ownerPlayerId: 'player_2',
        col: 4,
        row: 4,
      );
      final current = FogOfWarState(
        players: {
          'player_1': PlayerFogOfWar(
            playerId: 'player_1',
            discoveredHexes: {const HexCoordinate(col: 0, row: 4)},
          ),
        },
      );
      final legacyCounters = FogOfWarRecomputeCounters();
      final worldMapCounters = FogOfWarRecomputeCounters();
      final legacyService = FogOfWarService(counters: legacyCounters);
      final worldMapService = FogOfWarService(counters: worldMapCounters);

      final legacyRecomputed = legacyService.recompute(
        current: current,
        mapData: mapData,
        playerIds: const ['player_1', 'player_2'],
        units: [previousUnit, opponent],
        cities: const [],
      );
      final worldMapRecomputed = worldMapService.recompute(
        current: current,
        mapData: worldMapLookup,
        playerIds: const ['player_1', 'player_2'],
        units: [previousUnit, opponent],
        cities: const [],
      );

      expect(worldMapRecomputed, legacyRecomputed);
      expect(worldMapCounters.fullRecomputeCount, 1);
      legacyCounters.reset();
      worldMapCounters.reset();

      final legacyMoved = legacyService.recomputeAfterUnitMove(
        current: legacyRecomputed,
        mapData: mapData,
        previousUnit: previousUnit,
        movedUnit: movedUnit,
        units: [movedUnit, opponent],
        cities: const [],
      );
      final worldMapMoved = worldMapService.recomputeAfterUnitMove(
        current: worldMapRecomputed,
        mapData: worldMapLookup,
        previousUnit: previousUnit,
        movedUnit: movedUnit,
        units: [movedUnit, opponent],
        cities: const [],
      );

      expect(worldMapMoved, legacyMoved);
      expect(
        worldMapMoved.visibilityFor(
          'player_1',
          const HexCoordinate(col: 1, row: 4),
        ),
        FogVisibility.visible,
        reason: 'the moved observer must use the height-2 range bonus',
      );
      expect(
        worldMapCounters.unitMoveIncrementalCount,
        legacyCounters.unitMoveIncrementalCount,
      );
      expect(
        worldMapCounters.unitMoveFallbackCount,
        legacyCounters.unitMoveFallbackCount,
      );
      expect(
        worldMapCounters.unitMoveIncrementalCount +
            worldMapCounters.unitMoveFallbackCount,
        1,
      );
    });
  });
}

Set<HexCoordinate> _visibleHexes(MapTileLookup mapData) {
  return const FogRevealCalculator().visibleHexesFor(
    mapData: mapData,
    sources: const [
      FogRevealSource(
        playerId: 'player_1',
        origin: HexCoordinate(col: 1, row: 2),
        range: 3,
        observerHeight: 0,
      ),
    ],
  );
}

MapTileLookup _worldMapLookup(MapData mapData) {
  final worldMap = LegacyWorldMapAdapter.fromMapData(mapData);
  return WorldMapReadView(worldMap);
}

MapData _sparseFogMap() => MapData(
  cols: 5,
  rows: 5,
  tiles: const [
    TileData(
      col: 1,
      row: 2,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 2,
      row: 2,
      terrains: [TerrainType.mountain],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 3,
      row: 2,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 3,
      terrains: [TerrainType.plains],
      resources: [],
      height: 2,
    ),
    TileData(
      col: 1,
      row: 4,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 1,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 1,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 4,
      row: 4,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
