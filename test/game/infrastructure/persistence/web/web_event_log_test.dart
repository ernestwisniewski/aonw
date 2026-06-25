import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_event_log.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast_memory.dart';

void main() {
  group('WebEventLog', () {
    late WebDatabase db;
    late WebEventLog log;

    setUp(() async {
      db = await WebDatabase.open(
        name: 'test.db',
        factory: newDatabaseFactoryMemory(),
      );
      log = WebEventLog(database: db);
    });

    tearDown(() async => db.close());

    test('latestOffset returns 0 when no commands logged', () async {
      expect(await log.latestOffset('save_1'), 0);
    });

    test('append + readSince round-trip preserves command fields', () async {
      await log.append(
        'save_1',
        LoggedCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 1, 1),
          turn: 1,
          command: const SkipUnitTurnCommand('unit_1'),
        ),
      );
      await log.append(
        'save_1',
        LoggedCommand(
          offset: 2,
          timestamp: DateTime.utc(2026, 1, 2),
          turn: 1,
          command: const SkipUnitTurnCommand('unit_2'),
        ),
      );

      final commands = await log.readSince('save_1').toList();
      expect(commands.map((c) => c.offset).toList(), [1, 2]);
      expect(await log.latestOffset('save_1'), 2);
    });

    test('readSince filters by offset', () async {
      for (var i = 1; i <= 5; i++) {
        await log.append(
          'save_1',
          LoggedCommand(
            offset: i,
            timestamp: DateTime.utc(2026, 1, i),
            turn: 1,
            command: SkipUnitTurnCommand('unit_$i'),
          ),
        );
      }

      final commands = await log.readSince('save_1', offset: 3).toList();
      expect(commands.map((c) => c.offset).toList(), [3, 4, 5]);
    });

    test('keeps each saveId independent', () async {
      await log.append(
        'save_a',
        LoggedCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 1, 1),
          turn: 1,
          command: const SkipUnitTurnCommand('unit_1'),
        ),
      );
      await log.append(
        'save_b',
        LoggedCommand(
          offset: 1,
          timestamp: DateTime.utc(2026, 1, 1),
          turn: 1,
          command: const SkipUnitTurnCommand('unit_2'),
        ),
      );

      expect((await log.readSince('save_a').toList()).length, 1);
      expect((await log.readSince('save_b').toList()).length, 1);
    });
  });
}
