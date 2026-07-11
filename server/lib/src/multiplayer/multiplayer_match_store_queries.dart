part of 'multiplayer_match_store.dart';

Future<List<WireMatch>> _listVisibleMatches(
  ServerpodMultiplayerMatchStore store,
  String userIdentifier,
) async {
  final participantRows = await GameMatch.db.find(
    store._session,
    where: (table) =>
        ((table.state.equals('open')) | (table.state.equals('running'))) &
        table.players.any(
          (player) => player.userIdentifier.equals(userIdentifier),
        ),
    orderByList: _newestMatchOrder,
    limit: multiplayerVisibleParticipantMatchLimit,
    transaction: store._transaction,
    include: GameMatch.include(
      players: GamePlayer.includeList(orderBy: (table) => table.seatOrder),
    ),
  );
  final publicRows = await GameMatch.db.find(
    store._session,
    where: (table) =>
        table.state.equals('open') &
        table.private.equals(false) &
        table.inviteCode.equals(null),
    orderByList: _newestMatchOrder,
    limit: multiplayerVisiblePublicLobbyLimit,
    transaction: store._transaction,
    include: GameMatch.include(
      players: GamePlayer.includeList(orderBy: (table) => table.seatOrder),
    ),
  );

  final participantIds = {for (final row in participantRows) row.publicId};
  final matchesById = <String, WireMatch>{};
  for (final row in [...participantRows, ...publicRows]) {
    matchesById.putIfAbsent(row.publicId, () => _wireMatch(row, row.players!));
  }
  final matches = matchesById.values.toList();
  matches.sort(
    (first, second) =>
        _compareVisibleMatches(first, second, participantIds: participantIds),
  );
  return matches;
}

Future<StoredMatchState?> _findOpenQuickplayCandidate(
  ServerpodMultiplayerMatchStore store,
  CreateMatchRequest _,
) async {
  final rows = await GameMatch.db.find(
    store._session,
    where: (table) =>
        table.state.equals('open') &
        table.private.equals(false) &
        table.quickplay.equals(true) &
        table.inviteCode.equals(null),
    orderByList: (table) => [
      Order(column: table.createdAt),
      Order(column: table.publicId),
    ],
    limit: multiplayerQuickplayCandidateScanLimit,
    transaction: store._transaction,
    lockMode: store._transaction == null ? null : LockMode.forUpdate,
    lockBehavior: store._transaction == null ? null : LockBehavior.wait,
  );

  for (final row in rows) {
    final state = await store._stateFromRow(row);
    if (state.match.players.length < state.match.maxPlayers) return state;
  }
  return null;
}

Future<List<WireEvent>> _listEvents(
  ServerpodMultiplayerMatchStore store,
  String matchId,
  int afterOffset,
) async {
  final row = await store._requireMatchRow(matchId);
  final eventRows = await GameEvent.db.find(
    store._session,
    where: (table) =>
        table.matchId.equals(row.id!) & (table.offset > afterOffset),
    orderBy: (table) => table.offset,
    limit: multiplayerEventPageSize,
    transaction: store._transaction,
  );
  return [for (final eventRow in eventRows) eventRow.event];
}

Future<RunningMatchStatePage> _listRunningStates(
  ServerpodMultiplayerMatchStore store, {
  RunningMatchCursor? after,
}) async {
  final rows = await GameMatch.db.find(
    store._session,
    where: (table) {
      final running = table.state.equals('running');
      if (after == null) return running;
      return running &
          ((table.createdAt > after.createdAt) |
              (table.createdAt.equals(after.createdAt) &
                  (table.publicId > after.publicId)));
    },
    orderByList: (table) => [
      Order(column: table.createdAt),
      Order(column: table.publicId),
    ],
    limit: multiplayerRunningMatchPageSize,
    transaction: store._transaction,
    include: GameMatch.include(
      players: GamePlayer.includeList(orderBy: (table) => table.seatOrder),
      snapshots: GameSnapshot.includeList(
        orderBy: (table) => table.offset,
        orderDescending: true,
      ),
    ),
  );
  final states = <StoredMatchState>[];
  for (final row in rows) {
    try {
      final snapshots = row.snapshots;
      if (snapshots == null || snapshots.isEmpty) {
        throw StateError('Running match snapshot not found.');
      }
      states.add(
        StoredMatchState(
          match: _wireMatch(row, row.players!),
          snapshot: snapshots
              .reduce(
                (latest, candidate) =>
                    candidate.offset > latest.offset ? candidate : latest,
              )
              .snapshot,
        ),
      );
    } on ArgumentError {
      // Old snapshots can remain in the database after a wire protocol bump.
      // They cannot be resumed by the current server, but they also must not
      // stop timeout processing for healthy running matches.
    }
  }
  final lastRawRow = rows.isEmpty ? null : rows.last;
  return RunningMatchStatePage(
    states: states,
    nextCursor:
        rows.length < multiplayerRunningMatchPageSize || lastRawRow == null
        ? null
        : RunningMatchCursor(
            createdAt: lastRawRow.createdAt,
            publicId: lastRawRow.publicId,
          ),
  );
}

List<Order> _newestMatchOrder(GameMatchTable table) => [
  Order(column: table.createdAt, orderDescending: true),
  Order(column: table.publicId, orderDescending: true),
];

int _compareVisibleMatches(
  WireMatch first,
  WireMatch second, {
  required Set<String> participantIds,
}) {
  final createdAtOrder = second.createdAt.compareTo(first.createdAt);
  if (createdAtOrder != 0) return createdAtOrder;

  final firstIsParticipant = participantIds.contains(first.id);
  final secondIsParticipant = participantIds.contains(second.id);
  if (firstIsParticipant != secondIsParticipant) {
    return firstIsParticipant ? -1 : 1;
  }
  return second.id.compareTo(first.id);
}
