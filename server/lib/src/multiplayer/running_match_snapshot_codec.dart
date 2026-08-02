import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/lossless_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/player_match_wire_schema_guard.dart';
import 'package:aonw_server/src/multiplayer/wire_player_domain_mapper.dart';

const LosslessMatchSnapshotCodec _losslessMatchSnapshotCodec =
    LosslessMatchSnapshotCodec();
const PlayerMatchWireSchemaGuard _playerMatchWireSchemaGuard =
    PlayerMatchWireSchemaGuard();

/// Decodes and encodes only current-version running snapshots.
final class RunningMatchSnapshotCodec {
  const RunningMatchSnapshotCodec();

  DecodedRunningMatchSnapshot decode({
    required WireMatch match,
    required WireSnapshot snapshot,
  }) {
    if (match.state != 'running') {
      throw StateError(
        'Cannot decode a ${match.state} match as a running snapshot.',
      );
    }
    return _losslessMatchSnapshotCodec.decode(snapshot);
  }

  /// Materializes canonical state only when its persisted identity roster
  /// exactly matches the authoritative transport roster.
  ///
  /// Turn state may be sparse, but it may never introduce an identity outside
  /// that roster.
  CanonicalGameSnapshot canonicalWithValidatedRoster(
    DecodedRunningMatchSnapshot source, {
    required WireMatch match,
  }) {
    if (match.state != 'running') {
      throw StateError(
        'Cannot validate a ${match.state} match as a running snapshot.',
      );
    }
    final expectedParticipants = _domainParticipants(match);
    final expectedColors = {
      for (final player in expectedParticipants) player.id: player.colorValue,
    };
    final expectedCountries = {
      for (final player in expectedParticipants) player.id: player.country,
    };
    final expectedPlayerIds = expectedColors.keys.toSet();
    final save = source.save;
    final state = source.wire.state;
    final canonical = source.canonical;
    _playerMatchWireSchemaGuard.validateCanonicalRoster(
      save: save,
      state: state,
      canonical: canonical,
    );
    _requireMatchingRoster(source.wire.matchId == match.id);
    _requireMatchingRoster(canonical.metadata.id == match.id);
    _requireMatchingRoster(
      _sameOrderedPlayers(save.players, expectedParticipants),
    );
    _requireMatchingRoster(
      _sameOrderedPlayers(canonical.domain.participants, expectedParticipants),
    );
    _requireMatchingRoster(_sameRawMap(state['playerColors'], expectedColors));
    _requireMatchingRoster(
      _sameRawMap(
        state['playerCountries'],
        expectedCountries.map(
          (playerId, country) => MapEntry(playerId, country.name),
        ),
      ),
    );
    _requireMatchingRoster(
      save.playerStates.keys.every(expectedPlayerIds.contains),
    );
    return canonical;
  }

  /// Encodes a canonical initial match.
  WireSnapshot encodeInitial({
    required WireMatch match,
    required CanonicalGameSnapshot snapshot,
  }) {
    if (match.state != 'running') {
      throw StateError(
        'Cannot encode a ${match.state} match as an initial running snapshot.',
      );
    }
    if (match.id != snapshot.metadata.id) {
      throw ArgumentError.value(
        snapshot.metadata.id,
        'snapshot',
        'Snapshot metadata id must match the running match id.',
      );
    }
    if (snapshot.eventLogOffset != 0) {
      throw ArgumentError.value(
        snapshot.eventLogOffset,
        'snapshot',
        'An initial snapshot must have event offset zero.',
      );
    }
    if (snapshot.domain.turnStartedAt != snapshot.metadata.savedAtUtc) {
      throw ArgumentError.value(
        snapshot.domain.turnStartedAt,
        'snapshot',
        'Initial turn start must match the saved-at timestamp.',
      );
    }
    final expectedParticipants = _domainParticipants(match);
    final expectedPlayerIds = {
      for (final player in expectedParticipants) player.id,
    };
    _requireMatchingRoster(
      _sameOrderedPlayers(snapshot.domain.participants, expectedParticipants) &&
          _sameSet(
            snapshot.domain.turnStatesByPlayerId.keys.toSet(),
            expectedPlayerIds,
          ),
    );
    final encoded = _losslessMatchSnapshotCodec.encodeCanonical(snapshot);
    return WireSnapshot(
      matchId: snapshot.metadata.id,
      offset: snapshot.eventLogOffset,
      save: encoded.save,
      state: encoded.state,
    );
  }

