sealed class SystemCommand {
  const SystemCommand();
}

/// Wire/persistence codec owned by the trusted system-command boundary.
abstract final class SystemCommandCodec {
  static Map<String, dynamic> toJson(SystemCommand command) =>
      switch (command) {
        FinalizeTimedOutTurn(:final playerIds, :final skippedPlayerIds) => {
          'type': 'FinalizeTimedOutTurn',
          'playerIds': playerIds,
          'skippedPlayerIds': skippedPlayerIds,
        },
        KickParticipant(:final playerId, :final reason, :final timeoutStreak) =>
          {
            'type': 'KickParticipant',
            'playerId': playerId,
            'reason': reason,
            'timeoutStreak': timeoutStreak,
          },
      };

  static SystemCommand fromJson(Map<String, dynamic> json) {
    return switch (json['type']) {
      'FinalizeTimedOutTurn' => FinalizeTimedOutTurn(
        playerIds: _stringList(json, 'playerIds'),
        skippedPlayerIds: _stringList(json, 'skippedPlayerIds'),
      ),
      'KickParticipant' => KickParticipant(
        playerId: json['playerId'] as String,
        reason: json['reason'] as String,
        timeoutStreak: json['timeoutStreak'] as int,
      ),
      final type => throw FormatException('Unknown SystemCommand type: $type'),
    };
  }

  static List<String> _stringList(Map<String, dynamic> json, String key) =>
      List<String>.unmodifiable((json[key] as List).cast<String>());
}

/// Persisted envelope that cannot be decoded as a player-authored command.
final class RecordedSystemCommand {
  const RecordedSystemCommand(this.command);

  static const recordKind = 'system';

  final SystemCommand command;

  Map<String, dynamic> toJson() => {
    'recordKind': recordKind,
    'command': SystemCommandCodec.toJson(command),
  };

  factory RecordedSystemCommand.fromJson(Map<String, dynamic> json) {
    if (json['recordKind'] != recordKind) {
      throw const FormatException('Expected a recorded system command.');
    }
    return RecordedSystemCommand(
      SystemCommandCodec.fromJson(
        Map<String, dynamic>.from(json['command'] as Map),
      ),
    );
  }

  static bool isEnvelope(Map<String, dynamic> json) =>
      json['recordKind'] == recordKind;
}

/// Finalizes an expired simultaneous turn using the participant scope chosen
/// by the trusted server boundary.
final class FinalizeTimedOutTurn extends SystemCommand {
  const FinalizeTimedOutTurn({
    required this.playerIds,
    required this.skippedPlayerIds,
  });

  final List<String> playerIds;
  final List<String> skippedPlayerIds;
}

/// Applies the existing participant-unavailable lifecycle transition.
final class KickParticipant extends SystemCommand {
  const KickParticipant({
    required this.playerId,
    required this.reason,
    required this.timeoutStreak,
  });

  final String playerId;
  final String reason;
  final int timeoutStreak;
}
