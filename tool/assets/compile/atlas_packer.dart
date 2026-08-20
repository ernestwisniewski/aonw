import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const int maxAtlasPageSize = 2048;
const int atlasPadding = 4;
const int atlasExtrusion = atlasPadding ~/ 2;
const String requiredCwebpVersion = '1.6.0';

enum AtlasCompression { lossless, visuallyLossless }

class AtlasFrameInput {
  AtlasFrameInput({
    required this.id,
    required this.region,
    required this.index,
    required this.image,
    required this.originalWidth,
    required this.originalHeight,
    required this.offsetX,
    required this.offsetYFromTop,
    this.contentBounds,
    this.gridColumn,
    this.gridRow,
    this.statusTop,
  });

  final String id;
  final String region;
  final int index;
  final img.Image image;
  final int originalWidth;
  final int originalHeight;
  final int offsetX;
  final int offsetYFromTop;
  final List<int>? contentBounds;
  final int? gridColumn;
  final int? gridRow;
  double? statusTop;
}

class AtlasOutput {
  const AtlasOutput({required this.atlasPath, required this.frameEntries});

  final String atlasPath;
  final Map<String, Map<String, Object>> frameEntries;
}

Future<AtlasOutput> writeAtlasFiles({
  required String atlasId,
  required List<AtlasFrameInput> frames,
  required Directory outputRoot,
  AtlasCompression compression = AtlasCompression.lossless,
  int? gridColumns,
  int? gridRows,
}) async {
  _validateAtlasFrames(atlasId, frames);
  final directory = await _prepareAtlasDirectory(outputRoot, atlasId);
  final pages = _layoutPages(frames, gridColumns, gridRows);
  final atlas = StringBuffer();
  await _writeAtlasPages(
    atlasId: atlasId,
    pages: pages,
    directory: directory,
    compression: compression,
    descriptor: atlas,
  );
  final atlasFile = File('${directory.path}/$atlasId.atlas');
  await atlasFile.writeAsString(atlas.toString(), flush: true);
  return AtlasOutput(
    atlasPath: atlasFile.path,
    frameEntries: _frameEntries(atlasId, frames),
  );
}

void _validateAtlasFrames(String atlasId, List<AtlasFrameInput> frames) {
  if (frames.isEmpty) throw StateError('Atlas $atlasId has no frames');
  for (final frame in frames) {
    final changesBounds =
        frame.offsetX != 0 ||
        frame.offsetYFromTop != 0 ||
        frame.originalWidth != frame.image.width ||
        frame.originalHeight != frame.image.height;
    if (!changesBounds) continue;
    throw StateError(
      '${frame.id} changes the source-frame bounds. Runtime atlases must '
      'preserve the complete frame with zero trim offsets.',
    );
  }
}

Future<Directory> _prepareAtlasDirectory(
  Directory outputRoot,
  String atlasId,
) async {
  final directory = Directory('${outputRoot.path}/$atlasId');
  if (await directory.exists()) await directory.delete(recursive: true);
  await directory.create(recursive: true);
  return directory;
}

List<_PageLayout> _layoutPages(
  List<AtlasFrameInput> frames,
  int? columns,
  int? rows,
) => columns == null || rows == null
    ? _pack(frames)
    : _packGrid(frames, columns: columns, rows: rows);

Future<void> _writeAtlasPages({
  required String atlasId,
  required List<_PageLayout> pages,
  required Directory directory,
  required AtlasCompression compression,
  required StringBuffer descriptor,
}) async {
  for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
    final page = pages[pageIndex];
    final pageName = '${atlasId}_$pageIndex.webp';
    final pageImage = _renderPage(page);
    await _writeWebp(
      pageImage,
      File('${directory.path}/$pageName'),
      compression: compression,
    );
    _appendPageDescriptor(descriptor, pageName, page);
    if (pageIndex != pages.length - 1) descriptor.writeln();
  }
}

img.Image _renderPage(_PageLayout page) {
  final image = img.Image(
    width: page.width,
    height: page.height,
    numChannels: 4,
  );
  for (final placement in page.placements) {
    _copyWithExtrusion(
      image,
      placement.frame.image,
      x: placement.x,
      y: placement.y,
    );
  }
  return image;
}

