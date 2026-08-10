part of 'selection_command_chip.dart';

class _SelectionCommandChipStyle {
  const _SelectionCommandChipStyle({
    required this.dangerFill,
    required this.dangerBorder,
    required this.accent,
    required this.foreground,
    required this.highlighted,
    required this.surface,
    required this.background,
  });

  final Color dangerFill;
  final Color dangerBorder;
  final Color accent;
  final Color foreground;
  final bool highlighted;
  final SurfaceElevation surface;
  final Color? background;

  factory _SelectionCommandChipStyle.resolve(SelectionCommandChip widget) {
    final dangerFill = Color.lerp(
      GameUiTheme.danger,
      GameUiTheme.copper,
      0.18,
    )!;
    final dangerBorder = Color.lerp(
      GameUiTheme.dangerSubtle,
      GameUiTheme.copperDeep,
      0.22,
    )!;
    final accent = _accent(widget, dangerFill);
    return _SelectionCommandChipStyle(
      dangerFill: dangerFill,
      dangerBorder: dangerBorder,
      accent: accent,
      foreground: _foreground(widget, accent),
      highlighted: widget.active || widget.prominent || widget.pulseBorder,
      surface: _surface(widget),
      background: _background(widget, dangerFill, accent),
    );
  }

  static Color _accent(SelectionCommandChip widget, Color dangerFill) {
    if (widget.dangerOutlined) return dangerFill;
    if (widget.active) return GameUiTheme.gold;
    return widget.color;
  }

  static Color _foreground(SelectionCommandChip widget, Color accent) {
    if (widget.dangerOutlined) return Colors.black;
    if (widget.active) return GameUiTheme.bg;
    return Color.lerp(accent, Colors.white, 0.22)!;
  }

  static SurfaceElevation _surface(SelectionCommandChip widget) {
    if (widget.dangerOutlined || widget.active) {
      return widget.active ? SurfaceElevation.modal : SurfaceElevation.raised;
    }
    if (widget.prominent || widget.pulseBorder) {
      return SurfaceElevation.raised;
    }
    return SurfaceElevation.flat;
  }

  static Color? _background(
    SelectionCommandChip widget,
    Color dangerFill,
    Color accent,
  ) {
    if (widget.dangerOutlined) return dangerFill;
    if (widget.active) return accent;
    if (widget.prominent || widget.pulseBorder) {
      return Color.lerp(GameUiTheme.surface, accent, 0.18)!;
    }
    return null;
  }

  double borderWidth(SelectionCommandChip widget, double pulse) {
    if (widget.dangerOutlined) {
      return (widget.active ? 1.8 : 1.6) + pulse * 0.3;
    }
    if (widget.active) return 2.0 + pulse * 0.5;
    if (widget.pulseBorder) return 1.7 + pulse;
    return widget.prominent ? 1.7 : 1.2;
  }

  int glowAlpha(SelectionCommandChip widget, double pulse) {
    if (widget.dangerOutlined) return 48 + (pulse * 28).round();
    if (widget.active) return 90 + (pulse * 44).round();
    if (widget.pulseBorder) return 78 + (pulse * 60).round();
    return 78;
  }

  Color? pulseBackground(SelectionCommandChip widget, double pulse) {
    if (widget.dangerOutlined) {
      return Color.lerp(dangerFill, dangerBorder, pulse * 0.14)!;
    }
    if (widget.pulseBorder && !widget.active) {
      return Color.lerp(GameUiTheme.surface, accent, 0.18 + pulse * 0.08)!;
    }
    return background;
  }
}
