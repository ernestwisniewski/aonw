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
