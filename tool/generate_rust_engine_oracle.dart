import 'dart:convert';
import 'dart:io';

import 'package:aonw_core/domain.dart';

import '../test/support/reducer_parity_fixture.dart';
import '../test/support/reducer_parity_movement_characterization.dart';

const _reviewedFixtureIds = {
  'movement-adjacent-accepted',
  'movement-out-of-bounds-rejected',
  'movement-wrong-actor-rejected',
  'unit-action-cancel-orders-accepted',
  'unit-action-cancel-skipped-accepted',
  'unit-action-fortify-busy-rejected',
  'unit-action-fortify-unrelated-pending-accepted',
  'unit-action-skip-accepted',
  'unit-action-wrong-actor-rejected',
};

void main() {
  final root = Directory.current;
  final corpus = MovementReducerParityCharacterization.extend(
    ReducerParityCorpus.load(root),
  );
  final fixtures =
      corpus
          .where((fixture) {
            return _reviewedFixtureIds.contains(fixture.id) ||
                fixture.id.startsWith('movement-characterization-');
          })
          .toList(growable: false)
        ..sort((left, right) => left.id.compareTo(right.id));

  if (fixtures.length != 44) {
    throw StateError(
      'Expected 44 current Rust fixtures, got ${fixtures.length}.',
    );
  }

  final output = Directory('${root.path}/test/fixtures/reducer_parity_v2')
    ..createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  for (final fixture in fixtures) {
    final path = '${output.path}/${fixture.id}.json';
    File(path).writeAsStringSync('${encoder.convert(_encode(fixture))}\n');
  }
}

Map<String, Object?> _encode(ReducerParityFixture fixture) {
  return {
    'fixtureVersion': 2,
    'id': fixture.id,
    'family': fixture.family,
    'input': {
      'now': fixture.now.toUtc().toIso8601String(),
      'actorPlayerId': fixture.actorPlayerId,
      'tick': fixture.tick,
      'rulesetId': 'standard',
      'map': jsonDecode(WorldMapCodec.toJson(fixture.mapData)),
      'match': fixture.match.toJson(),
      'save': fixture.save.toJson(),
      'state': CanonicalGameSnapshotCodec.encodeDomainState(fixture.state),
      'command': DomainCommandCodec.toJson(fixture.command),
    },
    'expected': {
      'accepted': fixture.expectedAccepted,
      'reason': fixture.expectedReason,
      'save': fixture.expectedSave,
      'state': fixture.expectedState,
      'events': fixture.expectedEvents,
      'movementExecutions': fixture.expectedMovementExecutions ?? const [],
    },
  };
}
