import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/assets/compile/map_atlas_builder.dart';
import '../../tool/assets/compile/map_atlas_compositor.dart';
import '../../tool/assets/compile/map_page_writer.dart';
import '../../tool/assets/compile/map_texture_geometry.dart';

void main() {
  test('map bounds include the odd-q column shift for every map width', () {
    const rows = 3;
    for (final columns in [1, 2, 3, 4, 7]) {
      final placements = [
        for (var column = 0; column < columns; column++)
          for (var row = 0; row < rows; row++) mapTilePlacement(column, row, 1),
      ];
      final right = placements
          .map((placement) => placement.exactLeft + placement.exactWidth)
          .reduce(math.max);
      final bottom = placements
          .map((placement) => placement.exactTop + placement.exactHeight)
          .reduce(math.max);

      expect(mapWorldWidth(columns), closeTo(right, 1e-9));
      expect(
        mapWorldHeight(columns, rows),
        closeTo(bottom, 1e-9),
        reason: '$columns odd-q columns',
      );
    }
  });

  test('atlas retains the bottom of the last tile in an odd column', () async {
    const columns = 3;
    const rows = 2;
    final source = img.Image(width: 120, height: 104, numChannels: 3)
      ..clear(img.ColorRgb8(210, 70, 40));
    final build = await MapAtlasBuilder(
      columns: columns,
      rows: rows,
      source: _MemoryTileSource(source),
    ).build();
    final placement = mapTilePlacement(1, rows - 1, build.scale);

    expect(
      placement.rasterTop + placement.rasterHeight,
      lessThanOrEqualTo(build.image.height),
    );
    final x = (placement.exactLeft + placement.exactWidth * 0.5).floor();
    final y = (placement.exactTop + placement.exactHeight - 1).floor();
    final pixel = build.image.getPixel(x, y);
    expect(pixel.r.toInt(), greaterThan(180));
    expect(pixel.g.toInt(), lessThan(100));
    expect(pixel.b.toInt(), lessThan(80));
  });

  test('fractional-scale hex coverage has no rasterization pinholes', () {
    const columns = 4;
    const rows = 4;
    const scale = 1.6586158009393042;
    const color = (red: 220, green: 180, blue: 140);
    final width = (mapWorldWidth(columns) * scale).ceil();
    final height = (mapWorldHeight(columns, rows) * scale).ceil();
    final compositor = MapAtlasCompositor(width: width, height: height);
    final sources = <(int, int), img.Image>{};

    for (var column = 0; column < columns; column++) {
      for (var row = 0; row < rows; row++) {
        final placement = mapTilePlacement(column, row, scale);
        final size = (placement.rasterWidth, placement.rasterHeight);
        final source = sources.putIfAbsent(
          size,
          () =>
              img.Image(width: size.$1, height: size.$2, numChannels: 3)
                ..clear(img.ColorRgb8(color.red, color.green, color.blue)),
        );
        compositor.compositeHex(source, placement: placement);
      }
    }

    final horizontalMargin = (mapHexRadius * 2 * scale).ceil();
    final verticalMargin = (math.sqrt(3) * mapHexRadius * scale).ceil();
    for (var y = verticalMargin; y < height - verticalMargin; y++) {
      for (var x = horizontalMargin; x < width - horizontalMargin; x++) {
        final pixel = compositor.image.getPixel(x, y);
        expect(
          (pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()),
          (color.red, color.green, color.blue),
          reason: 'uncovered or darkened pixel at ($x, $y)',
        );
      }
    }
  });

  test(
    'compiled map pages do not bake dark seams between hex images',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'map-atlas-seam-',
      );
      addTearDown(() => temporary.delete(recursive: true));

      const sourceRed = 220;
      const sourceGreen = 180;
      const sourceBlue = 140;
      final source = img.Image(width: 270, height: 200, numChannels: 3)
        ..clear(img.ColorRgb8(sourceRed, sourceGreen, sourceBlue));
      final sourceFile = File('${temporary.path}/tile.png');
      await sourceFile.writeAsBytes(img.encodePng(source), flush: true);

      const columns = 4;
      const rows = 4;
      final build = await MapAtlasBuilder(
        columns: columns,
        rows: rows,
        source: FileMapTileImageSource(
          files: List.filled(columns * rows, sourceFile),
          rows: rows,
        ),
      ).build();
      final output = Directory('${temporary.path}/runtime/map');
      await MapPageWriter(mapId: 'seam-test', output: output).write(build);
      final encoded = img.decodeJpg(
        await File('${output.path}/page_00.jpg').readAsBytes(),
      );
      expect(encoded, isNotNull);

      final scale = build.scale;
      final horizontalMargin = (mapHexRadius * 2 * scale).ceil();
      final verticalMargin = (math.sqrt(3) * mapHexRadius * scale).ceil();
      var darkestDelta = 0;
      for (
        var y = verticalMargin + mapPageGutter;
        y < build.image.height - verticalMargin + mapPageGutter;
        y++
      ) {
        for (
          var x = horizontalMargin + mapPageGutter;
          x < build.image.width - horizontalMargin + mapPageGutter;
          x++
        ) {
          final pixel = encoded!.getPixel(x, y);
          darkestDelta = math.max(
            darkestDelta,
            math.max(
              sourceRed - pixel.r.toInt(),
              math.max(
                sourceGreen - pixel.g.toInt(),
                sourceBlue - pixel.b.toInt(),
              ),
            ),
          );
        }
      }

      expect(
        darkestDelta,
        lessThanOrEqualTo(4),
        reason: 'JPEG encoding must not reintroduce a visible dark hex outline',
      );
    },
  );
}

final class _MemoryTileSource implements MapTileImageSource {
  const _MemoryTileSource(this.image);

  final img.Image image;

  @override
  Future<img.Image> load(int column, int row) async => image.clone();
}
