import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/theme/surface_shape.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
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

  @override
  Widget build(BuildContext context) {
    final iconColor = open ? GameUiTheme.goldLight : GameUiTheme.gold;

    if (bare) {
      return Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          selected: open,
          label: tooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPressed,
            onLongPress: onLongPress,
            child: Stack(
              key: buttonKey,
              clipBehavior: Clip.none,
              children: [
                SizedBox.square(
                  dimension: extent,
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(size: iconSize, color: iconColor),
                      child: iconBuilder(iconColor),
                    ),
                  ),
                ),
                if (badgeLabel != null)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: _GameUiSideMenuBadge(
                      label: badgeLabel!,
                      tone: badgeTone,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        key: buttonKey,
        color: SurfaceElevation.flat.fill(
          background: GameUiTheme.bg,
          alpha: 205,
        ),
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
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox.square(
              dimension: extent,
              child: InkWell(
                borderRadius: GameUiTheme.borderRadius,
                onTap: onPressed,
                onLongPress: onLongPress,
                child: Center(
                  child: IconTheme(
                    data: IconThemeData(size: iconSize, color: iconColor),
                    child: iconBuilder(iconColor),
                  ),
                ),
              ),
            ),
            if (badgeLabel != null)
              Positioned(
                right: -3,
                top: -3,
                child: _GameUiSideMenuBadge(
                  label: badgeLabel!,
                  tone: badgeTone,
                ),
              ),
          ],
        ),
      ),
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

class GameUiOptionsButton extends StatelessWidget {
  final bool open;
  final VoidCallback onPressed;
  final bool bare;

  const GameUiOptionsButton({
    required this.open,
    required this.onPressed,
    this.bare = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GameUiSideMenuButton(
      buttonKey: const Key('gameOptions.optionsButton'),
      open: open,
      tooltip: context.l10n.optionsTooltip,
      iconBuilder: (color) => Icon(Icons.settings_outlined, color: color),
      onPressed: onPressed,
      bare: bare,
    );
  }
}

class GameUiOptionsPanel extends StatelessWidget {
  final List<Widget> children;
  final double width;

  const GameUiOptionsPanel({
    required this.children,
    this.width = 196,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: SurfaceElevation.floating.fill(
        background: GameUiTheme.bg,
        alpha: 235,
      ),
      borderRadius: GameUiTheme.borderRadius,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            borderRadius: GameUiTheme.borderRadius,
            side: BorderSide(
              color: SurfaceElevation.flat.strokeColor(
                color: GameUiTheme.gold,
                alpha: 110,
              ),
            ),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GameUiEpicHeader(
              label: GameText.sectionLabel(l10n.optionsTitle),
              textKey: const Key('gameOptions.panelTitle'),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class GameUiVisibilityRow extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const GameUiVisibilityRow({
    required this.label,
    required this.value,
    required this.onToggle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final message = value
        ? l10n.visibilityHideAction(label)
        : l10n.visibilityShowAction(label);
    return Tooltip(
      message: message,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.labelSmall,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              value ? Icons.check_rounded : Icons.close_rounded,
              size: 16,
              color: value ? GameUiTheme.success : GameUiTheme.danger,
            ),
          ],
        ),
      ),
    );
  }
}
