import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

enum EpicButtonVariant { primary, outlined, text }

typedef EpicButtonIconBuilder = Widget Function(Color color);

class EpicButton extends StatefulWidget {
  const EpicButton._({
    super.key,
    required this.variant,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconWidget,
    this.iconBuilder,
    this.padding,
    this.minWidth,
  });

  factory EpicButton.primary({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    Widget? iconWidget,
    EpicButtonIconBuilder? iconBuilder,
    EdgeInsetsGeometry? padding,
    double? minWidth,
    Key? key,
  }) {
    return EpicButton._(
      key: key,
      variant: EpicButtonVariant.primary,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      iconBuilder: iconBuilder,
      padding: padding,
      minWidth: minWidth,
    );
  }

  factory EpicButton.outlined({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    Widget? iconWidget,
    EpicButtonIconBuilder? iconBuilder,
    EdgeInsetsGeometry? padding,
    double? minWidth,
    Key? key,
  }) {
    return EpicButton._(
      key: key,
      variant: EpicButtonVariant.outlined,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      iconBuilder: iconBuilder,
      padding: padding,
      minWidth: minWidth,
    );
  }

  factory EpicButton.text({
    required VoidCallback? onPressed,
    required String label,
    IconData? icon,
    Widget? iconWidget,
    EpicButtonIconBuilder? iconBuilder,
    EdgeInsetsGeometry? padding,
    Key? key,
  }) {
    return EpicButton._(
      key: key,
      variant: EpicButtonVariant.text,
      onPressed: onPressed,
      label: label,
      icon: icon,
      iconWidget: iconWidget,
      iconBuilder: iconBuilder,
      padding: padding,
    );
  }

  final EpicButtonVariant variant;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Widget? iconWidget;
  final EpicButtonIconBuilder? iconBuilder;
  final EdgeInsetsGeometry? padding;
  final double? minWidth;

  @override
  State<EpicButton> createState() => _EpicButtonState();
}

class _EpicButtonState extends State<EpicButton> {
  bool _hovered = false;
  bool _pressed = false;

  bool get _disabled => widget.onPressed == null;

  @override
  Widget build(BuildContext context) {
    final padding =
        widget.padding ??
        const EdgeInsets.symmetric(horizontal: 18, vertical: 12);
    final foreground = _foreground();
    final content = Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.iconBuilder != null ||
              widget.iconWidget != null ||
              widget.icon != null) ...[
            widget.iconBuilder?.call(foreground) ??
                widget.iconWidget ??
                Icon(widget.icon, size: 16, color: foreground),
            const SizedBox(width: 8),
          ],
          Text(
            widget.label,
            style: GameUiTheme.menuButton.copyWith(color: foreground),
          ),
        ],
      ),
    );

    final child = switch (widget.variant) {
      EpicButtonVariant.primary => _wrapPrimary(content),
      EpicButtonVariant.outlined => _wrapOutlined(content),
      EpicButtonVariant.text => _wrapText(content),
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      cursor: _disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: _disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: _disabled ? null : () => setState(() => _pressed = false),
        onTap: _disabled ? null : widget.onPressed,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: widget.minWidth ?? 0),
          child: child,
        ),
      ),
    );
  }

  Color _foreground() {
    return switch (widget.variant) {
      EpicButtonVariant.primary =>
        _disabled
            ? SurfaceElevation.flat.fill(background: GameUiTheme.bg, alpha: 140)
            : GameUiTheme.bg,
      EpicButtonVariant.outlined =>
        _disabled
            ? GameUiTheme.textTertiary
            : (_hovered ? GameUiTheme.goldLight : GameUiTheme.textPrimary),
      EpicButtonVariant.text =>
        _disabled
            ? GameUiTheme.textTertiary
            : (_hovered ? GameUiTheme.goldLight : GameUiTheme.textSecondary),
    };
  }

  Widget _wrapPrimary(Widget child) {
    const topColor = Color(0xFFD2A856);
    const bottomColor = Color(0xFFB68838);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: _pressed ? [bottomColor, topColor] : [topColor, bottomColor],
    );

    return AnimatedContainer(
      key: const ValueKey('epic-button-primary'),
      duration: GameMotion.snap,
      decoration: ShapeDecoration(
        gradient: _disabled
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  SurfaceElevation.flat.fill(background: topColor, alpha: 80),
                  SurfaceElevation.flat.fill(
                    background: bottomColor,
                    alpha: 80,
                  ),
                ],
              )
            : gradient,
        shape: RoundedRectangleBorder(
          borderRadius: GameUiTheme.buttonBorderRadius,
        ),
        shadows: !_disabled && _hovered
            ? [
                BoxShadow(
                  color: SurfaceElevation.flat.fill(
                    background: GameUiTheme.copper,
                    alpha: 80,
                  ),
                  blurRadius: 14,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }

  Widget _wrapOutlined(Widget child) {
    final innerColor = _hovered ? GameUiTheme.copper : GameUiTheme.copperDeep;
    return Container(
      key: const ValueKey('epic-button-outer'),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          borderRadius: GameUiTheme.buttonBorderRadius,
          side: const BorderSide(color: GameUiTheme.gold),
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: Container(
        key: const ValueKey('epic-button-inner'),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GameUiTheme.radiusButton - 2),
            side: BorderSide(color: innerColor),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _wrapText(Widget child) {
    return Stack(
      key: const ValueKey('epic-button-text'),
      children: [
        child,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: AnimatedContainer(
            duration: GameMotion.snap,
            height: 1,
            color: _hovered && !_disabled
                ? GameUiTheme.copper
                : Colors.transparent,
          ),
        ),
      ],
    );
  }
}
