import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../observability/server_operational_event_sink.dart';
import 'game_match_row_mapper.dart';

part 'multiplayer_match_store_creation.dart';
part 'multiplayer_match_store_limits.dart';
part 'multiplayer_match_store_queries.dart';

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

abstract interface class MultiplayerMatchStore {
  ServerOperationalEventSink get operationalEvents;

  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  );

  /// Returns bounded participant and public-lobby sets, merged newest first.
  Future<List<WireMatch>> listVisibleMatches(String userIdentifier);

  Future<List<StoredMatchState>> listRunningStates();

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
       _transaction = transaction;

  final Session _session;
  final Transaction? _transaction;

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
      _listVisibleMatches(this, userIdentifier);

  @override
  Future<List<StoredMatchState>> listRunningStates() =>
      _listRunningStates(this);

  @override
  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest request,
  ) => _findOpenQuickplayCandidate(this, request);

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
      _createState(this, state);

  @override
  Future<StoredMatchState> saveState(StoredMatchState state) {
    return transaction((store) async {
      final txStore = store as ServerpodMultiplayerMatchStore;
      final row = await txStore._requireMatchRow(state.match.id, lock: true);
      final updatedRow = await GameMatch.db.updateRow(
        txStore._session,
        gameMatchRowForState(row, state.match, DateTime.now().toUtc()),
        transaction: txStore._transaction,
      );
      await txStore._replacePlayers(updatedRow.id!, state.match.players);
      await txStore._saveLatestSnapshot(updatedRow.id!, state.snapshot);
      return state;
    });
  }

  @override
  Future<StoredMatchState> appendEvent(
    StoredMatchState state,
    WireEvent event, {
    String? actorPlayerId,
    String? clientMessageId,
  }) {
    return transaction((store) async {
      final txStore = store as ServerpodMultiplayerMatchStore;
      final row = await txStore._requireMatchRow(state.match.id, lock: true);
      final updatedRow = await GameMatch.db.updateRow(
        txStore._session,
        gameMatchRowForState(row, state.match, DateTime.now().toUtc()),
        transaction: txStore._transaction,
      );
      await GameEvent.db.insertRow(
        txStore._session,
        GameEvent(
          matchId: updatedRow.id!,
          offset: event.offset,
          actorPlayerId: actorPlayerId,
          clientMessageId: clientMessageId,
          event: event,
          createdAt: event.timestamp,
        ),
        transaction: txStore._transaction,
      );
      await txStore._saveLatestSnapshot(updatedRow.id!, state.snapshot);
      return state;
    });
  }

  @override
  Future<WireEvent?> findEventByClientMessageId(
    String matchId, {
    required String actorPlayerId,
    required String clientMessageId,
  }) async {
    final row = await _requireMatchRow(matchId);
    final eventRow = await GameEvent.db.findFirstRow(
      _session,
      where: (table) =>
          (table.matchId.equals(row.id!)) &
          (table.actorPlayerId.equals(actorPlayerId)) &
          (table.clientMessageId.equals(clientMessageId)),
      transaction: _transaction,
    );
    return eventRow?.event;
  }

  @override
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) =>
      _listEvents(this, matchId, afterOffset);

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
    return _stateFromRow(row);
  }

  Future<GameMatch> _requireMatchRow(
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

  Future<StoredMatchState> _stateFromRow(GameMatch row) async {
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
      match: _wireMatch(row, players),
      snapshot: snapshot.snapshot,
    );
  }

  Future<void> _replacePlayers(int matchRowId, List<WirePlayer> players) async {
    await GamePlayer.db.deleteWhere(
      _session,
      where: (table) => table.matchId.equals(matchRowId),
      transaction: _transaction,
    );
    if (players.isEmpty) return;
    await GamePlayer.db.insert(_session, [
      for (var index = 0; index < players.length; index++)
        _gamePlayer(matchRowId, players[index], index),
    ], transaction: _transaction);
  }

  Future<void> _saveLatestSnapshot(
    int matchRowId,
    WireSnapshot snapshot,
  ) async {
    final latest = await GameSnapshot.db.findFirstRow(
      _session,
      where: (table) => table.matchId.equals(matchRowId),
      orderBy: (table) => table.offset,
      orderDescending: true,
      transaction: _transaction,
    );
    if (latest != null && latest.offset > snapshot.offset) {
      throw StateError(
        'Cannot replace snapshot at offset ${latest.offset} with stale '
        'offset ${snapshot.offset}.',
      );
    }

    final now = DateTime.now().toUtc();
    if (latest == null) {
      await GameSnapshot.db.insertRow(
        _session,
        GameSnapshot(
          matchId: matchRowId,
          offset: snapshot.offset,
          snapshot: snapshot,
          createdAt: now,
        ),
        transaction: _transaction,
      );
    } else {
      await GameSnapshot.db.updateRow(
        _session,
        latest.copyWith(
          offset: snapshot.offset,
          snapshot: snapshot,
          createdAt: now,
        ),
        transaction: _transaction,
      );
    }

    await GameSnapshot.db.deleteWhere(
      _session,
      where: (table) =>
          (table.matchId.equals(matchRowId)) & (table.offset < snapshot.offset),
      transaction: _transaction,
    );
  }
}

WireMatch _wireMatch(GameMatch row, List<GamePlayer> players) {
  return WireMatch(
    id: row.publicId,
    ownerUserId: row.ownerUserIdentifier,
    name: row.name,
    mapName: row.mapName,
    players: [for (final player in players) _wirePlayer(player)],
    maxPlayers: row.maxPlayers,
    minPlayers: row.minPlayers,
    quickplay: row.quickplay,
    turn: row.turn,
    state: row.state,
    createdAt: row.createdAt,
    autoStartAt: row.autoStartAt,
    inviteCode: row.inviteCode,
  );
}

WirePlayer _wirePlayer(GamePlayer row) {
  return WirePlayer(
    id: row.publicPlayerId,
    userId: row.userIdentifier,
    name: row.displayName,
    colorValue: row.colorValue,
    country: PlayerCountry.values.byName(row.countryId),
    kind: WirePlayerKind.values.byName(row.kind),
    connectionState: WirePlayerConnectionState.values.byName(
      row.connectionState,
    ),
    ready: row.ready,
  );
}

GamePlayer _gamePlayer(int matchRowId, WirePlayer player, int seatOrder) {
  return GamePlayer(
    matchId: matchRowId,
    publicPlayerId: player.id,
    userIdentifier: player.userId,
    displayName: player.name,
    colorValue: player.colorValue,
    countryId: player.country.name,
    kind: player.kind.name,
    connectionState: player.connectionState.name,
    ready: player.ready,
    seatOrder: seatOrder,
  );
}
