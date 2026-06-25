import 'dart:convert';
import 'dart:io';

import 'package:aonw/game/application/ports/event_log.dart';
import 'package:aonw/game/application/ports/logged_command.dart';
import 'package:aonw/game/infrastructure/persistence/game_storage.dart';

class JsonEventLog implements EventLog {
  final Directory? savesDir;

  const JsonEventLog({this.savesDir});

  @override
  Future<void> append(String saveId, LoggedCommand command) async {
    final file = await _file(saveId);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(command.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  @override
  Stream<LoggedCommand> readSince(String saveId, {int offset = 0}) async* {
    final file = await _file(saveId);
    if (!await file.exists()) return;

    final lines = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (line.trim().isEmpty) continue;
      final command = LoggedCommand.fromJson(
        jsonDecode(line) as Map<String, dynamic>,
      );
      if (command.offset >= offset) yield command;
    }
  }

  @override
  Stream<LoggedCommand> readAll(String saveId) {
    return readSince(saveId);
  }

  @override
  Future<int> latestOffset(String saveId) async {
    var latest = 0;
    await for (final command in readSince(saveId)) {
      if (command.offset > latest) latest = command.offset;
    }
    return latest;
  }

  Future<File> _file(String saveId) async {
    final dir = await GameStorage.saveDirectory(saveId, savesDir: savesDir);
    return File('${dir.path}/events.log');
  }
}
