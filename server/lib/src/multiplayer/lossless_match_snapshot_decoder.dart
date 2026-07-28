import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/protocol.dart';

const _losslessMatchSnapshotAdapter = LegacyGameSnapshotAdapter();

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

  late final CanonicalGameSnapshot canonical = _losslessMatchSnapshotAdapter
      .toCanonical(save: save, state: state, eventLogOffset: eventLogOffset);

  bool get hasSerializedTurnStartedAt {
    final runtimeState = wire.state['runtimeState'];
    return runtimeState is Map && runtimeState['turnStartedAt'] != null;
  }
}

/// Parses a raw match snapshot without inferring or validating its lifecycle.
///
/// Callers that require a running match must use `RunningMatchSnapshotCodec`
/// instead. This boundary exists for already-classified server messages whose
/// wire schema is validated separately before parsing.
final class LosslessMatchSnapshotDecoder {
  const LosslessMatchSnapshotDecoder();

  DecodedRunningMatchSnapshot decode(WireSnapshot snapshot) {
    return DecodedRunningMatchSnapshot._(wire: snapshot);
  }
}
