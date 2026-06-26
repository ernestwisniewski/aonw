part of 'new_game_screen.dart';

class _GamePremisePanel extends StatelessWidget {
  const _GamePremisePanel({required this.flow, super.key});

  final NewGameFlow flow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.bg.withAlpha(138),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
        border: Border.all(color: GameUiTheme.gold.withAlpha(92)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.newGamePremiseTitle,
              style: GameUiTheme.cardTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.newGamePremiseBody,
              style: GameUiTheme.body.copyWith(
                color: GameUiTheme.textPrimary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MenuMetricPill(
                  icon: Icons.location_city_outlined,
                  label: l10n.newGamePillarCities,
                ),
                MenuMetricPill(
                  icon: Icons.shield_outlined,
                  label: l10n.newGamePillarUnits,
                ),
                MenuMetricPill(
                  icon: Icons.science_outlined,
                  label: l10n.newGamePillarResearch,
                  color: GameUiTheme.scienceAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _FlowSummaryStrip(flow: flow),
          ],
        ),
      ),
    );
  }
}

class _FlowSummaryStrip extends StatelessWidget {
  const _FlowSummaryStrip({required this.flow});

  final NewGameFlow flow;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: GameUiTheme.surface.withAlpha(156),
        borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
        border: Border.all(color: GameUiTheme.copper.withAlpha(118)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(flow.icon, size: 20, color: GameUiTheme.goldLight),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _flowDescription(l10n, flow),
                style: GameUiTheme.bodyStrong.copyWith(
                  color: GameUiTheme.goldLight,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeChoiceCard extends StatelessWidget {
  const _ModeChoiceCard({
    super.key,
    required this.flow,
    required this.selected,
    required this.enabled,
    required this.disabledReason,
    required this.onTap,
  });

  final NewGameFlow flow;
  final bool selected;
  final bool enabled;
  final String? disabledReason;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final disabled = !enabled;
    final effectiveSelected = selected && enabled;
    return Semantics(
      button: true,
      enabled: enabled,
      selected: effectiveSelected,
      label: disabledReason == null
          ? flow.menuLabel(l10n)
          : '${flow.menuLabel(l10n)}. $disabledReason',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: GameMotion.snap,
          padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                effectiveSelected
                    ? GameUiTheme.gold.withAlpha(42)
                    : disabled
                    ? GameUiTheme.surface.withAlpha(100)
                    : GameUiTheme.surface.withAlpha(168),
                GameUiTheme.bg.withAlpha(disabled ? 124 : 170),
              ],
            ),
            borderRadius: BorderRadius.circular(GameUiTheme.radiusCard),
            border: Border.all(
              color: effectiveSelected
                  ? GameUiTheme.goldLight
                  : disabled
                  ? GameUiTheme.goldDark.withAlpha(76)
                  : GameUiTheme.gold.withAlpha(84),
              width: effectiveSelected ? 1.3 : 1,
            ),
            boxShadow: effectiveSelected
                ? [
                    BoxShadow(
                      color: GameUiTheme.gold.withAlpha(32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: GameUiTheme.bg.withAlpha(disabled ? 98 : 150),
                  borderRadius: BorderRadius.circular(GameUiTheme.radiusButton),
                  border: Border.all(
                    color: GameUiTheme.gold.withAlpha(disabled ? 58 : 120),
                  ),
                ),
                child: SizedBox.square(
                  dimension: 42,
                  child: Icon(
                    flow.icon,
                    size: 22,
                    color: effectiveSelected
                        ? GameUiTheme.goldLight
                        : disabled
                        ? GameUiTheme.textMuted
                        : GameUiTheme.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GameText.menuLabel(flow.menuLabel(l10n)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.cardTitle.copyWith(
                        color: disabled
                            ? GameUiTheme.textMuted
                            : GameUiTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _flowDescription(l10n, flow),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GameUiTheme.cardMeta.copyWith(
                        color: disabled
                            ? GameUiTheme.textMuted
                            : GameUiTheme.textTertiary,
                        height: 1.25,
                      ),
                    ),
                    if (disabledReason != null) ...[
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.lock_clock_outlined,
                            size: 13,
                            color: GameUiTheme.copper,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              disabledReason!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GameUiTheme.toolbarLabel.copyWith(
                                color: GameUiTheme.copper,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (effectiveSelected) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.check_circle_outline,
                  size: 20,
                  color: GameUiTheme.goldLight,
                ),
              ] else if (disabled) ...[
                const SizedBox(width: 10),
                const Icon(
                  Icons.lock_outline,
                  size: 19,
                  color: GameUiTheme.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
