import 'package:aonw/game/domain/ai/pressure_target_resolver.dart';
import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/match_rules.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PressureTargetResolver', () {
    test('pressures neutral players near cultural victory', () {
      final cities = [
        for (var i = 0; i < 4; i++)
          GameCity(
            id: 'human_city_$i',
            ownerPlayerId: 'human',
            name: 'Human $i',
            center: CityHex(col: i, row: 0),
          ),
      ];
      final state = PersistentGameState(
        cities: cities,
        artifacts: [
          for (var i = 0; i < 4; i++)
            WorldArtifact(
              id: 'artifact_$i',
              type: WorldArtifactType.values[i],
              location: WorldArtifactLocation.stored(cityId: cities[i].id),
            ),
        ],
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'human',
            'ai',
            DiplomaticRelationStatus.neutral,
          ),
        ),
      );

      final result = const PressureTargetResolver().resolve(
        players: _players,
        playerId: 'ai',
        state: state,
        turn: 2,
        matchRules: MatchRules.standard,
        mapData: _mapData,
      );

      expect(result.playerIds, {'human'});
    });

    test('includes score leader and exposes score race analysis', () {
      final matchRules = MatchRules.forGameLength(GameLengthConfig.standard60);
      final state = PersistentGameState(
        cities: const [
          GameCity(
            id: 'ai_city',
            ownerPlayerId: 'ai',
            name: 'AI City',
            center: CityHex(col: 0, row: 0),
          ),
          GameCity(
            id: 'leader_city_a',
            ownerPlayerId: 'leader',
            name: 'Leader A',
            center: CityHex(col: 1, row: 0),
          ),
          GameCity(
            id: 'leader_city_b',
            ownerPlayerId: 'leader',
            name: 'Leader B',
            center: CityHex(col: 2, row: 0),
          ),
        ],
        runtimeState: GameRuntimeState(
          diplomacy: DiplomacyState.empty.setStatus(
            'human',
            'ai',
            DiplomaticRelationStatus.neutral,
          ),
        ),
      );

      final result = const PressureTargetResolver().resolve(
        players: _players,
        playerId: 'ai',
        state: state,
        turn: 50,
        matchRules: matchRules,
        mapData: _mapData,
      );

      expect(result.scoreRace?.leaderPlayerId, 'leader');
      expect(result.playerIds, {'leader'});
    });
  });
}

const _players = [
  Player(id: 'human', name: 'Human', colorValue: 0xFF2563EB),
  Player(id: 'ai', name: 'AI', colorValue: 0xFFDC2626, kind: PlayerKind.ai),
  Player(
    id: 'leader',
    name: 'Leader',
    colorValue: 0xFF16A34A,
    kind: PlayerKind.ai,
  ),
];

final _mapData = MapData(
  cols: 4,
  rows: 1,
  tiles: const [
    TileData(
      col: 0,
      row: 0,
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
      col: 2,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
    TileData(
      col: 3,
      row: 0,
      terrains: [TerrainType.plains],
      resources: [],
      height: 0,
    ),
  ],
);
