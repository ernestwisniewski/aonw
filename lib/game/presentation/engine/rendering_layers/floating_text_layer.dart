import 'dart:async';
import 'dart:ui' as ui;

import 'package:aonw/game/domain/reducer/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_marker_layer.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_canvas_text_style.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class FloatingTextLayer extends Component with LayerAttachment {
  final DateTime Function() _now;
  final Map<({int col, int row}), List<_FloatingTextStackEntry>> _recentSpawns =
      {};
  final Set<FloatingTextComponent> _components = {};
  bool reduceMotion;
  bool visible;

  static const Duration _stackWindow = Duration(milliseconds: 500);
  static const double _stackOffsetY = 12;
  static const double _plainRise = -34;
  static const double _bubbleRise = -24;
  static const double _cityLabelBubbleOffsetY = -38;
  static const double _bubbleMoveDuration = 3.05;
  static const double _bubbleFadeDuration = 1.45;
  static const double _bubbleFadeDelay = 2.05;
  static const double _bubbleRemoveDelay = 3.7;

  FloatingTextLayer({
    DateTime Function()? now,
    this.reduceMotion = false,
    this.visible = true,
  }) : _now = now ?? DateTime.now;

  FloatingTextComponent spawn({
    required Component parent,
    required ShowFloatingTextEffect effect,
  }) {
    _pruneDetachedComponents();
    final stackSlot = _reserveStackSlot(effect.col, effect.row);
    final component = FloatingTextComponent(
      text: effect.text,
      color: Color(effect.colorValue),
      position:
          _worldPositionFor(
            effect.col,
            effect.row,
            presentation: effect.presentation,
          ) +
          Vector2(0, stackSlot * _stackOffsetY),
      priority: _priorityFor(effect.col, effect.row),
      presentation: effect.presentation,
    );
    if (!visible) return component;
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    if (!reduceMotion) {
      final bubble = effect.presentation == FloatingTextPresentation.bubble;
      unawaited(
        Future<void>.value(
          component.add(
            MoveEffect.by(
              Vector2(0, bubble ? _bubbleRise : _plainRise),
              EffectController(
                duration: bubble ? _bubbleMoveDuration : 1.05,
                curve: Curves.easeOutCubic,
              ),
            ),
          ),
        ),
      );
      unawaited(
        Future<void>.value(
          component.add(
            OpacityEffect.fadeOut(
              EffectController(
                duration: bubble ? _bubbleFadeDuration : 0.55,
                startDelay: bubble ? _bubbleFadeDelay : 0.45,
              ),
              target: component,
            ),
          ),
        ),
      );
    }
    unawaited(
      Future<void>.value(
        component.add(
          RemoveEffect(
            delay: effect.presentation == FloatingTextPresentation.bubble
                ? _bubbleRemoveDelay
                : 1.08,
          ),
        ),
      ),
    );
    _components.add(component);
    unawaited(Future<void>.value(owner.add(component)));
    return component;
  }

  void clear() {
    for (final component in _components) {
      component.removeFromParent();
    }
    _components.clear();
    _recentSpawns.clear();
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  void _pruneDetachedComponents() {
    _components.removeWhere((component) {
      return component.parent == null && !component.isMounted;
    });
  }

  Vector2 _worldPositionFor(
    int col,
    int row, {
    required FloatingTextPresentation presentation,
  }) {
    if (presentation == FloatingTextPresentation.bubble) {
      return CityMarkerLayer.worldPositionFor(col, row) +
          Vector2(0, _cityLabelBubbleOffsetY);
    }
    final tileCenter = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultConfig.hexRadius,
    );
    return Vector2(tileCenter.x, tileCenter.y * HexGrid.perspectiveY - 28);
  }

  int _priorityFor(int col, int row) {
    return MapPriority.perTile(MapPriority.floatingText, col: col, row: row);
  }

  int _reserveStackSlot(int col, int row) {
    final now = _now();
    _pruneOldSpawns(now);

    final key = (col: col, row: row);
    final entries = _recentSpawns[key] ?? const <_FloatingTextStackEntry>[];
    final usedSlots = {for (final entry in entries) entry.slot};
    var slot = 0;
    while (usedSlots.contains(slot)) {
      slot++;
    }
    _recentSpawns[key] = [
      ...entries,
      _FloatingTextStackEntry(slot: slot, spawnedAt: now),
    ];
    return slot;
  }

  void _pruneOldSpawns(DateTime now) {
    for (final entry in _recentSpawns.entries.toList()) {
      final active = [
        for (final spawn in entry.value)
          if (now.difference(spawn.spawnedAt) < _stackWindow) spawn,
      ];
      if (active.isEmpty) {
        _recentSpawns.remove(entry.key);
      } else {
        _recentSpawns[entry.key] = active;
      }
    }
  }
}

