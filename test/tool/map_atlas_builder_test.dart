import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/assets/compile/map_atlas_builder.dart';
import '../../tool/assets/compile/map_atlas_compositor.dart';
import '../../tool/assets/compile/map_page_writer.dart';
import '../../tool/assets/compile/map_texture_geometry.dart';

void main() {
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
        sourceFiles: List.filled(columns * rows, sourceFile),
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
