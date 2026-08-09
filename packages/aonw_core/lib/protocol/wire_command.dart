import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'wire_command.freezed.dart';

@freezed
abstract class WireCommand with _$WireCommand {
  const WireCommand._();

  const factory WireCommand({
    @Default(kProtocolVersion) int v,
    required String matchId,
    required int tick,
    int? turn,
    required String actorPlayerId,
    required Map<String, dynamic> command,
  }) = _WireCommand;

  factory WireCommand.fromJson(Map<String, dynamic> json) {
    return WireCommand(
      v: WireJson.readVersion(
        json,
        'WireCommand',
        expectedVersion: kProtocolVersion,
      ),
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
}
