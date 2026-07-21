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

  /// Creates a fresh semantic view without marking the raw wire as changed.
  /// Pass [state] explicitly to [RunningMatchSnapshotCodec.encode] to persist it.
  DecodedRunningMatchSnapshot withState(PersistentGameState state) {
    return DecodedRunningMatchSnapshot._(
      wire: wire,
      decodedSave: save,
      decodedState: state,
    );
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
}
