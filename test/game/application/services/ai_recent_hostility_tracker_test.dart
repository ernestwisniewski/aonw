import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/recorded_domain_command.dart';
import 'package:aonw/game/application/ports/save_snapshot.dart';
import 'package:aonw/game/application/services/ai_recent_hostility_tracker.dart';
import 'package:aonw/game/domain/game_save.dart';
import 'package:aonw/map/domain/map_selection.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiRecentHostilityTracker', () {
    test('reads recent attacks and captures against the AI player', () async {
      final eventLog = _MemoryEventLog()
        ..commands.addAll([
          _logged(
            offset: 1,
            actorPlayerId: 'player_3',
            events: const [
              UnitAttackedEvent(
                attackerUnitId: 'warrior_3',
                attackerOwnerPlayerId: 'player_3',
                defenderUnitId: 'warrior_2',
                defenderOwnerPlayerId: 'player_2',
              ),
            ],
          ),
          _logged(
            offset: 2,
            actorPlayerId: 'player_2',
            events: const [
              UnitAttackedEvent(
                attackerUnitId: 'warrior_2',
                attackerOwnerPlayerId: 'player_2',
                defenderUnitId: 'warrior_3',
                defenderOwnerPlayerId: 'player_3',
              ),
            ],
          ),
          _logged(
            offset: 3,
            actorPlayerId: 'player_4',
            events: const [
              CityCapturedEvent(
                cityId: 'city_2',
                previousOwnerPlayerId: 'player_2',
                newOwnerPlayerId: 'player_4',
              ),
            ],
          ),
          _logged(
            offset: 4,
            actorPlayerId: 'player_5',
            events: const [
              UnitAttackedEvent(
                attackerUnitId: 'warrior_5',
                attackerOwnerPlayerId: 'player_5',
                defenderUnitId: 'warrior_2',
                defenderOwnerPlayerId: 'player_2',
              ),
            ],
          ),
        ]);
      final tracker = AiRecentHostilityTracker(eventLog: eventLog);

      final hostile = await tracker.hostilePlayerIds(
        snapshot: _snapshot(eventLogOffset: 3),
        playerId: 'player_2',
      );

      expect(hostile, {'player_3', 'player_4'});
    });

    test('keeps only the configured command window', () async {
      final eventLog = _MemoryEventLog()
        ..commands.addAll([
          _logged(
            offset: 1,
            actorPlayerId: 'player_3',
            events: const [
              UnitAttackedEvent(
                attackerUnitId: 'old_warrior',
                attackerOwnerPlayerId: 'player_3',
                defenderUnitId: 'warrior_2',
                defenderOwnerPlayerId: 'player_2',
              ),
            ],
          ),
          _logged(
            offset: 2,
            actorPlayerId: 'player_4',
            events: const [
              UnitKilledEvent(
                unitId: 'warrior_2',
                ownerPlayerId: 'player_2',
                attackerUnitId: 'warrior_4',
              ),
            ],
          ),
        ]);
      final tracker = AiRecentHostilityTracker(
        eventLog: eventLog,
        commandWindow: 1,
      );

      final hostile = await tracker.hostilePlayerIds(
        snapshot: _snapshot(eventLogOffset: 2),
        playerId: 'player_2',
      );

      expect(hostile, {'player_4'});
    });

    test('reads projected hostility from an event-only entry', () async {
      final eventLog = _MemoryEventLog()
        ..commands.add(
          _logged(
            offset: 1,
            actorPlayerId: 'player_3',
            command: null,
            events: const [
              UnitAttackedEvent(
                attackerUnitId: 'warrior_3',
                attackerOwnerPlayerId: 'player_3',
                defenderUnitId: 'warrior_2',
                defenderOwnerPlayerId: 'player_2',
              ),
            ],
          ),
        );
      final tracker = AiRecentHostilityTracker(eventLog: eventLog);

      final hostile = await tracker.hostilePlayerIds(
        snapshot: _snapshot(eventLogOffset: 1),
        playerId: 'player_2',
      );

      expect(hostile, {'player_3'});
    });
  });
}

RecordedDomainCommand _logged({
  required int offset,
  required String actorPlayerId,
  required List<GameEvent> events,
  DomainCommand? command = const SkipUnitTurnCommand('unit'),
}) {
  return RecordedDomainCommand(
    offset: offset,
    timestamp: DateTime.utc(2026, 5, 17, 12, offset),
    turn: 1,
    actorPlayerId: actorPlayerId,
    command: command,
    events: events,
  );
}

CanonicalGameSnapshot _snapshot({required int eventLogOffset}) {
  return GameSnapshotFactory.create(
    save: _save(),
    eventLogOffset: eventLogOffset,
  );
}

GameSave _save() {
  return GameSave(
    id: 'save_1',
    name: 'AI hostility test',
    mapName: 'verdantia',
    mapSource: MapSource.asset,
    turn: 4,
    playerStates: const {
      'player_1': PlayerTurnState.active,
      'player_2': PlayerTurnState.active,
    },
    savedAt: DateTime.utc(2026, 5, 17, 12),
    camera: CameraState.zero,
    players: const [
      Player(id: 'player_1', name: 'Human', colorValue: 0xFF2563EB),
      Player(
        id: 'player_2',
        name: 'AI',
        colorValue: 0xFFDC2626,
        kind: PlayerKind.ai,
        ai: AiPlayer(strategyId: AiStrategyId.basic, seed: 99),
      ),
    ],
    gameMode: GameMode.hotSeat,
  );
}

class _MemoryEventLog implements EventLog {
  final commands = <RecordedDomainCommand>[];

  @override
  Future<void> append(String saveId, RecordedDomainCommand command) async {
    commands.add(command);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    return commands.isEmpty ? 0 : commands.last.offset;
  }

  @override
  Stream<RecordedDomainCommand> readAll(String saveId) => readSince(saveId);

  @override
  Stream<RecordedDomainCommand> readSince(
    String saveId, {
    int offset = 0,
  }) async* {
    for (final command in commands) {
      if (command.offset >= offset) yield command;
    }
  }
}
