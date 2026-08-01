import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_event_log.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_game_repository.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_replay_store.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_snapshot_store.dart';

WebDatabase? _database;
Future<WebDatabase>? _databaseFuture;

Future<WebDatabase> _openDatabase() {
  final existing = _database;
  if (existing != null) return Future.value(existing);
  final pending = _databaseFuture;
  if (pending != null) return pending;
  final future = WebDatabase.open().then((db) {
    _database = db;
    return db;
  });
  _databaseFuture = future;
  return future;
}

Future<WebDatabase> _resolveDatabaseFuture(
  Future<WebDatabase>? databaseFuture,
) => databaseFuture ?? _openDatabase();

GameRepository createPlatformGameRepository({
  required Clock clock,
  required IdGenerator idGenerator,
  Future<WebDatabase>? databaseFuture,
}) {
  return _LazyWebGameRepository(
    clock: clock,
    idGenerator: idGenerator,
    databaseFuture: _resolveDatabaseFuture(databaseFuture),
  );
}

EventLog createPlatformEventLog({Future<WebDatabase>? databaseFuture}) {
  return _LazyWebEventLog(
    databaseFuture: _resolveDatabaseFuture(databaseFuture),
  );
}

SnapshotStore createPlatformSnapshotStore({
  required Clock clock,
  Future<WebDatabase>? databaseFuture,
}) {
  return _LazyWebSnapshotStore(
    databaseFuture: _resolveDatabaseFuture(databaseFuture),
  );
}

ReplayStore createPlatformReplayStore({Future<WebDatabase>? databaseFuture}) {
  return _LazyWebReplayStore(
    databaseFuture: _resolveDatabaseFuture(databaseFuture),
  );
}

class _LazyWebGameRepository implements GameRepository {
  final Clock clock;
  final IdGenerator idGenerator;
  final Future<WebDatabase> databaseFuture;
  WebGameRepository? _delegate;

  _LazyWebGameRepository({
    required this.clock,
    required this.idGenerator,
    required this.databaseFuture,
  });

  Future<WebGameRepository> _resolve() async {
    final existing = _delegate;
    if (existing != null) return existing;
    final db = await databaseFuture;
    final repo = WebGameRepository(
      database: db,
      snapshotStore: WebSnapshotStore(database: db),
      clock: clock,
      idGenerator: idGenerator,
    );
    _delegate = repo;
    return repo;
  }

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) {
    final year = now.year.toString().padLeft(4, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '$mapDisplayName — $year-$month-$day';
  }

  @override
  Future<String> create(NewGameRequest request) async =>
      (await _resolve()).create(request);

  @override
  Future<List<GameSaveIndex>> list() async => (await _resolve()).list();

  @override
  Future<CanonicalGameSnapshot> load(String saveId) async =>
      (await _resolve()).load(saveId);

  @override
  Future<void> save(CanonicalGameSnapshot snapshot) async =>
      (await _resolve()).save(snapshot);

  @override
  Future<void> delete(String saveId) async => (await _resolve()).delete(saveId);

  @override
  Future<CanonicalGameSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async => (await _resolve()).saveCamera(saveId, camera, savedAt: savedAt);
}

class _LazyWebSnapshotStore implements SnapshotStore {
  final Future<WebDatabase> databaseFuture;
  WebSnapshotStore? _delegate;

  _LazyWebSnapshotStore({required this.databaseFuture});

  Future<WebSnapshotStore> _resolve() async {
    final existing = _delegate;
    if (existing != null) return existing;
    final db = await databaseFuture;
    final store = WebSnapshotStore(database: db);
    _delegate = store;
    return store;
  }

  @override
  Future<Snapshot?> latest(String saveId) async =>
      (await _resolve()).latest(saveId);

  @override
  Future<void> save(String saveId, Snapshot snapshot) async =>
      (await _resolve()).save(saveId, snapshot);
}

class _LazyWebEventLog implements EventLog {
  final Future<WebDatabase> databaseFuture;
  WebEventLog? _delegate;

  _LazyWebEventLog({required this.databaseFuture});

  Future<WebEventLog> _resolve() async {
    final existing = _delegate;
    if (existing != null) return existing;
    final db = await databaseFuture;
    final log = WebEventLog(database: db);
    _delegate = log;
    return log;
  }

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async =>
      (await _resolve()).append(saveId, command);

  @override
  Stream<RecordedDomainCommand> readSince(
    String saveId, {
    int offset = 0,
  }) async* {
    final log = await _resolve();
    yield* log.readSince(saveId, offset: offset);
  }

  @override
  Future<int> latestOffset(String saveId) async =>
      (await _resolve()).latestOffset(saveId);

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => readSince(saveId);
}

class _LazyWebReplayStore implements ReplayStore {
  final Future<WebDatabase> databaseFuture;
  WebReplayStore? _delegate;

  _LazyWebReplayStore({required this.databaseFuture});

  Future<WebReplayStore> _resolve() async {
    final existing = _delegate;
    if (existing != null) return existing;
    final db = await databaseFuture;
    final store = WebReplayStore(database: db);
    _delegate = store;
    return store;
  }

  @override
  Future<CanonicalGameSnapshot?> initialSnapshot(String saveId) async =>
      (await _resolve()).initialSnapshot(saveId);

  @override
  Future<void> saveInitialSnapshot(
    String saveId,
    CanonicalGameSnapshot snapshot,
  ) async => (await _resolve()).saveInitialSnapshot(saveId, snapshot);

  @override
  Future<void> delete(String saveId) async => (await _resolve()).delete(saveId);
}
