import 'dart:developer' as developer;

import 'package:aonw/game/application/ports/game_logger.dart';

final class DeveloperGameLogger implements GameLogger {
  const DeveloperGameLogger();

  @override
  void info(String tag, String message) {
    developer.log(message, name: tag);
  }

  @override
  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    developer.log(
      message,
      name: tag,
      level: 900,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
