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
    final file = await _file(saveId);
    if (!await file.exists()) return 0;
    final line = await _readLastNonEmptyLine(file);
    if (line == null) return 0;
    return LoggedCommand.fromJson(
      jsonDecode(line) as Map<String, dynamic>,
    ).offset;
  }

  Future<File> _file(String saveId) async {
    final dir = await GameStorage.saveDirectory(saveId, savesDir: savesDir);
    return File('${dir.path}/events.log');
  }
}

Future<String?> _readLastNonEmptyLine(File file) async {
  final reader = await file.open();
  try {
    final length = await reader.length();
    if (length == 0) return null;

    var window = 4096;
    while (true) {
      final start = length > window ? length - window : 0;
      await reader.setPosition(start);
      final bytes = await reader.read(length - start);
      final end = _trimmedLineEnd(bytes);
      if (end == 0) {
        if (start == 0) return null;
        window *= 2;
        continue;
      }

      final lineStart = _lastLineBreak(bytes, end);
      if (lineStart >= 0 || start == 0) {
        return utf8.decode(bytes.sublist(lineStart + 1, end));
      }
      window *= 2;
    }
  } finally {
    await reader.close();
  }
}

int _trimmedLineEnd(List<int> bytes) {
  var end = bytes.length;
  while (end > 0 && _isJsonlTrailingWhitespace(bytes[end - 1])) {
    end--;
  }
  return end;
}

bool _isJsonlTrailingWhitespace(int byte) =>
    byte == 0x0a || byte == 0x0d || byte == 0x20 || byte == 0x09;

int _lastLineBreak(List<int> bytes, int end) {
  var index = end - 1;
  while (index >= 0 && bytes[index] != 0x0a) {
    index--;
  }
  return index;
}
