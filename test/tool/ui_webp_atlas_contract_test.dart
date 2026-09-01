import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  const sheetSize = 1254;
  const expectedRegionCounts = <String, int>{
    '1': 33,
    '3': 26,
    '4': 46,
    '5': 73,
    '6': 85,
  };
  final uiDirectory = Directory('${Directory.current.path}/assets/ui');
  final readme = File('${uiDirectory.path}/README.md');

  test('UI source atlases stay documented and outside runtime imports', () {
    final files =
        uiDirectory
            .listSync()
            .whereType<File>()
            .map((file) => file.uri.pathSegments.last)
            .toList()
          ..sort();

    expect(files, <String>[
      '.gitignore',
      '1.json',
      '1.webp',
      '3.json',
      '3.webp',
      '4.json',
      '4.webp',
      '5.json',
      '5.webp',
      '6.json',
      '6.webp',
      'README.md',
      'auto_trim_coordinates.dart',
      'auto_trim_models.dart',
      'build_preview.sh',
      'sync_readme_from_atlas_json.dart',
    ]);
    expect(
      File('${uiDirectory.path}/.gitignore').readAsStringSync(),
      'preview/\n',
    );
    final previewScript = File(
      '${uiDirectory.path}/build_preview.sh',
    ).readAsStringSync();
    expect(previewScript, contains('-lossless'));
    expect(previewScript, contains('-exact'));
    expect(previewScript, contains(r'-crop "$x" "$y" "$width" "$height"'));
    expect(previewScript, contains("jq -er"));
    expect(previewScript, isNot(contains('README.md')));
    final trimScript = File(
      '${uiDirectory.path}/auto_trim_coordinates.dart',
    ).readAsStringSync();
    expect(trimScript, contains("const _alphaThreshold = '1%';"));
    expect(trimScript, contains("'-trim',"));
    expect(trimScript, contains("RegExp(r'^([0-9]+)\\.json\$')"));
    expect(trimScript, isNot(contains('README.md')));
    final readmeSyncScript = File(
      '${uiDirectory.path}/sync_readme_from_atlas_json.dart',
    ).readAsStringSync();
    expect(readmeSyncScript, contains('FreeTexturePacker JSON'));
    expect(
      File('${Directory.current.path}/pubspec.yaml').readAsStringSync(),
      isNot(contains('assets/ui')),
    );
    expect(
      File('${Directory.current.path}/Makefile').readAsStringSync(),
      isNot(contains('assets/ui')),
    );
  });

  test('FreeTexturePacker JSON is the pixel-tight coordinate source', () {
    final markdown = readme.readAsStringSync();
    expect(markdown, contains('original `1254 × 1254` resolution'));
    expect(markdown, contains('**263 UI regions**'));
    expect(markdown, contains('`alpha >= 3/255`'));
    expect(markdown, contains('with no padding'));
    expect(markdown, contains('source of truth for coordinates'));

    var totalRegions = 0;
    for (final entry in expectedRegionCounts.entries) {
      totalRegions += _verifyAtlasSheet(
        uiDirectory: uiDirectory,
        markdown: markdown,
        sheet: entry.key,
        expectedRegionCount: entry.value,
        sheetSize: sheetSize,
      );
    }

    expect(totalRegions, 263);
  });
}

int _verifyAtlasSheet({
  required Directory uiDirectory,
  required String markdown,
  required String sheet,
  required int expectedRegionCount,
  required int sheetSize,
}) {
  final readmeRegions = _parseRegions(_sheetSection(markdown, sheet));
  final image = img.decodeWebP(
    File('${uiDirectory.path}/$sheet.webp').readAsBytesSync(),
  );
  expect(image, isNotNull, reason: 'sheet $sheet must decode as WebP');
  expect(image!.width, sheetSize, reason: 'sheet $sheet width');
  expect(image.height, sheetSize, reason: 'sheet $sheet height');

  final document = _readAtlasDocument(uiDirectory, sheet);
  final frames = document['frames'] as Map<String, dynamic>;
  final meta = document['meta'] as Map<String, dynamic>;
  final regions = <_AtlasRegion>[
    for (final entry in frames.entries)
      _regionFromFrame(entry.key, entry.value),
  ];
  expect(frames, hasLength(regions.length), reason: 'sheet $sheet');
  expect(regions, hasLength(expectedRegionCount), reason: 'sheet $sheet');
  expect(
    regions.map((region) => region.id).toSet(),
    hasLength(regions.length),
    reason: 'sheet $sheet region identifiers must be unique',
  );
  expect(
    readmeRegions.map((region) => region.signature),
    regions.map((region) => region.signature),
    reason: 'README must mirror sheet $sheet JSON frames',
  );
  _verifyMetadata(meta, sheet, sheetSize);
  for (final region in regions) {
    _verifyRegion(image, frames, region, sheet, sheetSize);
  }
  return regions.length;
}

