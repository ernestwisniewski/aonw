part of 'multiplayer_match_store.dart';

final class InviteCodeConflictException implements Exception {
  const InviteCodeConflictException();
}

Future<StoredMatchState> _createState(
  ServerpodMultiplayerMatchStore store,
  StoredMatchState state,
) {
  return store.transaction((transactionStore) async {
    final txStore = transactionStore as ServerpodMultiplayerMatchStore;
    final now = DateTime.now().toUtc();
    final match = state.match;
    late final GameMatch row;
    try {
      row = await GameMatch.db.insertRow(
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
    } on DatabaseQueryException catch (error) {
      if (match.inviteCode != null &&
          error.code == '23505' &&
          error.constraintName == 'aonw_match_invite_code_idx') {
        throw const InviteCodeConflictException();
      }
      rethrow;
    }
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
