part of '../running_match_snapshot_codec_test.dart';

void _registerRunningMatchSnapshotCodecTransitionTests(
  RunningMatchSnapshotCodec codec,
) {
  group('RunningMatchSnapshotCodec canonical transitions', () {
    test('returns the raw snapshot for a semantic no-op', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );

      expect(
        codec.encodeCanonical(decoded, decoded.canonical),
        same(fixture.wire),
      );
    });

    test('metadata-only savedAt change reuses the stable domain encoding', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        metadata: decoded.canonical.metadata.copyWith(
          savedAtUtc: decoded.canonical.metadata.savedAtUtc.add(
            const Duration(seconds: 1),
          ),
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(encoded.state, same(fixture.wire.state));
      expect(encoded.save, isNot(same(fixture.wire.save)));
      expect(
        (encoded.state['lifecycle']! as Map)['turnStartedAt'],
        fixture.save.savedAt.toIso8601String(),
      );
      expect(
        codec.decode(match: fixture.match, snapshot: encoded).canonical,
        next,
      );
    });

    test('domain-only change preserves raw save and explicit turn start', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        domain: decoded.canonical.domain.copyWith(
          playerGold: const {'player-1': 17},
        ),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(encoded.save, same(fixture.wire.save));
      expect(encoded.state['playerGold'], const {'player-1': 17});
      expect(
        (encoded.state['lifecycle']! as Map)['turnStartedAt'],
        fixture.save.savedAt.toIso8601String(),
      );
    });

    test('writes a changed turnStartedAt', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final startedAt = fixture.save.savedAt.add(const Duration(minutes: 1));
      final next = decoded.canonical.copyWith(
        domain: decoded.canonical.domain.copyWith(turnStartedAt: startedAt),
      );

      final encoded = codec.encodeCanonical(decoded, next);

      expect(
        (encoded.state['lifecycle']! as Map)['turnStartedAt'],
        startedAt.toIso8601String(),
      );
    });

    test('rejects a running snapshot without a turn start', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        domain: decoded.canonical.domain.copyWith(turnStartedAt: null),
      );

      expect(() => codec.encodeCanonical(decoded, next), throwsArgumentError);
    });

    test('rejects an event offset owned by the persistence transaction', () {
      final fixture = _fixture();
      final decoded = codec.decode(
        match: fixture.match,
        snapshot: fixture.wire,
      );
      final next = decoded.canonical.copyWith(
        eventLogOffset: decoded.eventLogOffset + 1,
      );

      expect(() => codec.encodeCanonical(decoded, next), throwsArgumentError);
    });
  });
}
