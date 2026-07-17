import 'dart:async';

import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/application/ports/replay_store.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/replay_service.dart';
import 'package:aonw/game/presentation/providers/replay/replay_providers.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw/map/domain/terrain_type.dart';
import 'package:aonw/map/providers/map_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds replay reducer from one indexed session map view', () async {
    const selection = MapSelection(name: 'map', source: MapSource.asset);
    final mapData = MapData(
      cols: 1,
      rows: 1,
      tiles: const [
        TileData(
          col: 0,
          row: 0,
          terrains: [TerrainType.plains],
          resources: [],
          height: 0,
        ),
      ],
    );
    final container = ProviderContainer(
      overrides: [
        activeMapProvider(selection).overrideWithValue(AsyncData(mapData)),
        mapImagePathProvider(
          selection,
        ).overrideWithValue(const AsyncData(null)),
        savedCameraProvider('save_1').overrideWithValue(const AsyncData(null)),
        gameSaveProvider('save_1').overrideWithValue(const AsyncData(null)),
        replayStoreProvider.overrideWithValue(const _MissingReplayStore()),
        eventLogProvider.overrideWithValue(const _EmptyEventLog()),
      ],
    );
    addTearDown(container.dispose);
    final sessionProvider = gameSessionProvider(selection, 'save_1');
    final sessionSubscription = container.listen(sessionProvider, (_, _) {});
    addTearDown(sessionSubscription.close);
    final session = await container.read(sessionProvider.future);
    expect(session.mapData, same(mapData));
    final provider = replayTimelineProvider(
      const ReplayTimelineRequest(selection: selection, saveId: 'save_1'),
    );
    final failure = Completer<Object>();
    final subscription = container.listen(provider, (_, next) {
      if (next.hasError && !failure.isCompleted) failure.complete(next.error!);
    }, fireImmediately: true);
    addTearDown(subscription.close);

    expect(
      await failure.future,
      isA<ReplayBuildException>().having(
        (error) => error.reason,
        'reason',
        ReplayBuildFailureReason.missingInitialSnapshot,
      ),
    );
  });
}

final class _MissingReplayStore implements ReplayStore {
  const _MissingReplayStore();

  @override
  Future<SaveSnapshot?> initialSnapshot(String saveId) async => null;

  @override
  Future<void> saveInitialSnapshot(
    String saveId,
    SaveSnapshot snapshot,
  ) async {}

  @override
  Future<void> delete(String saveId) async {}
}

final class _EmptyEventLog implements EventLog {
  const _EmptyEventLog();

  @override
  Future<void> append(String saveId, LoggedCommand command) async {}

  @override
  Future<int> latestOffset(String saveId) async => 0;

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) =>
      const Stream.empty();

  @override
  Stream<LoggedCommand> readAll(String saveId) => const Stream.empty();
}