Map<String, dynamic> _readAtlasDocument(Directory directory, String sheet) {
  return jsonDecode(File('${directory.path}/$sheet.json').readAsStringSync())
      as Map<String, dynamic>;
}

void _verifyMetadata(Map<String, dynamic> meta, String sheet, int sheetSize) {
  expect(meta['app'], 'http://free-tex-packer.com');
  expect(meta['version'], '0.6.7');
  expect(meta['image'], '$sheet.webp');
  expect(meta['format'], 'webp');
  expect(meta['size'], <String, dynamic>{'w': sheetSize, 'h': sheetSize});
  expect(meta['scale'], 1);
}

void _verifyRegion(
  img.Image image,
  Map<String, dynamic> frames,
  _AtlasRegion region,
  String sheet,
  int sheetSize,
) {
  expect(region.x, greaterThanOrEqualTo(0), reason: region.id);
  expect(region.y, greaterThanOrEqualTo(0), reason: region.id);
  expect(region.width, greaterThan(0), reason: region.id);
  expect(region.height, greaterThan(0), reason: region.id);
  expect(region.right, lessThanOrEqualTo(sheetSize), reason: region.id);
  expect(region.bottom, lessThanOrEqualTo(sheetSize), reason: region.id);

  final frame = frames['${region.id}.webp'] as Map<String, dynamic>;
  expect(frame['frame'], <String, dynamic>{
    'x': region.x,
    'y': region.y,
    'w': region.width,
    'h': region.height,
  });
  expect(frame['rotated'], isFalse);
  expect(frame['trimmed'], isFalse);
  expect(frame['spriteSourceSize'], <String, dynamic>{
    'x': 0,
    'y': 0,
    'w': region.width,
    'h': region.height,
  });
  expect(frame['sourceSize'], <String, dynamic>{
    'w': region.width,
    'h': region.height,
  });
  expect(frame['pivot'], <String, dynamic>{'x': 0.5, 'y': 0.5});
  expect(
    _opaqueEdges(image, region),
    everyElement(isTrue),
    reason: 'sheet $sheet region ${region.id} must touch every bound',
  );
}

List<bool> _opaqueEdges(img.Image image, _AtlasRegion region) {
  var top = false;
  var right = false;
  var bottom = false;
  var left = false;
  for (var y = region.y; y < region.bottom; y++) {
    for (var x = region.x; x < region.right; x++) {
      if (image.getPixel(x, y).a.toInt() <= 2) continue;
      if (y == region.y) top = true;
      if (x == region.right - 1) right = true;
      if (y == region.bottom - 1) bottom = true;
      if (x == region.x) left = true;
    }
  }
  return [top, right, bottom, left];
}

String _sheetSection(String markdown, String sheet) {
  final start = markdown.indexOf('## Sheet $sheet');
  if (start < 0) throw StateError('Missing README section for sheet $sheet');
  final end = markdown.indexOf('\n## Sheet ', start + 1);
  return markdown.substring(start, end < 0 ? markdown.length : end);
}

List<_AtlasRegion> _parseRegions(String section) {
  final rowPattern = RegExp(
    r'^\| `([^`]+)` \| (\d+) \| (\d+) \| (\d+) \| (\d+) \|$',
    multiLine: true,
  );
  return [
    for (final match in rowPattern.allMatches(section))
      _AtlasRegion(
        id: match.group(1)!,
        x: int.parse(match.group(2)!),
        y: int.parse(match.group(3)!),
        width: int.parse(match.group(4)!),
        height: int.parse(match.group(5)!),
      ),
  ];
}

final class _AtlasRegion {
  const _AtlasRegion({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String id;
  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;
  String get signature => '$id:$x,$y,$width,$height';
}

_AtlasRegion _regionFromFrame(String filename, dynamic value) {
  if (!filename.endsWith('.webp') || value is! Map<String, dynamic>) {
    throw FormatException('Invalid FreeTexturePacker frame: $filename');
  }
  final frame = value['frame'];
  if (frame is! Map<String, dynamic>) {
    throw FormatException('Missing FreeTexturePacker bounds: $filename');
  }
  return _AtlasRegion(
    id: filename.substring(0, filename.length - '.webp'.length),
    x: frame['x'] as int,
    y: frame['y'] as int,
    width: frame['w'] as int,
    height: frame['h'] as int,
  );
}
