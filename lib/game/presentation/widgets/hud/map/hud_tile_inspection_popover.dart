import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_inspection_components.dart';
import 'package:aonw/game/presentation/widgets/hud/map/hud_map_objective_inspection.dart';
import 'package:aonw/game/presentation/widgets/selection/view_models.dart';
import 'package:aonw/game/presentation/widgets/theme/game_hud_theme.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

class HudTileInspectionPopover extends StatelessWidget {
  const HudTileInspectionPopover({
    required this.model,
    required this.activePlayerId,
    required this.research,
    required this.technologyRuleset,
    required this.objectiveProgress,
    required this.onClose,
    required this.arrowOnLeft,
    required this.arrowTop,
    required this.maxHeight,
    super.key,
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
    return HudMapInspectionPopoverFrame(
      arrowOnLeft: arrowOnLeft,
      arrowTop: arrowTop,
      maxHeight: maxHeight,
      borderAlpha: 150,
      child: _TileInspectionContent(
        model: model,
        activePlayerId: activePlayerId,
        research: research,
        technologyRuleset: technologyRuleset,
        objectiveProgress: objectiveProgress,
        onClose: onClose,
      ),
    );
  }
}

class _TileInspectionContent extends StatelessWidget {
  const _TileInspectionContent({
    required this.model,
    required this.activePlayerId,
    required this.research,
    required this.technologyRuleset,
    required this.objectiveProgress,
    required this.onClose,
  });

  final SelectionViewModel model;
  final String activePlayerId;
  final ResearchState research;
  final TechnologyRuleset technologyRuleset;
  final MapObjectiveProgress? objectiveProgress;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _sections(l10n),
      ),
    );
  }

  List<Widget> _sections(AppLocalizations l10n) {
    return [
      _Header(model: model, onClose: onClose),
      const SizedBox(height: 10),
      HudMapInspectionSection(
        icon: GameIcons.info,
        title: l10n.commonDescription,
        child: _Description(model: model),
      ),
      const SizedBox(height: 8),
      HudMapInspectionSection(
        icon: GameIcons.terrain,
        title: l10n.commonTerrain,
        child: HudMapInspectionValueLine(
          value: _itemValue(
            model,
            SelectionInfoItemSemanticId.terrain,
            fallback: l10n.commonNoneLower,
          ),
          color: const Color(0xFF89B66F),
        ),
      ),
      const SizedBox(height: 8),
      HudMapInspectionSection(
        icon: GameIcons.resources,
        title: l10n.commonResources,
        child: HudMapInspectionValueLine(
          value: _itemValue(
            model,
            SelectionInfoItemSemanticId.resources,
            fallback: l10n.commonNoneLower,
          ),
          color: GameUiTheme.resourcesAccent,
        ),
      ),
      if (objectiveProgress case final progress?)
        HudMapObjectiveInspectionSection(progress: progress),
      const SizedBox(height: 8),
      HudMapInspectionSection(
        icon: GameIcons.improvement,
        title: l10n.mapInspectionPossibleImprovementsTitle,
        child: _PossibleImprovements(
          items: model.improvements,
          activePlayerId: activePlayerId,
          research: research,
          technologyRuleset: technologyRuleset,
        ),
      ),
    ];
  }
}

String _itemValue(
  SelectionViewModel model,
  String label, {
  required String fallback,
}) {
  for (final item in model.items) {
    if ((item.label == label || item.semanticId == label) &&
        item.value.trim().isNotEmpty) {
      return item.value;
    }
  }
  return fallback;
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
    final detailItems = _detailItems(model);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _description(model),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style: GameUiTheme.bodySmall.copyWith(
            color: GameUiTheme.textPrimary,
            height: 1.22,
          ),
        ),
        if (model.yields.isNotEmpty) _YieldDetails(items: model.yields),
        if (detailItems.isNotEmpty) _FactDetails(items: detailItems),
      ],
    );
  }
}

String _description(SelectionViewModel model) {
  if (model.description.isNotEmpty) return model.description;
  return model.subtitle.isEmpty ? model.title : model.subtitle;
}

List<SelectionInfoItem> _detailItems(SelectionViewModel model) {
  return model.items
      .where((item) {
        return item.semanticId != SelectionInfoItemSemanticId.terrain &&
            item.semanticId != SelectionInfoItemSemanticId.resources &&
            item.semanticId != SelectionInfoItemSemanticId.height;
      })
      .toList(growable: false);
}

class _YieldDetails extends StatelessWidget {
  const _YieldDetails({required this.items});

  final List<SelectionYieldItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 5,
        runSpacing: 5,
        children: [
          for (final item in items)
            HudMapInspectionYieldPill(
              icon: item.icon,
              value: item.value,
              label: item.label,
              color: item.color,
            ),
        ],
      ),
    );
  }
}

class _FactDetails extends StatelessWidget {
  const _FactDetails({required this.items});

  final List<SelectionInfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          for (final item in items.take(2))
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: HudMapInspectionSmallFact(item: item),
            ),
        ],
      ),
    );
  }
}
