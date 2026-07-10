import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('latest database definition preserves auth maintenance indexes', () {
    final registry = File('migrations/migration_registry.txt');
    final latestVersion = registry
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .last;
    final migrationDirectory = Directory('migrations/$latestVersion');
    final definition = File(
      '${migrationDirectory.path}/definition.sql',
    ).readAsStringSync();
    final migration = File(
      'migrations/20260710111535872-auth-maintenance-indexes/migration.sql',
    ).readAsStringSync();

    expect(definition, contains('"aonw_steam_auth_request_expires_at_idx"'));
    expect(
      definition,
      contains('"serverpod_auth_core_jwt_refresh_token_last_updated_at"'),
    );
    expect(
      definition,
      contains('"serverpod_auth_idp_rate_limited_request_attempt_composite"'),
    );
    expect(
      migration,
      contains(
        'Apply this small\n-- auth-table migration in a maintenance window',
      ),
    );
    expect(
      RegExp(
        r'^CREATE INDEX CONCURRENTLY',
        multiLine: true,
      ).hasMatch(migration),
      isFalse,
    );
  });
}
