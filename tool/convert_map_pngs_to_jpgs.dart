// One-off CLI: re-encodes every PNG slice in a map directory to JPEG q=90
// and deletes the original PNGs. `map.json` and other files are left alone.
//
// Usage:
//   dart run tool/convert_map_pngs_to_jpgs.dart <dir> [quality]
//
// Example:
//   dart run tool/convert_map_pngs_to_jpgs.dart assets/maps/verdantia 90
import 'dart:io';

import 'package:image/image.dart' as img;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln(
      'usage: dart run tool/convert_map_pngs_to_jpgs.dart <dir> [quality]',
    );
    exit(64);
  }
  final dirPath = args[0];
  final quality = args.length > 1 ? int.parse(args[1]) : 90;
  final dir = Directory(dirPath);
  if (!await dir.exists()) {
    stderr.writeln('directory not found: $dirPath');
    exit(66);
  }

  var converted = 0;
  var skipped = 0;
  var failed = 0;

  for (final entity in dir.listSync(recursive: false)) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (!name.toLowerCase().endsWith('.png')) {
      skipped++;
      continue;
    }
    try {
      final bytes = await entity.readAsBytes();
      final decoded = img.decodePng(bytes);
      if (decoded == null) {
        stderr.writeln('decode failed: $name');
        failed++;
        continue;
      }
      final jpegBytes = img.encodeJpg(decoded, quality: quality);
      final stem = entity.path.substring(0, entity.path.length - 4);
      final jpgPath = '$stem.jpg';
      await File(jpgPath).writeAsBytes(jpegBytes, flush: true);
      await entity.delete();
      converted++;
      if (converted % 50 == 0) {
        stdout.writeln('converted $converted files…');
      }
    } catch (e) {
      stderr.writeln('error on $name: $e');
      failed++;
    }
  }

  stdout.writeln(
    'done: $converted converted, $skipped skipped, $failed failed',
  );
}
