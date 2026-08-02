import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/game_match_row_mapper.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_persistence.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_queries.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_snapshots.dart';
import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:serverpod/serverpod.dart';

export 'multiplayer_match_store_limits.dart';
export 'multiplayer_match_store_persistence.dart'
    show InviteCodeConflictException;

class StoredMatchState {
  const StoredMatchState({required this.match, required this.snapshot});

  final WireMatch match;
  final WireSnapshot snapshot;

  int get offset => snapshot.offset;

  int nextOffset() => offset + 1;

  StoredMatchState copyWith({WireMatch? match, WireSnapshot? snapshot}) {
    return StoredMatchState(
      match: match ?? this.match,
      snapshot: snapshot ?? this.snapshot,
    );
  }
}

final class RunningMatchCursor {
  const RunningMatchCursor({required this.createdAt, required this.publicId});

  final DateTime createdAt;
  final String publicId;

  @override
  bool operator ==(Object other) {
    return other is RunningMatchCursor &&
        other.createdAt == createdAt &&
        other.publicId == publicId;
  }

  @override
  int get hashCode => Object.hash(createdAt, publicId);
}

final class RunningMatchStatePage {
  RunningMatchStatePage({
    required Iterable<StoredMatchState> states,
    required this.nextCursor,
  }) : states = List.unmodifiable(states);

  final List<StoredMatchState> states;
  final RunningMatchCursor? nextCursor;
}

abstract interface class MultiplayerMatchStore {
  ServerOperationalEventSink get operationalEvents;

  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  );

  /// Returns bounded participant and public-lobby sets, merged newest first.
  Future<List<WireMatch>> listVisibleMatches(String userIdentifier);

  Future<RunningMatchStatePage> listRunningStates({RunningMatchCursor? after});

  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest request,
  );

  Future<StoredMatchState?> findState(String matchId, {bool lock = false});

  Future<StoredMatchState?> findPrivateState(
    String inviteCode, {
    bool lock = false,
  });

  Future<StoredMatchState> createState(StoredMatchState state);

  Future<StoredMatchState> saveState(StoredMatchState state);

  Future<StoredMatchState> appendEvent(
    StoredMatchState state,
    WireEvent event, {
    String? actorPlayerId,
    String? clientMessageId,
  });

  Future<WireEvent?> findEventByClientMessageId(
    String matchId, {
    required String actorPlayerId,
    required String clientMessageId,
  });

  /// Returns at most [multiplayerEventPageSize] events after [afterOffset].
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset);
}

class ServerpodMultiplayerMatchStore implements MultiplayerMatchStore {
  ServerpodMultiplayerMatchStore(Session session)
    : this._(
        session: session,
        transaction: null,
        operationalEvents: ServerpodOperationalEventSink(session),
      );

  ServerpodMultiplayerMatchStore._({
    required Session session,
    required Transaction? transaction,
    required this.operationalEvents,
  }) : _session = session,
       _transaction = transaction {
    _queries = MultiplayerMatchQueryStore(this);
    _persistence = MultiplayerMatchPersistenceStore(this);
    _snapshots = MultiplayerMatchSnapshotStore(session, transaction);
  }

  final Session _session;
  final Transaction? _transaction;
  late final MultiplayerMatchQueryStore _queries;
  late final MultiplayerMatchPersistenceStore _persistence;
  late final MultiplayerMatchSnapshotStore _snapshots;

  Session get sessionForCapabilities => _session;
  Transaction? get transactionForCapabilities => _transaction;

  @override
  final ServerOperationalEventSink operationalEvents;

