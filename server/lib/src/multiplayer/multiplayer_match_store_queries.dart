import 'package:aonw_core/protocol.dart';
import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/game_match_row_mapper.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:serverpod/serverpod.dart';

/// Owns bounded multiplayer discovery, resume, and event queries.
final class MultiplayerMatchQueryStore {
  const MultiplayerMatchQueryStore(this._store);

  final ServerpodMultiplayerMatchStore _store;

  Future<List<WireMatch>> listVisibleMatches(String userIdentifier) async {
    final participantRows = await GameMatch.db.find(
      _store.sessionForCapabilities,
      where: (table) =>
          ((table.state.equals('open')) | (table.state.equals('running'))) &
          table.players.any(
            (player) => player.userIdentifier.equals(userIdentifier),
          ),
      orderByList: _newestMatchOrder,
      limit: multiplayerVisibleParticipantMatchLimit,
      transaction: _store.transactionForCapabilities,
      include: GameMatch.include(
        players: GamePlayer.includeList(orderBy: (table) => table.seatOrder),
      ),
    );
    final publicRows = await GameMatch.db.find(
      _store.sessionForCapabilities,
      where: (table) =>
          table.state.equals('open') &
          table.private.equals(false) &
          table.inviteCode.equals(null),
      orderByList: _newestMatchOrder,
      limit: multiplayerVisiblePublicLobbyLimit,
      transaction: _store.transactionForCapabilities,
      include: GameMatch.include(
        players: GamePlayer.includeList(orderBy: (table) => table.seatOrder),
      ),
    );

    final participantIds = {for (final row in participantRows) row.publicId};
    final matchesById = <String, WireMatch>{};
    for (final row in [...participantRows, ...publicRows]) {
      matchesById.putIfAbsent(
        row.publicId,
        () => wireMatchFromRow(row, row.players!),
      );
    }
    return matchesById.values.toList()..sort(
      (first, second) =>
          _compareVisibleMatches(first, second, participantIds: participantIds),
    );
  }

  Future<StoredMatchState?> findOpenQuickplayCandidate(
    CreateMatchRequest request,
  ) async {
    final rows = await GameMatch.db.find(
      _store.sessionForCapabilities,
      where: (table) =>
          table.state.equals('open') &
          table.private.equals(false) &
          table.quickplay.equals(true) &
          table.inviteCode.equals(null) &
          table.mapName.equals(request.mapName),
      orderByList: (table) => [
        Order(column: table.createdAt),
        Order(column: table.publicId),
      ],
      limit: multiplayerQuickplayCandidateScanLimit,
      transaction: _store.transactionForCapabilities,
      lockMode: _store.transactionForCapabilities == null
          ? null
          : LockMode.forUpdate,
      lockBehavior: _store.transactionForCapabilities == null
          ? null
          : LockBehavior.wait,
    );

    for (final row in rows) {
      final state = await _store.stateFromRowForCapabilities(row);
      if (state.match.mapName == request.mapName &&
          state.match.players.length < state.match.maxPlayers) {
        return state;
      }
    }
    return null;
  }

  Future<List<WireEvent>> listEvents(String matchId, int afterOffset) async {
    final row = await _store.requireMatchRowForCapabilities(matchId);
    final eventRows = await GameEvent.db.find(
      _store.sessionForCapabilities,
      where: (table) =>
          table.matchId.equals(row.id!) & (table.offset > afterOffset),
      orderBy: (table) => table.offset,
      limit: multiplayerEventPageSize,
      transaction: _store.transactionForCapabilities,
    );
    return [for (final eventRow in eventRows) eventRow.event];
  }

  Future<RunningMatchStatePage> listRunningStates({
    RunningMatchCursor? after,
  }) async {
    final rows = await GameMatch.db.find(
      _store.sessionForCapabilities,
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
      limit: multiplayerRunningMatchPageSize + 1,
      transaction: _store.transactionForCapabilities,
      include: GameMatch.include(
        players: GamePlayer.includeList(orderBy: (table) => table.seatOrder),
        snapshots: GameSnapshot.includeList(
          orderBy: (table) => table.offset,
          orderDescending: true,
        ),
      ),
    );
    final pageRows = rows.take(multiplayerRunningMatchPageSize).toList();
    final states = <StoredMatchState>[];
    for (final row in pageRows) {
      try {
        final snapshots = row.snapshots;
        if (snapshots == null || snapshots.isEmpty) {
          throw StateError('Running match snapshot not found.');
        }
        states.add(
          StoredMatchState(
            match: wireMatchFromRow(row, row.players!),
            snapshot: snapshots
                .reduce(
                  (latest, candidate) =>
                      candidate.offset > latest.offset ? candidate : latest,
                )
                .snapshot,
          ),
        );
      } on ArgumentError {
        // Incompatible snapshots must not stop healthy timeout processing.
      }
    }
    final lastRawRow = pageRows.isEmpty ? null : pageRows.last;
    return RunningMatchStatePage(
      states: states,
      nextCursor:
          rows.length <= multiplayerRunningMatchPageSize || lastRawRow == null
          ? null
          : RunningMatchCursor(
              createdAt: lastRawRow.createdAt,
              publicId: lastRawRow.publicId,
            ),
    );
  }
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
