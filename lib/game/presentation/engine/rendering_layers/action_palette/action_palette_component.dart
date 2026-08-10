import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_cache.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_catalog.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/hud_canvas_shapes.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

part 'action_palette_icon_rendering.dart';
part 'action_palette_layout.dart';
part 'action_palette_preview_rendering.dart';

typedef ActionPaletteIdCallback = void Function(String optionId);

class ActionPaletteComponent extends PositionComponent with TapCallbacks {
  ActionPaletteComponent({
    required List<ActionPaletteOption> options,
    required String? previewedOptionId,
    required this.onPreview,
    required this.onConfirm,
    required this.onCancel,
  }) : _options = List.unmodifiable(options),
       _previewedOptionId = _validPreviewedOptionId(options, previewedOptionId),
       super(
         anchor: Anchor.center,
         priority: MapPriority.actionPalette,
         size: _measureSize(
           options,
           _validPreviewedOptionId(options, previewedOptionId),
         ),
       );

  static const double _iconSize = 44;
  static const double _iconGap = 6;
  static const double _barPaddingX = 12;
  static const double _barPaddingY = 8;
  static const double _barRadius = 10;
  static const double _previewPanelGap = 6;
  static const double _previewPanelHeight = 92;
  static const double _minPreviewWidth = 228;
  static const double _flipUpperBand = 0.25;
  static const double _flipHysteresis = 0.05;

  static final Paint _borderPaint = HudPaint.border(
    BorderEmphasis.regular,
    alpha: 132,
  );
  static final Paint _availableTintPaint = HudPaint.fill(
    HudPalette.info,
    alpha: 38,
  );
  static final Paint _recommendedTintPaint = HudPaint.fill(
    HudPalette.gold,
    alpha: 44,
  );
  static final Paint _blockedOverlayPaint = HudPaint.shadow(alpha: 148);
  static final Paint _spritePaint = Paint()
    ..filterQuality = FilterQuality.medium;

  List<ActionPaletteOption> _options;
  String? _previewedOptionId;
  String? _tooltipMessage;
  AnimationFrameAdjustmentCatalog _adjustments =
      const AnimationFrameAdjustmentCatalog.empty();

  final ActionPaletteIdCallback onPreview;
  final ActionPaletteIdCallback onConfirm;
  final VoidCallback onCancel;

  @visibleForTesting
  List<ActionPaletteOption> get optionsForTesting => _options;

  @visibleForTesting
  List<Rect> get optionRectsForTesting => _layoutOptionRects();

  @visibleForTesting
  Rect? get ctaRectForTesting => _ctaRect;

  @visibleForTesting
  String? get tooltipMessageForTesting => _tooltipMessage;

  void updateOptions(List<ActionPaletteOption> next) {
    _options = List.unmodifiable(next);
    final previewed = _previewedOption;
    if (previewed == null || previewed.isBlocked) {
      _previewedOptionId = null;
    }
    size = _measureSize(_options, _previewedOptionId);
  }

  void updatePreviewed(String? optionId) {
    _previewedOptionId = _validPreviewedOptionId(_options, optionId);
    _tooltipMessage = null;
    size = _measureSize(_options, _previewedOptionId);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await Future.wait(
      FieldImprovementSpriteCatalog.assetPaths.map(
        FieldImprovementSpriteCache.load,
      ),
    );
    _adjustments = await AnimationFrameAdjustmentCatalogCache.load();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _paintBackground(canvas);
    final rects = _layoutOptionRects();
    for (var i = 0; i < _options.length; i++) {
      _paintIcon(canvas, _options[i], rects[i]);
    }
    final previewed = _previewedOption;
    if (previewed != null) {
      _paintPreviewPanel(canvas, previewed);
    }
    final tooltip = _tooltipMessage;
    if (tooltip != null && tooltip.isNotEmpty) {
      _paintTooltip(canvas, tooltip);
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    final local = event.localPosition;
    final offset = Offset(local.x, local.y);
    final ctaRect = _ctaRect;
    if (ctaRect != null && ctaRect.contains(offset)) {
      final previewed = _previewedOption;
      if (previewed != null) onConfirm(previewed.id);
      return;
    }
    final option = _hitOption(offset);
    if (option == null) {
      onCancel();
      return;
    }
    _handleOptionTap(option);
  }

  @visibleForTesting
  void tapOptionForTesting(String optionId) {
    final option = _options
        .where((option) => option.id == optionId)
        .firstOrNull;
    if (option == null) return;
    _handleOptionTap(option);
  }

  @visibleForTesting
  void tapCtaForTesting() {
    final previewed = _previewedOption;
    if (previewed == null || previewed.isBlocked) return;
    onConfirm(previewed.id);
  }

  static bool shouldFlipBelow({
    required double actorScreenTopY,
    required double actorScreenBottomY,
    required double screenHeight,
    required bool wasFlippedBelow,
  }) {
    if (screenHeight <= 0) return wasFlippedBelow;
    final actorMidY = (actorScreenTopY + actorScreenBottomY) / 2;
    final relative = actorMidY / screenHeight;
    if (wasFlippedBelow) {
      return relative < _flipUpperBand + _flipHysteresis;
    }
    return relative < _flipUpperBand;
  }

  @visibleForTesting
  ui.Rect? spriteDestinationForTesting({
    required ui.Image image,
    required ActionPaletteOption option,
    required Rect iconRect,
  }) {
    final source = _sourceRectFor(image, option);
    if (source == null) return null;
    return _spriteDestinationFor(
      option: option,
      baseSource: source,
      iconRect: iconRect,
    );
  }

  @visibleForTesting
  ui.Rect? spriteSourceForTesting({
    required ui.Image image,
    required ActionPaletteOption option,
  }) {
    final source = _sourceRectFor(image, option);
    if (source == null) return null;
    return _spriteSourceFor(option: option, baseSource: source);
  }
}
