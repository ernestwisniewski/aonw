import 'package:aonw_core/domain.dart';
import 'package:aonw_core/game/compatibility.dart';
import 'package:aonw_core/protocol.dart';

const _legacyGameSnapshotAdapter = LegacyGameSnapshotAdapter();
const _losslessMatchSnapshotCodec = LosslessMatchSnapshotCodec();

/// A lossless view of one authoritative snapshot from a running match.
///
/// The raw wire representation stays available so unchanged fields and absent
/// optional keys do not get materialized by a legacy/canonical round-trip.
final class DecodedRunningMatchSnapshot {
  DecodedRunningMatchSnapshot._({required this.wire});

  final WireSnapshot wire;

  int get eventLogOffset => wire.offset;

  late final GameSave save = GameSave.fromJson(wire.save);

  late final PersistentGameState state = PersistentGameState.fromJson(
    wire.state,
  );

  late final CanonicalGameSnapshot canonical = _losslessMatchSnapshotCodec
      .canonical(this);

  bool get hasSerializedTurnStartedAt {
    final runtimeState = wire.state['runtimeState'];
    return runtimeState is Map && runtimeState['turnStartedAt'] != null;
  }
}

/// Owns the single server compatibility seam between raw legacy snapshot
/// parts and the canonical snapshot.
///
/// Decoding remains lazy through [DecodedRunningMatchSnapshot]. Encoding
/// returns typed legacy parts only after a lossless canonical round-trip; the
/// running codec retains lifecycle and raw wire-preservation policy.
final class LosslessMatchSnapshotCodec {
  const LosslessMatchSnapshotCodec();

  DecodedRunningMatchSnapshot decode(WireSnapshot snapshot) {
    return DecodedRunningMatchSnapshot._(wire: snapshot);
  }

  CanonicalGameSnapshot canonical(DecodedRunningMatchSnapshot snapshot) {
    return _canonicalFromLegacyParts(
      save: snapshot.save,
      state: snapshot.state,
      eventLogOffset: snapshot.eventLogOffset,
    );
  }

  ({GameSave save, PersistentGameState state}) encodeCanonical(
    CanonicalGameSnapshot snapshot,
  ) {
    final legacy = _legacyGameSnapshotAdapter.toLegacy(snapshot);
    final represented = _canonicalFromLegacyParts(
      save: legacy.save,
      state: legacy.state,
      eventLogOffset: legacy.eventLogOffset,
    );
    if (represented != snapshot) {
      throw ArgumentError.value(
        snapshot,
        'snapshot',
        'Canonical snapshot cannot be represented losslessly by legacy '
            'save/state.',
      );
    }
    return (save: legacy.save, state: legacy.state);
  }
}

CanonicalGameSnapshot _canonicalFromLegacyParts({
  required GameSave save,
  required PersistentGameState state,
  required int eventLogOffset,
}) {
  return _legacyGameSnapshotAdapter.toCanonical(
    save: save,
    state: state,
    eventLogOffset: eventLogOffset,
  );
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
