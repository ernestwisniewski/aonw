import 'package:serverpod/serverpod.dart';

enum MultiplayerProjectionSurface { matchList, snapshot, eventHistory, stream }

typedef ServerOperationalLogWriter =
    void Function(
      String message, {
      required LogLevel level,
      StackTrace? stackTrace,
    });

/// Emits a deliberately small, non-sensitive set of operational events.
///
/// Callers provide only enums, canonical match ids, and internal reason codes.
/// Tokens, account identifiers, network addresses, nonces, and payloads do not
/// belong in this interface.
abstract interface class ServerOperationalEventSink {
  void authRateLimited({required Enum action});

  void commandRejected({required String matchId, required String reasonCode});

  void streamConnected({required String matchId, required bool reconnect});

  void streamDisconnected({required String matchId});

  void matchAbandoned({required String matchId, required String reasonCode});

  void projectionFailed({
    required String matchId,
    required MultiplayerProjectionSurface surface,
    required Object error,
    required StackTrace stackTrace,
  });
}

final class ServerpodOperationalEventSink
    implements ServerOperationalEventSink {
  factory ServerpodOperationalEventSink(Session session) {
    return ServerpodOperationalEventSink.withWriter((
      message, {
      required level,
      stackTrace,
    }) {
      session.log(message, level: level, stackTrace: stackTrace);
    });
  }

  ServerpodOperationalEventSink.withWriter(this._write);

  static final RegExp _safeIdentifierPattern = RegExp(
    r'^[A-Za-z0-9_-]{1,128}$',
  );
  static final RegExp _safeReasonPattern = RegExp(r'^[a-z0-9_]{1,80}$');
  static final RegExp _safeTypePattern = RegExp(r'^[A-Za-z0-9_]{1,80}$');

  final ServerOperationalLogWriter _write;

  @override
  void authRateLimited({required Enum action}) {
    _emit(
      'event=auth_rate_limited action=${action.name}',
      level: LogLevel.warning,
    );
  }

  @override
  void commandRejected({required String matchId, required String reasonCode}) {
    _emit(
      'event=multiplayer_command_rejected '
      'match_id=${_safeIdentifier(matchId)} '
      'reason=${_safeReason(reasonCode)}',
      level: LogLevel.info,
    );
  }

  @override
  void streamConnected({required String matchId, required bool reconnect}) {
    _emit(
      'event=${reconnect ? 'multiplayer_stream_reconnected' : 'multiplayer_stream_connected'} '
      'match_id=${_safeIdentifier(matchId)}',
      level: LogLevel.info,
    );
  }

  @override
  void streamDisconnected({required String matchId}) {
    _emit(
      'event=multiplayer_stream_disconnected '
      'match_id=${_safeIdentifier(matchId)}',
      level: LogLevel.info,
    );
  }

  @override
  void matchAbandoned({required String matchId, required String reasonCode}) {
    _emit(
      'event=multiplayer_match_abandoned '
      'match_id=${_safeIdentifier(matchId)} '
      'reason=${_safeReason(reasonCode)}',
      level: LogLevel.info,
    );
  }

  @override
  void projectionFailed({
    required String matchId,
    required MultiplayerProjectionSurface surface,
    required Object error,
    required StackTrace stackTrace,
  }) {
    _emit(
      'event=multiplayer_projection_failed '
      'match_id=${_safeIdentifier(matchId)} '
      'surface=${surface.name} '
      'error_type=${_safeType(error.runtimeType.toString())}',
      level: LogLevel.error,
      stackTrace: stackTrace,
    );
  }

  void _emit(
    String message, {
    required LogLevel level,
    StackTrace? stackTrace,
  }) {
    try {
      _write(message, level: level, stackTrace: stackTrace);
    } catch (_) {
      // Observability is best-effort and must never change request behavior.
    }
  }

  String _safeIdentifier(String value) {
    return _safeIdentifierPattern.hasMatch(value) ? value : 'invalid';
  }

  String _safeReason(String value) {
    return _safeReasonPattern.hasMatch(value) ? value : 'unspecified';
  }

  String _safeType(String value) {
    return _safeTypePattern.hasMatch(value) ? value : 'UnknownError';
  }
}

final class NoopServerOperationalEventSink
    implements ServerOperationalEventSink {
  const NoopServerOperationalEventSink();

  @override
  void authRateLimited({required Enum action}) {}

  @override
  void commandRejected({required String matchId, required String reasonCode}) {}

  @override
  void streamConnected({required String matchId, required bool reconnect}) {}

  @override
  void streamDisconnected({required String matchId}) {}

  @override
  void matchAbandoned({required String matchId, required String reasonCode}) {}

  @override
  void projectionFailed({
    required String matchId,
    required MultiplayerProjectionSurface surface,
    required Object error,
    required StackTrace stackTrace,
  }) {}
}
