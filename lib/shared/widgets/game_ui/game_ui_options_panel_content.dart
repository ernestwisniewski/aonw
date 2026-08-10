import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_side_menu_button.dart';
import 'package:flutter/material.dart';

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
