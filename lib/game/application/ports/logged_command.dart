import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/domain/reducer/game_state/game_command_context.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';

class LoggedCommand {
  final int offset;
  final DateTime timestamp;
  final int turn;
  final GameCommand command;
  final List<GameEvent> events;
  final List<LoggedActivityEntry> activity;
  final String? actorPlayerId;
  final bool canAct;
  final int commandTick;
  final bool ignoreFogOfWar;

  const LoggedCommand({
    required this.offset,
    required this.timestamp,
    required this.turn,
    required this.command,
    this.events = const [],
    this.activity = const [],
    this.actorPlayerId,
    this.canAct = true,
    this.commandTick = 0,
    this.ignoreFogOfWar = false,
  });

  factory LoggedCommand.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>? ?? const <dynamic>[];
    final rawActivity = json['activity'] as List<dynamic>? ?? const <dynamic>[];
    return LoggedCommand(
      offset: json['offset'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String).toUtc(),
      turn: json['turn'] as int,
      actorPlayerId: json['actorPlayerId'] as String?,
      canAct: json['canAct'] as bool? ?? true,
      commandTick: json['commandTick'] as int? ?? 0,
      ignoreFogOfWar: json['ignoreFogOfWar'] as bool? ?? false,
      command: GameCommandSerializer.fromJson(
        json['command'] as Map<String, dynamic>,
      ),
      events: rawEvents
          .map(
            (event) => GameEventSerializer.fromJson(
              Map<String, dynamic>.from(event as Map),
            ),
          )
          .toList(),
      activity: rawActivity
          .map(
            (entry) => LoggedActivityEntry.fromJson(
              Map<String, dynamic>.from(entry as Map),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'turn': turn,
      'actorPlayerId': ?actorPlayerId,
      'canAct': canAct,
      'commandTick': commandTick,
      'ignoreFogOfWar': ignoreFogOfWar,
      'command': GameCommandSerializer.toJson(command),
      'events': events.map(GameEventSerializer.toJson).toList(),
      'activity': activity.map((entry) => entry.toJson()).toList(),
    };
  }

  GameCommandContext toCommandContext() {
    return GameCommandContext(
      actorPlayerId: actorPlayerId,
      canAct: canAct,
      commandTick: commandTick,
      ignoreFogOfWar: ignoreFogOfWar,
    );
  }
}
