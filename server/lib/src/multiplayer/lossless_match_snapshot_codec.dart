import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';

const _losslessMatchSnapshotCodec = LosslessMatchSnapshotCodec();

/// A decoded view of one readable authoritative running snapshot.
final class DecodedRunningMatchSnapshot {
  DecodedRunningMatchSnapshot._({required this.wire});

  final WireSnapshot wire;

  int get eventLogOffset => wire.offset;

  late final GameSave save = GameSave.fromJson(wire.save);

  late final CanonicalGameSnapshot canonical = _losslessMatchSnapshotCodec
      .canonical(this);
}

/// Maps a readable wire snapshot to and from the canonical domain envelope.
final class LosslessMatchSnapshotCodec {
  const LosslessMatchSnapshotCodec();

  DecodedRunningMatchSnapshot decode(WireSnapshot snapshot) {
    return DecodedRunningMatchSnapshot._(wire: snapshot);
  }

  CanonicalGameSnapshot canonical(DecodedRunningMatchSnapshot snapshot) {
    return CanonicalGameSnapshotCodec.decode(
      CanonicalGameSnapshotData(
        save: snapshot.wire.save,
        state: snapshot.wire.state,
        eventLogOffset: snapshot.eventLogOffset,
      ),
    );
  }

  CanonicalGameSnapshotData encodeCanonical(CanonicalGameSnapshot snapshot) {
    final encoded = CanonicalGameSnapshotCodec.encode(snapshot);
    final represented = CanonicalGameSnapshotCodec.decode(encoded);
    if (represented != snapshot) {
      throw ArgumentError.value(
        snapshot,
        'snapshot',
        'Canonical snapshot cannot be represented losslessly by the current '
            'wire schema.',
      );
    }
    return encoded;
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
    return _losslessMatchSnapshotCodec.decode(snapshot);
  }
}
