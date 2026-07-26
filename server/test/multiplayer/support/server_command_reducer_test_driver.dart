import 'package:aonw_core/domain.dart';
import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/multiplayer/running_match_snapshot_codec.dart';
import 'package:aonw_server/src/multiplayer/server_command_reducer.dart';

final class ServerCommandReducerTestDriver {
  const ServerCommandReducerTestDriver();

  static const _codec = RunningMatchSnapshotCodec();

  Future<ServerCommandTestReduction> reduce({
    required ServerCommandReducer reducer,
    required WireMatch match,
    required WireSnapshot wireSnapshot,
    required WireCommand wireCommand,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    final decoded = _codec.decode(match: match, snapshot: wireSnapshot);
    final reduction = await reducer.reduce(
      match: match,
      snapshot: decoded.canonical,
      wireCommand: wireCommand,
      actorPlayerId: actorPlayerId,
      now: now,
    );
    return ServerCommandTestReduction._(decoded: decoded, reduction: reduction);
  }

  Future<ServerCommandTestReduction> reduceTimedOutTurn({
    required ServerCommandReducer reducer,
    required WireMatch match,
    required WireSnapshot wireSnapshot,
    required String actorPlayerId,
    required DateTime now,
  }) async {
    final decoded = _codec.decode(match: match, snapshot: wireSnapshot);
    final reduction = await reducer.reduceTimedOutTurn(
      match: match,
      snapshot: decoded.canonical,
      actorPlayerId: actorPlayerId,
      now: now,
    );
    return ServerCommandTestReduction._(decoded: decoded, reduction: reduction);
  }
}

final class ServerCommandTestReduction {
  const ServerCommandTestReduction._({
    required this.decoded,
    required this.reduction,
  });

  static const _codec = RunningMatchSnapshotCodec();

  final DecodedRunningMatchSnapshot decoded;
  final ServerCommandReduction reduction;

  bool get accepted => reduction.accepted;
  String? get reason => reduction.reason;
  List<GameEvent> get events => reduction.events;
  List<MovementCommandExecution> get movementExecutions =>
      reduction.movementExecutions;
  GameOutcome? get outcome => reduction.outcome;
  CanonicalGameSnapshot get previousSnapshot => decoded.canonical;
  CanonicalGameSnapshot? get nextSnapshot => reduction.nextSnapshot;

  WireSnapshot get wireSnapshot {
    final next = nextSnapshot;
    return next == null ? decoded.wire : _codec.encodeCanonical(decoded, next);
  }
}
