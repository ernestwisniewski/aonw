import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/infrastructure/persistence/initial_game_snapshot_factory.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_replay_store.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_snapshot_store.dart';
import 'package:aonw_core/game/domain/save.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:sembast/sembast.dart';

class WebGameRepository implements GameRepository {
  static final StoreRef<String, Map<String, Object?>> _savesIndex =
      stringMapStoreFactory.store('saves');

  final WebDatabase database;
  final WebSnapshotStore snapshotStore;
  final ReplayStore replayStore;
  final Clock clock;
  final IdGenerator idGenerator;

  WebGameRepository({
    required this.database,
    required this.snapshotStore,
    ReplayStore? replayStore,
    required this.clock,
    required this.idGenerator,
  }) : replayStore = replayStore ?? WebReplayStore(database: database);

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) {
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$mapDisplayName — $year-$month-$day';
  }

  @override
  Future<String> create(NewGameRequest request) async {
    final id = idGenerator.nextId();
    final now = clock.nowUtc();
    final startPositionSeed =
        request.startPositionSeed ??
        StartingPositionSeed.fromParts([
          now,
          id,
          request.mapName,
          request.players.length,
          for (final player in request.players) player.id,
        ]);
    final initial = createInitialGameSnapshot(
      id: id,
      now: now,
      request: request,
      startPositionSeed: startPositionSeed,
    );
    final save = initial.save;
    final snapshot = initial.snapshot;

    await snapshotStore.save(id, Snapshot(state: snapshot, createdAt: now));
    await replayStore.saveInitialSnapshot(id, snapshot);
    await _writeIndex(save);
    return id;
  }

  @override
  Future<List<GameSaveIndex>> list() async {
    final records = await _savesIndex.find(database.database);
    final indexes = <GameSaveIndex>[];
    for (final record in records) {
      try {
        final index = GameSaveIndex.fromJson(
          Map<String, dynamic>.from(record.value),
        );
        final snapshot = await snapshotStore.latest(index.id);
        if (snapshot == null) {
          throw StateError('Save snapshot not found: ${index.id}');
        }
        final replayAvailable =
            await replayStore.initialSnapshot(index.id) != null;
        indexes.add(index.copyWith(replayAvailable: replayAvailable));
      } catch (error) {
        indexes.add(_corruptedIndexFor(record.key, record.value, error));
      }
    }
    indexes.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return indexes;
  }

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async {
    final snapshot = await snapshotStore.latest(saveId);
    if (snapshot == null) {
      throw StateError('Save snapshot not found: $saveId');
    }
    return snapshot.state;
  }

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async {
    await snapshotStore.save(
      snapshot.save.id,
      Snapshot(state: snapshot, createdAt: snapshot.save.savedAt),
    );
    await _writeIndex(snapshot.save);
  }

  @override
  Future<void> delete(String saveId) async {
    await _savesIndex.record(saveId).delete(database.database);
    await replayStore.delete(saveId);
    await snapshotStore.delete(saveId);
  }

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    final snapshot = await load(saveId);
    final updated = snapshot.withCamera(
      camera,
      savedAt: savedAt?.toUtc() ?? clock.nowUtc(),
    );
    await save(updated);
    return updated;
  }

  Future<void> _writeIndex(GameSave save) async {
    final index = GameSaveIndex(
      id: save.id,
      name: save.name,
      mapName: save.mapName,
      mapSource: save.mapSource,
      turn: save.turn,
      savedAt: save.savedAt,
      gameMode: save.gameMode,
      origin: save.origin,
      replayAvailable: true,
    );
    await _savesIndex.record(save.id).put(database.database, index.toJson());
  }

  GameSaveIndex _corruptedIndexFor(
    String saveId,
    Map<String, Object?> rawIndex,
    Object error,
  ) {
    try {
      final partial = GameSaveIndex.fromJson(
        Map<String, dynamic>.from(rawIndex),
      );
      return partial.copyWith(
        corrupted: true,
        corruptionMessage: error.toString(),
      );
    } catch (_) {
      return GameSaveIndex(
        id: saveId,
        name: saveId,
        mapName: '',
        turn: 0,
        savedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        corrupted: true,
        corruptionMessage: error.toString(),
      );
    }
  }
}
