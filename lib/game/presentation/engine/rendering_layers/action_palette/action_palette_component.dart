import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_cache.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_catalog.dart';
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

  void _handleOptionTap(ActionPaletteOption option) {
    if (option.isBlocked) {
      _tooltipMessage = option.blockedReason ?? '';
      return;
    }
    _tooltipMessage = null;
    onPreview(option.id);
  }

  ActionPaletteOption? _hitOption(Offset local) {
    final rects = _layoutOptionRects();
    for (var i = 0; i < rects.length; i++) {
      if (rects[i].contains(local)) return _options[i];
    }
    return null;
  }

  ActionPaletteOption? get _previewedOption {
    final id = _previewedOptionId;
    if (id == null) return null;
    return _options.where((option) => option.id == id).firstOrNull;
  }

  Rect? get _ctaRect {
    final previewed = _previewedOption;
    if (previewed == null || previewed.isBlocked) return null;
    final panelRect = _previewPanelRect;
    final width = _ctaWidthFor(previewed.ctaLabel, panelRect.width);
    return Rect.fromLTWH(
      panelRect.right - width - 12,
      panelRect.bottom - 34,
      width,
      24,
    );
  }

  Rect get _previewPanelRect {
    const top = _barPaddingY + _iconSize + _previewPanelGap;
    return Rect.fromLTWH(
      _barPaddingX,
      top,
      size.x - _barPaddingX * 2,
      _previewPanelHeight,
    );
  }

  List<Rect> _layoutOptionRects() {
    final rects = <Rect>[];
    if (_options.isEmpty) return rects;
    final rowWidth =
        _options.length * _iconSize + (_options.length - 1) * _iconGap;
    var x = (size.x - rowWidth) / 2;
    for (var i = 0; i < _options.length; i++) {
      rects.add(Rect.fromLTWH(x, _barPaddingY, _iconSize, _iconSize));
      x += _iconSize + _iconGap;
    }
    return rects;
  }

  void _paintBackground(Canvas canvas) {
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    HudCanvasShapes.roundedSurface(
      canvas,
      rect,
      elevation: SurfaceElevation.raised,
      border: BorderEmphasis.regular,
      backgroundAlpha: 232,
      borderAlpha: 132,
      radius: _barRadius,
    );
  }

  void _paintIcon(Canvas canvas, ActionPaletteOption option, Rect rect) {
    final iconRrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final tintPaint = option.isRecommended
        ? _recommendedTintPaint
        : _availableTintPaint;
    if (!option.isBlocked) {
      canvas.drawRRect(iconRrect, tintPaint);
    }

    if (!_paintVectorIcon(canvas, option, rect) &&
        !_paintImprovementSprite(canvas, option, rect)) {
      _paintFallbackIcon(canvas, option, rect);
    }

    if (option.isBlocked) {
      canvas.drawRRect(iconRrect, _blockedOverlayPaint);
      _paintBadge(canvas, rect, 'L', GameUiTheme.textMuted);
    }
    if (option.isRecommended) {
      _strokeIcon(canvas, rect, GameUiTheme.gold, 2);
      _paintBadge(canvas, rect, '*', GameUiTheme.goldLight);
    }
    if (option.selected || option.id == _previewedOptionId) {
      _strokeIcon(canvas, rect.deflate(1), GameUiTheme.goldLight, 3);
    }
  }

  void _paintFallbackIcon(
    Canvas canvas,
    ActionPaletteOption option,
    Rect rect,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: option.label.characters.firstOrNull ?? '?',
        style: GameUiTheme.cardTitle.copyWith(fontSize: 18),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  bool _paintVectorIcon(Canvas canvas, ActionPaletteOption option, Rect rect) {
    final icon = option.vectorIcon;
    if (icon == null) return false;
    final iconSize = math.min(rect.width, rect.height) - 14;
    GameIconRenderer.paintIcon(
      canvas,
      icon,
      topLeft: Offset(
        rect.center.dx - iconSize / 2,
        rect.center.dy - iconSize / 2,
      ),
      size: iconSize,
      color: option.isBlocked ? GameUiTheme.textMuted : GameUiTheme.goldLight,
    );
    return true;
  }

  void _paintBadge(Canvas canvas, Rect iconRect, String label, Color color) {
    final badgeRect = Rect.fromCircle(
      center: Offset(iconRect.right - 7, iconRect.top + 7),
      radius: 7,
    );
    canvas.drawOval(
      badgeRect,
      HudPaint.surface(
        SurfaceElevation.raised,
        background: HudPalette.surfaceDeep,
        alpha: 230,
      ),
    );
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontFamily: GameUiTheme.bodyFont,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        badgeRect.center.dx - painter.width / 2,
        badgeRect.center.dy - painter.height / 2,
      ),
    );
  }

  void _strokeIcon(Canvas canvas, Rect rect, Color color, double width) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      HudPaint.border(
        BorderEmphasis.active,
        color: color,
        alpha: 255,
        strokeWidth: width,
      ),
    );
  }

  bool _paintImprovementSprite(
    Canvas canvas,
    ActionPaletteOption option,
    Rect rect,
  ) {
    final type = _improvementTypeFor(option);
    if (type == null) return false;
    final image = FieldImprovementSpriteCache.imageFor(
      FieldImprovementSpriteCatalog.assetPathFor(type),
    );
    if (image == null) return false;
    final source = _sourceRectFor(image, option);
    if (source == null) return false;
    canvas.drawImageRect(
      image,
      _spriteSourceFor(option: option, baseSource: source),
      _spriteDestinationFor(option: option, baseSource: source, iconRect: rect),
      _spritePaint,
    );
    return true;
  }

  void _paintPreviewPanel(Canvas canvas, ActionPaletteOption option) {
    final panelRect = _previewPanelRect;
    canvas.drawRRect(
      RRect.fromRectAndRadius(panelRect, const Radius.circular(8)),
      HudPaint.surface(
        SurfaceElevation.flat,
        background: HudPalette.chipSurface,
        alpha: 210,
      ),
    );

    TextPainter(
        text: TextSpan(
          text: option.label,
          style: GameUiTheme.bodyStrong.copyWith(
            color: GameUiTheme.textBright,
            fontSize: 13,
          ),
        ),
        maxLines: 1,
        ellipsis: '...',
        textDirection: TextDirection.ltr,
      )
      ..layout(maxWidth: panelRect.width - 18)
      ..paint(canvas, Offset(panelRect.left + 8, panelRect.top + 8));

    _paintYieldChips(canvas, option, panelRect);

    final turns = option.turns;
    if (turns != null) {
      TextPainter(
          text: TextSpan(
            text: '$turns tur',
            style: GameUiTheme.chipLabel.copyWith(color: GameUiTheme.textMuted),
          ),
          textDirection: TextDirection.ltr,
        )
        ..layout()
        ..paint(canvas, Offset(panelRect.left + 8, panelRect.bottom - 28));
    }

    final ctaRect = _ctaRect;
    if (ctaRect == null) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(ctaRect, const Radius.circular(6)),
      HudPaint.fill(HudPalette.gold),
    );
    final ctaPainter = TextPainter(
      text: TextSpan(
        text: option.ctaLabel,
        style: GameUiTheme.actionLabel.copyWith(color: GameUiTheme.bg),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: ctaRect.width - 8);
    ctaPainter.paint(
      canvas,
      Offset(
        ctaRect.center.dx - ctaPainter.width / 2,
        ctaRect.center.dy - ctaPainter.height / 2,
      ),
    );
  }

  void _paintYieldChips(
    Canvas canvas,
    ActionPaletteOption option,
    Rect panelRect,
  ) {
    var x = panelRect.left + 8;
    final y = panelRect.top + 34;
    for (final chip in option.yieldChips) {
      final text =
          '${chip.value > 0 ? '+' : ''}${chip.value}${_yieldLabel(chip.kind)}';
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: GameUiTheme.chipLabel.copyWith(color: _yieldColor(chip.kind)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final width = painter.width + 12;
      final rect = Rect.fromLTWH(x, y, width, 20);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(10)),
        HudPaint.fill(HudPalette.surfaceDeep),
      );
      painter.paint(canvas, Offset(rect.left + 6, rect.top + 3));
      x += width + 5;
      if (x > panelRect.right - 44) break;
    }
  }

  void _paintTooltip(Canvas canvas, String message) {
    final painter = TextPainter(
      text: TextSpan(
        text: message,
        style: GameUiTheme.bodySmall.copyWith(color: GameUiTheme.textBright),
      ),
      maxLines: 2,
      ellipsis: '...',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);
    final rect = Rect.fromLTWH(
      (size.x - painter.width - 16) / 2,
      -painter.height - 12,
      painter.width + 16,
      painter.height + 8,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas
      ..drawRRect(
        rrect,
        HudPaint.surface(
          SurfaceElevation.raised,
          background: HudPalette.surfaceDeep,
          alpha: 238,
        ),
      )
      ..drawRRect(rrect, _borderPaint);
    painter.paint(canvas, Offset(rect.left + 8, rect.top + 4));
  }

  static FieldImprovementType? _improvementTypeFor(ActionPaletteOption option) {
    final row = option.iconAtlasRow;
    if (row == null ||
        row < 0 ||
        row >= FieldImprovementSpriteCatalog.typesInAtlasOrder.length) {
      return null;
    }
    return FieldImprovementSpriteCatalog.typesInAtlasOrder[row];
  }

  static ui.Rect? _sourceRectFor(ui.Image image, ActionPaletteOption option) {
    final type = _improvementTypeFor(option);
    if (type == null) return null;
    return FieldImprovementSpriteCatalog.sourceRectFor(
      imageWidth: image.width,
      imageHeight: image.height,
      type: type,
      eraColumn: option.iconAtlasColumn ?? 0,
    );
  }

  AnimationFrameAdjustment _frameAdjustmentFor(ActionPaletteOption option) {
    final type = _improvementTypeFor(option);
    if (type == null) return const AnimationFrameAdjustment();
    return _adjustments.adjustmentFor(
      assetPath: FieldImprovementSpriteCatalog.assetPathFor(type),
      animationId: FieldImprovementSpriteCatalog.adjustmentIdForVariant(
        type: type,
        eraColumn: option.iconAtlasColumn ?? 0,
      ),
      frameIndex: 0,
    );
  }

  ui.Rect _spriteSourceFor({
    required ActionPaletteOption option,
    required ui.Rect baseSource,
  }) {
    return _frameAdjustmentFor(option).croppedSourceFor(baseSource);
  }

  ui.Rect _spriteDestinationFor({
    required ActionPaletteOption option,
    required ui.Rect baseSource,
    required Rect iconRect,
  }) {
    final adjustment = _frameAdjustmentFor(option);
    final baseDestination = iconRect.deflate(4);
    final offset = adjustment.scaledOffset(
      baseSize: BoardAssetCapStyles.improvement.topSize,
      targetSize: baseDestination.size,
    );
    return adjustment
        .adjustedDestinationFor(
          baseSource: baseSource,
          baseDestination: baseDestination,
        )
        .shift(offset);
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

  static String _yieldLabel(ActionPaletteYieldKind kind) => switch (kind) {
    ActionPaletteYieldKind.food => 'F',
    ActionPaletteYieldKind.production => 'P',
    ActionPaletteYieldKind.gold => 'G',
    ActionPaletteYieldKind.defense => 'D',
  };

  static Color _yieldColor(ActionPaletteYieldKind kind) => switch (kind) {
    ActionPaletteYieldKind.food => GameUiTheme.success,
    ActionPaletteYieldKind.production => GameUiTheme.gold,
    ActionPaletteYieldKind.gold => GameUiTheme.resourcesAccent,
    ActionPaletteYieldKind.defense => GameUiTheme.info,
  };

  static Vector2 _measureSize(
    Iterable<ActionPaletteOption> options,
    String? previewedOptionId,
  ) {
    final list = options.toList(growable: false);
    final rowWidth = list.isEmpty
        ? 0.0
        : list.length * _iconSize + (list.length - 1) * _iconGap;
    final previewed =
        previewedOptionId != null &&
        list.any(
          (option) => option.id == previewedOptionId && !option.isBlocked,
        );
    final width = math.max<double>(
      rowWidth + _barPaddingX * 2,
      previewed ? _minPreviewWidth : 0,
    );
    final height =
        _barPaddingY +
        _iconSize +
        _barPaddingY +
        (previewed ? _previewPanelGap + _previewPanelHeight : 0);
    return Vector2(width, height);
  }

  static String? _validPreviewedOptionId(
    Iterable<ActionPaletteOption> options,
    String? previewedOptionId,
  ) {
    if (previewedOptionId == null) return null;
    final matching = options
        .where((option) => option.id == previewedOptionId)
        .firstOrNull;
    if (matching == null || matching.isBlocked) return null;
    return previewedOptionId;
  }

  static double _ctaWidthFor(String label, double panelWidth) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: GameUiTheme.actionLabel),
      textDirection: TextDirection.ltr,
    )..layout();
    final preferred = painter.width + 20;
    final maxWidth = math.max(74.0, panelWidth - 24);
    return math.min(math.max(74.0, preferred), maxWidth);
  }
}
