import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/infrastructure/persistence/web/web_database.dart';
import 'package:sembast/sembast.dart';

class WebEventLog implements EventLog {
  static final StoreRef<String, Map<String, Object?>> _store =
      stringMapStoreFactory.store('events');

  final WebDatabase database;

  const WebEventLog({required this.database});

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    final key = _key(saveId, command.offset);
    await _store.record(key).put(database.database, command.toJson());
  }

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    final prefix = '$saveId:';
    final records = await _store.find(
      database.database,
      finder: Finder(
        filter: Filter.matches(Field.key, '^${RegExp.escape(prefix)}'),
        sortOrders: [SortOrder(Field.key)],
      ),
    );
    for (final record in records) {
      final command = LoggedCommand.fromJson(
        Map<String, dynamic>.from(record.value),
      );
      if (command.offset >= offset) yield command;
    }
  }

  @override
  Future<int> latestOffset(String saveId) async {
    var latest = 0;
    await for (final command in readSince(saveId)) {
      if (command.offset > latest) latest = command.offset;
    }
    return latest;
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) => readSince(saveId);

  static String _key(String saveId, int offset) =>
      '$saveId:${offset.toString().padLeft(12, '0')}';
}
