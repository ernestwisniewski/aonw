part of 'action_palette_component.dart';

extension _ActionPalettePreviewRendering on ActionPaletteComponent {
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
      ..drawRRect(rrect, ActionPaletteComponent._borderPaint);
    painter.paint(canvas, Offset(rect.left + 8, rect.top + 4));
  }
}

String _yieldLabel(ActionPaletteYieldKind kind) => switch (kind) {
  ActionPaletteYieldKind.food => 'F',
  ActionPaletteYieldKind.production => 'P',
  ActionPaletteYieldKind.gold => 'G',
  ActionPaletteYieldKind.defense => 'D',
};

Color _yieldColor(ActionPaletteYieldKind kind) => switch (kind) {
  ActionPaletteYieldKind.food => GameUiTheme.success,
  ActionPaletteYieldKind.production => GameUiTheme.gold,
  ActionPaletteYieldKind.gold => GameUiTheme.resourcesAccent,
  ActionPaletteYieldKind.defense => GameUiTheme.info,
};
