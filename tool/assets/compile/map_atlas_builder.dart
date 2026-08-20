import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

import 'map_atlas_compositor.dart';
import 'map_texture_geometry.dart';

final class MapAtlasBuilder {
  const MapAtlasBuilder({
    required this.columns,
    required this.rows,
    required this.sourceFiles,
  });

  final int columns;
  final int rows;
  final List<File> sourceFiles;

  Future<MapAtlasBuild> build() async {
    final worldWidth = mapWorldWidth(columns);
    final worldHeight = mapWorldHeight(columns, rows);
    final scale = mapCompilationScale(worldWidth, worldHeight);
    final width = math.max(1, (worldWidth * scale).ceil());
    final height = math.max(1, (worldHeight * scale).ceil());
    final atlas = MapAtlasCompositor(width: width, height: height);
    final averageColors = <String, int>{};
    for (var column = 0; column < columns; column++) {
      for (var row = 0; row < rows; row++) {
        final source = await _decode(sourceFiles[column * rows + row]);
        averageColors['$column,$row'] = _averageHexColor(source);
        _placeTile(atlas, source, column, row, scale);
      }
    }
    return MapAtlasBuild(
      image: atlas.image,
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      scale: scale,
      averageColors: Map.unmodifiable(averageColors),
    );
  }

  Future<img.Image> _decode(File file) async {
    final decoded = img.decodeImage(await file.readAsBytes());
    if (decoded == null) throw StateError('Cannot decode ${file.path}');
    return decoded.convert(numChannels: 4);
  }

  void _placeTile(
    MapAtlasCompositor atlas,
    img.Image source,
    int column,
    int row,
    double scale,
  ) {
    final placement = mapTilePlacement(column, row, scale);
    final resized = img.copyResize(
      source,
      width: placement.rasterWidth,
      height: placement.rasterHeight,
      interpolation: img.Interpolation.average,
    );
    atlas.compositeHex(resized, placement: placement);
  }
}

final class MapAtlasBuild {
  const MapAtlasBuild({
    required this.image,
    required this.worldWidth,
    required this.worldHeight,
    required this.scale,
    required this.averageColors,
  });

  final img.Image image;
  final double worldWidth;
  final double worldHeight;
  final double scale;
  final Map<String, int> averageColors;
}

int _averageHexColor(img.Image image) {
  final stride = math.max(1, math.min(image.width, image.height) ~/ 48);
  var red = 0;
  var green = 0;
  var blue = 0;
  var count = 0;
  for (var y = 0; y < image.height; y += stride) {
    for (var x = 0; x < image.width; x += stride) {
      if (!unitHexContains((x + 0.5) / image.width, (y + 0.5) / image.height)) {
        continue;
      }
      final pixel = image.getPixel(x, y);
      red += pixel.r.toInt();
      green += pixel.g.toInt();
      blue += pixel.b.toInt();
      count++;
    }
  }
  if (count == 0) return 0xff000000;
  return 0xff000000 |
      ((red ~/ count) << 16) |
      ((green ~/ count) << 8) |
      (blue ~/ count);
}
