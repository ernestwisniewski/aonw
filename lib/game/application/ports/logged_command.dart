import 'package:aonw/game/application/ports/activity_history_entry.dart';
import 'package:aonw/game/application/ports/logged_game_command_codec.dart';
import 'package:aonw/game/domain/game_command_context.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/match_rules.dart';

class LoggedCommand {
  final int offset;
  final DateTime timestamp;

  /// Game turn used by deterministic reducers. It is independent from the
  /// transport command tick and can be absent in legacy network history.
  final int? turn;

  /// The originating command, when it is visible to this log reader.
  ///
  /// Multiplayer projections can expose safe domain events while redacting
  /// the command that produced them. Such event-only entries remain useful
  /// for activity and hostility tracking, but cannot be reduced during state
  /// replay.
  final GameCommand? command;
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
      turn: json['turn'] as int?,
      actorPlayerId: json['actorPlayerId'] as String?,
      canAct: json['canAct'] as bool? ?? true,
      commandTick: json['commandTick'] as int? ?? 0,
      ignoreFogOfWar: json['ignoreFogOfWar'] as bool? ?? false,
      command: switch (json['command']) {
        final Map<Object?, Object?> value => LoggedGameCommandCodec.fromJson(
          Map<String, dynamic>.from(value),
        ),
        null => null,
        final value => throw FormatException(
          'Expected command to be a JSON object or null, got '
          '${value.runtimeType}.',
        ),
      },
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
      if (turn != null) 'turn': turn,
      'actorPlayerId': ?actorPlayerId,
      'canAct': canAct,
      'commandTick': commandTick,
      'ignoreFogOfWar': ignoreFogOfWar,
      if (command case final command?)
        'command': LoggedGameCommandCodec.toJson(command),
      'events': events.map(GameEventSerializer.toJson).toList(),
      'activity': activity.map((entry) => entry.toJson()).toList(),
    };
  }

  GameCommandContext toCommandContext({
    VictoryRules victoryRules = VictoryRules.standard,
    PaceBalance paceBalance = PaceBalance.unlimited,
    int? fallbackTurn,
  }) {
    final replayTurn = turn ?? fallbackTurn;
    if (replayTurn == null) {
      throw StateError(
        'Cannot build a command context without the originating game turn.',
      );
    }
    return GameCommandContext(
      actorPlayerId: actorPlayerId,
      canAct: canAct,
      combatSeedTurn: replayTurn,
      commandTick: commandTick,
      paceBalance: paceBalance,
      victoryRules: victoryRules,
      ignoreFogOfWar: ignoreFogOfWar,
    );
  }
}
