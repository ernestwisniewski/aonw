import 'dart:io';
import 'dart:ui' as ui;

import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/map_image_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MapImageLayer', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('map_image_layer_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('clips per-tile slices to the hex shape', () async {
      final sliceFile = File('${tempDir.path}/1x1.jpg');
      await _writeSolidJpeg(sliceFile, width: 8, height: 8, color: Colors.red);

      final layer = MapImageLayer(
        config: const MapConfig(hexRadius: 20),
        cols: 1,
        rows: 1,
      );
      await layer.loadSlices(slicePathFor: (_, _) => sliceFile.path);

      final image = await _renderLayer(layer);
      final outsideHex = await _pixelAt(image, x: 2, y: 2);
      final insideHex = await _pixelAt(image, x: 20, y: 17);

      expect(outsideHex.alpha, 0);
      expect(insideHex.alpha, 255);
      expect(insideHex.red, greaterThan(200));
    });

    test('uses precomposed slice atlas for fast rendering', () async {
      final sliceFile = File('${tempDir.path}/1x1.jpg');
      await _writeSolidJpeg(sliceFile, width: 8, height: 8, color: Colors.red);

      final layer = MapImageLayer(
        config: const MapConfig(hexRadius: 20),
        cols: 1,
        rows: 1,
      );
      await layer.loadSlices(slicePathFor: (_, _) => sliceFile.path);

      expect(layer.hasSliceAtlasForTesting, isTrue);

      layer.preferFastRendering = true;
      final image = await _renderLayer(layer);
      final outsideHex = await _pixelAt(image, x: 2, y: 2);
      final insideHex = await _pixelAt(image, x: 20, y: 17);

      expect(outsideHex.alpha, 0);
      expect(insideHex.alpha, 255);
      expect(insideHex.red, greaterThan(200));
    });

    test('keeps fast atlas clipped while scaled', () async {
      final sliceFile = File('${tempDir.path}/1x1.jpg');
      await _writeSolidJpeg(sliceFile, width: 8, height: 8, color: Colors.red);

      final layer = MapImageLayer(
        config: const MapConfig(hexRadius: 20),
        cols: 1,
        rows: 1,
      );
      await layer.loadSlices(slicePathFor: (_, _) => sliceFile.path);

      layer.preferFastRendering = true;
      final image = await _renderLayer(layer, scale: 0.75);
      final outsideHex = await _pixelAt(image, x: 1, y: 1);
      final insideHex = await _pixelAt(image, x: 15, y: 13);

      expect(outsideHex.alpha, 0);
      expect(insideHex.alpha, 255);
      expect(insideHex.red, greaterThan(200));
    });

    test('samples average colors from sliced hex images', () async {
      final sliceFile = File('${tempDir.path}/1x1.jpg');
      await _writeSolidJpeg(
        sliceFile,
        width: 12,
        height: 12,
        color: const Color(0xFFFF0000),
      );

      final layer = MapImageLayer(
        config: const MapConfig(hexRadius: 20),
        cols: 1,
        rows: 1,
      );
      await layer.loadSlices(slicePathFor: (_, _) => sliceFile.path);

      final color = layer.averageColorForTile(0, 0);

      expect(color, isNotNull);
      expect(color!.r, greaterThan(0.85));
      expect(color.g, lessThan(0.1));
      expect(color.b, lessThan(0.1));
    });

    test('samples per-tile colors from a single stretched map image', () async {
      final mapFile = File('${tempDir.path}/map.jpg');
      await _writeSplitJpeg(
        mapFile,
        width: 70,
        height: 52,
        leftColor: Colors.red,
        rightColor: Colors.blue,
      );

      final layer = MapImageLayer(
        config: const MapConfig(hexRadius: 20),
        cols: 2,
        rows: 1,
      );
      await layer.loadImage(mapFile.path);

      final left = layer.averageColorForTile(0, 0);
      final right = layer.averageColorForTile(1, 0);

      expect(left, isNotNull);
      expect(right, isNotNull);
      expect(left!.r, greaterThan(left.b));
      expect(right!.b, greaterThan(right.r));
    });
  });
}

Future<void> _writeSolidJpeg(
  File file, {
  required int width,
  required int height,
  required Color color,
}) async {
  await _writeJpegFromCanvas(
    file,
    width: width,
    height: height,
    paint: (c) {
      c.drawRect(
        Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        Paint()..color = color,
      );
    },
  );
}

Future<void> _writeSplitJpeg(
  File file, {
  required int width,
  required int height,
  required Color leftColor,
  required Color rightColor,
}) async {
  await _writeJpegFromCanvas(
    file,
    width: width,
    height: height,
    paint: (c) {
      c
        ..drawRect(
          Rect.fromLTWH(0, 0, width / 2, height.toDouble()),
          Paint()..color = leftColor,
        )
        ..drawRect(
          Rect.fromLTWH(width / 2, 0, width / 2, height.toDouble()),
          Paint()..color = rightColor,
        );
    },
  );
}

Future<void> _writeJpegFromCanvas(
  File file, {
  required int width,
  required int height,
  required void Function(Canvas) paint,
}) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(width, height);
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final imgImage = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgba!.buffer,
    numChannels: 4,
    order: img.ChannelOrder.rgba,
  );
  await file.writeAsBytes(img.encodeJpg(imgImage, quality: 95));
}

Future<ui.Image> _renderLayer(MapImageLayer layer, {double scale = 1}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(scale);
  layer.render(canvas);
  return recorder.endRecording().toImage(
    (layer.size.x * scale).ceil(),
    (layer.size.y * scale).ceil(),
  );
}

Future<({int red, int alpha})> _pixelAt(
  ui.Image image, {
  required int x,
  required int y,
}) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  final offset = (y * image.width + x) * 4;
  return (red: bytes[offset], alpha: bytes[offset + 3]);
}
