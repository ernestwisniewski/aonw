part of '../running_match_snapshot_codec_boundary_test.dart';

const _invalidCodecShapeFixture = '''
class DecodedRunningMatchSnapshot {
  DecodedRunningMatchSnapshot(this.wire);
  final WireSnapshot wire;
}

class RunningMatchSnapshotCodec {
  Object decode(WireMatch match, WireSnapshot snapshot) => Object();

  WireSnapshot encode({
    required DecodedRunningMatchSnapshot source,
    required GameSave save,
    PersistentGameState? state,
  }) => source.wire.copyWith(
    save: save.toJson(),
    state: state?.toJson(),
  );
}
''';

const _invalidDecodeFlowFixture = '''
final class DecodedRunningMatchSnapshot {
  const DecodedRunningMatchSnapshot({
    required this.wire,
    required this.save,
    required this.state,
  });

  final WireSnapshot wire;
  final GameSave save;
  final PersistentGameState state;
}

final class RunningMatchSnapshotCodec {
  DecodedRunningMatchSnapshot decode({
    required WireMatch match,
    required WireSnapshot snapshot,
  }) {
    final save = GameSave.fromJson(snapshot.save);
    final phase = snapshot.state['phase'];
    if (match.state != 'running' || phase == 'finished') {
      throw StateError('Match is not running.');
    }
    final state = PersistentGameState.fromJson(snapshot.state);
    return DecodedRunningMatchSnapshot(
      wire: snapshot,
      save: save,
      state: state,
    );
  }

  WireSnapshot encode(
    DecodedRunningMatchSnapshot source, {
    GameSave? save,
    PersistentGameState? state,
  }) => source.wire.copyWith(
    save: save?.toJson(),
    state: state?.toJson(),
  );
}
''';

const _invalidEagerDecodeFixture = '''
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

  late final GameSave save = _decodedSave ?? GameSave.fromJson(wire.save);
  late final PersistentGameState state =
      _decodedState ?? PersistentGameState.fromJson(wire.state);
}

final class RunningMatchSnapshotCodec {
  DecodedRunningMatchSnapshot decode({
    required WireMatch match,
    required WireSnapshot snapshot,
  }) {
    if (match.state != 'running') {
      throw StateError('Match is not running.');
    }
    return DecodedRunningMatchSnapshot._(
      wire: snapshot,
      decodedSave: GameSave.fromJson(snapshot.save),
      decodedState: PersistentGameState.fromJson(snapshot.state),
    );
  }

  WireSnapshot encode(
    DecodedRunningMatchSnapshot source, {
    GameSave? save,
    PersistentGameState? state,
  }) {
    if (save == null && state == null) return source.wire;
    return source.wire.copyWith(
      save: save?.toJson(),
      state: state?.toJson(),
    );
  }
}
''';

const _invalidHelperDecodeFixture = '''
final class DecodedRunningMatchSnapshot {
  DecodedRunningMatchSnapshot._({required this.wire});

  final WireSnapshot wire;
  late final GameSave save = GameSave.fromJson(wire.save);
  late final PersistentGameState state =
      PersistentGameState.fromJson(wire.state);
}

final class RunningMatchSnapshotCodec {
  DecodedRunningMatchSnapshot decode({
    required WireMatch match,
    required WireSnapshot snapshot,
  }) {
    if (match.state != 'running') {
      throw StateError('Match is not running.');
    }
    parseLegacySnapshot(snapshot);
    return DecodedRunningMatchSnapshot._(wire: snapshot);
  }

  WireSnapshot encode(
    DecodedRunningMatchSnapshot source, {
    GameSave? save,
    PersistentGameState? state,
  }) {
    if (save == null && state == null) return source.wire;
    return source.wire.copyWith(
      save: save?.toJson(),
      state: state?.toJson(),
    );
  }
}
''';

const _invalidEncodeFlowFixture = '''
final class DecodedRunningMatchSnapshot {
  const DecodedRunningMatchSnapshot({
    required this.wire,
    required this.save,
    required this.state,
  });

  final WireSnapshot wire;
  final GameSave save;
  final PersistentGameState state;

  CanonicalGameSnapshot toCanonical() => throw UnimplementedError();
}

final class RunningMatchSnapshotCodec {
  DecodedRunningMatchSnapshot decode({
    required WireMatch match,
    required WireSnapshot snapshot,
  }) {
    if (match.state != 'running') {
      throw StateError('Match is not running.');
    }
    return DecodedRunningMatchSnapshot(
      wire: snapshot,
      save: GameSave.fromJson(snapshot.save),
      state: PersistentGameState.fromJson(snapshot.state),
    );
  }

  WireSnapshot encode(
    DecodedRunningMatchSnapshot source, {
    GameSave? save,
    PersistentGameState? state,
  }) {
    final canonical = source.toCanonical();
    final legacy = adapter.toLegacy(canonical);
    return WireSnapshot(
      matchId: source.wire.matchId,
      offset: source.wire.offset,
      save: (save ?? legacy.save).toJson(),
      state: (state ?? legacy.state).toJson(),
    );
  }
}
''';

