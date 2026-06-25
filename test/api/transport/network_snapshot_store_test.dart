import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/api/transport/network_snapshot_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart'
    show WireEvent, WireMatch, WireSnapshot;
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkSnapshotStore', () {
    test('loads the latest server snapshot', () async {
      const codec = SnapshotCodec();
      final wire = codec.toWire(
        matchId: 'match_1',
        snapshot: SaveSnapshot(
          save: _save(),
          playerColors: const {'player_1': 0xFF2563EB},
          eventLogOffset: 9,
        ),
      );
      final backend = _FakeMultiplayerBackend(snapshot: wire);
      final store = NetworkSnapshotStore(
        backendClient: backend,
        token: AuthToken('jwt-token'),
      );

      final snapshot = await store.latest('match_1');

      expect(backend.loadedSnapshotId, 'match_1');
      expect(snapshot, isNotNull);
      expect(snapshot!.offset, 9);
      expect(snapshot.state.save.id, 'match_1');
      expect(snapshot.state.playerColors, {'player_1': 0xFF2563EB});
      expect(snapshot.createdAt, DateTime.utc(2026, 4, 26, 10));
    });

    test('returns null for missing snapshots', () async {
      final store = NetworkSnapshotStore(
        backendClient: _FakeMultiplayerBackend(
          loadSnapshotError: const sp.ServerpodClientException(
            'not found',
            404,
          ),
        ),
        token: AuthToken('jwt-token'),
      );

      await expectLater(store.latest('missing'), completion(isNull));
    });

    test('does not allow client-side writes', () {
      final store = NetworkSnapshotStore(
        backendClient: _FakeMultiplayerBackend(),
        token: AuthToken('jwt-token'),
      );

      expect(
        () => store.save(
          'match_1',
          Snapshot(
            offset: 1,
            state: SaveSnapshot(save: _save()),
            createdAt: DateTime.utc(2026),
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

class _FakeMultiplayerBackend implements MultiplayerBackendClient {
  _FakeMultiplayerBackend({this.snapshot, this.loadSnapshotError});

  final WireSnapshot? snapshot;
  final Object? loadSnapshotError;

  String? loadedSnapshotId;

  @override
  Future<WireMatch> createMatch(sp.CreateMatchRequest request) {
    throw UnimplementedError();
  }

  @override
  Future<void> leaveMatch(String matchId) {
    throw UnimplementedError();
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) {
    throw UnimplementedError();
  }

  @override
  Future<List<WireMatch>> listMatches() {
    throw UnimplementedError();
  }

  @override
  Future<WireSnapshot> loadSnapshot(String matchId) async {
    loadedSnapshotId = matchId;
    final error = loadSnapshotError;
    if (error != null) throw error;
    final value = snapshot;
    if (value == null) {
      throw const sp.ServerpodClientException('not found', 404);
    }
    return value;
  }
}

GameSave _save() {
  return GameSave(
    id: 'match_1',
    name: 'Sunday duel',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 2,
    playerStates: const {'player_1': PlayerTurnState.active},
    savedAt: DateTime.utc(2026, 4, 26, 10),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
    ],
    gameMode: GameMode.multiplayer,
  );
}
