import 'package:aonw/game/application/ports/logged_command.dart';

abstract interface class EventLog {
  Future<void> append(String saveId, LoggedCommand command);

  Stream<LoggedCommand> readSince(String saveId, {int offset = 0});

  Future<int> latestOffset(String saveId);

  Stream<LoggedCommand> readAll(String saveId) {
    return readSince(saveId);
  }
}
