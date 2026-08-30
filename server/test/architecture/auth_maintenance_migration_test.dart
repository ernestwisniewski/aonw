import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('initial database definition contains auth maintenance indexes', () {
    final registry = File('migrations/migration_registry.txt');
    final versions = registry
        .readAsLinesSync()
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
    expect(versions, hasLength(1));
    expect(versions.single, endsWith('-initial-schema'));
    final migrationDirectory = Directory('migrations/${versions.single}');
    final definition = File(
      '${migrationDirectory.path}/definition.sql',
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
    expect(definition, contains('CREATE TABLE "aonw_game_match"'));
    for (final removedTable in [
      'aonw_match',
      'aonw_player',
      'aonw_snapshot',
      'aonw_event',
      'aonw_match_presence_lease',
    ]) {
      expect(definition, isNot(contains('CREATE TABLE "$removedTable"')));
    }
  });
}
