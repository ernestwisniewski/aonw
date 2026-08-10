import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_focus_ring.dart';
import 'package:flutter/material.dart';

enum GameUiSideMenuBadgeTone { count, score, domination }

class GameUiSideMenuButton extends StatelessWidget {
  const GameUiSideMenuButton({
    required this.open,
    required this.tooltip,
    required this.iconBuilder,
    required this.onPressed,
    this.onLongPress,
    this.buttonKey,
    this.badgeLabel,
    this.badgeTone = GameUiSideMenuBadgeTone.count,
    this.iconSize = 18,
    this.bare = false,
    this.gamepadFocused = false,
    super.key,
  });

  static const double extent = 44;

  final bool open;
  final String tooltip;
  final Widget Function(Color color) iconBuilder;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final Key? buttonKey;
  final String? badgeLabel;
  final GameUiSideMenuBadgeTone badgeTone;
  final double iconSize;
  final bool bare;
  final bool gamepadFocused;

  @override
  Widget build(BuildContext context) {
    final iconColor = open ? GameUiTheme.goldLight : GameUiTheme.gold;
    return _withGamepadFocusRing(
      Tooltip(
        message: tooltip,
        child: bare ? _bareButton(iconColor) : _framedButton(iconColor),
      ),
    );
  }

  Widget _bareButton(Color iconColor) {
    return Semantics(
      button: true,
      selected: open,
      label: tooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        onLongPress: onLongPress,
        child: _buttonStack(iconColor, interactive: false, stackKey: buttonKey),
      ),
    );
  }

  Widget _framedButton(Color iconColor) {
    return Material(
      key: buttonKey,
      color: SurfaceElevation.flat.fill(background: GameUiTheme.bg, alpha: 205),
      shape: RoundedRectangleBorder(
        borderRadius: GameUiTheme.borderRadius,
        side: BorderSide(
          color: open
              ? GameUiTheme.gold
              : SurfaceElevation.flat.strokeColor(
                  color: GameUiTheme.gold,
                  alpha: 92,
                ),
        ),
      ),
      child: _buttonStack(iconColor, interactive: true),
    );
  }

  Widget _buttonStack(
    Color iconColor, {
    required bool interactive,
    Key? stackKey,
  }) {
    final icon = Center(
      child: IconTheme(
        data: IconThemeData(size: iconSize, color: iconColor),
        child: iconBuilder(iconColor),
      ),
    );
    final button = SizedBox.square(
      dimension: extent,
      child: interactive
          ? InkWell(
              borderRadius: GameUiTheme.borderRadius,
              onTap: onPressed,
              onLongPress: onLongPress,
              child: icon,
            )
          : icon,
    );
    return Stack(
      key: stackKey,
      clipBehavior: Clip.none,
      children: [button, if (badgeLabel != null) _badge()],
    );
  }

  Widget _badge() {
    return Positioned(
      right: -3,
      top: -3,
      child: _GameUiSideMenuBadge(label: badgeLabel!, tone: badgeTone),
    );
  }

  Widget _withGamepadFocusRing(Widget child) {
    return GameUiFocusRing(
      focused: gamepadFocused,
      borderRadius: GameUiTheme.borderRadius,
      child: child,
    );
  }
}

class _GameUiSideMenuBadge extends StatelessWidget {
  const _GameUiSideMenuBadge({required this.label, required this.tone});

  final String label;
  final GameUiSideMenuBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final style = _GameUiSideMenuBadgeStyle.resolve(tone);

    return DecoratedBox(
      decoration: SurfaceElevation.modal.decoration(
        background: style.background,
        backgroundAlpha: 255,
        borderColor: style.borderColor,
        border: BorderEmphasis.active,
        borderWidth: style.borderWidth,
        shape: SurfaceShape.pill,
        includeShadow: false,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Center(
            child: Text(
              label,
              style: GameUiTheme.labelSmall.copyWith(
                color: style.foreground,
                fontSize: 9,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameUiSideMenuBadgeStyle {
  const _GameUiSideMenuBadgeStyle({
    required this.background,
    required this.borderColor,
    required this.foreground,
    required this.borderWidth,
  });

  final Color background;
  final Color borderColor;
  final Color foreground;
  final double borderWidth;

  static _GameUiSideMenuBadgeStyle resolve(GameUiSideMenuBadgeTone tone) {
    return switch (tone) {
      GameUiSideMenuBadgeTone.count => const _GameUiSideMenuBadgeStyle(
        background: GameUiTheme.gold,
        borderColor: GameUiTheme.bg,
        foreground: GameUiTheme.bg,
        borderWidth: 1.2,
      ),
      GameUiSideMenuBadgeTone.score => const _GameUiSideMenuBadgeStyle(
        background: GameUiTheme.scienceAccent,
        borderColor: GameUiTheme.bg,
        foreground: GameUiTheme.bg,
        borderWidth: 1.3,
      ),
      GameUiSideMenuBadgeTone.domination => const _GameUiSideMenuBadgeStyle(
        background: GameUiTheme.dangerSubtle,
        borderColor: GameUiTheme.danger,
        foreground: GameUiTheme.goldLight,
        borderWidth: 1.4,
      ),
    };
  }
}
