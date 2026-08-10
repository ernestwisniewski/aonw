part of 'worker_action_selection_detail_content.dart';

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        key: const Key('selectionInfo.workerBuild.cancel'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: SurfaceElevation.flat.fill(
            background: GameUiTheme.chipSurface,
            alpha: 128,
          ),
          foregroundColor: GameUiTheme.textSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: const GameIcon(
          GameIcons.close,
          size: GameIconSize.small,
          color: GameUiTheme.textSecondary,
        ),
        label: Text(
          AppLocalizations.of(context).cancelAction,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.actionLabel.copyWith(
            color: GameUiTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _WorkerBuildHeader extends StatelessWidget {
  const _WorkerBuildHeader({required this.selected, required this.compact});

  final WorkerImprovementOptionViewModel? selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BuildIcon(compact: compact),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                selected == null
                    ? l10n.workerActionSelectImprovement
                    : l10n.workerActionSelectedImprovement(selected!.title),
                style: GameHudTheme.selectionTitle,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.workerActionSelectionHint,
                style: GameHudTheme.selectionSubtitle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuildIcon extends StatelessWidget {
  const _BuildIcon({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 34 : 38,
      height: compact ? 34 : 38,
      alignment: Alignment.center,
      decoration: SurfaceElevation.flat.decoration(
        accent: GameHudTheme.success,
        backgroundAlpha: 95,
        border: BorderEmphasis.regular,
        shape: SurfaceShape.chip,
      ),
      child: const GameIcon(
        GameIcons.improvement,
        size: GameIconSize.regular,
        color: GameHudTheme.success,
      ),
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.selected,
    required this.canConfirm,
    required this.onPressed,
  });

  final WorkerImprovementOptionViewModel? selected;
  final bool canConfirm;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = selected == null
        ? l10n.workerActionSelectImprovement
        : l10n.workerActionBuildImprovement(selected!.title);
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        key: const Key('selectionInfo.workerBuild.confirm'),
        onPressed: canConfirm ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: canConfirm
              ? GameUiTheme.gold
              : SurfaceElevation.flat.fill(
                  background: GameUiTheme.chipSurface,
                  alpha: 150,
                ),
          foregroundColor: canConfirm ? GameUiTheme.bg : GameUiTheme.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: GameIcon(
          GameIcons.production,
          size: GameIconSize.small,
          color: canConfirm ? GameUiTheme.bg : GameUiTheme.textMuted,
        ),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.actionLabel.copyWith(
            color: canConfirm ? GameUiTheme.bg : GameUiTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