  /// Encodes one canonical current-version transition.
  WireSnapshot encodeCanonical(
    DecodedRunningMatchSnapshot source,
    CanonicalGameSnapshot next,
  ) {
    final previous = source.canonical;
    if (next == previous) return source.wire;
    _requireMatchingRoster(
      _sameOrderedPlayers(
        next.domain.participants,
        previous.domain.participants,
      ),
    );
    _requireUnchangedEventLogOffset(previous, next);
    _requireRepresentableRunningTurnStart(next);

    final encoded = _losslessMatchSnapshotCodec.encodeCanonical(next);
    return source.wire.copyWith(
      save: _jsonEquals(encoded.save, source.wire.save)
          ? source.wire.save
          : encoded.save,
      state: _jsonEquals(encoded.state, source.wire.state)
          ? source.wire.state
          : encoded.state,
    );
  }
}

bool _jsonEquals(Object? left, Object? right) {
  if (identical(left, right) || left == right) return true;
  if (left is Map<Object?, Object?> && right is Map<Object?, Object?>) {
    return _jsonMapsEqual(left, right);
  }
  if (left is List<Object?> && right is List<Object?>) {
    return _jsonListsEqual(left, right);
  }
  return false;
}

bool _jsonMapsEqual(Map<Object?, Object?> left, Map<Object?, Object?> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) ||
        !_jsonEquals(entry.value, right[entry.key])) {
      return false;
    }
  }
  return true;
}

bool _jsonListsEqual(List<Object?> left, List<Object?> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (!_jsonEquals(left[index], right[index])) return false;
  }
  return true;
}

bool _sameOrderedPlayers(List<Player> actual, List<Player> expected) {
  if (actual.length != expected.length) return false;
  for (var index = 0; index < actual.length; index += 1) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}

List<Player> _domainParticipants(WireMatch match) => [
  for (final player in match.players) domainPlayerFromWire(player),
];

bool _sameMap<K, V>(Map<K, V> actual, Map<K, V> expected) {
  if (actual.length != expected.length) return false;
  for (final entry in expected.entries) {
    if (actual[entry.key] != entry.value) return false;
  }
  return true;
}

bool _sameRawMap<K, V>(Object? raw, Map<K, V> expected) {
  if (raw is! Map<Object?, Object?>) return expected.isEmpty;
  return _sameMap(Map<K, V>.from(raw), expected);
}

bool _sameSet<T>(Set<T> actual, Set<T> expected) {
  return actual.length == expected.length && actual.containsAll(expected);
}

void _requireMatchingRoster(bool matches) {
  if (matches) return;
  throw const FormatException(
    'Running snapshot roster must exactly match authoritative players.',
  );
}

void _requireRepresentableRunningTurnStart(CanonicalGameSnapshot snapshot) {
  if (snapshot.domain.turnStartedAt != null) return;
  throw ArgumentError.value(
    snapshot.domain.turnStartedAt,
    'next',
    'A running snapshot must have a turn start timestamp.',
  );
}

void _requireUnchangedEventLogOffset(
  CanonicalGameSnapshot previous,
  CanonicalGameSnapshot next,
) {
  if (next.eventLogOffset == previous.eventLogOffset) return;
  throw ArgumentError.value(
    next.eventLogOffset,
    'next',
    'Running snapshot event offset is owned by the persistence transaction.',
  );
}
