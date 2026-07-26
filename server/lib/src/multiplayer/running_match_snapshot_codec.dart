import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/protocol.dart';

const _runningMatchSnapshotAdapter = LegacyGameSnapshotAdapter();

/// A lossless view of one authoritative snapshot from a running match.
///
/// The raw wire representation stays available so unchanged fields and absent
/// optional keys do not get materialized by a legacy/canonical round-trip.
final class DecodedRunningMatchSnapshot {
  DecodedRunningMatchSnapshot._({
    required this.wire,
    GameSave? decodedSave,
    PersistentGameState? decodedState,
  }) : _decodedSave = decodedSave,
       _decodedState = decodedState;

  final WireSnapshot wire;
  final GameSave? _decodedSave;
  final PersistentGameState? _decodedState;

  int get eventLogOffset => wire.offset;

  late final GameSave save = _decodedSave ?? GameSave.fromJson(wire.save);

  late final PersistentGameState state =
      _decodedState ?? PersistentGameState.fromJson(wire.state);

  late final CanonicalGameSnapshot canonical = _runningMatchSnapshotAdapter
      .toCanonical(save: save, state: state, eventLogOffset: eventLogOffset);

  bool get hadExplicitTurnStartedAt {
    final runtimeState = wire.state['runtimeState'];
    return runtimeState is Map && runtimeState.containsKey('turnStartedAt');
  }
}

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
    return DecodedRunningMatchSnapshot._(wire: snapshot);
  }

  WireSnapshot encode(
    DecodedRunningMatchSnapshot source, {
    GameSave? save,
    PersistentGameState? state,
  }) {
    if (save == null && state == null) return source.wire;
    return source.wire.copyWith(save: save?.toJson(), state: state?.toJson());
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

    final legacy = _runningMatchSnapshotAdapter.toLegacy(next);
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

PersistentGameState _preserveImplicitTurnStartedAt({
  required DecodedRunningMatchSnapshot source,
  required CanonicalGameSnapshot previous,
  required CanonicalGameSnapshot next,
  required PersistentGameState state,
}) {
  if (source.hadExplicitTurnStartedAt ||
      next.session.turnStartedAt != previous.session.turnStartedAt ||
      state.runtimeState.turnStartedAt == null) {
    return state;
  }
  return state.copyWith(
    runtimeState: state.runtimeState.copyWith(turnStartedAt: null),
  );
}
