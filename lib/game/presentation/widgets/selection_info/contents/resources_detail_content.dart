import 'package:aonw/game/presentation/widgets/selection/selection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/game/presentation/widgets/visual/game_insight_widgets.dart';
import 'package:aonw/l10n/game_text.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:flutter/material.dart';

class ResourcesDetailContent extends StatelessWidget {
  final SelectionResourcesDetail model;
  final bool compact;

  const ResourcesDetailContent({
    required this.model,
    required this.compact,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (model.valueCards.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < model.valueCards.length; i++) ...[
            _ResourceValueCardTile(
              card: model.valueCards[i],
              compact: compact,
              l10n: l10n,
            ),
            if (i != model.valueCards.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    if (model.resourceLabels.isEmpty) {
      return Text(
        l10n.resourceDetailNoResourcesOnTile,
        style: const TextStyle(
          color: GameHudTheme.textMuted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final label in model.resourceLabels) _ResourceTile(label: label),
      ],
    );
  }
}

class _ResourceValueCardTile extends StatelessWidget {
  final SelectionResourceValueCard card;
  final bool compact;
  final AppLocalizations l10n;

  const _ResourceValueCardTile({
    required this.card,
    required this.compact,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final density = compact
        ? SelectionDensity.compact
        : SelectionDensity.comfortable;
    final yieldComparison = _yieldComparisonItems(card);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
                _CategoryPill(
                  label: card.categoryLabel,
                  color: card.accentColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            _ResourceSection(
              title: l10n.resourceDetailAfterImprovementSection,
              body: _improvementBody(card),
            ),
            if (card.improvementYield.isNotEmpty) ...[
              const SizedBox(height: 7),
              SelectionYieldStrip(
                items: card.improvementYield,
                density: density,
              ),
            ],
            if (yieldComparison.isNotEmpty) ...[
              const SizedBox(height: 10),
              GameYieldDeltaComparison(
                title: l10n.resourceDetailYieldComparison,
                beforeLabel: l10n.visualCurrentLabel,
                afterLabel: l10n.resourceDetailAfterImprovementSection,
                items: yieldComparison,
                accent: card.accentColor,
              ),
            ],
            const SizedBox(height: 10),
            _ResourceSection(
              title: l10n.resourceDetailRequiresSection,
              body: _requirementBody(card),
            ),
            const SizedBox(height: 10),
            _ResourceSection(
              title: l10n.resourceDetailBestMoveSection,
              body: _bestMoveBody(card),
            ),
          ],
        ),
      ),
    );
  }

  String _improvementBody(SelectionResourceValueCard card) {
    if (card.improvementStatusKind ==
        SelectionResourceImprovementStatusKind.noLegalImprovementForTile) {
      return l10n.resourceDetailNoMatchingImprovementBody;
    }
    return card.improvementTitle;
  }

  String _requirementBody(SelectionResourceValueCard card) {
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

  String _bestMoveBody(SelectionResourceValueCard card) {
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
  final String label;
  final Color color;

  const _CategoryPill({required this.label, required this.color});

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
  final String title;
  final String body;

  const _ResourceSection({required this.title, required this.body});

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
  final String label;

  const _SectionTitle(this.label);

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

class _ResourceTile extends StatelessWidget {
  final String label;

  const _ResourceTile({required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: SurfaceElevation.flat.decoration(
        background: GameUiTheme.chipSurface,
        backgroundAlpha: 190,
        border: BorderEmphasis.regular,
        borderRadius: BorderRadius.circular(GameHudTheme.panelRadius),
        includeShadow: false,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GameIcon(
              GameIcons.resources,
              size: GameIconSize.small,
              color: GameUiTheme.gold,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: GameHudTheme.textBright,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
