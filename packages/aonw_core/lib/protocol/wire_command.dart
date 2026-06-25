import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';

class WireCommand {
  final int v;
  final String matchId;
  final int tick;
  final int? turn;
  final String actorPlayerId;
  final Map<String, dynamic> command;

  const WireCommand({
    this.v = kProtocolVersion,
    required this.matchId,
    required this.tick,
    this.turn,
    required this.actorPlayerId,
    required this.command,
  });

  factory WireCommand.fromJson(Map<String, dynamic> json) {
    return WireCommand(
      v: WireJson.readVersion(json, 'WireCommand'),
      matchId: WireJson.requiredString(json, 'WireCommand', 'matchId'),
      tick: WireJson.requiredInt(json, 'WireCommand', 'tick'),
      turn: WireJson.optionalInt(json, 'WireCommand', 'turn'),
      actorPlayerId: WireJson.requiredString(
        json,
        'WireCommand',
        'actorPlayerId',
      ),
      command: WireJson.requiredMap(json['command'], 'WireCommand.command'),
    );
  }

  Map<String, dynamic> toJson() => {
    'v': v,
    'matchId': matchId,
    'tick': tick,
    if (turn != null) 'turn': turn,
    'actorPlayerId': actorPlayerId,
    'command': Map<String, dynamic>.from(command),
  };

  WireCommand copyWith({
    int? v,
    String? matchId,
    int? tick,
    int? turn,
    String? actorPlayerId,
    Map<String, dynamic>? command,
  }) {
    return WireCommand(
      v: v ?? this.v,
      matchId: matchId ?? this.matchId,
      tick: tick ?? this.tick,
      turn: turn ?? this.turn,
      actorPlayerId: actorPlayerId ?? this.actorPlayerId,
      command: command ?? this.command,
    );
  }
}
