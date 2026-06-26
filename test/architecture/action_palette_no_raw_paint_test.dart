import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('migrated HUD canvas layers use shared HUD paint tokens', () {
    for (final path in _migratedHudCanvasFiles) {
      final source = File(path).readAsStringSync();

      expect(source, isNot(contains('MapPalette')), reason: path);
      expect(RegExp(r'\.withAlpha\(').hasMatch(source), isFalse, reason: path);
      expect(
        RegExp(r'Paint\(\)\s*\.\.\s*color').hasMatch(source),
        isFalse,
        reason: path,
      );
    }
  });
}

const _migratedHudCanvasFiles = [
  'lib/game/presentation/engine/rendering_layers/action_palette/'
      'action_palette_component.dart',
  'lib/game/presentation/engine/rendering_layers/hover_intent_marker.dart',
  'lib/game/presentation/engine/rendering_layers/threat_overlay.dart',
  'lib/game/presentation/engine/rendering_layers/city_founding_preview.dart',
  'lib/game/presentation/engine/rendering_layers/city_territory_overlay.dart',
  'lib/game/presentation/engine/rendering_layers/marker_health_bar.dart',
  'lib/game/presentation/engine/rendering_layers/floating_text_layer.dart',
  'lib/game/presentation/engine/rendering_layers/unit_move_preview_style.dart',
  'lib/game/presentation/engine/rendering_layers/unit_move_preview.dart',
  'lib/game/presentation/engine/rendering_layers/particle_effects_layer.dart',
  'lib/game/presentation/engine/rendering_layers/city_management_overlay.dart',
  'lib/game/presentation/engine/rendering_layers/'
      'city_territory_overlay_layer.dart',
  'lib/game/presentation/engine/rendering_layers/'
      'unit_marker_fallback_painter.dart',
  'lib/game/presentation/engine/rendering_layers/unit_marker_badges.dart',
  'lib/game/presentation/engine/rendering_layers/city_marker.dart',
  'lib/game/presentation/engine/rendering_layers/unit_marker.dart',
  'lib/game/presentation/engine/rendering_layers/sprite_shadow.dart',
  'lib/map/rendering/tile/hex_tile_painter.dart',
];
