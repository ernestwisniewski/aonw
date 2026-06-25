abstract interface class GameLogger {
  void info(String tag, String message);

  void warn(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]);
}
