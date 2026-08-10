part of 'action_palette_component.dart';

extension _ActionPaletteLayout on ActionPaletteComponent {
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
    const top =
        ActionPaletteComponent._barPaddingY +
        ActionPaletteComponent._iconSize +
        ActionPaletteComponent._previewPanelGap;
    return Rect.fromLTWH(
      ActionPaletteComponent._barPaddingX,
      top,
      size.x - ActionPaletteComponent._barPaddingX * 2,
      ActionPaletteComponent._previewPanelHeight,
    );
  }

  List<Rect> _layoutOptionRects() {
    final rects = <Rect>[];
    if (_options.isEmpty) return rects;
    final rowWidth =
        _options.length * ActionPaletteComponent._iconSize +
        (_options.length - 1) * ActionPaletteComponent._iconGap;
    var x = (size.x - rowWidth) / 2;
    for (var i = 0; i < _options.length; i++) {
      rects.add(
        Rect.fromLTWH(
          x,
          ActionPaletteComponent._barPaddingY,
          ActionPaletteComponent._iconSize,
          ActionPaletteComponent._iconSize,
        ),
      );
      x += ActionPaletteComponent._iconSize + ActionPaletteComponent._iconGap;
    }
    return rects;
  }
}

Vector2 _measureSize(
  Iterable<ActionPaletteOption> options,
  String? previewedOptionId,
) {
  final list = options.toList(growable: false);
  final rowWidth = list.isEmpty
      ? 0.0
      : list.length * ActionPaletteComponent._iconSize +
            (list.length - 1) * ActionPaletteComponent._iconGap;
  final previewed =
      previewedOptionId != null &&
      list.any((option) => option.id == previewedOptionId && !option.isBlocked);
  final width = math.max<double>(
    rowWidth + ActionPaletteComponent._barPaddingX * 2,
    previewed ? ActionPaletteComponent._minPreviewWidth : 0,
  );
  final height =
      ActionPaletteComponent._barPaddingY +
      ActionPaletteComponent._iconSize +
      ActionPaletteComponent._barPaddingY +
      (previewed
          ? ActionPaletteComponent._previewPanelGap +
                ActionPaletteComponent._previewPanelHeight
          : 0);
  return Vector2(width, height);
}

String? _validPreviewedOptionId(
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

double _ctaWidthFor(String label, double panelWidth) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: GameUiTheme.actionLabel),
    textDirection: TextDirection.ltr,
  )..layout();
  final preferred = painter.width + 20;
  final maxWidth = math.max(74.0, panelWidth - 24);
  return math.min(math.max(74.0, preferred), maxWidth);
}