void _appendPageDescriptor(
  StringBuffer descriptor,
  String pageName,
  _PageLayout page,
) {
  descriptor
    ..writeln(pageName)
    ..writeln('size:${page.width},${page.height}')
    ..writeln('format:RGBA8888')
    ..writeln('filter:Linear,Linear')
    ..writeln('repeat:none');
  for (final placement in page.placements) {
    final frame = placement.frame;
    final bottomOffset =
        frame.originalHeight - frame.offsetYFromTop - frame.image.height;
    descriptor
      ..writeln(frame.region)
      ..writeln(
        'bounds:${placement.x},${placement.y},'
        '${frame.image.width},${frame.image.height}',
      )
      ..writeln(
        'offsets:${frame.offsetX},$bottomOffset,'
        '${frame.originalWidth},${frame.originalHeight}',
      )
      ..writeln('index:${frame.index}');
  }
}

Map<String, Map<String, Object>> _frameEntries(
  String atlasId,
  List<AtlasFrameInput> frames,
) => {
  for (final frame in frames)
    frame.id: {
      'atlas': atlasId,
      'region': frame.region,
      'index': frame.index,
      if (frame.contentBounds != null) 'content': frame.contentBounds!,
      if (frame.gridColumn != null && frame.gridRow != null)
        'grid': [frame.gridColumn!, frame.gridRow!],
      if (frame.statusTop != null) 'statusTop': frame.statusTop!,
    },
};

Future<void> _writeWebp(
  img.Image image,
  File output, {
  required AtlasCompression compression,
}) async {
  if (compression == AtlasCompression.lossless) {
    await output.writeAsBytes(img.encodeWebP(image), flush: true);
    return;
  }
  await _requireCwebp();
  final temporaryPng = File('${output.path}.source.png');
  await temporaryPng.writeAsBytes(img.encodePng(image), flush: true);
  try {
    final result = await Process.run('cwebp', [
      '-quiet',
      '-q',
      '92',
      '-alpha_q',
      '100',
      '-m',
      '6',
      '-exact',
      '-metadata',
      'none',
      temporaryPng.path,
      '-o',
      output.path,
    ]);
    if (result.exitCode != 0) {
      throw StateError('cwebp failed: ${result.stderr}');
    }
  } finally {
    if (await temporaryPng.exists()) await temporaryPng.delete();
  }
}

Future<void>? _cwebpCheck;

Future<void> _requireCwebp() => _cwebpCheck ??= () async {
  final result = await Process.run('cwebp', ['-version']);
  if (result.exitCode != 0) {
    throw StateError('cwebp $requiredCwebpVersion is required');
  }
  final firstLine = (result.stdout as String).split('\n').first.trim();
  if (firstLine != requiredCwebpVersion) {
    throw StateError(
      'cwebp $requiredCwebpVersion is required, found $firstLine',
    );
  }
}();

AtlasFrameInput frameFromCell({
  required String id,
  required String region,
  required int index,
  required img.Image sheet,
  required int columns,
  required int rows,
  required int column,
  required int row,
  int? targetWidth,
  int sourceInset = 0,
  int? contentPadding,
}) {
  final left = (column * sheet.width / columns).round();
  final right = ((column + 1) * sheet.width / columns).round();
  final top = (row * sheet.height / rows).round();
  final bottom = ((row + 1) * sheet.height / rows).round();
  var frame = img.copyCrop(
    sheet,
    x: left + sourceInset,
    y: top + sourceInset,
    width: math.max(1, right - left - sourceInset * 2),
    height: math.max(1, bottom - top - sourceInset * 2),
  );
  if (targetWidth != null) {
    frame = img.copyResize(
      frame,
      width: targetWidth,
      interpolation: img.Interpolation.average,
    );
  }
  final rawContentBounds = contentPadding == null
      ? null
      : _alphaContentBounds(frame, padding: 0);
  return AtlasFrameInput(
    id: id,
    region: region,
    index: index,
    image: frame,
    originalWidth: frame.width,
    originalHeight: frame.height,
    offsetX: 0,
    offsetYFromTop: 0,
    contentBounds: contentPadding == null
        ? null
        : _alphaContentBounds(frame, padding: contentPadding),
    gridColumn: column,
    gridRow: row,
    statusTop: rawContentBounds?[1].toDouble(),
  );
}

List<int> _alphaContentBounds(img.Image image, {required int padding}) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a.toInt() <= 16) continue;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
  }
  if (maxX < minX || maxY < minY) return [0, 0, image.width, image.height];
  final left = math.max(0, minX - padding);
  final top = math.max(0, minY - padding);
  final right = math.min(image.width, maxX + 1 + padding);
  final bottom = math.min(image.height, maxY + 1 + padding);
  return [left, top, right - left, bottom - top];
}

