import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('latest schema preserves bounded multiplayer query indexes', () {
    final versions = File('migrations/migration_registry.txt')
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    final latestDefinition = File(
      'migrations/${versions.last}/definition.sql',
    ).readAsStringSync();
    final migrationVersion = versions.singleWhere(
      (version) => version.endsWith('-multiplayer-query-indexes'),
    );
    final migrationIndex = versions.indexOf(migrationVersion);
    expect(migrationIndex, greaterThan(0));
    final previousDefinition = File(
      'migrations/${versions[migrationIndex - 1]}/definition.sql',
    ).readAsStringSync();
    final migration = File(
      'migrations/$migrationVersion/migration.sql',
    ).readAsStringSync();
    final quickplayMapMigrationVersion = versions.singleWhere(
      (version) => version.endsWith('-quickplay-map-index'),
    );
    final quickplayMapMigration = File(
      'migrations/$quickplayMapMigrationVersion/migration.sql',
    ).readAsStringSync();

    const participantIndex =
        'CREATE UNIQUE INDEX "aonw_player_user_match_idx" '
        'ON "aonw_player" USING btree ("userIdentifier", "matchId");';
    const stateOrderIndex =
        'CREATE INDEX "aonw_match_state_created_public_idx" ON "aonw_match" '
        'USING btree ("state", "createdAt", "publicId");';
    const publicDiscoveryIndex =
        'CREATE INDEX "aonw_match_public_discovery_idx" ON "aonw_match" '
        'USING btree ("state", "private", "inviteCode", "createdAt", '
        '"publicId");';
    const quickplayIndex =
        'CREATE INDEX "aonw_match_quickplay_candidate_idx" ON "aonw_match" '
        'USING btree ("state", "private", "quickplay", "inviteCode", '
        '"mapName", "createdAt", "publicId");';
    const originalQuickplayIndex =
        'CREATE INDEX "aonw_match_quickplay_candidate_idx" ON "aonw_match" '
        'USING btree ("state", "private", "quickplay", "inviteCode", '
        '"createdAt", "publicId");';

    for (final index in [
      participantIndex,
      stateOrderIndex,
      publicDiscoveryIndex,
    ]) {
      expect(latestDefinition, contains(index));
      expect(migration, contains(index));
    }
    expect(latestDefinition, contains(quickplayIndex));
    expect(migration, contains(originalQuickplayIndex));
    expect(
      quickplayMapMigration,
      contains('DROP INDEX "aonw_match_quickplay_candidate_idx";'),
    );
    expect(quickplayMapMigration, contains(quickplayIndex));
    expect(quickplayMapMigration, contains('during a maintenance window'));

    expect(latestDefinition, contains('"aonw_player_match_public_idx"'));
    expect(
      previousDefinition,
      contains(
        'CREATE UNIQUE INDEX "aonw_player_match_user_idx" '
        'ON "aonw_player" USING btree ("matchId", "userIdentifier");',
      ),
    );
    expect(latestDefinition, isNot(contains('"aonw_player_match_user_idx"')));
    expect(latestDefinition, isNot(contains('"aonw_match_state_idx"')));
    expect(migration, contains('DROP INDEX "aonw_player_match_user_idx";'));
    expect(migration, contains('DROP INDEX "aonw_match_state_idx";'));
    expect(
      migration,
      contains('multiplayer-index migration in a maintenance window'),
    );
    expect(migration, contains('DROP/CREATE takes table\n-- locks'));
    expect(
      RegExp(
        r'^CREATE (?:UNIQUE )?INDEX CONCURRENTLY',
        multiLine: true,
      ).hasMatch(migration),
      isFalse,
    );
  });
}
