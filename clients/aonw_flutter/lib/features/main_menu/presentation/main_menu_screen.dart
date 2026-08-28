import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';

final class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    required this.onNewGame,
    required this.onOpenSettings,
    super.key,
  });

  final VoidCallback onNewGame;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: AonwPanel(
          semanticLabel: context.aonwL10n.mainMenuTitle,
          maxWidth: 420,
          padding: const EdgeInsets.all(AonwSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.aonwL10n.appTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AonwSpacing.xl),
              FilledButton.icon(
                key: const ValueKey('new-game'),
                onPressed: onNewGame,
                icon: const Icon(Icons.add),
                label: Text(context.aonwL10n.newGame),
              ),
              const SizedBox(height: AonwSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('menu-settings'),
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings),
                label: Text(context.aonwL10n.settingsTitle),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
