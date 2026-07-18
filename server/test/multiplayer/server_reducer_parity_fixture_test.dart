import 'dart:io';

import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';
import 'package:test/test.dart';

import '../../../test/support/reducer_parity_fixture.dart';

const _repeatCount = 3;

void main() {
  final repositoryRoot = Directory.current.parent;
  group('server reducer parity fixtures', () {
    for (final variant in const [
      (name: 'canonical map order', reverseInputMapEntries: false),
      (name: 'reversed map order', reverseInputMapEntries: true),
    ]) {
      final fixtures = ReducerParityCorpus.load(
        repositoryRoot,
        reverseInputMapEntries: variant.reverseInputMapEntries,
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
  final reduction = await reducer.reduce(
    match: fixture.match,
    snapshot: snapshot,
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

  final resultSave = GameSave.fromJson(reduction.snapshot.save);
  final resultState = PersistentGameState.fromJson(reduction.snapshot.state);
  expect(reducerParitySave(resultSave), fixture.expectedSave);
  expect(resultState.toJson(), fixture.expectedState);
  if (fixture.expectedAccepted) {
    expect(reduction.turn, fixture.expectedSave['turn']);
    expect(reduction.previousState?.toJson(), fixture.state.toJson());
    expect(reduction.state?.toJson(), fixture.expectedState);
    expect(reduction.outcome, isNotNull);
    expect(resultSave.savedAt, fixture.now);
  } else {
    expect(reduction.snapshot, same(snapshot));
    expect(reduction.turn, isNull);
    expect(reduction.previousState, isNull);
    expect(reduction.state, isNull);
    expect(reduction.outcome, isNull);
    expect(reduction.snapshot.toJson(), snapshot.toJson());
    expect(resultSave.savedAt, fixture.save.savedAt);
  }
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
