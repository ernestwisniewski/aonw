part of 'replay_screen.dart';

class _ReplayMapSurface extends StatelessWidget {
  const _ReplayMapSurface({
    required this.renderer,
    required this.loadingProgress,
    required this.l10n,
  });

  final GameRenderer? renderer;
  final ValueListenable<GameLoadingProgress> loadingProgress;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final renderer = this.renderer;
    if (renderer == null) {
      return ValueListenableBuilder<GameLoadingProgress>(
        valueListenable: loadingProgress,
        builder: (context, progress, _) => GameLoadingPanel(progress: progress),
      );
    }

    return ViewportGestureLayer(
      game: renderer,
      child: GameWidget(
        key: ValueKey(renderer),
        game: renderer,
        loadingBuilder: (_) => ValueListenableBuilder<GameLoadingProgress>(
          valueListenable: loadingProgress,
          builder: (context, progress, _) =>
              GameLoadingPanel(progress: progress),
        ),
        errorBuilder: (context, error) => ScrollableErrorView(
          message:
              '${l10n.replayErrorTitle}\n\n'
              '${l10n.replayErrorBody(error.toString())}',
          actionLabel: l10n.backAction,
          onAction: () => context.go('/load-game'),
        ),
      ),
    );
  }
}

class _ReplayTopBar extends StatelessWidget {
  final String title;
  final String saveName;
  final VoidCallback onClose;

  const _ReplayTopBar({
    required this.title,
    required this.saveName,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(
          children: [
            _ReplayIconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              icon: Icons.close_rounded,
              onPressed: onClose,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiTheme.bg.withAlpha(218),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: GameUiTheme.gold.withAlpha(110)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: GameUiTheme.cardTitle.copyWith(
                          color: GameUiTheme.goldLight,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          saveName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GameUiTheme.cardMeta,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
