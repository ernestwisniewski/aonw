import 'dart:convert';

import 'package:aonw_core/protocol.dart';
import 'package:serverpod/serverpod.dart';

/// Persists exactly one monotonic authoritative snapshot per match.
final class MultiplayerMatchSnapshotStore {
  const MultiplayerMatchSnapshotStore(this._session, this._transaction);

  final Session _session;
  final Transaction? _transaction;

  Future<void> saveLatest(int matchRowId, WireSnapshot snapshot) async {
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
      await _insertSnapshot(matchRowId, snapshot, now);
    } else {
      await _updateSnapshot(latest[0] as int, snapshot, now);
    }
    await _deleteSupersededSnapshots(matchRowId, snapshot.offset);
  }

  Future<void> _insertSnapshot(
    int matchRowId,
    WireSnapshot snapshot,
    DateTime createdAt,
  ) async {
    final inserted = await _session.db.unsafeExecute(
      '''
INSERT INTO "aonw_snapshot" ("matchId", "offset", "snapshot", "createdAt")
VALUES (@matchId, @offset, CAST(@snapshot AS json), @createdAt)
''',
      transaction: _transaction,
      parameters: QueryParameters.named({
        'matchId': matchRowId,
        ..._snapshotPayload(snapshot, createdAt),
      }),
    );
    if (inserted != 1) {
      throw StateError('Failed to insert the authoritative snapshot.');
    }
  }

  Future<void> _updateSnapshot(
    int snapshotId,
    WireSnapshot snapshot,
    DateTime createdAt,
  ) async {
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
        ..._snapshotPayload(snapshot, createdAt),
        'snapshotId': snapshotId,
      }),
    );
    if (updated != 1) {
      throw StateError(
        'The authoritative snapshot changed while it was being saved.',
      );
    }
  }

  Future<void> _deleteSupersededSnapshots(int matchRowId, int offset) async {
    await _session.db.unsafeExecute(
      '''
DELETE FROM "aonw_snapshot"
WHERE "matchId" = @matchId AND "offset" < @offset
''',
      transaction: _transaction,
      parameters: QueryParameters.named({
        'matchId': matchRowId,
        'offset': offset,
      }),
    );
  }

  Map<String, Object?> _snapshotPayload(
    WireSnapshot snapshot,
    DateTime createdAt,
  ) => {
    'offset': snapshot.offset,
    'snapshot': jsonEncode(snapshot.toJson()),
    'createdAt': createdAt,
  };
}
