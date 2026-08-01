import 'package:aonw/game/application/ports/recorded_domain_command.dart';

abstract interface class EventLog {
  Future<void> append(String saveId, RecordedDomainCommand command);

  Stream<RecordedDomainCommand> readSince(String saveId, {int offset = 0});

  Future<int> latestOffset(String saveId);

  Stream<RecordedDomainCommand> readAll(String saveId) {
    return readSince(saveId);
  }
}
