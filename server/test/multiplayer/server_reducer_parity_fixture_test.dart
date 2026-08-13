import 'dart:io';

import 'package:aonw_core/domain.dart';
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
    state: CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
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
      command: DomainCommandCodec.toJson(fixture.command),
    ),
    actorPlayerId: fixture.actorPlayerId,
    now: fixture.now,
  );

  expect(reduction.accepted, fixture.expectedAccepted);
  expect(reduction.reason, fixture.expectedReason);
  expect(reducerParityEvents(reduction.events), fixture.expectedEvents);
  if (fixture.expectedMovementExecutions case final expected?) {
    expect(
      reducerParityMovementExecutions(reduction.movementExecutions),
      expected,
    );
  }

  if (fixture.expectedAccepted) {
    final nextSnapshot = reduction.nextSnapshot!;
    final expectedPrevious = _canonical(
      save: fixture.save,
      state: fixture.state,
    );
    final expectedSaveBeforeTimestampUpdate = GameSave.fromJson({
      ...fixture.expectedSave,
      'savedAt': fixture.save.savedAt.toUtc().toIso8601String(),
    });
    final expectedBeforeTimestampUpdate = _canonical(
      save: expectedSaveBeforeTimestampUpdate,
      state: CanonicalGameSnapshotCodec.decodeDomainState(
        fixture.expectedState,
      ),
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
    final resultState = CanonicalGameSnapshotCodec.decodeDomainState(
      resultWire.state,
    );
    expect(reduction.nextSnapshot, isNull);
    expect(reduction.outcome, isNull);
    expect(resultWire, same(snapshot));
    expect(resultWire.toJson(), snapshot.toJson());
    expect(reducerParitySave(resultSave), fixture.expectedSave);
    expect(
      CanonicalGameSnapshotCodec.encodeDomainState(resultState),
      fixture.expectedState,
    );
    expect(resultSave.savedAt, fixture.save.savedAt);
  }
}

Map<String, Object?> _canonicalParitySnapshot(CanonicalGameSnapshot snapshot) {
  final encoded = CanonicalGameSnapshotCodec.encode(snapshot);
  return {
    'save': encoded.save,
    'state': encoded.state,
    'eventLogOffset': encoded.eventLogOffset,
  };
}

CanonicalGameSnapshot _canonical({
  required GameSave save,
  required DomainState state,
  int eventLogOffset = 0,
}) {
  return CanonicalGameSnapshotCodec.decode(
    CanonicalGameSnapshotData(
      save: save.toJson(),
      state: CanonicalGameSnapshotCodec.encodeDomainState(state),
      eventLogOffset: eventLogOffset,
    ),
  );
}

final class _FixtureMapCatalog implements MultiplayerMapCatalog {
  const _FixtureMapCatalog(this.mapData);

  final WorldMap mapData;

  @override
  Future<WorldMap> loadAssetMap(String mapName) async {
    if (mapName != mapData.mapName) {
      throw StateError('Unexpected parity map: $mapName.');
    }
    return WorldMapCodec.fromJson(WorldMapCodec.toJson(mapData));
  }
}
