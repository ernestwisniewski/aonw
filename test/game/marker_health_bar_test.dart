import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/units/marker_health_bar.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarkerHealthBar', () {
    test('paints type icon badge on the player color background', () async {
      final rendered = await _renderTypeBadge(
        backgroundColor: const Color(0xFFFF0000),
      );

      final background = rendered.rgbaAt(const Offset(25, 11));
      expect(background.red, greaterThan(150));
      expect(background.green, lessThan(80));
      expect(background.blue, lessThan(80));
      expect(background.alpha, greaterThan(150));
    });

    test('keeps active type badge glow compact', () {
      expect(
        MarkerHealthBar.activeGlowInflateForTesting,
        lessThanOrEqualTo(3.2),
      );
      expect(MarkerHealthBar.activeGlowAlphaForTesting, lessThanOrEqualTo(42));
    });

    test('maps health fraction through success warning danger colors', () {
      expect(
        MarkerHealthBar.healthColorForFraction(1).toARGB32(),
        HudPalette.success.toARGB32(),
      );
      expect(
        MarkerHealthBar.healthColorForFraction(0.5).toARGB32(),
        HudPalette.warning.toARGB32(),
      );
      expect(
        MarkerHealthBar.healthColorForFraction(0).toARGB32(),
        HudPalette.danger.toARGB32(),
      );

      final wounded = MarkerHealthBar.healthColorForFraction(0.25);
      expect(_redOf(wounded), greaterThan(_greenOf(wounded)));
      expect(_greenOf(wounded), greaterThan(_blueOf(wounded)));
    });
  });
}

int _redOf(Color color) => (color.toARGB32() >> 16) & 0xFF;

int _greenOf(Color color) => (color.toARGB32() >> 8) & 0xFF;

int _blueOf(Color color) => color.toARGB32() & 0xFF;

Future<_RenderedBadge> _renderTypeBadge({
  required Color backgroundColor,
}) async {
  const imageWidth = 60;
  const imageHeight = 40;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  MarkerHealthBar.paintTypeIconBadge(
    canvas,
    center: const Offset(30, 30),
    top: 30,
    width: 24,
    icon: GameIcons.army,
    backgroundColor: backgroundColor,
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(imageWidth, imageHeight);
  picture.dispose();
  final bytes = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();

  return _RenderedBadge(width: imageWidth, height: imageHeight, bytes: bytes!);
}

class _RenderedBadge {
  const _RenderedBadge({
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
