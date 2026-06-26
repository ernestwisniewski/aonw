import 'dart:math' as math;

import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/providers/map/map_inspection_provider.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

part 'hud_map_objective_inspection.dart';
part 'hud_map_objective_popover.dart';
part 'hud_artifact_step_pill.dart';

class HudMapInspectionMenu extends StatelessWidget {
  const HudMapInspectionMenu({
    required this.inspection,
    required this.selection,
    required this.viewportSize,
    required this.activePlayerId,
    required this.research,
    required this.technologyRuleset,
    required this.onClose,
    super.key,
  });

  static const double _horizontalGap = 20;
  static const double _margin = 12;
  static const double _maxWidth = 308;
  static const double _minWidth = 236;
  static const double _estimatedHeight = 354;

  final MapInspectionState inspection;
  final SelectionViewModel? selection;
  final Size viewportSize;
  final String activePlayerId;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final anchor = inspection.anchor;
    final model = inspection.selection == null ? null : selection;
    final artifact = inspection.artifact;
    final objective = inspection.objectiveProgress;
    if (anchor == null ||
        (model == null && artifact == null && objective == null)) {
      return const SizedBox.shrink();
    }

    final availableWidth = math.max(0.0, viewportSize.width - _margin * 2);
    final width = math.min(_maxWidth, math.max(_minWidth, availableWidth));
    final preferRight =
        anchor.dx + _horizontalGap + width <= viewportSize.width - _margin;
    final canUseLeft = anchor.dx - _horizontalGap - width >= _margin;
    final placeRight = preferRight || !canUseLeft;
    final left = placeRight
        ? math.min(
            anchor.dx + _horizontalGap,
            viewportSize.width - width - _margin,
          )
        : math.max(_margin, anchor.dx - _horizontalGap - width);
    final maxTop = math.max(_margin, viewportSize.height - _estimatedHeight);
    final top = (anchor.dy - 72).clamp(_margin, maxTop).toDouble();
    final arrowTop = (anchor.dy - top - 6).clamp(22.0, 232.0).toDouble();
    final maxHeight = math
        .max(160, viewportSize.height - top - _margin)
        .toDouble();

    return Positioned(
      key: const Key('hudMapInspectionMenu.positioned'),
      left: left,
      top: top,
      width: width,
      child: artifact != null
          ? _ArtifactInspectionPopover(
              artifact: artifact,
              onClose: onClose,
              arrowOnLeft: placeRight,
              arrowTop: arrowTop,
              maxHeight: maxHeight,
            )
          : model != null
          ? _InspectionPopover(
              model: model,
              activePlayerId: activePlayerId,
              research: research,
              technologyRuleset: technologyRuleset,
              objectiveProgress: objective,
              onClose: onClose,
              arrowOnLeft: placeRight,
              arrowTop: arrowTop,
              maxHeight: maxHeight,
            )
          : _ObjectiveInspectionPopover(
              progress: objective!,
              onClose: onClose,
              arrowOnLeft: placeRight,
              arrowTop: arrowTop,
              maxHeight: maxHeight,
            ),
    );
  }
}

class _ArtifactInspectionPopover extends StatelessWidget {
  const _ArtifactInspectionPopover({
    required this.artifact,
    required this.onClose,
    required this.arrowOnLeft,
    required this.arrowTop,
    required this.maxHeight,
  });

