import 'dart:io';

import 'package:aonw/game/application/ports/clock.dart';
import 'package:aonw/game/application/ports/game_repository.dart';
import 'package:aonw/game/application/ports/id_generator.dart';
import 'package:aonw/game/application/ports/new_game_request.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/ports/snapshot_store.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/game/infrastructure/persistence/game_storage.dart';
import 'package:aonw/game/infrastructure/persistence/json_replay_store.dart';
import 'package:aonw/game/infrastructure/persistence/json_snapshot_store.dart';
import 'package:aonw/game/infrastructure/system/system_clock.dart';
import 'package:aonw/game/infrastructure/system/timestamp_id_generator.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/fog.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';

class JsonGameRepository implements GameRepository {
  final Directory? savesDir;
  final JsonSnapshotStore? snapshotStore;
  final ReplayStore? replayStore;
  final Clock clock;
  final IdGenerator idGenerator;

  factory JsonGameRepository({
    Directory? savesDir,
    JsonSnapshotStore? snapshotStore,
    ReplayStore? replayStore,
    Clock? clock,
    IdGenerator? idGenerator,
  }) {
    final resolvedClock = clock ?? const SystemClock();
    return JsonGameRepository._(
      savesDir: savesDir,
      snapshotStore: snapshotStore,
      replayStore: replayStore,
      clock: resolvedClock,
      idGenerator: idGenerator ?? TimestampIdGenerator(clock: resolvedClock),
    );
  }

  JsonGameRepository._({
    this.savesDir,
    this.snapshotStore,
    this.replayStore,
    required this.clock,
    required this.idGenerator,
  });

  @override
  String defaultSaveName(String mapDisplayName, DateTime now) {
    return GameStorage.defaultSaveName(mapDisplayName, now);
  }

  @override
  Future<String> create(NewGameRequest request) async {
    final id = idGenerator.nextId();
    final now = clock.nowUtc();
    final startPositionSeed =
        request.startPositionSeed ??
        _startPositionSeed(id: id, now: now, request: request);
    final save = GameSave(
      id: id,
      name: request.name,
      mapName: request.mapName,
      mapSource: request.mapSource,
      turn: 1,
      playerStates: {
        for (final player in request.players) player.id: PlayerTurnState.active,
      },
      savedAt: now,
      camera: CameraState.zero,
      matchRules: request.matchRules,
      players: request.players,
      gameMode: request.gameMode,
    );
    final units = StartingUnits.unitsForPlayers(
      request.players,
      mapData: request.mapData,
      startPositionSeed: startPositionSeed,
    );
    final artifacts = request.mapData == null
        ? const <WorldArtifact>[]
        : WorldArtifactGenerator.generate(
            mapData: request.mapData!,
            startingUnits: units,
            seed: startPositionSeed,
          );
    final fogOfWar = request.mapData == null
        ? FogOfWarState.empty
        : const FogOfWarService().recompute(
            current: FogOfWarState.empty,
            mapData: request.mapData!,
            playerIds: request.players.map((player) => player.id),
            units: units,
            cities: const [],
          );
    final diplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: DiplomacyState.empty,
      fogOfWar: fogOfWar,
      units: units,
      cities: const [],
      playerIds: request.players.map((player) => player.id),
    );
    final snapshot = SaveSnapshot(
      save: save,
      playerColors: {
        for (final player in request.players) player.id: player.colorValue,
      },
      playerCountries: {
        for (final player in request.players) player.id: player.country,
      },
      units: units,
      artifacts: artifacts,
      fogOfWar: fogOfWar,
      runtimeState: GameRuntimeState(diplomacy: diplomacy),
    );

    await _snapshotStore.save(
      id,
      Snapshot(
        offset: snapshot.eventLogOffset,
        state: snapshot,
        createdAt: now,
      ),
    );
    await _replayStore.saveInitialSnapshot(id, snapshot);
    return id;
  }

  @override
  Future<List<GameSaveIndex>> list() async {
    final root = savesDir ?? await GameStorage.savesDirectory();
    if (!await root.exists()) return const [];

    final indexes = <GameSaveIndex>[];
    for (final entity in root.listSync().whereType<Directory>()) {
      final saveId = _saveIdFrom(entity);
      try {
        final snapshot = await _snapshotStore.latest(saveId);
        if (snapshot == null) {
          throw StateError('Save snapshot not found: $saveId');
        }
        final save = snapshot.state.save;
        final replayAvailable =
            await _replayStore.initialSnapshot(saveId) != null;
        indexes.add(
          GameSaveIndex(
            id: save.id,
            name: save.name,
            mapName: save.mapName,
            mapSource: save.mapSource,
            turn: save.turn,
            savedAt: save.savedAt,
            gameMode: save.gameMode,
            replayAvailable: replayAvailable,
          ),
        );
      } catch (error) {
        indexes.add(await _corruptedIndexFor(saveId, entity, error));
      }
    }
    indexes.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return indexes;
  }

  @override
  Future<SaveSnapshot> load(String saveId) async {
    final latestSnapshot = await _snapshotStore.latest(saveId);
    if (latestSnapshot == null) {
      throw StateError('Save snapshot not found: $saveId');
    }
    return latestSnapshot.state;
  }

  @override
  Future<void> save(SaveSnapshot snapshot) async {
    await _snapshotStore.save(
      snapshot.save.id,
      Snapshot(
        offset: snapshot.eventLogOffset,
        state: snapshot,
        createdAt: snapshot.save.savedAt,
      ),
    );
  }

  @override
  Future<void> delete(String saveId) async {
    await _replayStore.delete(saveId);
    await GameStorage.deleteSave(saveId, savesDir: savesDir);
  }

  @override
  Future<SaveSnapshot> saveCamera(
    String saveId,
    CameraState camera, {
    DateTime? savedAt,
  }) async {
    final snapshot = await load(saveId);
    final updated = snapshot.copyWith(
      save: snapshot.save.copyWith(
        camera: camera,
        savedAt: savedAt?.toUtc() ?? clock.nowUtc(),
      ),
    );
    await save(updated);
    return updated;
  }

  JsonSnapshotStore get _snapshotStore {
    return snapshotStore ?? JsonSnapshotStore(savesDir: savesDir, clock: clock);
  }

  ReplayStore get _replayStore {
    return replayStore ?? JsonReplayStore(savesDir: savesDir);
  }

  String _saveIdFrom(Directory directory) {
    return directory.uri.pathSegments
        .where((segment) => segment.isNotEmpty)
        .last;
  }

  Future<GameSaveIndex> _corruptedIndexFor(
    String saveId,
    Directory directory,
    Object error,
  ) async {
    DateTime savedAt;
    try {
      savedAt = (await directory.stat()).modified.toUtc();
    } catch (_) {
      savedAt = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return GameSaveIndex(
      id: saveId,
      name: saveId,
      mapName: '',
      turn: 0,
      savedAt: savedAt,
      corrupted: true,
      corruptionMessage: error.toString(),
    );
  }

  int _startPositionSeed({
    required String id,
    required DateTime now,
    required NewGameRequest request,
  }) => StartingPositionSeed.fromParts([
    now,
    id,
    request.mapName,
    request.players.length,
    for (final player in request.players) player.id,
  ]);
}
