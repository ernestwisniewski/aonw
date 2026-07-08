part of 'multiplayer_match_store.dart';

Future<List<StoredMatchState>> _listRunningStates(
  ServerpodMultiplayerMatchStore store,
) async {
  final rows = await GameMatch.db.find(
    store._session,
    where: (table) => table.state.equals('running'),
    orderBy: (table) => table.createdAt,
    transaction: store._transaction,
  );
  final states = <StoredMatchState>[];
  for (final row in rows) {
    try {
      states.add(await store._stateFromRow(row));
    } on ArgumentError {
      // Old snapshots can remain in the database after a wire protocol bump.
      // They cannot be resumed by the current server, but they also must not
      // stop timeout processing for healthy running matches.
    }
  }
  return states;
}
