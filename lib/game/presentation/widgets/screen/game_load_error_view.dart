import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/material.dart';

class GameLoadErrorView extends StatelessWidget {
  const GameLoadErrorView({
    required this.mapName,
    required this.error,
    required this.onBack,
    super.key,
  });

  final String mapName;
  final Object error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: GameUiEmptyState(
        iconWidget: const GameIcon(
          GameIcons.error,
          size: GameIconSize.hero,
          color: GameUiTheme.goldLight,
        ),
        title: l10n.gameLoadMapErrorTitle,
        message: l10n.gameLoadMapErrorMessage(mapName, error.toString()),
        action: OutlinedButton.icon(
          onPressed: onBack,
          icon: const GameIcon(
            GameIcons.back,
            size: GameIconSize.small,
            color: GameUiTheme.goldLight,
          ),
          label: Text(GameText.actionLabel(l10n.backAction)),
          style: GameUiTheme.outlinedButtonStyle(
            foreground: GameUiTheme.goldLight,
          ),
        ),
      ),
    );
  }
}