List<_PageLayout> _pack(List<AtlasFrameInput> frames) {
  final pages = <_PageLayout>[];
  var page = _PageLayout();
  pages.add(page);
  for (final frame in frames) {
    final paddedWidth = frame.image.width + atlasPadding;
    final paddedHeight = frame.image.height + atlasPadding;
    if (paddedWidth > maxAtlasPageSize || paddedHeight > maxAtlasPageSize) {
      throw StateError(
        '${frame.id} is ${frame.image.width}x${frame.image.height}; '
        'maximum packed region is ${maxAtlasPageSize - atlasPadding}',
      );
    }
    if (page.cursorX + paddedWidth > maxAtlasPageSize) {
      page
        ..cursorX = 0
        ..cursorY += page.rowHeight
        ..rowHeight = 0;
    }
    if (page.cursorY + paddedHeight > maxAtlasPageSize) {
      page = _PageLayout();
      pages.add(page);
    }
    final placement = _Placement(
      frame: frame,
      x: page.cursorX + atlasExtrusion,
      y: page.cursorY + atlasExtrusion,
    );
    page
      ..placements.add(placement)
      ..cursorX += paddedWidth
      ..rowHeight = math.max(page.rowHeight, paddedHeight)
      ..usedWidth = math.max(page.usedWidth, page.cursorX)
      ..usedHeight = math.max(page.usedHeight, page.cursorY + paddedHeight);
  }
  return pages;
}

List<_PageLayout> _packGrid(
  List<AtlasFrameInput> frames, {
  required int columns,
  required int rows,
}) {
  if (columns <= 0 || rows <= 0) {
    throw StateError('Atlas grid must have positive dimensions');
  }
  final slotWidth = frames
      .map((frame) => frame.image.width + atlasPadding)
      .reduce(math.max);
  final slotHeight = frames
      .map((frame) => frame.image.height + atlasPadding)
      .reduce(math.max);
  final columnsPerPage = math.max(1, maxAtlasPageSize ~/ slotWidth);
  final rowsPerPage = math.max(1, maxAtlasPageSize ~/ slotHeight);
  final horizontalPages = (columns / columnsPerPage).ceil();
  final verticalPages = (rows / rowsPerPage).ceil();
  final pages = [
    for (var pageRow = 0; pageRow < verticalPages; pageRow++)
      for (var pageColumn = 0; pageColumn < horizontalPages; pageColumn++)
        _PageLayout()
          ..usedWidth =
              math.min(columnsPerPage, columns - pageColumn * columnsPerPage) *
              slotWidth
          ..usedHeight =
              math.min(rowsPerPage, rows - pageRow * rowsPerPage) * slotHeight,
  ];
  final occupied = <(int, int)>{};
  for (final frame in frames) {
    final column = frame.gridColumn;
    final row = frame.gridRow;
    if (column == null || row == null) {
      throw StateError('${frame.id} has no source grid position');
    }
    if (column < 0 || column >= columns || row < 0 || row >= rows) {
      throw StateError('${frame.id} is outside the ${columns}x$rows grid');
    }
    if (!occupied.add((column, row))) {
      throw StateError('Duplicate atlas grid slot ($column, $row)');
    }
    final pageColumn = column ~/ columnsPerPage;
    final pageRow = row ~/ rowsPerPage;
    final page = pages[pageRow * horizontalPages + pageColumn];
    page.placements.add(
      _Placement(
        frame: frame,
        x: (column % columnsPerPage) * slotWidth + atlasExtrusion,
        y: (row % rowsPerPage) * slotHeight + atlasExtrusion,
      ),
    );
  }
  return pages;
}

void _copyWithExtrusion(
  img.Image destination,
  img.Image source, {
  required int x,
  required int y,
}) {
  for (var dy = -atlasExtrusion; dy < source.height + atlasExtrusion; dy++) {
    final sourceY = dy.clamp(0, source.height - 1);
    for (var dx = -atlasExtrusion; dx < source.width + atlasExtrusion; dx++) {
      final sourceX = dx.clamp(0, source.width - 1);
      final pixel = source.getPixel(sourceX, sourceY);
      destination.setPixelRgba(
        x + dx,
        y + dy,
        pixel.r,
        pixel.g,
        pixel.b,
        pixel.a,
      );
    }
  }
}

class _Placement {
  const _Placement({required this.frame, required this.x, required this.y});

  final AtlasFrameInput frame;
  final int x;
  final int y;
}

class _PageLayout {
  final List<_Placement> placements = [];
  int cursorX = 0;
  int cursorY = 0;
  int rowHeight = 0;
  int usedWidth = 0;
  int usedHeight = 0;

  int get width => usedWidth.clamp(1, maxAtlasPageSize);
  int get height => usedHeight.clamp(1, maxAtlasPageSize);
}
