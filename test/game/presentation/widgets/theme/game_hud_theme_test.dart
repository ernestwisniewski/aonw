import 'dart:io';

import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the expanded background hierarchy from the UX palette', () {
    expect(GameUiTheme.bg, const Color(0xFF0A0A0E));
    expect(GameUiTheme.surface, const Color(0xFF101620));
    expect(GameUiTheme.surfaceDeep, const Color(0xFF1A2030));
    expect(
      GameUiTheme.bg.computeLuminance(),
      lessThan(GameUiTheme.surface.computeLuminance()),
    );
    expect(
      GameUiTheme.surface.computeLuminance(),
      lessThan(GameUiTheme.surfaceDeep.computeLuminance()),
    );
  });

  test('surface overlay gradient fades from stronger to softer surface', () {
    final gradient = GameUiTheme.surfaceOverlayGradient();

    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.colors, [
      GameUiTheme.surface.withAlpha(232),
      GameUiTheme.surface.withAlpha(192),
    ]);
  });

  test('panel surface gradient uses the warm shell palette', () {
    final gradient = GameUiTheme.panelSurfaceGradient();

    expect(gradient.begin, Alignment.topCenter);
    expect(gradient.end, Alignment.bottomCenter);
    expect(gradient.colors, const [Color(0xFF101620), Color(0xFF1A1A1F)]);
  });

  test('defines semantic radius roles for the second iteration geometry', () {
    expect(GameUiTheme.radiusFrame, 2);
    expect(GameUiTheme.radiusCard, 10);
    expect(GameUiTheme.radiusPill, 999);
    expect(GameUiTheme.radiusChip, 14);
    expect(GameUiTheme.radiusButton, 12);
    expect(GameUiTheme.cardBorderRadius, BorderRadius.circular(10));
    expect(GameUiTheme.pillBorderRadius, BorderRadius.circular(999));
    expect(GameUiTheme.chipBorderRadius, BorderRadius.circular(14));
    expect(GameUiTheme.buttonBorderRadius, BorderRadius.circular(12));
    expect(GameUiTheme.borderRadius, GameUiTheme.cardBorderRadius);
    expect(GameHudTheme.buttonRadius, GameUiTheme.radiusButton);
    expect(GameHudTheme.panelRadius, GameUiTheme.radiusCard);
  });

  test('defines the shared HUD icon size scale', () {
    expect(GameIconSize.tiny, 12);
    expect(GameIconSize.small, 16);
    expect(GameIconSize.regular, 20);
    expect(GameIconSize.large, 28);
    expect(GameIconSize.hero, 36);
    expect(GameHudTheme.actionIconSize, GameIconSize.regular);
    expect(GameHudTheme.collapsedActionIconSize, GameIconSize.small);
    expect(GameIcons.workedHexes.strokeWidth, 2.0);
  });

  test('keeps game HUD presentation on GameIcons instead of Material icons', () {
    final offenders = <String>[];
    final roots = [
      Directory('lib/game/presentation/widgets'),
      File(
        'lib/game/presentation/engine/rendering_layers/city/city_management_overlay.dart',
      ),
    ];

    for (final root in roots) {
      final files = root is Directory
          ? root.listSync(recursive: true).whereType<File>()
          : [root as File];
      for (final file in files) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        final lines = file.readAsLinesSync();
        final legacyCount = _legacyMaterialIconBaseline[file.path] ?? 0;
        var materialIconCount = 0;
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('Icons.') && !line.contains('GameIcons.')) {
            materialIconCount++;
            if (materialIconCount <= legacyCount) continue;
            offenders.add('${file.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test('defines semantic surface elevations for the HUD design system', () {
    expect(SurfaceElevation.flat.fill(), GameUiTheme.surface.withAlpha(210));
    expect(SurfaceElevation.flat.borderAlpha, 60);
    expect(SurfaceElevation.flat.shadows().single.blurRadius, 12);
    expect(SurfaceElevation.raised.fill(), GameUiTheme.surface.withAlpha(230));
    expect(SurfaceElevation.raised.borderAlpha, 160);
    expect(SurfaceElevation.raised.shadows().single.blurRadius, 18);
    expect(SurfaceElevation.floating.fill(), GameUiTheme.bg.withAlpha(215));
    expect(SurfaceElevation.floating.borderAlpha, 110);
    expect(SurfaceElevation.modal.fill(), GameUiTheme.gold.withAlpha(235));
    expect(
      SurfaceElevation.modal.strokeColor(),
      GameUiTheme.goldLight.withAlpha(220),
    );
  });

  test(
    'HUD surface decoration helper applies accent and shadow consistently',
    () {
      final decoration = SurfaceElevation.floating.decoration(
        accent: GameUiTheme.scienceAccent,
        shape: SurfaceShape.pill,
      );

      expect(decoration.color, GameUiTheme.bg.withAlpha(215));
      expect(decoration.borderRadius, GameUiTheme.pillBorderRadius);
      expect(decoration.border, isA<Border>());
      final border = decoration.border! as Border;
      expect(border.top.color, GameUiTheme.scienceAccent.withAlpha(110));
      expect(decoration.boxShadow, hasLength(1));
      expect(decoration.boxShadow!.single.blurRadius, 10);
    },
  );

  test('defines shared motion tokens from the UX motion scale', () {
    expect(GameMotion.snap, const Duration(milliseconds: 120));
    expect(GameMotion.fade, const Duration(milliseconds: 200));
    expect(GameMotion.slide, const Duration(milliseconds: 240));
    expect(GameMotion.scene, const Duration(milliseconds: 350));
    expect(GameMotion.enter, Curves.easeOutCubic);
    expect(GameMotion.exit, Curves.easeInCubic);
    expect(GameMotion.stateChange, Curves.easeInOutCubic);
  });

  test('exposes semantic category accents through the HUD theme', () {
    expect(GameHudTheme.colorWarning, GameUiTheme.warning);
    expect(GameHudTheme.success, GameUiTheme.success);
    expect(GameHudTheme.successDim, GameUiTheme.successDim);
    expect(GameHudTheme.info, GameUiTheme.info);
    expect(GameHudTheme.scienceAccent, GameUiTheme.scienceAccent);
    expect(GameHudTheme.resourcesAccent, GameUiTheme.resourcesAccent);
  });

  test('keeps shared HUD micro typography at ten pixels or larger', () {
    final styles = <String, TextStyle>{
      'toolbarLabel': GameUiTheme.toolbarLabel,
      'chipLabel': GameUiTheme.chipLabel,
      'buttonTopLabel': GameHudTheme.buttonTopLabel,
      'buttonLabel': GameHudTheme.buttonLabel,
      'foundingStatusLabel': GameHudTheme.foundingStatusLabel,
      'selectionChip': GameHudTheme.selectionChip,
      'selectionTag': GameHudTheme.selectionTag,
      'selectionToggle': GameHudTheme.selectionToggle,
    };

    for (final entry in styles.entries) {
      expect(
        entry.value.fontSize,
        greaterThanOrEqualTo(10),
        reason: '${entry.key} should stay readable on phone HUD chrome.',
      );
    }
  });

  test('uses tabular figures for shared numeric HUD text styles', () {
    final styles = <String, TextStyle>{
      'bodySmall': GameUiTheme.bodySmall,
      'body': GameUiTheme.body,
      'bodyStrong': GameUiTheme.bodyStrong,
      'cardMeta': GameUiTheme.cardMeta,
      'toolbarLabel': GameUiTheme.toolbarLabel,
      'chipLabel': GameUiTheme.chipLabel,
      'buttonTopLabel': GameHudTheme.buttonTopLabel,
      'buttonLabel': GameHudTheme.buttonLabel,
      'buttonLargeNum': GameHudTheme.buttonLargeNum,
      'yieldValue': GameHudTheme.yieldValue,
    };

    for (final entry in styles.entries) {
      expect(
        _hasTabularFigures(entry.value),
        isTrue,
        reason: '${entry.key} should not jitter when numbers update.',
      );
    }
  });
}

bool _hasTabularFigures(TextStyle style) {
  return style.fontFeatures?.any(_isTabularFigureFeature) ?? false;
}

bool _isTabularFigureFeature(FontFeature feature) {
  return feature.feature == 'tnum' && feature.value == 1;
}

const _legacyMaterialIconBaseline = <String, int>{
  'lib/game/presentation/widgets/diplomacy/diplomacy_player_modal.dart': 1,
  'lib/game/presentation/widgets/diplomacy/diplomacy_player_modal_actions.dart':
      3,
  'lib/game/presentation/widgets/hud/action_deck/hud_action_deck_combat_modal.dart':
      5,
  'lib/game/presentation/widgets/options/game_options_overlay.dart': 1,
};
