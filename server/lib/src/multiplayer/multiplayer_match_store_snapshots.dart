part of 'multiplayer_match_store.dart';

extension ServerpodMultiplayerMatchStoreSnapshots
    on ServerpodMultiplayerMatchStore {
  Future<void> _saveLatestSnapshot(
    int matchRowId,
    WireSnapshot snapshot,
  ) async {
    final latestRows = await _session.db.unsafeQuery(
      '''
SELECT "id", "offset"
FROM "aonw_snapshot"
WHERE "matchId" = @matchId
ORDER BY "offset" DESC
LIMIT 1
''',
      transaction: _transaction,
      parameters: QueryParameters.named({'matchId': matchRowId}),
    );
    final latest = latestRows.isEmpty ? null : latestRows.first;
    final latestOffset = latest == null ? null : latest[1] as int;
    if (latestOffset != null && latestOffset > snapshot.offset) {
      throw StateError(
        'Cannot replace snapshot at offset $latestOffset with stale '
        'offset ${snapshot.offset}.',
      );
    }

    final now = DateTime.now().toUtc();
    if (latest == null) {
      final inserted = await _session.db.unsafeExecute(
        '''
INSERT INTO "aonw_snapshot" ("matchId", "offset", "snapshot", "createdAt")
VALUES (@matchId, @offset, CAST(@snapshot AS json), @createdAt)
''',
        transaction: _transaction,
        parameters: QueryParameters.named({
          'matchId': matchRowId,
          ..._snapshotPayloadQueryParameterValues(
            snapshot: snapshot,
            createdAt: now,
          ),
        }),
      );
      if (inserted != 1) {
        throw StateError('Failed to insert the authoritative snapshot.');
      }
    } else {
      final latestId = latest[0] as int;
      final updated = await _session.db.unsafeExecute(
        '''
UPDATE "aonw_snapshot"
SET "offset" = @offset,
    "snapshot" = CAST(@snapshot AS json),
    "createdAt" = @createdAt
WHERE "id" = @snapshotId AND "offset" <= @offset
''',
        transaction: _transaction,
        parameters: QueryParameters.named({
          ..._snapshotPayloadQueryParameterValues(
            snapshot: snapshot,
            createdAt: now,
          ),
          'snapshotId': latestId,
        }),
      );
      if (updated != 1) {
        throw StateError(
          'The authoritative snapshot changed while it was being saved.',
        );
      }
    }

    await _session.db.unsafeExecute(
      '''
DELETE FROM "aonw_snapshot"
WHERE "matchId" = @matchId AND "offset" < @offset
''',
      transaction: _transaction,
      parameters: QueryParameters.named({
        'matchId': matchRowId,
        'offset': snapshot.offset,
      }),
    );
  }

  Map<String, Object?> _snapshotPayloadQueryParameterValues({
    required WireSnapshot snapshot,
    required DateTime createdAt,
  }) {
    return {
      'offset': snapshot.offset,
      'snapshot': jsonEncode(snapshot.toJson()),
      'createdAt': createdAt,
    };
  }
}
