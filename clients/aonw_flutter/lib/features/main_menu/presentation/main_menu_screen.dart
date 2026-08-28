import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../l10n/l10n.dart';
import '../../save_game/application/local_save_state.dart';

typedef LocalSaveAvailabilityReader = Future<bool> Function();
typedef LocalGameResume = Future<LocalResumeResultView> Function();

final class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({
    required this.onNewGame,
    required this.onOpenSettings,
    required this.hasLocalSave,
    required this.resumeLocalGame,
    required this.onResumed,
    super.key,
  });

  final VoidCallback onNewGame;
  final VoidCallback onOpenSettings;
  final LocalSaveAvailabilityReader hasLocalSave;
  final LocalGameResume resumeLocalGame;
  final VoidCallback onResumed;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

final class _MainMenuScreenState extends State<MainMenuScreen> {
  late Future<bool> _hasSave;
  var _resuming = false;
  LocalResumeFailureViewCode? _failure;

  @override
  void initState() {
    super.initState();
    _hasSave = widget.hasLocalSave();
  }

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
              FutureBuilder<bool>(
                future: _hasSave,
                builder: (context, snapshot) => FilledButton.icon(
                  key: const ValueKey('continue-game'),
                  onPressed: snapshot.data == true && !_resuming
                      ? _resume
                      : null,
                  icon: _resuming
                      ? const SizedBox.square(
                          dimension: AonwSizes.compactProgress,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore),
                  label: Text(
                    _resuming
                        ? context.aonwL10n.resumingGame
                        : context.aonwL10n.continueGame,
                  ),
                ),
              ),
              const SizedBox(height: AonwSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('new-game'),
                onPressed: _resuming ? null : widget.onNewGame,
                icon: const Icon(Icons.add),
                label: Text(context.aonwL10n.newGame),
              ),
              const SizedBox(height: AonwSpacing.sm),
              OutlinedButton.icon(
                key: const ValueKey('menu-settings'),
                onPressed: _resuming ? null : widget.onOpenSettings,
                icon: const Icon(Icons.settings),
                label: Text(context.aonwL10n.settingsTitle),
              ),
              if (_failure case final failure?) ...[
                const SizedBox(height: AonwSpacing.sm),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    context.aonwL10n.resumeFailure(failure.name),
                    key: const ValueKey('resume-failure'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _resume() async {
    setState(() {
      _resuming = true;
      _failure = null;
    });
    final result = await widget.resumeLocalGame();
    if (!mounted) return;
    if (result.started) {
      widget.onResumed();
      return;
    }
    setState(() {
      _resuming = false;
      _failure = result.failure;
      _hasSave = widget.hasLocalSave();
    });
  }
}
