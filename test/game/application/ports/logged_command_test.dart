import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoggedCommand', () {
    test('round-trips command, events, actor and timestamp', () {
      final logged = LoggedCommand(
        offset: 7,
        timestamp: DateTime.utc(2026, 4, 24, 10, 30),
        turn: 4,
        actorPlayerId: 'p1',
        canAct: false,
        commandTick: 42,
        ignoreFogOfWar: true,
        command: const MoveUnitCommand('unit_1', 4, 5),
        events: const [
          UnitMovedEvent(
            unitId: 'unit_1',
            fromCol: 3,
            fromRow: 5,
            toCol: 4,
            toRow: 5,
          ),
        ],
        activity: const [
          LoggedActivityEntry(
            eventIndex: 0,
            playerId: 'p1',
            event: UnitMovedEvent(
              unitId: 'unit_1',
              fromCol: 3,
              fromRow: 5,
              toCol: 4,
              toRow: 5,
            ),
            context: GameActivityContext.empty,
          ),
        ],
      );

      final json = logged.toJson();
      final restored = LoggedCommand.fromJson(json);

      expect(restored.offset, 7);
      expect(restored.timestamp, DateTime.utc(2026, 4, 24, 10, 30));
      expect(restored.turn, 4);
      expect(restored.actorPlayerId, 'p1');
      expect(restored.canAct, isFalse);
      expect(restored.commandTick, 42);
      expect(restored.ignoreFogOfWar, isTrue);
      expect(restored.toCommandContext().actorPlayerId, 'p1');
      expect(restored.toCommandContext().ignoreFogOfWar, isTrue);
      expect(restored.command, isA<MoveUnitCommand>());
      expect(restored.events.single, isA<UnitMovedEvent>());
      expect(restored.activity.single.event, isA<UnitMovedEvent>());
    });

    test('omits null actor and restores empty events', () {
      final logged = LoggedCommand(
        offset: 1,
        timestamp: DateTime.utc(2026),
        turn: 1,
        command: const ToggleMoveTargetingCommand(),
      );

      final json = logged.toJson();
      final restored = LoggedCommand.fromJson(json);

      expect(json.containsKey('actorPlayerId'), isFalse);
      expect(restored.actorPlayerId, isNull);
      expect(restored.events, isEmpty);
      expect(restored.activity, isEmpty);
    });
  });
}
