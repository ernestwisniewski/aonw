import 'package:aonw_server/src/observability/server_operational_event_sink.dart';
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';

void main() {
  test('emits the supported operational events with deliberate fields', () {
    final records = <_LogRecord>[];
    final sink = _recordingSink(records);

    sink.authRateLimited(action: _AuthAction.emailLogin);
    sink.commandRejected(matchId: 'match-123', reasonCode: 'stale_turn');
    sink.streamConnected(matchId: 'match-123', reconnect: true);
    sink.streamDisconnected(matchId: 'match-123');

    expect(records.map((record) => record.message), [
      'event=auth_rate_limited action=emailLogin',
      'event=multiplayer_command_rejected '
          'match_id=match-123 reason=stale_turn',
      'event=multiplayer_stream_reconnected match_id=match-123',
      'event=multiplayer_stream_disconnected match_id=match-123',
    ]);
    expect(records.map((record) => record.level), [
      LogLevel.warning,
      LogLevel.info,
      LogLevel.info,
      LogLevel.info,
    ]);
  });

  test('drops unsafe identifiers and never stringifies projection errors', () {
    final records = <_LogRecord>[];
    final sink = _recordingSink(records);
    final error = _SensitiveError();
    final stackTrace = StackTrace.current;

    sink.commandRejected(
      matchId: 'user@example.test\nsecret-token',
      reasonCode: 'user@example.test',
    );
    sink.projectionFailed(
      matchId: 'match-123',
      surface: MultiplayerProjectionSurface.snapshot,
      error: error,
      stackTrace: stackTrace,
    );

    expect(
      records.first.message,
      'event=multiplayer_command_rejected '
      'match_id=invalid reason=unspecified',
    );
    expect(records.first.message, isNot(contains('example.test')));
    expect(records.first.message, isNot(contains('secret-token')));
    expect(
      records.last.message,
      'event=multiplayer_projection_failed '
      'match_id=match-123 surface=snapshot error_type=_SensitiveError',
    );
    expect(records.last.level, LogLevel.error);
    expect(records.last.stackTrace, same(stackTrace));
    expect(error.toStringCalled, isFalse);
  });

  test('logging failures never change request behavior', () {
    final sink = ServerpodOperationalEventSink.withWriter((
      _, {
      required level,
      stackTrace,
    }) {
      throw StateError('logger unavailable');
    });

    expect(
      () => sink.streamDisconnected(matchId: 'match-123'),
      returnsNormally,
    );
  });
}

ServerpodOperationalEventSink _recordingSink(List<_LogRecord> records) {
  return ServerpodOperationalEventSink.withWriter((
    message, {
    required level,
    stackTrace,
  }) {
    records.add(
      _LogRecord(message: message, level: level, stackTrace: stackTrace),
    );
  });
}

enum _AuthAction { emailLogin }

final class _SensitiveError {
  bool toStringCalled = false;

  @override
  String toString() {
    toStringCalled = true;
    return 'secret-token user@example.test';
  }
}

final class _LogRecord {
  const _LogRecord({
    required this.message,
    required this.level,
    required this.stackTrace,
  });

  final String message;
  final LogLevel level;
  final StackTrace? stackTrace;
}
