import 'dart:convert';

import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/save_snapshot_codec.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/wonder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips current fog, research, and wonder sentinels', () {
    const discoveredOnlyHex = HexCoordinate(col: 1, row: 2);
    const visibleHex = HexCoordinate(col: 3, row: 4);
    final snapshot = GameSnapshotFactory.create(
      save: _save(),
      fogOfWar: FogOfWarState(
        players: {
          'p1': PlayerFogOfWar(
            playerId: 'p1',
            discoveredHexes: {discoveredOnlyHex},
            visibleHexes: {visibleHex},
          ),
        },
      ),
      research: ResearchState(
        players: {
          'p1': PlayerResearchState(
            activeTechnologyId: TechnologyId.mining,
            scienceOverflow: 17,
          ),
        },
      ),
      wonderRegistry: WonderRegistry(
        completedBy: {WonderType.greatLibrary: 'p1'},
      ),
    );
    final json = SaveSnapshotCodec.toJson(snapshot);

    final restored = SaveSnapshotCodec.fromJson(json);

    final restoredFog = restored.fogOfWar.fogForPlayer('p1');
    expect(restoredFog.discoveredHexes, {discoveredOnlyHex, visibleHex});
    expect(restoredFog.visibleHexes, {visibleHex});
    expect(restored.research.forPlayer('p1').scienceOverflow, 17);
    expect(restored.wonderRegistry.ownerOf(WonderType.greatLibrary), 'p1');
    expect(SaveSnapshotCodec.toJson(restored), json);
  });

  test('decodes omitted optional state fields with canonical defaults', () {
    const discoveredHex = HexCoordinate(col: 5, row: 6);
    final json =
        jsonDecode(
                jsonEncode(
                  SaveSnapshotCodec.toJson(
                    GameSnapshotFactory.create(
                      save: _save(),
                      fogOfWar: FogOfWarState(
                        players: {
                          'p1': PlayerFogOfWar(
                            playerId: 'p1',
                            discoveredHexes: {discoveredHex},
                          ),
                        },
                      ),
                      research: ResearchState(
                        players: {
                          'p1': PlayerResearchState(
                            activeTechnologyId: TechnologyId.mining,
                            scienceOverflow: 17,
                          ),
                        },
                      ),
                      wonderRegistry: WonderRegistry(
                        completedBy: {WonderType.greatLibrary: 'p1'},
                      ),
                    ),
                  ),
                ),
              )
              as Map<String, dynamic>
          ..remove('wonderRegistry');
    ((json['fogOfWar'] as List<dynamic>).single as Map<String, dynamic>).remove(
      'visibleHexes',
    );
    (((json['research'] as Map<String, dynamic>)['players']
                as Map<String, dynamic>)['p1']
            as Map<String, dynamic>)
        .remove('scienceOverflow');

    final restored = SaveSnapshotCodec.fromJson(json);

    final restoredFog = restored.fogOfWar.fogForPlayer('p1');
    expect(restoredFog.discoveredHexes, {discoveredHex});
    expect(restoredFog.visibleHexes, isEmpty);
    expect(
      restored.research.forPlayer('p1').activeTechnologyId,
      TechnologyId.mining,
    );
    expect(restored.research.forPlayer('p1').scienceOverflow, 0);
    expect(restored.wonderRegistry, WonderRegistry.empty);
  });
}

GameSave _save() {
  return GameSave(
    id: 'save_state_round_trip',
    name: 'Game',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 1,
    playerStates: const {'p1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 1, 1),
    camera: CameraState.zero,
    players: const [Player(id: 'p1', name: 'Alice', colorValue: 0xFF4a7fc4)],
  );
}
