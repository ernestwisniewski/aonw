import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundScreen extends StatelessWidget {
  final String? path;

  const NotFoundScreen({this.path, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GameUiTheme.bg,
      body: GameUiEmptyState(
        icon: Icons.explore_off_outlined,
        title: context.l10n.notFoundScreenTitle,
        message: path,
        action: OutlinedButton.icon(
          onPressed: () => context.go('/'),
          icon: const Icon(Icons.home_outlined, size: 16),
          label: Text(context.l10n.notFoundBackToMenuAction),
          style: GameUiTheme.outlinedButtonStyle(
            foreground: GameUiTheme.goldLight,
          ),
        ),
      ),
    );
  }
}
