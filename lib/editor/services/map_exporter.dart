import 'dart:io';
import 'dart:typed_data';

import 'package:aonw/editor/domain/map_draft.dart';
import 'package:aonw/map/persistence/map_loader.dart';
import 'package:aonw/map/persistence/map_storage.dart';
import 'package:archive/archive_io.dart';
import 'package:file_selector/file_selector.dart';
import 'package:share_plus/share_plus.dart';

abstract final class MapExporter {
  /// Builds the export archive for [draft] under `<safeName>/`:
  ///   `map.json`              — map data (with `mapName = safeName`)
  ///   `image.jpg`             — cover image (if present)
  ///   `1x1.jpg`, `1x2.jpg`… — tile slices (if sliced)
  ///
  /// The archive folder name matches `<safeName>`. Returns the encoded bytes
  /// along with the resolved safe name.
  static Future<({Uint8List bytes, String safeName})> buildArchive(
    MapDraft draft,
    String filename,
  ) async {
    final safeName = MapStorage.sanitizeMapName(
      filename.trim().isNotEmpty ? filename : draft.mapName ?? 'map',
    );
    final sourceName = MapStorage.sanitizeMapName(
      draft.mapName?.trim().isNotEmpty == true ? draft.mapName! : safeName,
    );

    final archive = Archive();

    final mapDir = await MapStorage.mapDirectory(sourceName);
    if (await mapDir.exists()) {
      await for (final entity in mapDir.list(recursive: false)) {
        if (entity is! File) continue;
        final fileName = entity.uri.pathSegments.last;
        if (fileName == 'map.json') {
          continue;
        }
        final bytes = await entity.readAsBytes();
        archive.addFile(
          ArchiveFile('$safeName/$fileName', bytes.length, bytes),
        );
      }
    }

    draft.freeze(mapName: safeName);
    final exportMapData = draft.toMapData(mapName: safeName);
    final jsonBytes = MapLoader.toJson(exportMapData).codeUnits;
    archive.addFile(
      ArchiveFile('$safeName/map.json', jsonBytes.length, jsonBytes),
    );

    final zipBytes = ZipEncoder().encode(archive);
    return (bytes: Uint8List.fromList(zipBytes), safeName: safeName);
  }

  /// Exports the map as `<safeName>.zip` via the OS share sheet.
  static Future<void> share(MapDraft draft, String filename) async {
    final result = await buildArchive(draft, filename);
    final zipFile = File('${Directory.systemTemp.path}/${result.safeName}.zip');
    await zipFile.writeAsBytes(result.bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(zipFile.path, mimeType: 'application/zip')],
        subject: '${result.safeName}.zip',
      ),
    );
  }

  /// Exports the map as `<safeName>.zip` via a native "Save As…" dialog.
  /// Returns the chosen path, or null if the user cancelled.
  static Future<String?> saveToDisk(MapDraft draft, String filename) async {
    final result = await buildArchive(draft, filename);
    final location = await getSaveLocation(
      suggestedName: '${result.safeName}.zip',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'ZIP archive', extensions: ['zip']),
      ],
    );
    if (location == null) return null;

    final outPath = location.path.toLowerCase().endsWith('.zip')
        ? location.path
        : '${location.path}.zip';
    await File(outPath).writeAsBytes(result.bytes, flush: true);
    return outPath;
  }
}
