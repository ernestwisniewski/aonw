import 'package:aonw_core/application.dart';
import 'package:test/test.dart';

void main() {
  test('system codec round-trips every trusted command', () {
    const commands = <SystemCommand>[
      FinalizeTimedOutTurn(
        playerIds: ['player_1', 'player_2'],
        skippedPlayerIds: ['player_2'],
      ),
      KickParticipant(
        playerId: 'player_2',
        reason: 'timeout',
        timeoutStreak: 3,
      ),
    ];

    for (final command in commands) {
      final restored = SystemCommandCodec.fromJson(
        SystemCommandCodec.toJson(command),
      );
      expect(restored.runtimeType, command.runtimeType);
      expect(
        SystemCommandCodec.toJson(restored),
        SystemCommandCodec.toJson(command),
      );
    }
  });

  test('recorded system command has an explicit non-player envelope', () {
    const record = RecordedSystemCommand(
      FinalizeTimedOutTurn(
        playerIds: ['player_1'],
        skippedPlayerIds: ['player_1'],
      ),
    );

    expect(record.toJson()['recordKind'], RecordedSystemCommand.recordKind);
    expect(
      RecordedSystemCommand.fromJson(record.toJson()).command,
      isA<FinalizeTimedOutTurn>(),
    );
  });
}
