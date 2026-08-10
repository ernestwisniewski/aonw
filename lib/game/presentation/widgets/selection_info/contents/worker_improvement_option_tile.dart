part of 'worker_action_selection_detail_content.dart';

class _WorkerImprovementOptionTile extends StatelessWidget {
  const _WorkerImprovementOptionTile({
    required this.option,
    required this.compact,
    required this.onTap,
    super.key,
  });

  final WorkerImprovementOptionViewModel option;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(option);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: DecoratedBox(
          decoration: SurfaceElevation.flat.decoration(
            accent: accent,
            backgroundAlpha: option.selected ? 104 : 54,
            border: option.selected
                ? BorderEmphasis.strong
                : BorderEmphasis.regular,
            shape: SurfaceShape.card,
            includeShadow: false,
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 9 : 10),
            child: _WorkerImprovementOptionBody(
              option: option,
              compact: compact,
              accent: accent,
            ),
          ),
        ),
      ),
    );
  }

  static Color _accentFor(WorkerImprovementOptionViewModel option) {
    if (option.blocked) return GameUiTheme.textMuted;
    if (option.selected) return GameUiTheme.goldLight;
    if (option.recommended) return GameUiTheme.success;
    return GameUiTheme.gold;
  }
}

class _WorkerImprovementOptionBody extends StatelessWidget {
  const _WorkerImprovementOptionBody({
    required this.option,
    required this.compact,
    required this.accent,
  });

  final WorkerImprovementOptionViewModel option;
  final bool compact;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Opacity(
          opacity: option.blocked ? 0.45 : 1,
          child: FieldImprovementSpriteIcon(
            type: option.improvementType,
            size: compact ? 34 : 40,
            fallback: GameIcon(
              GameIcons.improvement,
              size: GameIconSize.small,
              color: accent,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: _WorkerImprovementOptionDetails(option: option)),
      ],
    );
  }
}

class _WorkerImprovementOptionDetails extends StatelessWidget {
  const _WorkerImprovementOptionDetails({required this.option});

  final WorkerImprovementOptionViewModel option;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                option.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionTag.copyWith(
                  color: option.blocked
                      ? GameUiTheme.textMuted
                      : GameUiTheme.textBright,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 6),
            _StatePill(option: option),
          ],
        ),
        const SizedBox(height: 5),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            ..._yieldChips(context, option.yield),
            _InfoChip(
              label: l10n.turnCountLabel(option.buildTurns),
              color: GameUiTheme.textSecondary,
            ),
          ],
        ),
        if (option.reason.trim().isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            option.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GameHudTheme.selectionSubtitle.copyWith(
              color: option.blocked
                  ? GameUiTheme.warning
                  : GameUiTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }

  static List<Widget> _yieldChips(BuildContext context, TileYield yield) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[
      if (yield.food != 0)
        _InfoChip(
          label: _signed(yield.food, l10n.yieldFoodShort),
          color: GameUiTheme.success,
        ),
      if (yield.production != 0)
        _InfoChip(
          label: _signed(yield.production, l10n.yieldProductionShort),
          color: GameUiTheme.gold,
        ),
      if (yield.gold != 0)
        _InfoChip(
          label: _signed(yield.gold, l10n.yieldGoldShort),
          color: GameUiTheme.resourcesAccent,
        ),
      if (yield.defense != 0)
        _InfoChip(
          label: _signed(yield.defense, l10n.yieldDefenseShort),
          color: GameUiTheme.info,
        ),
    ];
    if (chips.isNotEmpty) return chips;
    return [
      _InfoChip(
        label: l10n.workerActionNoYieldChange,
        color: GameUiTheme.textMuted,
      ),
    ];
  }

  static String _signed(int value, String suffix) =>
      '${value > 0 ? '+' : ''}$value $suffix';
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.option});

  final WorkerImprovementOptionViewModel option;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (:label, :color) = switch (option.state) {
      WorkerImprovementOptionState.selected => (
        label: l10n.commonSelectedAction,
        color: GameUiTheme.goldLight,
      ),
      WorkerImprovementOptionState.recommended => (
        label: l10n.cityBuildingSortRecommended,
        color: GameHudTheme.success,
      ),
      WorkerImprovementOptionState.available => (
        label: l10n.commonAvailable,
        color: GameUiTheme.gold,
      ),
      WorkerImprovementOptionState.blocked => (
        label: l10n.commonBlocked,
        color: GameUiTheme.textMuted,
      ),
    };
    return _InfoChip(label: label, color: color);
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        accent: color,
        backgroundAlpha: 58,
        border: BorderEmphasis.subtle,
        shape: SurfaceShape.pill,
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          style: GameHudTheme.selectionTag.copyWith(color: color, fontSize: 10),
        ),
      ),
    );
  }
}
