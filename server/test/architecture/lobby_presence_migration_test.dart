import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('presence migration retires unverifiable lobbies and adds leases', () {
    final versions = File('migrations/migration_registry.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    final version = versions.singleWhere(
      (entry) => entry.endsWith('-lobby-presence-leases'),
    );
    expect(version, versions.last);

    final migration = File(
      'migrations/$version/migration.sql',
    ).readAsStringSync();
    final definition = File(
      'migrations/$version/definition.sql',
    ).readAsStringSync();

    const table = 'CREATE TABLE "aonw_match_presence_lease"';
    const uniqueMembership =
        'CREATE UNIQUE INDEX "aonw_match_presence_user_idx" '
        'ON "aonw_match_presence_lease" USING btree '
        '("matchId", "userIdentifier");';
    const expiryIndex =
        'CREATE INDEX "aonw_match_presence_expiry_idx" '
        'ON "aonw_match_presence_lease" USING btree ("expiresAt");';

    for (final sql in [migration, definition]) {
      expect(sql, contains(table));
      expect(sql, contains(uniqueMembership));
      expect(sql, contains(expiryIndex));
      expect(sql, contains('REFERENCES "aonw_match"("id")'));
      expect(sql, contains('ON DELETE CASCADE'));
    }

    expect(migration, contains('UPDATE "aonw_snapshot"'));
    expect(migration, contains("'{state,phase}'"));
    expect(migration, contains("to_jsonb('abandoned'::text)"));
    expect(migration, contains("'{state,reason}'"));
    expect(migration, contains("to_jsonb('protocol_upgrade'::text)"));
    expect(migration, contains('UPDATE "aonw_match"'));
    expect(migration, contains('SET "state" = \'abandoned\''));
    expect(migration, contains('"endedAt" = now()'));
    expect(migration, contains('"autoStartAt" = NULL'));
    expect(migration, isNot(contains('DELETE FROM "aonw_match"')));
  });

  test('presence lease stays server-only in the schema source', () {
    final schema = File(
      'lib/src/multiplayer/models/game_match_presence_lease.spy.yaml',
    ).readAsStringSync();

    expect(schema, contains('serverOnly: true'));
    expect(schema, contains('connectionGeneration: String'));
    expect(schema, contains('expiresAt: DateTime'));
    expect(schema, contains('relation(name=match_presence_leases'));
  });
}
