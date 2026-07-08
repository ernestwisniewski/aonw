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
    } on ArgumentError catch (error, stackTrace) {
      store._session.log(
        'Skipping running multiplayer match with incompatible snapshot: '
        '${row.publicId}',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
    }
  }
  return states;
}
