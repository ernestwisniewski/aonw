import 'dart:io';

import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_palette.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Map rendering tokens', () {
    test('map palette keeps only map-specific roles', () {
      final source = File(
        'lib/map/rendering/map_palette.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('GameUiTheme')));
      for (final alias in _retiredHudMapPaletteAliases) {
        expect(source, isNot(contains(alias)), reason: alias);
      }

      expect(MapPalette.player(0xFF123456).toARGB32(), 0xFF123456);
      expect(MapPalette.worldBackground.toARGB32(), 0xFF000000);
      expect(MapPalette.defaultWallTint.toARGB32(), 0xFF111820);
      expect(MapPalette.fogHidden.toARGB32(), 0xFF000000);
      expect(MapPalette.fogDiscovered.toARGB32(), 0x80000000);
      expect(MapPalette.eraExpansionTint.toARGB32(), 0x00000000);
    });

    test('alpha, stroke, and priority scales stay named and ordered', () {
      expect(MapAlpha.whisper, lessThan(MapAlpha.faint));
      expect(MapAlpha.faint, lessThan(MapAlpha.soft));
      expect(MapAlpha.soft, lessThan(MapAlpha.regular));
      expect(MapAlpha.regular, lessThan(MapAlpha.strong));
      expect(MapAlpha.strong, lessThan(MapAlpha.solid));
      expect(MapAlpha.solid, lessThan(MapAlpha.opaque));
      expect(MapAlpha.opaque, lessThan(MapAlpha.full));

      expect(MapStroke.hairline, lessThan(MapStroke.thin));
      expect(MapStroke.thin, lessThan(MapStroke.regular));
      expect(MapStroke.regular, lessThan(MapStroke.bold));
      expect(MapStroke.bold, lessThan(MapStroke.glow));
      expect(MapStroke.glow, lessThan(MapStroke.routeShadow));

      expect(MapPriority.territory, greaterThan(MapPriority.terrain));
      expect(MapPriority.contextOverlay, lessThan(MapPriority.intentOverlay));
      expect(MapPriority.fieldImprovement, lessThan(MapPriority.artifact));
      expect(MapPriority.artifact, lessThan(MapPriority.city));
      expect(MapPriority.city, lessThan(MapPriority.unit));
      expect(
        MapPriority.movePreviewRoute,
        greaterThan(MapPriority.perTile(MapPriority.city, col: 2, row: 99)),
      );
      expect(
        MapPriority.movePreviewPill,
        greaterThan(MapPriority.movePreviewRoute),
      );
      expect(
        MapPriority.actionPalette,
        greaterThan(MapPriority.movePreviewPill),
      );
      expect(
        MapPriority.perTile(MapPriority.floatingText, col: 2, row: 3),
        MapPriority.floatingText + MapPriority.rowStride * 3 + 2,
      );
    });

    test('migrated files use the semantic map palette directly', () {
      for (final path in _mapTokenGuardFiles) {
        final source = File(path).readAsStringSync();
        expect(source, isNot(contains('MapOverlayPalette')), reason: path);
      }
    });
  });

  group('Map token migration guard', () {
    test('migrated layer files use named map priorities', () {
      for (final path in _mapTokenGuardFiles) {
        final source = File(path).readAsStringSync();
        expect(
          RegExp(r'\.\.priority\s*=\s*\d').hasMatch(source),
          isFalse,
          reason: path,
        );
        expect(
          RegExp(r'priority:\s*\d').hasMatch(source),
          isFalse,
          reason: path,
        );
        expect(source, isNot(contains('+ row * 1000')), reason: path);
      }
    });

    test('migrated files use named alpha tokens', () {
      final literalAlpha = RegExp(r'\.withAlpha\(\d+\)');
      for (final path in _mapTokenGuardFiles) {
        final source = File(path).readAsStringSync();
        expect(literalAlpha.hasMatch(source), isFalse, reason: path);
      }
    });

    test('migrated files do not define local ARGB color literals', () {
      final colorLiteral = RegExp(r'\bColor\(0x[0-9A-Fa-f]+\)');
      for (final path in _mapTokenGuardFiles) {
        final source = File(path).readAsStringSync();
        expect(colorLiteral.hasMatch(source), isFalse, reason: path);
      }
    });
  });
}

const _mapTokenGuardFiles = [
  'lib/map/rendering/map_icon_badge.dart',
  'lib/map/rendering/map_intent_marker.dart',
  'lib/map/rendering/tile/hex_tile_painter.dart',
  'lib/game/presentation/engine/rendering_layers/overlays/threat_overlay.dart',
  'lib/game/presentation/engine/rendering_layers/city/city_founding_preview.dart',
  'lib/game/presentation/engine/rendering_layers/city/city_management_overlay.dart',
  'lib/game/presentation/engine/rendering_layers/units/unit_move_preview.dart',
  'lib/game/presentation/engine/rendering_layers/units/unit_move_preview_style.dart',
  'lib/game/presentation/engine/rendering_layers/city/city_territory_overlay.dart',
  'lib/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay.dart',
  'lib/game/presentation/engine/rendering_layers/effects/era_tint_overlay_layer.dart',
  'lib/game/presentation/engine/rendering_layers/effects/particle_effects_layer.dart',
  'lib/game/presentation/engine/rendering_layers/effects/floating_text_layer.dart',
  'lib/game/presentation/engine/rendering_layers/overlays/threat_overlay_layer.dart',
  'lib/game/presentation/engine/rendering_layers/city/city_founding_preview_layer.dart',
  'lib/game/presentation/engine/rendering_layers/city/city_management_overlay_layer.dart',
  'lib/game/presentation/engine/rendering_layers/units/unit_move_preview_layer.dart',
  'lib/game/presentation/engine/rendering_layers/city/city_territory_overlay_layer.dart',
  'lib/game/presentation/engine/rendering_layers/overlays/fog_of_war_overlay_layer.dart',
];

const _retiredHudMapPaletteAliases = [
  'enemy',
  'neutral',
  'intentMove',
  'intentAttack',
  'intentBuild',
  'intentInspect',
  'threatHigh',
  'threatLow',
  'workerWorkable',
  'workerBuildable',
  'workerExpansion',
  'growthRecommended',
  'growthCandidate',
  'eventCity',
  'eventCombat',
  'eventResearch',
  'particleWarm',
  'particleLight',
  'labelBackground',
  'labelText',
];
