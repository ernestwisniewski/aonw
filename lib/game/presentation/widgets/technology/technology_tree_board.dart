import 'dart:math' as math;

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/hud/hud_panel_empty_state.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_canvas.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_horizontal_scrollbar.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_node.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

class TechnologyTreeBoard extends StatelessWidget {
  const TechnologyTreeBoard({
    required this.cards,
    required this.selectedTechnologyId,
    required this.hasDetailsLayer,
    required this.compact,
    required this.pathAnimation,
    required this.verticalController,
    required this.horizontalController,
    required this.l10n,
    required this.onTechnologySelected,
    required this.onTechnologyDetails,
    required this.onBuildingDetails,
    required this.onUnitDetails,
    required this.onResearch,
    super.key,
  });

  final List<TechnologyCardViewModel> cards;
  final TechnologyId? selectedTechnologyId;
  final bool hasDetailsLayer;
  final bool compact;
  final Animation<double> pathAnimation;
  final ScrollController verticalController;
  final ScrollController horizontalController;
  final AppLocalizations l10n;
  final ValueChanged<TechnologyCardViewModel> onTechnologySelected;
  final ValueChanged<TechnologyCardViewModel> onTechnologyDetails;
  final ValueChanged<CityBuildingType> onBuildingDetails;
  final ValueChanged<GameUnitType> onUnitDetails;
  final ValueChanged<TechnologyId> onResearch;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return _EmptyTechnologyState(l10n: l10n);
    }

    final metrics = TechnologyTreeBoardMetrics.fromCards(
      cards,
      compact: compact,
    );
    final selectedPath = TechnologyPathSelection.from(
      cards,
      targetId: _selectedPathTarget(),
    );
    final bottomReserve = compact ? 24.0 : 28.0;

    return Stack(
      children: [
        Scrollbar(
          controller: verticalController,
          thumbVisibility: !compact,
          child: SingleChildScrollView(
            controller: verticalController,
            child: SingleChildScrollView(
              controller: horizontalController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: metrics.width,
                height: metrics.height + bottomReserve,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    key: const Key('technologyTreeBoard.grid'),
                    width: metrics.width,
                    height: metrics.height,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: TechnologyTreePainter(
                              cards: cards,
                              rects: metrics.rects,
                              selectedPath: selectedPath,
                              pathAnimation: pathAnimation,
                            ),
                          ),
                        ),
                        for (final card in cards)
                          Positioned.fromRect(
                            rect: metrics.rects[card.id]!,
                            child: TechnologyTreeNode(
                              card: card,
                              l10n: l10n,
                              selected: selectedPath.targetId == card.id,
                              inSelectedPath: selectedPath.ids.contains(
                                card.id,
                              ),
                              onSelected: () => onTechnologySelected(card),
                              onDetails: () => onTechnologyDetails(card),
                              showUnlockDetails: !hasDetailsLayer,
                              onBuildingDetails: onBuildingDetails,
                              onUnitDetails: onUnitDetails,
                              onResearch: card.canSelect
                                  ? () => onResearch(card.id)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: compact ? 14 : 20,
          right: compact ? 14 : 20,
          bottom: compact ? 8 : 10,
          child: TechnologyTreeHorizontalScrollbar(
            controller: horizontalController,
            compact: compact,
          ),
        ),
      ],
    );
  }

  TechnologyId? _selectedPathTarget() {
    for (final card in cards) {
      if (card.id == selectedTechnologyId &&
          card.state == TechnologyCardState.locked) {
        return selectedTechnologyId;
      }
    }
    return null;
  }
}

class TechnologyTreeBoardMetrics {
  const TechnologyTreeBoardMetrics({
    required this.nodeWidth,
    required this.nodeHeight,
    required this.horizontalGap,
    required this.verticalGap,
    required this.padding,
    required this.size,
    required this.rects,
  });

  final double nodeWidth;
  final double nodeHeight;
  final double horizontalGap;
  final double verticalGap;
  final double padding;
  final Size size;
  final Map<TechnologyId, Rect> rects;

  double get width => size.width;
  double get height => size.height;

  factory TechnologyTreeBoardMetrics.fromCards(
    List<TechnologyCardViewModel> cards, {
    required bool compact,
  }) {
    final nodeWidth = compact ? 164.0 : 194.0;
    final nodeHeight = compact ? 164.0 : 174.0;
    final horizontalGap = compact ? 34.0 : 52.0;
    const verticalGap = 18.0;
    const padding = 16.0;

    final maxColumn = cards.isEmpty
        ? 0
        : cards.map((card) => card.treeColumn).reduce(math.max);
    final maxRow = cards.isEmpty
        ? 0
        : cards.map((card) => card.treeRow).reduce(math.max);
    final width =
        padding * 2 + (maxColumn + 1) * nodeWidth + maxColumn * horizontalGap;
    final height =
        padding * 2 + (maxRow + 1) * nodeHeight + maxRow * verticalGap;

    return TechnologyTreeBoardMetrics(
      nodeWidth: nodeWidth,
      nodeHeight: nodeHeight,
      horizontalGap: horizontalGap,
      verticalGap: verticalGap,
      padding: padding,
      size: Size(width, height),
      rects: Map.unmodifiable({
        for (final card in cards)
          card.id: Rect.fromLTWH(
            padding + card.treeColumn * (nodeWidth + horizontalGap),
            padding + card.treeRow * (nodeHeight + verticalGap),
            nodeWidth,
            nodeHeight,
          ),
      }),
    );
  }
}

class _EmptyTechnologyState extends StatelessWidget {
  const _EmptyTechnologyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: HudPanelEmptyState(
          icon: GameIcons.science,
          title: l10n.technologyTreeEmptyTitle,
          body: l10n.technologyTreeEmptyBody,
          accent: GameUiTheme.scienceAccent,
          compact: false,
        ),
      ),
    );
  }
}
