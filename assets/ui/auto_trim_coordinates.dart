import 'dart:convert';
import 'dart:io';

const _alphaThreshold = '1%';
const _segmentationThresholds = ['1%', '5%', '10%', '20%', '30%'];
const _secondaryAreaRatio = 0.005;
const _minimumSecondaryArea = 8;
const _workerCount = 8;

final _atlasJsonPattern = RegExp(r'^([0-9]+)\.json$');
final _geometryPattern = RegExp(
  r'^([0-9]+) ([0-9]+) ([+-]?[0-9]+) ([+-]?[0-9]+)$',
);
final _componentPattern = RegExp(
  r'^\s*[0-9]+: ([0-9]+)x([0-9]+)\+([0-9]+)\+([0-9]+) '
  r'[^ ]+ ([0-9]+) (.+)$',
);

Future<void> main(List<String> arguments) async {
  if (arguments.contains('--help') || arguments.contains('-h')) {
    stdout.writeln(
      'Usage: dart run assets/ui/auto_trim_coordinates.dart [--check]\n'
      '\n'
      'Without --check, rewrites FreeTexturePacker JSON coordinates in place.\n'
      'With --check, exits non-zero when any coordinate is not tightly trimmed.',
    );
    return;
  }
  final unknown = arguments.where((argument) => argument != '--check');
  if (unknown.isNotEmpty) {
    stderr.writeln('Unknown arguments: ${unknown.join(' ')}');
    exitCode = 64;
    return;
  }

  final checkOnly = arguments.contains('--check');
  final uiDirectory = File.fromUri(Platform.script).absolute.parent;
  final jsonFiles = await uiDirectory
      .list()
      .where((entity) {
        return entity is File &&
            _atlasJsonPattern.hasMatch(entity.uri.pathSegments.last);
      })
      .cast<File>()
      .toList();
  jsonFiles.sort((left, right) {
    final leftSheet = int.parse(
      _atlasJsonPattern.firstMatch(left.uri.pathSegments.last)!.group(1)!,
    );
    final rightSheet = int.parse(
      _atlasJsonPattern.firstMatch(right.uri.pathSegments.last)!.group(1)!,
    );
    return leftSheet.compareTo(rightSheet);
  });

  final atlases = <String, _AtlasDocument>{};
  final regions = <_Region>[];
  for (final file in jsonFiles) {
    final sheet = _atlasJsonPattern
        .firstMatch(file.uri.pathSegments.last)!
        .group(1)!;
    final atlas = await _AtlasDocument.load(file, sheet);
    atlases[sheet] = atlas;
    regions.addAll(atlas.regions);
  }
  if (regions.isEmpty) {
    throw const FormatException('No FreeTexturePacker JSON frames were found.');
  }

  final trimmed = <_Region>[];
  for (var start = 0; start < regions.length; start += _workerCount) {
    final end = (start + _workerCount).clamp(0, regions.length);
    trimmed.addAll(
      await Future.wait(
        regions.sublist(start, end).map((region) => _trim(uiDirectory, region)),
      ),
    );
  }

  final changed = <(_Region, _Region)>[];
  for (var index = 0; index < regions.length; index++) {
    final before = regions[index];
    final after = trimmed[index];
    if (!before.hasSameBounds(after)) changed.add((before, after));
    atlases[after.sheet]!.update(after);
  }

  final changedDocuments = <(_AtlasDocument, String)>[];
  for (final atlas in atlases.values) {
    final encoded = atlas.encode();
    if (encoded != atlas.source) changedDocuments.add((atlas, encoded));
  }

  if (changedDocuments.isEmpty) {
    stdout.writeln(
      'All ${regions.length} UI regions are already pixel-tight at alpha '
      'threshold $_alphaThreshold and their JSON metadata is canonical.',
    );
    return;
  }

  if (checkOnly) {
    stderr.writeln(
      '${changed.length} of ${regions.length} UI regions require trimming:',
    );
    for (final (before, after) in changed.take(20)) {
      stderr.writeln(
        '  ${before.sheet}/${before.id}: '
        '${before.bounds} -> ${after.bounds}',
      );
    }
    if (changed.length > 20) {
      stderr.writeln('  ...and ${changed.length - 20} more');
    }
    final metadataOnly = changedDocuments
        .map((entry) => entry.$1.sheet)
        .where((sheet) => !changed.any((entry) => entry.$1.sheet == sheet))
        .toList();
    if (metadataOnly.isNotEmpty) {
      stderr.writeln(
        '  JSON metadata also requires normalization: '
        '${metadataOnly.join(', ')}',
      );
    }
    exitCode = 1;
    return;
  }

  for (final (atlas, encoded) in changedDocuments) {
    await _writeAtomically(atlas.file, encoded);
  }
  stdout.writeln(
    'Updated ${changedDocuments.length} FreeTexturePacker JSON files; trimmed '
    '${changed.length} of ${regions.length} UI regions at alpha threshold '
    '$_alphaThreshold.',
  );
}

