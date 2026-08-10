part of 'resources_detail_content.dart';

class _ResourceValueCardCopy {
  const _ResourceValueCardCopy(this.l10n);

  final AppLocalizations l10n;

  String improvementBody(SelectionResourceValueCard card) {
    if (card.improvementStatusKind ==
        SelectionResourceImprovementStatusKind.noLegalImprovementForTile) {
      return l10n.resourceDetailNoMatchingImprovementBody;
    }
    return card.improvementTitle;
  }

  String requirementBody(SelectionResourceValueCard card) {
    return switch (card.improvementStatusKind) {
      SelectionResourceImprovementStatusKind.requiresTechnology =>
        card.requiredTechnologyName ?? card.improvementStatus,
      SelectionResourceImprovementStatusKind.availableForWorker =>
        l10n.resourceDetailRequirementNoneCanBuild,
      SelectionResourceImprovementStatusKind.outsideCityBorders =>
        l10n.resourceDetailRequirementOutsideCity,
      SelectionResourceImprovementStatusKind.tileAlreadyImproved =>
        l10n.resourceDetailRequirementAlreadyImproved,
      SelectionResourceImprovementStatusKind.cityCenter =>
        l10n.resourceDetailRequirementCityCenter,
      SelectionResourceImprovementStatusKind.selectWorkerOrCity =>
        l10n.resourceDetailRequirementSelectWorkerOrCity,
      SelectionResourceImprovementStatusKind.noLegalImprovementForTile =>
        l10n.resourceDetailRequirementNoLegalImprovement,
      SelectionResourceImprovementStatusKind.custom => card.improvementStatus,
    };
  }

  String bestMoveBody(SelectionResourceValueCard card) {
    return switch (card.improvementStatusKind) {
      SelectionResourceImprovementStatusKind.requiresTechnology =>
        l10n.resourceDetailBestMoveRequiresTechnology(
          card.requiredTechnologyName ?? card.improvementStatus,
          card.improvementTitle,
        ),
      SelectionResourceImprovementStatusKind.availableForWorker =>
        l10n.resourceDetailBestMoveAvailable(card.improvementTitle),
      SelectionResourceImprovementStatusKind.outsideCityBorders =>
        l10n.resourceDetailBestMoveOutsideCity,
      SelectionResourceImprovementStatusKind.tileAlreadyImproved =>
        l10n.resourceDetailBestMoveAlreadyImproved,
      SelectionResourceImprovementStatusKind.cityCenter =>
        l10n.resourceDetailBestMoveCityCenter,
      SelectionResourceImprovementStatusKind.selectWorkerOrCity =>
        l10n.resourceDetailBestMoveSelectWorkerOrCity,
      SelectionResourceImprovementStatusKind.noLegalImprovementForTile =>
        l10n.resourceDetailBestMoveNoLegalImprovement,
      SelectionResourceImprovementStatusKind.custom => card.improvementStatus,
    };
  }
}

List<GameYieldDeltaItem> _yieldComparisonItems(
  SelectionResourceValueCard card,
) {
  final values = <String, _YieldComparisonAccumulator>{};
  for (final item in card.currentYield) {
    values[item.label] = _YieldComparisonAccumulator(
      icon: item.icon,
      label: item.label,
      color: item.color,
      before: item.value,
      delta: 0,
    );
  }
  for (final item in card.improvementYield) {
    final existing = values[item.label];
    values[item.label] = existing == null
        ? _YieldComparisonAccumulator(
            icon: item.icon,
            label: item.label,
            color: item.color,
            before: 0,
            delta: item.value,
          )
        : existing.copyWith(delta: existing.delta + item.value);
  }
  return [
    for (final value in values.values)
      GameYieldDeltaItem(
        icon: value.icon,
        label: value.label,
        before: value.before,
        after: value.before + value.delta,
        color: value.color,
      ),
  ];
}

class _YieldComparisonAccumulator {
  const _YieldComparisonAccumulator({
    required this.icon,
    required this.label,
    required this.color,
    required this.before,
    required this.delta,
  });

  final GameIconData icon;
  final String label;
  final Color color;
  final int before;
  final int delta;

  _YieldComparisonAccumulator copyWith({int? delta}) {
    return _YieldComparisonAccumulator(
      icon: icon,
      label: label,
      color: color,
      before: before,
      delta: delta ?? this.delta,
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: SurfaceElevation.flat.fill(background: color, alpha: 28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: SurfaceElevation.flat.strokeColor(color: color, alpha: 120),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          GameText.uppercase(label),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _ResourceSection extends StatelessWidget {
  const _ResourceSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SectionTitle(title),
        const SizedBox(height: 3),
        Text(
          body,
          style: const TextStyle(
            color: GameHudTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      GameText.uppercase(label),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: GameHudTheme.textBright,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
