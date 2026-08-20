import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/map/application/map_image_source.dart';
import 'package:aonw/map/rendering/map_image_layer.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'saved slice atlas has no dark or transparent internal hex seams',
    () async {
      final temporary = await Directory.systemTemp.createTemp(
        'saved-map-seam-',
      );
      addTearDown(() => temporary.delete(recursive: true));

      final source = img.Image(width: 32, height: 24, numChannels: 3)
        ..clear(img.ColorRgb8(220, 180, 140));
      final jpeg = img.encodeJpg(source, quality: 95);
      const columns = 4;
      const rows = 4;
      for (var column = 0; column < columns; column++) {
        for (var row = 0; row < rows; row++) {
          await File(
            '${temporary.path}/${column + 1}x${row + 1}.jpg',
          ).writeAsBytes(jpeg, flush: true);
        }
      }

      final layer = MapImageLayer(
        config: const MapConfig(hexRadius: 20),
        cols: columns,
        rows: rows,
      );
      addTearDown(layer.clearImage);
      await layer.loadSource(SavedMapSliceSetSource(temporary.path));
      final rendered = await _render(layer);
      addTearDown(rendered.dispose);
      final data = await rendered.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      final pixels = data!.buffer.asUint8List();

      var darkestDelta = 0;
      var minimumAlpha = 255;
      var darkestPixel = (x: 0, y: 0, red: 0, green: 0, blue: 0, alpha: 0);
      for (var y = 40; y < rendered.height - 40; y++) {
        for (var x = 40; x < rendered.width - 40; x++) {
          final offset = (y * rendered.width + x) * 4;
          final delta = math.max(
            220 - pixels[offset],
            math.max(180 - pixels[offset + 1], 140 - pixels[offset + 2]),
          );
          if (delta > darkestDelta) {
            darkestDelta = delta;
            darkestPixel = (
              x: x,
              y: y,
              red: pixels[offset],
              green: pixels[offset + 1],
              blue: pixels[offset + 2],
              alpha: pixels[offset + 3],
            );
          }
          minimumAlpha = math.min(minimumAlpha, pixels[offset + 3]);
        }
      }
      expect(
        darkestDelta,
        lessThanOrEqualTo(5),
        reason:
            'slice composition must not darken an internal hex edge; '
            'worst pixel: $darkestPixel',
      );
      expect(
        minimumAlpha,
        greaterThanOrEqualTo(250),
        reason: 'slice composition must not leave an internal coverage gap',
      );
    },
  );
}

Future<ui.Image> _render(MapImageLayer layer) async {
  final recorder = ui.PictureRecorder();
  layer.render(ui.Canvas(recorder));
  return recorder.endRecording().toImage(
    layer.size.x.ceil(),
    layer.size.y.ceil(),
  );
}
