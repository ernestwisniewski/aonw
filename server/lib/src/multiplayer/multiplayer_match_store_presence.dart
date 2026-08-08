import 'package:aonw_server/src/generated/protocol.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store.dart';
import 'package:aonw_server/src/multiplayer/multiplayer_match_store_limits.dart';
import 'package:serverpod/serverpod.dart';

/// Owns targeted, server-only presence lease persistence.
final class MultiplayerMatchPresenceStore {
  const MultiplayerMatchPresenceStore(this._store);

  final ServerpodMultiplayerMatchStore _store;

  Future<ExpiredPresenceLeasePage> listExpired({
    required DateTime nowUtc,
    ExpiredPresenceLeaseCursor? after,
  }) async {
    final cutoff = nowUtc.toUtc();
    final rows = await GameMatchPresenceLease.db.find(
      _store.sessionForCapabilities,
      where: (table) {
        final expired = table.expiresAt <= cutoff;
        if (after == null) return expired;
        return expired &
            ((table.expiresAt > after.expiresAt) |
                (table.expiresAt.equals(after.expiresAt) &
                    (table.id > after.rowId)));
      },
      orderByList: (table) => [
        Order(column: table.expiresAt),
        Order(column: table.id),
      ],
      limit: multiplayerPresenceLeasePageSize + 1,
      transaction: _store.transactionForCapabilities,
      include: GameMatchPresenceLease.include(match: GameMatch.include()),
    );
    final pageRows = rows.take(multiplayerPresenceLeasePageSize).toList();
    final candidates = <ExpiredPresenceLeaseCandidate>[];
    for (final row in pageRows) {
      final match = row.match;
      final rowId = row.id;
      if (match == null || rowId == null) continue;
      candidates.add(
        ExpiredPresenceLeaseCandidate(
          rowId: rowId,
          matchId: match.publicId,
          lease: _storedLease(row),
        ),
      );
    }
    final last = pageRows.isEmpty ? null : pageRows.last;
    return ExpiredPresenceLeasePage(
      candidates: candidates,
      nextCursor:
          rows.length <= multiplayerPresenceLeasePageSize || last?.id == null
          ? null
          : ExpiredPresenceLeaseCursor(
              expiresAt: last!.expiresAt,
              rowId: last.id!,
            ),
    );
  }

  Future<void> upsert({
    required String matchId,
    required StoredMatchPresenceLease lease,
  }) async {
    final match = await _store.requireMatchRowForCapabilities(
      matchId,
      lock: true,
    );
    final existing = await GameMatchPresenceLease.db.findFirstRow(
      _store.sessionForCapabilities,
      where: (table) =>
          table.matchId.equals(match.id!) &
          table.userIdentifier.equals(lease.userIdentifier),
      transaction: _store.transactionForCapabilities,
    );
    if (existing == null) {
      await GameMatchPresenceLease.db.insertRow(
        _store.sessionForCapabilities,
        GameMatchPresenceLease(
          matchId: match.id!,
          userIdentifier: lease.userIdentifier,
          connectionGeneration: lease.connectionGeneration,
          expiresAt: lease.expiresAt,
          updatedAt: lease.updatedAt,
        ),
        transaction: _store.transactionForCapabilities,
      );
      return;
    }
    await GameMatchPresenceLease.db.updateRow(
      _store.sessionForCapabilities,
      existing.copyWith(
        connectionGeneration: lease.connectionGeneration,
        expiresAt: lease.expiresAt,
        updatedAt: lease.updatedAt,
      ),
      transaction: _store.transactionForCapabilities,
    );
  }

  Future<bool> renew({
    required String matchId,
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime expiresAt,
    required DateTime updatedAt,
  }) async {
    final match = await _store.requireMatchRowForCapabilities(
      matchId,
      lock: true,
    );
    final updated = await GameMatchPresenceLease.db.updateWhere(
      _store.sessionForCapabilities,
      columnValues: (table) => [
        table.expiresAt(expiresAt.toUtc()),
        table.updatedAt(updatedAt.toUtc()),
      ],
      where: (table) =>
          table.matchId.equals(match.id!) &
          table.userIdentifier.equals(userIdentifier) &
          table.connectionGeneration.equals(connectionGeneration),
      transaction: _store.transactionForCapabilities,
    );
    return updated.isNotEmpty;
  }

  Future<void> deleteOne({
    required String matchId,
    required String userIdentifier,
  }) async {
    final match = await _store.requireMatchRowForCapabilities(matchId);
    await GameMatchPresenceLease.db.deleteWhere(
      _store.sessionForCapabilities,
      where: (table) =>
          table.matchId.equals(match.id!) &
          table.userIdentifier.equals(userIdentifier),
      transaction: _store.transactionForCapabilities,
    );
  }

  Future<void> deleteAll(String matchId) async {
    final match = await _store.requireMatchRowForCapabilities(matchId);
    await GameMatchPresenceLease.db.deleteWhere(
      _store.sessionForCapabilities,
      where: (table) => table.matchId.equals(match.id!),
      transaction: _store.transactionForCapabilities,
    );
  }

  StoredMatchPresenceLease _storedLease(GameMatchPresenceLease row) {
    return StoredMatchPresenceLease(
      userIdentifier: row.userIdentifier,
      connectionGeneration: row.connectionGeneration,
      expiresAt: row.expiresAt,
      updatedAt: row.updatedAt,
    );
  }
}
