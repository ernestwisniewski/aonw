import 'package:aonw_flutter/features/map/presentation/camera/map_initial_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('applies authored zoom after fitting and centers the map', () {
    final matrix = MapInitialCamera.centeredFit(
      viewport: const Size(900, 800),
      content: const Size(750, 600),
      authoredZoom: 1.25,
    );

    expect(matrix.getMaxScaleOnAxis(), closeTo(1.5, 1e-9));
    expect(matrix.getTranslation().x, closeTo(-112.5, 1e-9));
    expect(matrix.getTranslation().y, closeTo(-50, 1e-9));
  });
}
