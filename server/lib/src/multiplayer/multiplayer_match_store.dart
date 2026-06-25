import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';

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
  Future<T> transaction<T>(
    Future<T> Function(MultiplayerMatchStore store) action,
  );

  Future<List<StoredMatchState>> listVisibleMatchStates(String userIdentifier);

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

  Future<List<WireEvent>> listEvents(String matchId, int afterOffset);
}

class ServerpodMultiplayerMatchStore implements MultiplayerMatchStore {
  ServerpodMultiplayerMatchStore(Session session)
    : this._(session: session, transaction: null);

  const ServerpodMultiplayerMatchStore._({
    required Session session,
    required Transaction? transaction,
  }) : _session = session,
       _transaction = transaction;

  final Session _session;
  final Transaction? _transaction;

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
        ),
      );
    });
  }

  @override
  Future<List<StoredMatchState>> listVisibleMatchStates(
    String userIdentifier,
  ) async {
    final rows = await GameMatch.db.find(
      _session,
      where: (table) =>
          (table.state.equals('open')) | (table.state.equals('running')),
      orderBy: (table) => table.createdAt,
      transaction: _transaction,
    );
    final states = <StoredMatchState>[];
    for (final row in rows) {
      final state = await _stateFromRow(row);
      if (_isVisibleToUser(state.match, userIdentifier)) {
        states.add(state);
      }
    }
    return states;
  }

  @override
  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest _,
  ) async {
    final rows = await GameMatch.db.find(
      _session,
      where: (table) =>
          (table.state.equals('open')) &
          (table.private.equals(false)) &
          (table.quickplay.equals(true)) &
          (table.inviteCode.equals(null)),
      orderBy: (table) => table.createdAt,
      transaction: _transaction,
      lockMode: _transaction == null ? null : LockMode.forUpdate,
      lockBehavior: _transaction == null ? null : LockBehavior.wait,
    );

    for (final row in rows) {
      final state = await _stateFromRow(row);
      if (state.match.players.length < state.match.maxPlayers) {
        return state;
      }
    }
    return null;
  }

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
  Future<StoredMatchState> createState(StoredMatchState state) {
    return transaction((store) async {
      final txStore = store as ServerpodMultiplayerMatchStore;
      final now = DateTime.now().toUtc();
      final match = state.match;
      final row = await GameMatch.db.insertRow(
        txStore._session,
        GameMatch(
          publicId: match.id,
          ownerUserIdentifier: match.ownerUserId,
          name: match.name,
          mapName: match.mapName,
          state: match.state,
          turn: match.turn,
          maxPlayers: match.maxPlayers,
          minPlayers: match.minPlayers,
          private: match.inviteCode != null,
          quickplay: match.quickplay,
          createdAt: match.createdAt,
          autoStartAt: match.autoStartAt,
          inviteCode: match.inviteCode,
          startedAt: match.state == 'running' ? now : null,
        ),
        transaction: txStore._transaction,
      );
      await txStore._replacePlayers(row.id!, match.players);
      await GameSnapshot.db.insertRow(
        txStore._session,
        GameSnapshot(
          matchId: row.id!,
          offset: state.snapshot.offset,
          snapshot: state.snapshot,
          createdAt: now,
        ),
        transaction: txStore._transaction,
      );
      return state;
    });
  }

  @override
  Future<StoredMatchState> saveState(StoredMatchState state) {
    return transaction((store) async {
      final txStore = store as ServerpodMultiplayerMatchStore;
      final row = await txStore._requireMatchRow(state.match.id, lock: true);
      final updatedRow = await GameMatch.db.updateRow(
        txStore._session,
        row.copyWith(
          ownerUserIdentifier: state.match.ownerUserId,
          name: state.match.name,
          mapName: state.match.mapName,
          state: state.match.state,
          turn: state.match.turn,
          maxPlayers: state.match.maxPlayers,
          minPlayers: state.match.minPlayers,
          private: state.match.inviteCode != null,
          quickplay: state.match.quickplay,
          autoStartAt: state.match.autoStartAt,
          inviteCode: state.match.inviteCode,
          startedAt: state.match.state == 'running'
              ? row.startedAt ?? DateTime.now().toUtc()
              : row.startedAt,
        ),
        transaction: txStore._transaction,
      );
      await txStore._replacePlayers(updatedRow.id!, state.match.players);
      await txStore._upsertSnapshot(updatedRow.id!, state.snapshot);
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
      await GameEvent.db.insertRow(
        txStore._session,
        GameEvent(
          matchId: row.id!,
          offset: event.offset,
          actorPlayerId: actorPlayerId,
          clientMessageId: clientMessageId,
          event: event,
          createdAt: event.timestamp,
        ),
        transaction: txStore._transaction,
      );
      await txStore._upsertSnapshot(row.id!, state.snapshot);
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
  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    final row = await _requireMatchRow(matchId);
    final eventRows = await GameEvent.db.find(
      _session,
      where: (table) =>
          (table.matchId.equals(row.id!)) & (table.offset > afterOffset),
      orderBy: (table) => table.offset,
      transaction: _transaction,
    );
    return [for (final eventRow in eventRows) eventRow.event];
  }

  Future<StoredMatchState?> _findStateBy({
    required Expression Function(GameMatchTable table) where,
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

  Future<void> _upsertSnapshot(int matchRowId, WireSnapshot snapshot) async {
    final existing = await GameSnapshot.db.findFirstRow(
      _session,
      where: (table) =>
          (table.matchId.equals(matchRowId)) &
          (table.offset.equals(snapshot.offset)),
      transaction: _transaction,
    );
    final now = DateTime.now().toUtc();
    if (existing == null) {
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
      return;
    }
    await GameSnapshot.db.updateRow(
      _session,
      existing.copyWith(snapshot: snapshot, createdAt: now),
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

bool _isVisibleToUser(WireMatch match, String userIdentifier) {
  final participant = match.players.any(
    (player) => player.userId == userIdentifier,
  );
  if (participant) return true;
  return match.state == 'open' && match.inviteCode == null;
}