const _invalidCanonicalEncodeFlowFixture = '''
final class RunningMatchSnapshotCodec {
  WireSnapshot encodeCanonical(
    DecodedRunningMatchSnapshot source,
    CanonicalGameSnapshot next,
  ) {
    final legacy = adapter.toLegacy(next);
    return source.wire.copyWith(
      save: legacy.save.toJson(),
      state: legacy.state.toJson(),
    );
  }
}
''';

const _invalidLosslessHelperFixture = '''
final class DecodedRunningMatchSnapshot {
  DecodedRunningMatchSnapshot._({required this.wire});

  final WireSnapshot wire;
  late final GameSave save = GameSave.fromJson(wire.save);
  late final PersistentGameState state =
      PersistentGameState.fromJson(wire.state);
}

final class LosslessMatchSnapshotCodec {
  DecodedRunningMatchSnapshot decode(WireSnapshot snapshot) {
    inspectSnapshot(snapshot);
    return DecodedRunningMatchSnapshot._(wire: snapshot);
  }
}
''';

const _invalidLosslessTearOffFixture = '''
final class DecodedRunningMatchSnapshot {
  DecodedRunningMatchSnapshot._({required this.wire});

  final WireSnapshot wire;
  late final GameSave save = GameSave.fromJson(wire.save);
  late final PersistentGameState state =
      PersistentGameState.fromJson(wire.state);
}

final class LosslessMatchSnapshotCodec {
  DecodedRunningMatchSnapshot decode(WireSnapshot snapshot) {
    final make = DecodedRunningMatchSnapshot._;
    return make(wire: snapshot);
  }
}
''';

const _invalidLosslessConversionDecoyFixture = '''
const _legacyGameSnapshotAdapter = LegacyGameSnapshotAdapter();

final class LosslessMatchSnapshotCodec {
  CanonicalGameSnapshot canonical(DecodedRunningMatchSnapshot snapshot) {
    return canonicalFromAdapter(snapshot);
  }

  ({GameSave save, PersistentGameState state}) encodeCanonical(
    CanonicalGameSnapshot snapshot,
  ) {
    final legacy = encodeWithAdapter(snapshot);
    return (save: legacy.save, state: legacy.state);
  }
}

CanonicalGameSnapshot canonicalFromAdapter(
  DecodedRunningMatchSnapshot snapshot,
) {
  return _canonicalFromLegacyParts(
    save: snapshot.save,
    state: snapshot.state,
    eventLogOffset: snapshot.eventLogOffset,
  );
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

({GameSave save, PersistentGameState state}) encodeWithAdapter(
  CanonicalGameSnapshot snapshot,
) {
  final legacy = _legacyGameSnapshotAdapter.toLegacy(snapshot);
  final represented = _canonicalFromLegacyParts(
    save: legacy.save,
    state: legacy.state,
    eventLogOffset: legacy.eventLogOffset,
  );
  if (represented != snapshot) {
    throw ArgumentError.value(snapshot, 'snapshot', 'not lossless');
  }
  return (save: legacy.save, state: legacy.state);
}
''';

const _invalidLateEventLogOffsetGuardFixture = '''
final class RunningMatchSnapshotCodec {
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
          ) &&
          _hasCompleteTurnStateRoster(next),
    );
    _requireRepresentableRunningTurnStart(next);
    final legacy = _losslessMatchSnapshotCodec.encodeCanonical(next);
    _requireUnchangedEventLogOffset(previous, next);
    return source.wire;
  }
}
''';

const _invalidRawPreservationDecoyFixture = '''
WireSnapshot _encodeCanonicalParts(
  DecodedRunningMatchSnapshot source, {
  GameSave? save,
  PersistentGameState? state,
}) {
  if (save == null && state == null) return source.wire;
  return source.wire.copyWith(
    save: save?.toJson(),
    state: state?.toJson(),
  );
}

Map<String, dynamic> _preserveRawFields(
  Map<String, dynamic> candidate,
  Map<String, dynamic> raw,
  Set<String> fields,
) {
  final preserved = Map<String, dynamic>.from(candidate);
  for (final field in fields) {
    preserved[field] = raw[field];
  }
  return preserved;
}

WireSnapshot _correctCanonicalParts(
  DecodedRunningMatchSnapshot source, {
  GameSave? save,
  PersistentGameState? state,
}) {
  if (save == null && state == null) return source.wire;
  return source.wire.copyWith(
    save: save == null
        ? null
        : _preserveRawFields(save.toJson(), source.wire.save, const {
            'players',
          }),
    state: state == null
        ? null
        : _preserveRawFields(state.toJson(), source.wire.state, const {
            'playerColors',
            'playerCountries',
          }),
  );
}

Map<String, dynamic> _correctRawFields(
  Map<String, dynamic> candidate,
  Map<String, dynamic> raw,
  Set<String> fields,
) {
  final preserved = Map<String, dynamic>.from(candidate);
  for (final field in fields) {
    if (raw.containsKey(field)) {
      preserved[field] = raw[field];
    } else {
      preserved.remove(field);
    }
  }
  return preserved;
}
''';