  @override
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  ) {
    if (_transaction != null) {
      return action(this);
    }
    return _session.db.transaction((transaction) {
      return action(
        ServerpodMultiplayerMatchStore._(
          session: _session,
          transaction: transaction,
          operationalEvents: operationalEvents,
        ),
      );
    });
  }

  @override
  Future<List<WireMatch>> listVisibleMatches(String userIdentifier) =>
      _queries.listVisibleMatches(userIdentifier);

  @override
  Future<RunningMatchStatePage> listRunningStates({
    RunningMatchCursor? after,
  }) => _queries.listRunningStates(after: after);

  @override
  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest request,
  ) => _queries.findOpenQuickplayCandidate(request);

  @override
  Future<StoredMatchState?> findState(String matchId, {bool lock = false}) {
    return _findStateBy(
      where: (table) => table.publicId.equals(matchId),
      lock: lock,
    );
  }

  @override
  Future<StoredMatchState?> findPrivateState(
    String inviteCode, {
    bool lock = false,
  }) {
    return _findStateBy(
      where: (table) => table.inviteCode.equals(inviteCode),
      lock: lock,
    );
  }

  @override
  Future<StoredMatchState> createState(StoredMatchState state) =>
      _persistence.create(state);

  @override
  Future<StoredMatchState> saveState(StoredMatchState state) =>
      _persistence.save(state);

  @override
  Future<StoredMatchState> appendEvent(
    StoredMatchState state,
    WireEvent event, {
    String? actorPlayerId,
    String? clientMessageId,
  }) => _persistence.appendEvent(
    state,
    event,
    actorPlayerId: actorPlayerId,
    clientMessageId: clientMessageId,
  );

  @override
  Future<WireEvent?> findEventByClientMessageId(
    String matchId, {
    required String actorPlayerId,
    required String clientMessageId,
  }) => _persistence.findEventByClientMessageId(
    matchId,
    actorPlayerId: actorPlayerId,
    clientMessageId: clientMessageId,
  );

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) =>
      _queries.listEvents(matchId, afterOffset);

  Future<StoredMatchState?> _findStateBy({
    required Expression<dynamic> Function(GameMatchTable table) where,
    required bool lock,
  }) async {
    final row = await GameMatch.db.findFirstRow(
      _session,
      where: where,
      transaction: _transaction,
      lockMode: lock && _transaction != null ? LockMode.forUpdate : null,
      lockBehavior: lock && _transaction != null ? LockBehavior.wait : null,
    );
    if (row == null) return null;
    return stateFromRowForCapabilities(row);
  }

  Future<GameMatch> requireMatchRowForCapabilities(
    String matchId, {
    bool lock = false,
  }) async {
    final row = await GameMatch.db.findFirstRow(
      _session,
      where: (table) => table.publicId.equals(matchId),
      transaction: _transaction,
      lockMode: lock && _transaction != null ? LockMode.forUpdate : null,
      lockBehavior: lock && _transaction != null ? LockBehavior.wait : null,
    );
    if (row == null) {
      throw StateError('Match not found.');
    }
    return row;
  }

  Future<StoredMatchState> stateFromRowForCapabilities(GameMatch row) async {
    final players = await GamePlayer.db.find(
      _session,
      where: (table) => table.matchId.equals(row.id!),
      orderBy: (table) => table.seatOrder,
      transaction: _transaction,
    );
    final snapshot = await GameSnapshot.db.findFirstRow(
      _session,
      where: (table) => table.matchId.equals(row.id!),
      orderBy: (table) => table.offset,
      orderDescending: true,
      transaction: _transaction,
    );
    if (snapshot == null) {
      throw StateError('Match snapshot not found.');
    }
    return StoredMatchState(
      match: wireMatchFromRow(row, players),
      snapshot: snapshot.snapshot,
    );
  }

  Future<void> replacePlayersForCapabilities(
    int matchRowId,
    List<WirePlayer> players,
  ) async {
    await GamePlayer.db.deleteWhere(
      _session,
      where: (table) => table.matchId.equals(matchRowId),
      transaction: _transaction,
    );
    if (players.isEmpty) return;
    await GamePlayer.db.insert(_session, [
      for (var index = 0; index < players.length; index++)
        gamePlayerRow(matchRowId, players[index], index),
    ], transaction: _transaction);
  }

  Future<void> saveSnapshotForCapabilities(
    int matchRowId,
    WireSnapshot snapshot,
  ) => _snapshots.saveLatest(matchRowId, snapshot);
}
