import 'dart:io';

import 'package:aonw/shared/persistence/app_data_directory.dart';

abstract final class GameStorage {
  static String defaultSaveName(String mapDisplayName, DateTime now) =>
      '$mapDisplayName — ${_dateStamp(now)}';

  static String _dateStamp(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static Future<Directory> savesDirectory() async {
    final docs = await AppDataDirectory.documentsDirectory();
    return Directory('${docs.path}/saves');
  }

  static Future<Directory> saveDirectory(
    String id, {
    Directory? savesDir,
  }) async {
    final root = savesDir ?? await savesDirectory();
    return Directory('${root.path}/$id');
  }

  /// Deletes the entire save folder.
  static Future<void> deleteSave(String id, {Directory? savesDir}) async {
    final dir = await saveDirectory(id, savesDir: savesDir);
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}
