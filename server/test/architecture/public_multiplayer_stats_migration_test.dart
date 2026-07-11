import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('stats migration adds lifecycle columns, backfill, and indexes', () {
    final versions = File('migrations/migration_registry.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    final version = versions.singleWhere(
      (entry) => entry.endsWith('-public-multiplayer-stats'),
    );
    final migration = File(
      'migrations/$version/migration.sql',
    ).readAsStringSync();
    final definition = File(
      'migrations/${versions.last}/definition.sql',
    ).readAsStringSync();

    for (final column in ['endedAt', 'outcomeCondition', 'winnerPlayerId']) {
      expect(migration, contains('ADD COLUMN "$column"'));
      expect(definition, contains('"$column"'));
    }
    expect(migration, contains('SELECT DISTINCT ON ("matchId")'));
    expect(migration, contains('ORDER BY "matchId", "offset" DESC'));
    expect(migration, contains("IN ('finished', 'abandoned')"));
    expect(migration, contains('"match"."endedAt" IS NULL'));
    expect(definition, contains('"aonw_match_started_at_idx"'));
    expect(definition, contains('"aonw_match_ended_at_idx"'));
  });
}
