import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class GameUiAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onClose;
  final String? closeTooltip;
  final IconData leadingIcon;
  final List<Widget> actions;

  const GameUiAppBar({
    required this.title,
    required this.onClose,
    this.closeTooltip,
    this.leadingIcon = Icons.arrow_back_rounded,
    this.actions = const [],
    super.key,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: onClose,
        tooltip: closeTooltip ?? l10n.backAction,
        icon: Icon(leadingIcon, size: 20),
        color: GameUiTheme.goldLight,
        style: IconButton.styleFrom(
          backgroundColor: SurfaceElevation.flat.fill(
            background: GameUiTheme.surface,
            alpha: 150,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: GameUiTheme.borderRadius,
            side: BorderSide(
              color: SurfaceElevation.flat.strokeColor(
                color: GameUiTheme.gold,
                alpha: 80,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GameUiTheme.screenTitle,
      ),
      actions: actions,
    );
  }
}
