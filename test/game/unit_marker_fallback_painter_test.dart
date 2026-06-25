import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_fallback_painter.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UnitMarkerFallbackPainter', () {
    test('paints fallback marker with the player color body', () async {
      final rendered = await _renderFallbackMarker(
        markerSize: UnitMarkerFallbackSize.normal,
        playerColor: const Color(0xFFFF0000),
      );

      final body = rendered.rgbaAt(const Offset(11, 20));
      expect(body.red, greaterThan(150));
      expect(body.green, lessThan(80));
      expect(body.blue, lessThan(80));
      expect(body.alpha, greaterThan(150));
    });

    test('keeps separate status geometry for normal and small markers', () {
      const center = Offset(14, 14);

      expect(
        UnitMarkerFallbackPainter.statusTopFor(
          center,
          UnitMarkerFallbackSize.normal,
        ),
        0,
      );
      expect(
        UnitMarkerFallbackPainter.statusTopFor(
          center,
          UnitMarkerFallbackSize.small,
        ),
        6,
      );
      expect(
        UnitMarkerFallbackPainter.statusWidthFor(UnitMarkerFallbackSize.normal),
        26,
      );
      expect(
        UnitMarkerFallbackPainter.statusWidthFor(UnitMarkerFallbackSize.small),
        20,
      );
    });
  });
}

Future<_RenderedMarker> _renderFallbackMarker({
  required UnitMarkerFallbackSize markerSize,
  required Color playerColor,
}) async {
  const imageWidth = 40;
  const imageHeight = 40;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  UnitMarkerFallbackPainter.paint(
    canvas,
    center: const Offset(20, 20),
    playerColor: playerColor,
    icon: GameIcons.archer,
    markerSize: markerSize,
    selected: false,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(imageWidth, imageHeight);
  picture.dispose();
  final bytes = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();

  return _RenderedMarker(width: imageWidth, height: imageHeight, bytes: bytes!);
}

class _RenderedMarker {
  const _RenderedMarker({
    required this.width,
    required this.height,
    required this.bytes,
  });

  final int width;
  final int height;
  final ByteData bytes;

  _Rgba rgbaAt(Offset offset) {
    final x = offset.dx.round().clamp(0, width - 1);
    final y = offset.dy.round().clamp(0, height - 1);
    final offsetInBytes = (y * width + x) * 4;
    return _Rgba(
      red: bytes.getUint8(offsetInBytes),
      green: bytes.getUint8(offsetInBytes + 1),
      blue: bytes.getUint8(offsetInBytes + 2),
      alpha: bytes.getUint8(offsetInBytes + 3),
    );
  }
}

class _Rgba {
  const _Rgba({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;
}
