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
  return Future.wait(rows.map(store._stateFromRow));
}
