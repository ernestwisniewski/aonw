import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw/api/session/auth_token.dart';
import 'package:aonw/api/transport/multiplayer_backend_client.dart';
import 'package:aonw/api/transport/network_game_repository.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server_client/aonw_server_client.dart' as sp;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkGameRepository', () {
    test('creates matches through Serverpod and returns match id', () async {
      final backend = _FakeMultiplayerBackend(
        createdMatch: _match(id: 'match_new'),
      );
      final repository = _repository(backend);

      final id = await repository.create(
        const NewGameRequest(
          name: 'Duel',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [
            Player(
              id: 'player_1',
              name: 'Alice',
              colorValue: 0xFF2563EB,
              country: PlayerCountry.germany,
            ),
            Player(
              id: 'player_2',
              name: 'Bob',
              colorValue: 0xFFDC2626,
              country: PlayerCountry.japan,
            ),
          ],
          gameMode: GameMode.multiplayer,
        ),
      );

      expect(id, 'match_new');
      expect(backend.createdRequest?.name, 'Duel');
      expect(backend.createdRequest?.mapName, 'verdantia');
      expect(backend.createdRequest?.maxPlayers, 2);
      expect(backend.createdRequest?.minPlayers, 2);
      expect(backend.createdRequest?.private, isFalse);
      expect(backend.createdRequest?.countryId, PlayerCountry.germany.name);
    });

    test('lists matches as save indexes', () async {
      final repository = _repository(
        _FakeMultiplayerBackend(matches: [_match(id: 'match_1', turn: 3)]),
      );

      final indexes = await repository.list();

      expect(indexes.single.id, 'match_1');
      expect(indexes.single.name, 'Sunday duel');
      expect(indexes.single.mapName, 'verdantia');
      expect(indexes.single.turn, 3);
      expect(indexes.single.savedAt, DateTime.utc(2026, 4, 26, 11));
    });

    test('uses requested player count for mixed human and AI seats', () async {
      final backend = _FakeMultiplayerBackend(
        createdMatch: _match(id: 'match_ai'),
      );
      final repository = _repository(backend);

      await repository.create(
        const NewGameRequest(
          name: 'Duel',
          mapName: 'verdantia',
          mapSource: MapSource.asset,
          players: [
            Player(id: 'player_1', name: 'Alice', colorValue: 0xFF2563EB),
            Player(
              id: 'player_2',
              name: 'AI Random',
              colorValue: 0xFFDC2626,
              country: PlayerCountry.germany,
              kind: PlayerKind.ai,
              ai: AiPlayer(
                strategyId: AiStrategyId.random,
                difficulty: AiDifficulty.normal,
                persona: AiPersona.aggressive,
                seed: 42,
              ),
            ),
          ],
          gameMode: GameMode.multiplayer,
        ),
      );

      expect(backend.createdRequest?.maxPlayers, 2);
      expect(backend.createdRequest?.minPlayers, 2);
    });

    test('loads snapshots from the network snapshot endpoint', () async {
      const codec = SnapshotCodec();
      final cache = _MemorySnapshotStore();
      final snapshot = SaveSnapshot(
        save: _save(),
        playerColors: const {'player_1': 0xFF2563EB},
        eventLogOffset: 12,
      );
      final backend = _FakeMultiplayerBackend(
        snapshot: codec.toWire(matchId: 'match_1', snapshot: snapshot),
      );
      final repository = _repository(backend, snapshotCache: cache);

      final loaded = await repository.load('match_1');

      expect(backend.loadedSnapshotId, 'match_1');
      expect(loaded.save.id, 'match_1');
      expect(loaded.eventLogOffset, 12);
      expect(loaded.playerColors, {'player_1': 0xFF2563EB});
      expect(cache.snapshots['match_1']?.state.eventLogOffset, 12);
    });

    test('falls back to cached snapshots when network load fails', () async {
      final cache = _MemorySnapshotStore();
      await cache.save(
        'match_1',
        Snapshot(
          offset: 8,
          state: SaveSnapshot(
            save: _save(),
            playerColors: const {'player_1': 0xFF2563EB},
            eventLogOffset: 8,
          ),
          createdAt: DateTime.utc(2026, 4, 26, 10),
        ),
      );
      final repository = _repository(
        _FakeMultiplayerBackend(
          loadSnapshotError: const sp.ServerpodClientException('offline', -1),
        ),
        snapshotCache: cache,
      );

      final snapshot = await repository.load('match_1');

      expect(snapshot.save.id, 'match_1');
      expect(snapshot.eventLogOffset, 8);
      expect(snapshot.playerColors, {'player_1': 0xFF2563EB});
    });

    test('leaves matches through Serverpod on delete', () async {
      final backend = _FakeMultiplayerBackend();
      final repository = _repository(backend);

      await repository.delete('match_1');

      expect(backend.leftMatchId, 'match_1');
    });

    test('does not allow direct client-side mutations', () {
      final repository = _repository(_FakeMultiplayerBackend());

      expect(
        () => repository.save(SaveSnapshot(save: _save())),
        throwsA(isA<UnsupportedError>()),
      );
      expect(
        () => repository.saveCamera('match_1', CameraState.zero),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

NetworkGameRepository _repository(
  MultiplayerBackendClient backend, {
  SnapshotStore? snapshotCache,
}) {
  return NetworkGameRepository(
    backendClient: backend,
    token: AuthToken('jwt-token'),
    snapshotCache: snapshotCache,
  );
}

class _MemorySnapshotStore implements SnapshotStore {
  final snapshots = <String, Snapshot>{};

  @override
  Future<Snapshot?> latest(String saveId) async => snapshots[saveId];

  @override
  Future<void> save(String saveId, Snapshot snapshot) async {
    snapshots[saveId] = snapshot;
  }
}

class _FakeMultiplayerBackend implements MultiplayerBackendClient {
  _FakeMultiplayerBackend({
    this.matches = const [],
    this.createdMatch,
    this.snapshot,
    this.loadSnapshotError,
  });

  final List<WireMatch> matches;
  final WireMatch? createdMatch;
  final WireSnapshot? snapshot;
  final Object? loadSnapshotError;

  sp.CreateMatchRequest? createdRequest;
  String? loadedSnapshotId;
  String? leftMatchId;

  @override
  Future<WireMatch> createMatch(sp.CreateMatchRequest request) async {
    createdRequest = request;
    return createdMatch ?? _match(id: 'created_match');
  }

  @override
  Future<void> leaveMatch(String matchId) async {
    leftMatchId = matchId;
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) {
    throw UnimplementedError();
  }

  @override
  Future<List<WireMatch>> listMatches() async {
    return matches;
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

WireMatch _match({required String id, int turn = 1}) {
  return WireMatch(
    id: id,
    ownerUserId: 'user_1',
    name: 'Sunday duel',
    mapName: 'verdantia',
    players: const [
      WirePlayer(
        id: 'player_1',
        userId: 'user_1',
        name: 'Alice',
        colorValue: 0xFF2563EB,
        kind: WirePlayerKind.human,
        connectionState: WirePlayerConnectionState.connected,
      ),
    ],
    turn: turn,
    state: 'open',
    createdAt: DateTime.utc(2026, 4, 26, 11),
  );
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
