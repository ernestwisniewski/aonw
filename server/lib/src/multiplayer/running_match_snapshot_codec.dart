import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/protocol.dart';

import 'package:aonw_server/src/multiplayer/lossless_match_snapshot_decoder.dart';
import 'package:aonw_server/src/multiplayer/player_match_wire_schema_guard.dart';
import 'package:aonw_server/src/multiplayer/wire_player_domain_mapper.dart';

export 'package:aonw_server/src/multiplayer/lossless_match_snapshot_decoder.dart'
    show DecodedRunningMatchSnapshot;

const _runningMatchSnapshotAdapter = LegacyGameSnapshotAdapter();
const LosslessMatchSnapshotDecoder _losslessMatchSnapshotDecoder =
    LosslessMatchSnapshotDecoder();
const PlayerMatchWireSchemaGuard _playerMatchWireSchemaGuard =
    PlayerMatchWireSchemaGuard();

/// Decodes only running snapshots and preserves their original wire envelope.
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
    return _losslessMatchSnapshotDecoder.decode(snapshot);
  }

  /// Materializes canonical state only when its persisted roster is complete
  /// and exactly matches the authoritative transport roster.
  CanonicalGameSnapshot canonicalWithValidatedRoster(
    DecodedRunningMatchSnapshot source, {
    required WireMatch match,
  }) {
    if (match.state != 'running') {
      throw StateError(
        'Cannot validate a ${match.state} match as a running snapshot.',
      );
    }
    final expectedParticipants = [
      for (final player in match.players) domainPlayerFromWire(player),
    ];
    final expectedColors = {
      for (final player in expectedParticipants) player.id: player.colorValue,
    };
    final expectedCountries = {
      for (final player in expectedParticipants) player.id: player.country,
    };
    final expectedPlayerIds = expectedColors.keys.toSet();
    final save = source.save;
    final state = source.state;
    _playerMatchWireSchemaGuard.validateCanonicalRoster(
      save: save,
      state: state,
    );
    final canonical = source.canonical;
    _requireMatchingRoster(source.wire.matchId == match.id);
    _requireMatchingRoster(canonical.metadata.id == match.id);
    _requireMatchingRoster(
      _sameOrderedPlayers(save.players, expectedParticipants),
    );
    _requireMatchingRoster(
      _sameOrderedPlayers(canonical.domain.participants, expectedParticipants),
    );
    _requireMatchingRoster(_sameMap(state.playerColors, expectedColors));
    _requireMatchingRoster(_sameMap(state.playerCountries, expectedCountries));
    _requireMatchingRoster(
      _sameSet(save.playerStates.keys.toSet(), expectedPlayerIds),
    );
    return canonical;
  }

  WireSnapshot encode(
    DecodedRunningMatchSnapshot source, {
    GameSave? save,
    PersistentGameState? state,
  }) {
    if (save == null && state == null) return source.wire;
    return source.wire.copyWith(save: save?.toJson(), state: state?.toJson());
  }

  /// Encodes a canonical initial match while retaining the historical wire.
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
    if (snapshot.session.turnStartedAt != snapshot.metadata.savedAtUtc) {
      throw ArgumentError.value(
        snapshot.session.turnStartedAt,
        'snapshot',
        'Initial turn start must match the saved-at timestamp.',
      );
    }
    final legacy = _legacySnapshotParts(snapshot);
    final state = _withoutInitialTurnStartedAt(legacy.state);
    return WireSnapshot(
      matchId: snapshot.metadata.id,
      offset: snapshot.eventLogOffset,
      save: legacy.save.toJson(),
      state: state.toJson(),
    );
  }

  /// Encodes one canonical transition while preserving unchanged raw halves.
  ///
  /// Compatibility conversion is intentionally confined to this wire I/O
  /// boundary. An absent legacy `turnStartedAt` remains absent unless the
  /// canonical transition changed its semantic value.
  WireSnapshot encodeCanonical(
    DecodedRunningMatchSnapshot source,
    CanonicalGameSnapshot next,
  ) {
    final previous = source.canonical;
    if (next == previous) return source.wire;

    final legacy = _legacySnapshotParts(next);
    final nextState = _preserveImplicitTurnStartedAt(
      source: source,
      previous: previous,
      next: next,
      state: legacy.state,
    );
    return encode(
      source,
      save: legacy.save == source.save ? null : legacy.save,
      state: nextState == source.state ? null : nextState,
    );
  }
}

LegacyGameSnapshotParts _legacySnapshotParts(CanonicalGameSnapshot snapshot) {
  return _runningMatchSnapshotAdapter.toLegacy(snapshot);
}

PersistentGameState _withoutInitialTurnStartedAt(PersistentGameState state) {
  if (state.runtimeState.turnStartedAt == null) return state;
  return state.copyWith(
    runtimeState: state.runtimeState.copyWith(turnStartedAt: null),
  );
}

bool _sameOrderedPlayers(List<Player> actual, List<Player> expected) {
  if (actual.length != expected.length) return false;
  for (var index = 0; index < actual.length; index += 1) {
    if (actual[index] != expected[index]) return false;
  }
  return true;
}

bool _sameMap<K, V>(Map<K, V> actual, Map<K, V> expected) {
  if (actual.length != expected.length) return false;
  for (final entry in expected.entries) {
    if (actual[entry.key] != entry.value) return false;
  }
  return true;
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

PersistentGameState _preserveImplicitTurnStartedAt({
  required DecodedRunningMatchSnapshot source,
  required CanonicalGameSnapshot previous,
  required CanonicalGameSnapshot next,
  required PersistentGameState state,
}) {
  if (source.hasSerializedTurnStartedAt ||
      next.session.turnStartedAt != previous.session.turnStartedAt ||
      state.runtimeState.turnStartedAt == null) {
    return state;
  }
  return state.copyWith(
    runtimeState: state.runtimeState.copyWith(turnStartedAt: null),
  );
}
