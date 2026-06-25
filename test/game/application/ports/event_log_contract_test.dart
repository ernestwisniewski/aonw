import 'dart:io';

import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/infrastructure/persistence/json_event_log.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventLog contract: JsonEventLog', () {
    late Directory tempDir;
    late EventLog eventLog;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('event_log_contract_');
      eventLog = JsonEventLog(savesDir: tempDir);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('missing logs read as empty with zero latest offset', () async {
      expect(await eventLog.latestOffset('save_1'), 0);
      expect(await eventLog.readAll('save_1').toList(), isEmpty);
      expect(await eventLog.readSince('save_1', offset: 1).toList(), isEmpty);
    });

    test(
      'append preserves order and readSince uses an inclusive offset',
      () async {
        await eventLog.append('save_1', _logged(1, 'player_1'));
        await eventLog.append('save_1', _logged(2, 'player_2'));
        await eventLog.append('save_1', _logged(4, 'player_1'));

        final all = await eventLog.readAll('save_1').toList();
        final sinceTwo = await eventLog.readSince('save_1', offset: 2).toList();

        expect(all.map((command) => command.offset), [1, 2, 4]);
        expect(sinceTwo.map((command) => command.offset), [2, 4]);
        expect(sinceTwo.first.actorPlayerId, 'player_2');
        expect(sinceTwo.first.command, isA<EndTurnCommand>());
        expect(sinceTwo.first.events.single, isA<TurnEndedEvent>());
        expect(await eventLog.latestOffset('save_1'), 4);
      },
    );
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