  final WorldArtifact artifact;
  final VoidCallback onClose;
  final bool arrowOnLeft;
  final double arrowTop;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: arrowOnLeft ? -5 : null,
            right: arrowOnLeft ? null : -5,
            top: arrowTop,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: GameUiTheme.surfaceDeep.withAlpha(244),
                  border: Border.all(color: GameUiTheme.gold.withAlpha(145)),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GameUiTheme.surfaceDeep.withAlpha(246),
                    GameUiTheme.bg.withAlpha(238),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GameUiTheme.gold.withAlpha(168)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(130),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ArtifactHeader(artifact: artifact, onClose: onClose),
                      const SizedBox(height: 10),
                      _Section(
                        icon: GameIcons.info,
                        title: l10n.commonDescription,
                        child: _ArtifactDescription(artifact: artifact),
                      ),
                      const SizedBox(height: 8),
                      _Section(
                        icon: GameIcons.artifact,
                        title: l10n.worldArtifactBonusTitle,
                        child: _ValueLine(
                          value: GameDisplayNames.worldArtifactShortBonus(
                            l10n,
                            artifact.type,
                          ),
                          color: GameUiTheme.goldLight,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Section(
                        icon: GameIcons.victory,
                        title: l10n.worldArtifactHeritageTitle,
                        child: Text(
                          l10n.worldArtifactHeritageBody,
                          style: GameUiTheme.bodySmall.copyWith(
                            color: GameUiTheme.textPrimary,
                            height: 1.22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectionPopover extends StatelessWidget {
  const _InspectionPopover({
    required this.model,
    required this.activePlayerId,
    required this.research,
    required this.technologyRuleset,
    required this.objectiveProgress,
    required this.onClose,
    required this.arrowOnLeft,
    required this.arrowTop,
    required this.maxHeight,
  });

  final SelectionViewModel model;
  final String activePlayerId;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final MapObjectiveProgress? objectiveProgress;
  final VoidCallback onClose;
  final bool arrowOnLeft;
  final double arrowTop;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: arrowOnLeft ? -5 : null,
            right: arrowOnLeft ? null : -5,
            top: arrowTop,
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: GameUiTheme.surfaceDeep.withAlpha(244),
                  border: Border.all(color: GameUiTheme.gold.withAlpha(145)),
                ),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GameUiTheme.surfaceDeep.withAlpha(246),
                    GameUiTheme.bg.withAlpha(238),
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: GameUiTheme.gold.withAlpha(150)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(130),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(model: model, onClose: onClose),
                      const SizedBox(height: 10),
                      _Section(
                        icon: GameIcons.info,
                        title: l10n.commonDescription,
                        child: _Description(model: model),
                      ),
                      const SizedBox(height: 8),
                      _Section(
                        icon: GameIcons.terrain,
                        title: l10n.commonTerrain,
                        child: _ValueLine(
                          value: _itemValue(
                            model,
                            SelectionInfoItemSemanticId.terrain,
                            fallback: l10n.commonNoneLower,
                          ),
                          color: const Color(0xFF89B66F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _Section(
                        icon: GameIcons.resources,
                        title: l10n.commonResources,
                        child: _ValueLine(
                          value: _itemValue(
                            model,
                            SelectionInfoItemSemanticId.resources,
                            fallback: l10n.commonNoneLower,
                          ),
                          color: GameUiTheme.resourcesAccent,
                        ),
                      ),
                      if (objectiveProgress case final progress?)
                        _MapObjectiveInspectionSection(progress: progress),
                      const SizedBox(height: 8),
                      _Section(
                        icon: GameIcons.improvement,
                        title: l10n.mapInspectionPossibleImprovementsTitle,
                        child: _PossibleImprovements(
                          items: model.improvements,
                          activePlayerId: activePlayerId,
                          research: research,
                          technologyRuleset: technologyRuleset,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _itemValue(
    SelectionViewModel model,
    String label, {
    required String fallback,
  }) {
    for (final item in model.items) {
      if (_matchesItem(item, label) && item.value.trim().isNotEmpty) {
        return item.value;
      }
    }
    return fallback;
  }

  static bool _matchesItem(SelectionInfoItem item, String label) {
    return item.label == label || item.semanticId == label;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.model, required this.onClose});

  final SelectionViewModel model;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: model.color.withAlpha(38),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: model.color.withAlpha(150)),
          ),
          child: Center(
            child: GameIcon(model.icon, size: 20, color: model.color),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                model.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionTitle.copyWith(fontSize: 15),
              ),
              if (model.subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  model.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GameHudTheme.selectionSubtitle.copyWith(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          key: const Key('hudMapInspectionMenu.close'),
          tooltip: l10n.closeAction,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          onPressed: onClose,
          icon: const GameIcon(
            GameIcons.close,
            size: 15,
            color: GameUiTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ArtifactHeader extends StatelessWidget {
  const _ArtifactHeader({required this.artifact, required this.onClose});

  final WorldArtifact artifact;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: GameUiTheme.gold.withAlpha(42),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GameUiTheme.gold.withAlpha(170)),
          ),
          child: const Center(
            child: GameIcon(
              GameIcons.artifact,
              size: 20,
              color: GameUiTheme.goldLight,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                GameDisplayNames.worldArtifact(l10n, artifact.type),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionTitle.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 2),
              Text(
                GameDisplayNames.worldArtifactLocation(l10n, artifact.location),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GameHudTheme.selectionSubtitle.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          key: const Key('hudMapInspectionMenu.artifact.close'),
          tooltip: l10n.closeAction,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          onPressed: onClose,
          icon: const GameIcon(
            GameIcons.close,
            size: 15,
            color: GameUiTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _ArtifactDescription extends StatelessWidget {
  const _ArtifactDescription({required this.artifact});

  final WorldArtifact artifact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          GameDisplayNames.worldArtifactDescription(l10n, artifact.type),
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            height: 1.22,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            _ArtifactStepPill(
              icon: GameIcons.shovel,
              label: l10n.worldArtifactStepExcavate,
            ),
            _ArtifactStepPill(
              icon: GameIcons.move,
              label: l10n.worldArtifactStepMove,
            ),
            _ArtifactStepPill(
              icon: GameIcons.storeArtifact,
              label: l10n.worldArtifactStepStore,
            ),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final GameIconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GameIcon(icon, size: 14, color: GameUiTheme.goldLight),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GameUiTheme.toolbarLabel.copyWith(
                    color: GameUiTheme.goldLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: GameUiTheme.gold.withAlpha(36)),
            const SizedBox(height: 7),
            child,
          ],
        ),
      ),
    );
  }
}

class _PossibleImprovements extends StatelessWidget {
  const _PossibleImprovements({
    required this.items,
    required this.activePlayerId,
    required this.research,
    required this.technologyRuleset,
  });

  final List<SelectionImprovementItem> items;
  final String activePlayerId;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        AppLocalizations.of(context).mapInspectionNoPossibleImprovements,
        key: const Key('hudMapInspectionMenu.improvements.empty'),
        style: GameUiTheme.bodySmall.copyWith(color: GameUiTheme.textMuted),
      );
    }

    return Column(
      key: const Key('hudMapInspectionMenu.improvements'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          _PossibleImprovementLine(
            item: item,
            activePlayerId: activePlayerId,
            research: research,
            technologyRuleset: technologyRuleset,
          ),
      ],
    );
  }
}

class _PossibleImprovementLine extends StatelessWidget {
  const _PossibleImprovementLine({
    required this.item,
    required this.activePlayerId,
    required this.research,
    required this.technologyRuleset,
  });

  final SelectionImprovementItem item;
  final String activePlayerId;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requiredTechnology =
        TechnologyUnlockQuery.unlockingTechnologyForFieldImprovement(
          improvementType: item.type,
          ruleset: technologyRuleset,
        );
    final hasTechnology =
        requiredTechnology == null ||
        (activePlayerId.isNotEmpty &&
            TechnologyUnlockQuery.hasFieldImprovementUnlocked(
              playerId: activePlayerId,
              improvementType: item.type,
              research: research,
              ruleset: technologyRuleset,
            ));
    final technologyLabel = requiredTechnology == null
        ? l10n.mapInspectionImprovementAvailableFromStart
        : GameDisplayNames.technology(l10n, requiredTechnology.id);
    final technologyColor = hasTechnology
        ? GameUiTheme.success
        : GameUiTheme.danger;

    return Padding(
      key: Key('hudMapInspectionMenu.improvement.${item.type.name}'),
      padding: const EdgeInsets.only(bottom: 5),
      child: Wrap(
        spacing: 5,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            item.title,
            style: GameUiTheme.bodyStrong.copyWith(
              color: GameUiTheme.textPrimary,
              fontSize: 11.5,
            ),
          ),
          Text(
            '($technologyLabel)',
            key: Key(
              'hudMapInspectionMenu.improvement.${item.type.name}.technology',
            ),
            style: GameUiTheme.bodySmall.copyWith(
              color: technologyColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.model});

  final SelectionViewModel model;

  @override
  Widget build(BuildContext context) {
    final detailItems = [
      for (final item in model.items)
        if (item.semanticId != SelectionInfoItemSemanticId.terrain &&
            item.semanticId != SelectionInfoItemSemanticId.resources &&
            item.semanticId != SelectionInfoItemSemanticId.height)
          item,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          model.description.isEmpty
              ? (model.subtitle.isEmpty ? model.title : model.subtitle)
              : model.description,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            height: 1.22,
          ),
        ),
        if (model.yields.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final item in model.yields)
                _YieldPill(
                  icon: item.icon,
                  value: item.value,
                  label: item.label,
                  color: item.color,
                ),
            ],
          ),
        ],
        if (detailItems.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final item in detailItems.take(2))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: _SmallFact(item: item),
            ),
        ],
      ],
    );
  }
}

class _ValueLine extends StatelessWidget {
  const _ValueLine({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: GameUiTheme.bodyStrong.copyWith(color: color),
    );
  }
}

class _SmallFact extends StatelessWidget {
  const _SmallFact({required this.item});

  final SelectionInfoItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GameIcon(item.icon, size: 13, color: item.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            item.showLabel ? '${item.label}: ${item.value}' : item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GameUiTheme.bodySmall.copyWith(
              color: GameUiTheme.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _YieldPill extends StatelessWidget {
  const _YieldPill({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final GameIconData icon;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '$label: $value',
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha(110)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GameIcon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              '$value',
              style: GameHudTheme.yieldValue.copyWith(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
