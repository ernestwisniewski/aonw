part of 'resources_detail_content.dart';

class _ResourceValueCardTile extends StatelessWidget {
  const _ResourceValueCardTile({
    required this.card,
    required this.compact,
    required this.l10n,
  });

  final SelectionResourceValueCard card;
  final bool compact;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 180,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(8),
        includeShadow: false,
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 12),
        child: _ResourceValueCardBody(card: card, compact: compact, l10n: l10n),
      ),
    );
  }
}

class _ResourceValueCardBody extends StatelessWidget {
  const _ResourceValueCardBody({
    required this.card,
    required this.compact,
    required this.l10n,
  });

  final SelectionResourceValueCard card;
  final bool compact;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final density = compact
        ? SelectionDensity.compact
        : SelectionDensity.comfortable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ResourceValueCardHeader(card: card, compact: compact),
        const SizedBox(height: 10),
        _ResourceCurrentValue(card: card, density: density, l10n: l10n),
        if (card.strategicFlow case final flow?) ...[
          const SizedBox(height: 10),
          _StrategicResourceFlow(flow: flow, accent: card.accentColor),
        ],
        const SizedBox(height: 10),
        _ResourceImprovementValue(card: card, density: density, l10n: l10n),
      ],
    );
  }
}

class _StrategicResourceFlow extends StatelessWidget {
  const _StrategicResourceFlow({required this.flow, required this.accent});

  final SelectionStrategicResourceFlow flow;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final statusColor = flow.active ? GameUiTheme.success : GameUiTheme.warning;
    return Semantics(
      label: '${l10n.resourceDetailEmpireSupplySection}. ${flow.description}',
      child: DecoratedBox(
        decoration: SurfaceElevation.flat.decoration(
          background: statusColor,
          backgroundAlpha: 20,
          borderColor: statusColor,
          border: BorderEmphasis.regular,
          borderRadius: BorderRadius.circular(7),
          includeShadow: false,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameIcon(
                flow.active ? GameIcons.resources : GameIcons.warning,
                size: GameIconSize.small,
                color: statusColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      GameText.uppercase(
                        l10n.resourceDetailEmpireSupplySection,
                      ),
                      style: TextStyle(
                        color: accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      flow.description,
                      style: const TextStyle(
                        color: GameHudTheme.textBright,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResourceValueCardHeader extends StatelessWidget {
  const _ResourceValueCardHeader({required this.card, required this.compact});

  final SelectionResourceValueCard card;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GameIcon(
          GameIcons.resources,
          size: compact ? GameIconSize.small : GameIconSize.regular,
          color: card.accentColor,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            card.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GameHudTheme.textBright,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        _CategoryPill(label: card.categoryLabel, color: card.accentColor),
      ],
    );
  }
}

class _ResourceCurrentValue extends StatelessWidget {
  const _ResourceCurrentValue({
    required this.card,
    required this.density,
    required this.l10n,
  });

  final SelectionResourceValueCard card;
  final SelectionDensity density;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ResourceSection(
          title: l10n.resourceDetailValueSection,
          body: card.expansionReason,
        ),
        const SizedBox(height: 10),
        _ResourceSection(
          title: l10n.resourceDetailCurrentSection,
          body: card.currentSummary,
        ),
        if (card.currentYield.isNotEmpty) ...[
          const SizedBox(height: 7),
          SelectionYieldStrip(items: card.currentYield, density: density),
        ],
      ],
    );
  }
}

class _ResourceImprovementValue extends StatelessWidget {
  const _ResourceImprovementValue({
    required this.card,
    required this.density,
    required this.l10n,
  });

  final SelectionResourceValueCard card;
  final SelectionDensity density;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final copy = _ResourceValueCardCopy(l10n);
    final comparison = _yieldComparisonItems(card);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ResourceSection(
          title: l10n.resourceDetailAfterImprovementSection,
          body: copy.improvementBody(card),
        ),
        if (card.improvementYield.isNotEmpty) ...[
          const SizedBox(height: 7),
          SelectionYieldStrip(items: card.improvementYield, density: density),
        ],
        if (comparison.isNotEmpty) ...[
          const SizedBox(height: 10),
          GameYieldDeltaComparison(
            title: l10n.resourceDetailYieldComparison,
            beforeLabel: l10n.visualCurrentLabel,
            afterLabel: l10n.resourceDetailAfterImprovementSection,
            items: comparison,
            accent: card.accentColor,
          ),
        ],
        const SizedBox(height: 10),
        _ResourceSection(
          title: l10n.resourceDetailRequiresSection,
          body: copy.requirementBody(card),
        ),
        const SizedBox(height: 10),
        _ResourceSection(
          title: l10n.resourceDetailBestMoveSection,
          body: copy.bestMoveBody(card),
        ),
      ],
    );
  }
}
