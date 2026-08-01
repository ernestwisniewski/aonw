import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _factoryPath =
    'server/lib/src/multiplayer/initial_multiplayer_snapshot_factory.dart';
const _lifecyclePath =
    'server/lib/src/multiplayer/match_lifecycle_service.dart';
const _codecPath =
    'server/lib/src/multiplayer/running_match_snapshot_codec.dart';

void main() {
  group('initial canonical multiplayer snapshot', () {
    test('factory builds DomainState and CanonicalGameSnapshot directly', () {
      final source = File(_factoryPath).readAsStringSync();

      expect(source, contains('Future<CanonicalGameSnapshot> create('));
      expect(
        RegExp(r'DomainState\.snapshot\(').allMatches(source),
        hasLength(1),
      );
      expect(
        RegExp(r'CanonicalGameSnapshot\.snapshot\(').allMatches(source),
        hasLength(1),
      );
      expect(source, isNot(contains('WireSnapshot')));
      expect(source, isNot(contains('GameSave(')));
      expect(source, isNot(contains('toLegacy')));
      expect(source, isNot(contains('toCanonical')));
    });

    test('lifecycle maps, builds, and encodes once in order', () {
      final source = File(_lifecyclePath).readAsStringSync();
      final map = source.indexOf('.map(domainPlayerFromWire)');
      final create = source.indexOf('snapshotFactory.create(');
      final encode = source.indexOf(
        '_runningMatchSnapshotCodec.encodeInitial(',
      );

      expect(map, greaterThanOrEqualTo(0));
      expect(create, greaterThan(map));
      expect(encode, greaterThan(create));
    });

    test('encoder validates canonical id, offset, turn start, and roster', () {
      final source = File(_codecPath).readAsStringSync();

      expect(source, contains("match.state != 'running'"));
      expect(source, contains('match.id != snapshot.metadata.id'));
      expect(source, contains('snapshot.eventLogOffset != 0'));
      expect(
        source,
        contains(
          'snapshot.domain.turnStartedAt != snapshot.metadata.savedAtUtc',
        ),
      );
      expect(source, contains('_sameOrderedPlayers('));
      expect(source, contains('_losslessMatchSnapshotCodec.encodeCanonical('));
    });
  });
}
