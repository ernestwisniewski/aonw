import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_map_catalog.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

import '../../../test/support/reducer_parity_auto_explore_characterization.dart';
import '../../../test/support/reducer_parity_combat_characterization.dart';
import '../../../test/support/reducer_parity_diplomacy_characterization.dart';
import '../../../test/support/reducer_parity_fixture.dart';
import '../../../test/support/reducer_parity_movement_characterization.dart';
import '../../../test/support/reducer_parity_resource_trade_characterization.dart';
import 'support/server_command_reducer_test_driver.dart';

const _repeatCount = 3;
const _snapshotAdapter = LegacyGameSnapshotAdapter();
const _reducerDriver = ServerCommandReducerTestDriver();

void main() {
  final repositoryRoot = Directory.current.parent;
  group('server reducer parity fixtures', () {
    for (final variant in const [
      (name: 'canonical map order', reverseInputMapEntries: false),
      (name: 'reversed map order', reverseInputMapEntries: true),
    ]) {
      final fixtures = CombatReducerParityCharacterization.extend(
        AutoExploreReducerParityCharacterization.extend(
          MovementReducerParityCharacterization.extend(
            DiplomacyReducerParityCharacterization.extend(
              ResourceTradeReducerParityCharacterization.extend(
                ReducerParityCorpus.load(
                  repositoryRoot,
                  reverseInputMapEntries: variant.reverseInputMapEntries,
                ),
              ),
            ),
          ),
        ),
      );
      group(variant.name, () {
        for (final fixture in fixtures) {
          for (var run = 1; run <= _repeatCount; run++) {
            test('${fixture.id} run $run', () => _runFixture(fixture));
          }
        }
      });
    }
  });
}

Future<void> _runFixture(ReducerParityFixture fixture) async {
  final reducer = ServerCommandReducer(
    mapCatalog: _FixtureMapCatalog(fixture.mapData),
  );
  final snapshot = WireSnapshot(
    matchId: fixture.match.id,
    offset: 0,
    save: fixture.save.toJson(),
    state: fixture.state.toJson(),
  );
  final reduction = await _reducerDriver.reduce(
    reducer: reducer,
    match: fixture.match,
    wireSnapshot: snapshot,
    wireCommand: WireCommand(
      matchId: fixture.match.id,
      tick: fixture.tick,
      turn: fixture.save.turn,
      actorPlayerId: fixture.actorPlayerId,
      command: GameCommandSerializer.toJson(fixture.command),
    ),
    actorPlayerId: fixture.actorPlayerId,
    now: fixture.now,
  );

  expect(reduction.accepted, fixture.expectedAccepted);
  expect(reduction.reason, fixture.expectedReason);
  expect(reducerParityEvents(reduction.events), fixture.expectedEvents);

  if (fixture.expectedAccepted) {
    final nextSnapshot = reduction.nextSnapshot!;
    final expectedPrevious = _snapshotAdapter.toCanonical(
      save: fixture.save,
      state: fixture.state,
    );
    final expectedSaveBeforeTimestampUpdate = GameSave.fromJson({
      ...fixture.expectedSave,
      'savedAt': fixture.save.savedAt.toUtc().toIso8601String(),
    });
    final expectedBeforeTimestampUpdate = _snapshotAdapter.toCanonical(
      save: expectedSaveBeforeTimestampUpdate,
      state: PersistentGameState.fromJson(fixture.expectedState),
    );
    final expectedNext = expectedBeforeTimestampUpdate.copyWith(
      metadata: expectedBeforeTimestampUpdate.metadata.copyWith(
        savedAtUtc: fixture.now,
      ),
    );
    expect(
      _canonicalParitySnapshot(reduction.previousSnapshot),
      _canonicalParitySnapshot(expectedPrevious),
    );
    expect(
      _canonicalParitySnapshot(nextSnapshot),
      _canonicalParitySnapshot(expectedNext),
    );
    expect(reduction.outcome, isNotNull);
    expect(nextSnapshot.metadata.savedAtUtc, fixture.now);
  } else {
    final resultWire = reduction.wireSnapshot;
    final resultSave = GameSave.fromJson(resultWire.save);
    final resultState = PersistentGameState.fromJson(resultWire.state);
    expect(reduction.nextSnapshot, isNull);
    expect(reduction.outcome, isNull);
    expect(resultWire, same(snapshot));
    expect(resultWire.toJson(), snapshot.toJson());
    expect(reducerParitySave(resultSave), fixture.expectedSave);
    expect(resultState.toJson(), fixture.expectedState);
    expect(resultSave.savedAt, fixture.save.savedAt);
  }
}

Map<String, Object?> _canonicalParitySnapshot(CanonicalGameSnapshot snapshot) {
  final legacy = _snapshotAdapter.toLegacy(snapshot);
  return {
    'save': legacy.save.toJson(),
    'state': legacy.state.toJson(),
    'eventLogOffset': legacy.eventLogOffset,
  };
}

final class _FixtureMapCatalog implements MultiplayerMapCatalog {
  const _FixtureMapCatalog(this.mapData);

  final MapData mapData;

  @override
  Future<MapData> loadAssetMap(String mapName) async {
    if (mapName != mapData.mapName) {
      throw StateError('Unexpected parity map: $mapName.');
    }
    return MapDataCodec.fromJson(MapDataCodec.toJson(mapData));
  }
}
