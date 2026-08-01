import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _resignationPath =
    'server/lib/src/multiplayer/match_lifecycle_service_resignation.dart';

void main() {
  group('participant resignation engine integration', () {
    test('uses the system engine as the only authoritative mutation', () {
      final source = File(_resignationPath).readAsStringSync();

      expect(
        RegExp(r'GameEngine\(\)\.applySystem\(').allMatches(source),
        hasLength(1),
      );
      expect(source, contains('command: KickParticipant('));
      expect(source, contains('domain: nextSnapshot.domain'));
      expect(source, isNot(contains('transition.domain')));
      expect(source, isNot(contains('ParticipantResignationTransition.apply')));
    });

    test('validates, mutates, decides, and encodes in dependency order', () {
      final source = File(_resignationPath).readAsStringSync();
      final validated = source.indexOf('canonicalWithValidatedRoster(');
      final duplicateGuard = source.indexOf('.domain.isKicked(');
      final engine = source.indexOf('_snapshotAfterResignationKick(');
      final decision = source.indexOf(
        'ParticipantResignationTransition.resolve(',
      );
      final encoded = source.indexOf('.encodeCanonical(');

      expect(validated, greaterThanOrEqualTo(0));
      expect(duplicateGuard, greaterThan(validated));
      expect(engine, greaterThan(duplicateGuard));
      expect(decision, greaterThan(engine));
      expect(encoded, greaterThan(decision));
    });
  });
}