Future<void> _writeAtomically(File output, String contents) async {
  final temporary = File('${output.path}.cropper.tmp');
  await temporary.writeAsString(contents, flush: true);
  try {
    await temporary.rename(output.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

Future<_Region> _trim(Directory uiDirectory, _Region region) async {
  final atlas = File('${uiDirectory.path}/${region.sheet}.webp');
  if (!await atlas.exists()) {
    throw FileSystemException('Missing atlas sheet', atlas.path);
  }
  final cell = await _segmentationCell(atlas, region);
  return _trimCell(atlas, region, cell);
}

Future<_Cell> _segmentationCell(File atlas, _Region region) async {
  var result = _Cell.full(region);
  for (final threshold in _segmentationThresholds) {
    final components = await _foregroundComponents(atlas, region, threshold);
    if (components.isEmpty) continue;
    final main = components.first;
    final minimumArea = (main.area * _secondaryAreaRatio).round().clamp(
      _minimumSecondaryArea,
      main.area,
    );
    final secondary = components
        .skip(1)
        .where((component) => component.area >= minimumArea)
        .toList();
    if (secondary.isEmpty || !_isInset(main, region)) continue;
    final cell = _cellSeparating(main, secondary, region);
    if (cell.isConstrained(region)) result = result.intersect(cell);
  }
  return result;
}

Future<List<_Component>> _foregroundComponents(
  File atlas,
  _Region region,
  String threshold,
) async {
  final result = await Process.run('magick', [
    atlas.path,
    '-crop',
    '${region.width}x${region.height}+${region.x}+${region.y}',
    '+repage',
    '-alpha',
    'extract',
    '-threshold',
    threshold,
    '-define',
    'connected-components:verbose=true',
    '-connected-components',
    '8',
    'null:',
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'magick',
      const [],
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
  final components = <_Component>[];
  for (final line in (result.stdout as String).split('\n')) {
    final match = _componentPattern.firstMatch(line);
    if (match == null) continue;
    final color = match.group(6)!;
    if (!color.contains('(255,255,255)') &&
        !color.contains('gray(255)') &&
        color.trim() != 'white') {
      continue;
    }
    components.add(
      _Component(
        x: int.parse(match.group(3)!),
        y: int.parse(match.group(4)!),
        width: int.parse(match.group(1)!),
        height: int.parse(match.group(2)!),
        area: int.parse(match.group(5)!),
      ),
    );
  }
  components.sort((left, right) => right.area.compareTo(left.area));
  return components;
}

bool _isInset(_Component component, _Region region) {
  return (region.x == 0 || component.x > 0) &&
      (region.y == 0 || component.y > 0) &&
      (region.x + region.width == 1254 || component.right < region.width) &&
      (region.y + region.height == 1254 || component.bottom < region.height);
}

_Cell _cellSeparating(
  _Component main,
  List<_Component> secondary,
  _Region region,
) {
  var left = 0;
  var top = 0;
  var right = region.width;
  var bottom = region.height;
  for (final component in secondary) {
    final overlapsHorizontally =
        component.x < main.right && component.right > main.x;
    final overlapsVertically =
        component.y < main.bottom && component.bottom > main.y;
    final isLeft = component.right <= main.x;
    final isRight = component.x >= main.right;
    final isAbove = component.bottom <= main.y;
    final isBelow = component.y >= main.bottom;

    if (isLeft && overlapsVertically) {
      left = _max(left, (component.right + main.x) ~/ 2);
    } else if (isRight && overlapsVertically) {
      right = _min(right, (main.right + component.x + 1) ~/ 2);
    } else if (isAbove && overlapsHorizontally) {
      top = _max(top, (component.bottom + main.y) ~/ 2);
    } else if (isBelow && overlapsHorizontally) {
      bottom = _min(bottom, (main.bottom + component.y + 1) ~/ 2);
    } else if ((isLeft || isRight) && (isAbove || isBelow)) {
      final horizontalGap = isLeft
          ? main.x - component.right
          : component.x - main.right;
      final verticalGap = isAbove
          ? main.y - component.bottom
          : component.y - main.bottom;
      if (horizontalGap <= verticalGap) {
        if (isLeft) {
          left = _max(left, (component.right + main.x) ~/ 2);
        } else {
          right = _min(right, (main.right + component.x + 1) ~/ 2);
        }
      } else if (isAbove) {
        top = _max(top, (component.bottom + main.y) ~/ 2);
      } else {
        bottom = _min(bottom, (main.bottom + component.y + 1) ~/ 2);
      }
    }
  }
  return _Cell(left: left, top: top, right: right, bottom: bottom);
}

Future<_Region> _trimCell(File atlas, _Region region, _Cell cell) async {
  final result = await Process.run('magick', [
    atlas.path,
    '-crop',
    '${cell.width}x${cell.height}+'
        '${region.x + cell.left}+${region.y + cell.top}',
    '+repage',
    '-alpha',
    'extract',
    '-threshold',
    _alphaThreshold,
    '-bordercolor',
    'black',
    '-border',
    '1',
    '-trim',
    '-format',
    '%w %h %X %Y',
    'info:',
  ]);
  if (result.exitCode != 0) {
    throw ProcessException(
      'magick',
      const [],
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
  final geometry = _geometryPattern.firstMatch(
    (result.stdout as String).trim(),
  );
  if (geometry == null) {
    throw FormatException(
      'Cannot parse ImageMagick geometry for '
      '${region.sheet}/${region.id}: ${result.stdout}',
    );
  }
  final width = int.parse(geometry.group(1)!);
  final height = int.parse(geometry.group(2)!);
  final rawLocalX = int.parse(geometry.group(3)!);
  final rawLocalY = int.parse(geometry.group(4)!);
  if (width == 1 && height == 1 && rawLocalX == -1 && rawLocalY == -1) {
    throw StateError(
      '${region.sheet}/${region.id} has no pixels above alpha threshold '
      '$_alphaThreshold.',
    );
  }
  final localX = rawLocalX - 1;
  final localY = rawLocalY - 1;
  return region.withBounds(
    x: region.x + cell.left + localX,
    y: region.y + cell.top + localY,
    width: width,
    height: height,
  );
}

int _min(int left, int right) => left < right ? left : right;
int _max(int left, int right) => left > right ? left : right;

final class _Cell {
  const _Cell({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory _Cell.full(_Region region) {
    return _Cell(left: 0, top: 0, right: region.width, bottom: region.height);
  }

  final int left;
  final int top;
  final int right;
  final int bottom;

  int get width => right - left;
  int get height => bottom - top;

  bool isConstrained(_Region region) {
    return left > 0 ||
        top > 0 ||
        right < region.width ||
        bottom < region.height;
  }

  _Cell intersect(_Cell other) {
    final intersection = _Cell(
      left: _max(left, other.left),
      top: _max(top, other.top),
      right: _min(right, other.right),
      bottom: _min(bottom, other.bottom),
    );
    if (intersection.width <= 0 || intersection.height <= 0) return this;
    return intersection;
  }
}

final class _Component {
  const _Component({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.area,
  });

  final int x;
  final int y;
  final int width;
  final int height;
  final int area;

  int get right => x + width;
  int get bottom => y + height;
}

final class _Region {
  const _Region({
    required this.sheet,
    required this.id,
    required this.frameName,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final String sheet;
  final String id;
  final String frameName;
  final int x;
  final int y;
  final int width;
  final int height;

  String get bounds => '[$x,$y,$width,$height]';

  bool hasSameBounds(_Region other) {
    return x == other.x &&
        y == other.y &&
        width == other.width &&
        height == other.height;
  }

  _Region withBounds({
    required int x,
    required int y,
    required int width,
    required int height,
  }) {
    return _Region(
      sheet: sheet,
      id: id,
      frameName: frameName,
      x: x,
      y: y,
      width: width,
      height: height,
    );
  }
}

final class _AtlasDocument {
  _AtlasDocument({
    required this.file,
    required this.sheet,
    required this.source,
    required this.document,
    required this.regions,
  });

  static const _encoder = JsonEncoder.withIndent('  ');

  final File file;
  final String sheet;
  final String source;
  final Map<String, dynamic> document;
  final List<_Region> regions;

  static Future<_AtlasDocument> load(File file, String sheet) async {
    final source = await file.readAsString();
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('${file.path} must contain a JSON object.');
    }
    final framesValue = decoded['frames'];
    if (framesValue is! Map<String, dynamic>) {
      throw FormatException('${file.path} must contain a frames object.');
    }
    final regions = <_Region>[];
    for (final entry in framesValue.entries) {
      if (!entry.key.endsWith('.webp')) {
        throw FormatException(
          '${file.path} frame name must end in .webp: ${entry.key}',
        );
      }
      final value = entry.value;
      if (value is! Map<String, dynamic>) {
        throw FormatException('${file.path} frame ${entry.key} is invalid.');
      }
      if (value['rotated'] == true) {
        throw FormatException(
          '${file.path} frame ${entry.key} must not be rotated.',
        );
      }
      final bounds = value['frame'];
      if (bounds is! Map<String, dynamic>) {
        throw FormatException(
          '${file.path} frame ${entry.key} has no frame bounds.',
        );
      }
      regions.add(
        _Region(
          sheet: sheet,
          id: entry.key.substring(0, entry.key.length - '.webp'.length),
          frameName: entry.key,
          x: _readInt(bounds, 'x', file, entry.key),
          y: _readInt(bounds, 'y', file, entry.key),
          width: _readInt(bounds, 'w', file, entry.key),
          height: _readInt(bounds, 'h', file, entry.key),
        ),
      );
    }
    return _AtlasDocument(
      file: file,
      sheet: sheet,
      source: source,
      document: decoded,
      regions: regions,
    );
  }

  void update(_Region region) {
    final frames = document['frames'] as Map<String, dynamic>;
    final frame = frames[region.frameName] as Map<String, dynamic>;
    frame['frame'] = <String, int>{
      'x': region.x,
      'y': region.y,
      'w': region.width,
      'h': region.height,
    };
    frame['rotated'] = false;
    frame['trimmed'] = false;
    frame['spriteSourceSize'] = <String, int>{
      'x': 0,
      'y': 0,
      'w': region.width,
      'h': region.height,
    };
    frame['sourceSize'] = <String, int>{'w': region.width, 'h': region.height};
    frame['pivot'] = <String, double>{'x': 0.5, 'y': 0.5};
  }

  String encode() => '${_encoder.convert(document)}\n';
}

int _readInt(Map<String, dynamic> values, String key, File file, String frame) {
  final value = values[key];
  if (value is int) return value;
  throw FormatException('${file.path} frame $frame has invalid $key: $value');
}
