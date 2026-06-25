part of 'new_game_screen.dart';

class _NewGameLoading extends StatelessWidget {
  const _NewGameLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 260,
        child: LinearProgressIndicator(
          minHeight: 4,
          color: GameUiTheme.goldLight,
          backgroundColor: GameUiTheme.chipSurface,
        ),
      ),
    );
  }
}

class _NewGameActionSummary extends StatelessWidget {
  const _NewGameActionSummary({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: GameUiTheme.gold),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                GameText.actionLabel(title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameUiTheme.cardMeta,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NewGameStepRail extends StatelessWidget {
  const _NewGameStepRail({required this.step, required this.onStepSelected});

  final _NewGameStep step;
  final ValueChanged<_NewGameStep> onStepSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final steps = [
      (
        step: _NewGameStep.plan,
        icon: Icons.auto_awesome,
        label: l10n.newGameStepPlan,
      ),
      (
        step: _NewGameStep.review,
        icon: Icons.flag_outlined,
        label: l10n.newGameStepReview,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < steps.length; index++)
              _NewGameStepChip(
                number: index + 1,
                icon: steps[index].icon,
                label: steps[index].label,
                selected: step == steps[index].step,
                compact: compact,
                onTap: () => onStepSelected(steps[index].step),
              ),
          ],
        );
      },
    );
  }
}

class _NewGameStepChip extends StatelessWidget {
  const _NewGameStepChip({
    required this.number,
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final int number;
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: GameMotion.snap,
          width: compact ? null : 196,
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? GameUiTheme.gold.withAlpha(34)
                : GameUiTheme.bg.withAlpha(148),
            borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
            border: Border.all(
              color: selected
                  ? GameUiTheme.gold
                  : GameUiTheme.gold.withAlpha(78),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: GameUiTheme.copper.withAlpha(32),
                      blurRadius: 20,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Text(
                '$number',
                style: GameUiTheme.toolbarLabel.copyWith(
                  color: selected
                      ? GameUiTheme.goldLight
                      : GameUiTheme.textTertiary,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                icon,
                size: 16,
                color: selected ? GameUiTheme.goldLight : GameUiTheme.gold,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  GameText.actionLabel(label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.actionLabel.copyWith(
                    color: selected
                        ? GameUiTheme.goldLight
                        : GameUiTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