class _FloatingTextStackEntry {
  final int slot;
  final DateTime spawnedAt;

  const _FloatingTextStackEntry({required this.slot, required this.spawnedAt});
}

class FloatingTextComponent extends PositionComponent
    implements OpacityProvider {
  final String text;
  final Color color;
  final FloatingTextPresentation presentation;

  @override
  double opacity = 1;

  FloatingTextComponent({
    required this.text,
    required this.color,
    required super.position,
    required super.priority,
    this.presentation = FloatingTextPresentation.plain,
  }) : super(anchor: Anchor.center);

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    switch (presentation) {
      case FloatingTextPresentation.plain:
        _renderPlainText(canvas);
      case FloatingTextPresentation.bubble:
        _renderBubble(canvas);
    }
  }

  void _renderPlainText(ui.Canvas canvas) {
    final style = HudCanvasTextStyle.floatingText(color, opacity: opacity);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }

  void _renderBubble(ui.Canvas canvas) {
    final alpha = opacity.clamp(0.0, 1.0).toDouble();
    final textStyle = TextStyle(
      color: HudPalette.goldLight.withValues(alpha: alpha),
      fontFamily: 'Cinzel',
      fontSize: 10.5,
      height: 1,
      fontWeight: FontWeight.w700,
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: alpha * 0.75),
          offset: const Offset(0, 1),
          blurRadius: 2.5,
        ),
      ],
    );
    final painter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    )..layout(maxWidth: 136);

    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: (painter.width + 20).clamp(68.0, 156.0).toDouble(),
      height: painter.height + 10,
    );
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(rect.height / 2),
    );
    final tail = ui.Path()
      ..moveTo(rect.center.dx - 5, rect.bottom - 1)
      ..lineTo(rect.center.dx + 5, rect.bottom - 1)
      ..lineTo(rect.center.dx, rect.bottom + 5)
      ..close();
    final shadowPaint = HudPaint.opacityFill(
      Colors.black,
      opacity: alpha * 0.48,
      maskFilter: const ui.MaskFilter.blur(ui.BlurStyle.normal, 4),
    );
    final fillPaint = HudPaint.opacityFill(
      HudPalette.bg,
      opacity: alpha * 0.96,
    );
    final borderPaint = HudPaint.opacityStroke(
      color,
      opacity: alpha * 0.92,
      strokeWidth: 1.05,
    );
    final innerBorderPaint = HudPaint.opacityStroke(
      HudPalette.goldLight,
      opacity: alpha * 0.28,
      strokeWidth: 0.7,
    );

    canvas
      ..drawRRect(rrect.shift(const Offset(0, 1.5)), shadowPaint)
      ..drawRRect(rrect, fillPaint)
      ..drawPath(tail, fillPaint)
      ..drawRRect(rrect, borderPaint)
      ..drawPath(tail, borderPaint)
      ..drawRRect(rrect.deflate(1.5), innerBorderPaint);

    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
  }
}
