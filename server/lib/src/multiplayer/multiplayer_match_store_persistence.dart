import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/game_match_row_mapper.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:serverpod/serverpod.dart';

final class InviteCodeConflictException implements Exception {
  const InviteCodeConflictException();
}

/// Owns transactional match, event, roster, and snapshot writes.
final class MultiplayerMatchPersistenceStore {
  const MultiplayerMatchPersistenceStore(this._store);

  final ServerpodMultiplayerMatchStore _store;

  Future<StoredMatchState> create(StoredMatchState state) {
    return _store.transaction((transactionStore) async {
      final txStore = transactionStore as ServerpodMultiplayerMatchStore;
      final now = DateTime.now().toUtc();
      final match = state.match;
      late final GameMatch row;
      try {
        row = await GameMatch.db.insertRow(
          txStore.sessionForCapabilities,
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
            endedAt: match.endedAt,
            outcomeCondition: match.outcomeCondition,
            winnerPlayerId: match.winnerPlayerId,
            autoStartAt: match.autoStartAt,
            inviteCode: match.inviteCode,
            startedAt: match.state == 'running' ? now : null,
          ),
          transaction: txStore.transactionForCapabilities,
        );
      } on DatabaseQueryException catch (error) {
        if (match.inviteCode != null &&
            error.code == '23505' &&
            error.constraintName == 'aonw_match_invite_code_idx') {
          throw const InviteCodeConflictException();
        }
        rethrow;
      }
      await txStore.replacePlayersForCapabilities(row.id!, match.players);
      await GameSnapshot.db.insertRow(
        txStore.sessionForCapabilities,
        GameSnapshot(
          matchId: row.id!,
          offset: state.snapshot.offset,
          snapshot: state.snapshot,
          createdAt: now,
        ),
        transaction: txStore.transactionForCapabilities,
      );
      return state;
    });
  }

  Future<StoredMatchState> save(StoredMatchState state) {
    return _store.transaction((transactionStore) async {
      final txStore = transactionStore as ServerpodMultiplayerMatchStore;
      final row = await txStore.requireMatchRowForCapabilities(
        state.match.id,
        lock: true,
      );
      final updatedRow = await GameMatch.db.updateRow(
        txStore.sessionForCapabilities,
        gameMatchRowForState(row, state.match, DateTime.now().toUtc()),
        transaction: txStore.transactionForCapabilities,
      );
      await txStore.replacePlayersForCapabilities(
        updatedRow.id!,
        state.match.players,
      );
      await txStore.saveSnapshotForCapabilities(updatedRow.id!, state.snapshot);
      return state;
    });
  }

  Future<StoredMatchState> appendEvent(
    StoredMatchState state,
    WireEvent event, {
    String? actorPlayerId,
    String? clientMessageId,
  }) {
    return _store.transaction((transactionStore) async {
      final txStore = transactionStore as ServerpodMultiplayerMatchStore;
      final row = await txStore.requireMatchRowForCapabilities(
        state.match.id,
        lock: true,
      );
      final updatedRow = await GameMatch.db.updateRow(
        txStore.sessionForCapabilities,
        gameMatchRowForState(row, state.match, DateTime.now().toUtc()),
        transaction: txStore.transactionForCapabilities,
      );
      await GameEvent.db.insertRow(
        txStore.sessionForCapabilities,
        GameEvent(
          matchId: updatedRow.id!,
          offset: event.offset,
          actorPlayerId: actorPlayerId,
          clientMessageId: clientMessageId,
          event: event,
          createdAt: event.timestamp,
        ),
        transaction: txStore.transactionForCapabilities,
      );
      await txStore.saveSnapshotForCapabilities(updatedRow.id!, state.snapshot);
      return state;
    });
  }

  Future<WireEvent?> findEventByClientMessageId(
    String matchId, {
    required String actorPlayerId,
    required String clientMessageId,
  }) async {
    final row = await _store.requireMatchRowForCapabilities(matchId);
    final eventRow = await GameEvent.db.findFirstRow(
      _store.sessionForCapabilities,
      where: (table) =>
          (table.matchId.equals(row.id!)) &
          (table.actorPlayerId.equals(actorPlayerId)) &
          (table.clientMessageId.equals(clientMessageId)),
      transaction: _store.transactionForCapabilities,
    );
    return eventRow?.event;
  }
}
