import 'dart:convert';
import 'dart:io';

import 'package:image/image.dart' as img;

import 'atlas_packer.dart';

final class AtlasRuntimeParser {
  const AtlasRuntimeParser();

  Future<ParsedRuntimeAtlas> parse(File atlasFile, List<String> errors) async {
    final lines = const LineSplitter()
        .convert(await atlasFile.readAsString())
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final pages = <String>{};
    final regions = <String>{};
    String? currentPage;
    String? pendingRegion;
    (int, int, int, int)? pendingBounds;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.endsWith('.webp')) {
        currentPage = line;
        pages.add(line);
        await _verifyPage(atlasFile.parent, line, errors);
        pendingRegion = null;
        pendingBounds = null;
      } else if (!line.contains(':')) {
        pendingRegion = line;
        pendingBounds = null;
      } else if (line.startsWith('bounds:') && pendingRegion != null) {
        pendingBounds = _bounds(line, atlasFile, errors);
      } else if (line.startsWith('offsets:') && pendingRegion != null) {
        _verifyOffsets(line, pendingRegion, pendingBounds, atlasFile, errors);
      } else if (line.startsWith('index:') && pendingRegion != null) {
        if (currentPage == null || pendingBounds == null) {
          errors.add('${atlasFile.path}: incomplete region $pendingRegion');
        }
        final key = '$pendingRegion#${line.substring('index:'.length)}';
        if (!regions.add(key)) {
          errors.add('${atlasFile.path}: duplicate region $key');
        }
        pendingRegion = null;
      }
    }
    if (pages.isEmpty) errors.add('${atlasFile.path}: atlas has no pages');
    return ParsedRuntimeAtlas(pages: pages, regions: regions);
  }

  Future<void> _verifyPage(
    Directory parent,
    String name,
    List<String> errors,
  ) async {
    final file = File('${parent.path}/$name');
    if (!await file.exists()) {
      errors.add('missing atlas page ${file.path}');
      return;
    }
    final image = img.decodeWebP(await file.readAsBytes());
    if (image == null) {
      errors.add('invalid WebP page ${file.path}');
    } else if (image.width > maxAtlasPageSize ||
        image.height > maxAtlasPageSize) {
      errors.add('${file.path} exceeds ${maxAtlasPageSize}px');
    }
  }

  (int, int, int, int)? _bounds(String line, File atlas, List<String> errors) {
    final values = _integers(line.substring('bounds:'.length));
    if (values == null ||
        values.length != 4 ||
        values.any((value) => value < 0)) {
      errors.add('${atlas.path}: invalid $line');
      return null;
    }
    return (values[0], values[1], values[2], values[3]);
  }

  void _verifyOffsets(
    String line,
    String region,
    (int, int, int, int)? bounds,
    File atlas,
    List<String> errors,
  ) {
    final values = _integers(line.substring('offsets:'.length));
    if (bounds == null ||
        values == null ||
        values.length != 4 ||
        values[0] != 0 ||
        values[1] != 0 ||
        values[2] != bounds.$3 ||
        values[3] != bounds.$4) {
      errors.add('${atlas.path}: $region is trimmed or changes bounds');
    }
  }

  List<int>? _integers(String value) {
    try {
      return value.split(',').map(int.parse).toList(growable: false);
    } on FormatException {
      return null;
    }
  }
}

final class ParsedRuntimeAtlas {
  const ParsedRuntimeAtlas({required this.pages, required this.regions});

  final Set<String> pages;
  final Set<String> regions;
}
