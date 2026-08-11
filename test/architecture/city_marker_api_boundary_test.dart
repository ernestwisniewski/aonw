import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _cityMarkerDirectory =
    'lib/game/presentation/engine/rendering_layers/city';
const _implementationFiles = [
  'city_marker.dart',
  'city_marker_label_support.dart',
  'city_marker_sprite_rendering.dart',
  'city_marker_visual_state_support.dart',
];

void main() {
  test('CityMarker owns one visual update API and one debug snapshot', () {
    final root = File(
      '$_cityMarkerDirectory/city_marker.dart',
    ).readAsStringSync();
    final implementation = _implementationFiles
        .map((name) => File('$_cityMarkerDirectory/$name').readAsStringSync())
        .join('\n');

    expect(root, contains('CityMarkerVisualState get visualState'));
    expect(
      root,
      contains('void applyVisualState(CityMarkerVisualState value)'),
    );
    expect(root, contains('CityMarkerDebugSnapshot get debugSnapshot'));
    expect(implementation, isNot(contains('.debugSnapshot')));
    expect(
      RegExp(
        r'\b[A-Za-z0-9_]+ForTesting\s*(?:\(|=>|\{|;)',
      ).hasMatch(implementation),
      isFalse,
    );

    final extensionNames = RegExp(
      r'extension\s+([A-Za-z0-9_]+)\s+on\s+CityMarker\b',
    ).allMatches(implementation).map((match) => match[1]!);
    expect(extensionNames, everyElement(startsWith('_')));
    expect(
      File('$_cityMarkerDirectory/city_marker_mutable_state.dart').existsSync(),
      isFalse,
    );
  });
}
