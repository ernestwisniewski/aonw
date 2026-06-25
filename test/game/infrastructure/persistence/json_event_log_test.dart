import 'dart:io';

import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/infrastructure/persistence/json_event_log.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JsonEventLog', () {
    late Directory tempDir;
    late JsonEventLog eventLog;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('json_event_log_');
      eventLog = JsonEventLog(savesDir: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('missing log has zero latest offset and no commands', () async {
      expect(await eventLog.latestOffset('save_1'), 0);
      expect(await eventLog.readAll('save_1').toList(), isEmpty);
    });

    test('appends JSONL entries and reads from inclusive offset', () async {
      await eventLog.append('save_1', _logged(1, 'p1'));
      await eventLog.append('save_1', _logged(2, 'p2'));
      await eventLog.append('save_1', _logged(5, 'p1'));

      final commands = await eventLog.readSince('save_1', offset: 2).toList();

      expect(commands.map((command) => command.offset), [2, 5]);
      expect(commands.first.actorPlayerId, 'p2');
      expect(commands.first.command, isA<EndTurnCommand>());
      expect(commands.first.events.single, isA<TurnEndedEvent>());
      expect(await eventLog.latestOffset('save_1'), 5);
    });
  });
}

LoggedCommand _logged(int offset, String playerId) {
  return LoggedCommand(
    offset: offset,
    timestamp: DateTime.utc(2026, 4, 24, 12, offset),
    turn: 1,
    actorPlayerId: playerId,
    command: EndTurnCommand(playerId),
    events: [TurnEndedEvent(playerId: playerId)],
  );
}
