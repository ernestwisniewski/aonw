import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResearchTurnProcessor', () {
    test('does not change research when no technology is active', () {
      final city = _city();

      final result = ResearchTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        research: ResearchState.empty,
        mapData: _map(),
      );

      expect(result.scienceYield.total, 2);
      expect(result.research, ResearchState.empty);
      expect(result.changed, isFalse);
    });

    test('adds science to active technology progress', () {
      final city = _city();
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
          ),
        },
      );

      final result = ResearchTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        research: research,
        mapData: _map(),
      );

      final playerResearch = result.research.forPlayer('player_1');
      expect(playerResearch.progressFor(TechnologyId.agriculture), 2);
      expect(playerResearch.activeTechnologyId, TechnologyId.agriculture);
      expect(result.completedTechnologyId, isNull);
      expect(result.changed, isTrue);
    });

    test('completes active technology and clears its progress', () {
      final city = _city();
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
            progressByTechnologyId: {TechnologyId.agriculture: 5},
          ),
        },
      );

      final result = ResearchTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        research: research,
        mapData: _map(),
      );

      final playerResearch = result.research.forPlayer('player_1');
      expect(playerResearch.hasUnlocked(TechnologyId.agriculture), isTrue);
      expect(playerResearch.activeTechnologyId, isNull);
      expect(playerResearch.progressFor(TechnologyId.agriculture), 0);
      expect(playerResearch.scienceOverflow, 1);
      expect(result.completedTechnologyId, TechnologyId.agriculture);
    });

    test('applies satisfied technology boost discounts', () {
      final city = _city(controlledHexes: const [CityHex(col: 1, row: 0)]);
      final research = ResearchState(
        players: {
          'player_1': PlayerResearchState(
            activeTechnologyId: TechnologyId.agriculture,
            progressByTechnologyId: {TechnologyId.agriculture: 3},
          ),
        },
      );

      final result = ResearchTurnProcessor.advanceForPlayer(
        playerId: 'player_1',
        cities: [city],
        fieldImprovements: const [],
        research: research,
        mapData: _map(
          resourcesByCol: {
            1: {ResourceType.wheat},
          },
        ),
      );

      expect(
        result.research
            .forPlayer('player_1')
            .hasUnlocked(TechnologyId.agriculture),
        isTrue,
      );
      expect(result.completedTechnologyId, TechnologyId.agriculture);
    });
  });
}

GameCity _city({List<CityHex> controlledHexes = const []}) {
  return GameCity(
    id: 'city_1',
    ownerPlayerId: 'player_1',
    name: 'City',
    center: const CityHex(col: 0, row: 0),
    controlledHexes: controlledHexes,
  );
}

MapData _map({Map<int, Set<ResourceType>> resourcesByCol = const {}}) {
  return MapData(
    cols: 3,
    rows: 1,
    tiles: [
      for (var col = 0; col < 3; col++)
        TileData(
          col: col,
          row: 0,
          terrains: const [TerrainType.plains],
          resources: resourcesByCol[col]?.toList() ?? const [],
          height: 0,
        ),
    ],
  );
}
