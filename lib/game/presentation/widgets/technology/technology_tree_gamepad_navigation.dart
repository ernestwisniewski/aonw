import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/game/presentation/widgets/technology/technology_tree_board.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/widgets.dart';

abstract final class TechnologyTreeGamepadNavigation {
  static List<TechnologyCardViewModel> cardsFor({
    required TechnologyPanelViewModel viewModel,
    required bool showTree,
  }) {
    if (!showTree) return viewModel.recommendedTechnologies;
    return [...viewModel.technologies]..sort(_compareCards);
  }

  static TechnologyId? selectedTechnologyIdFor(
    List<TechnologyCardViewModel> cards,
    TechnologyId? selectedTechnologyId,
  ) {
    if (selectedTechnologyId != null &&
        cards.any((card) => card.id == selectedTechnologyId)) {
      return selectedTechnologyId;
    }
    for (final card in cards) {
      if (card.canSelect) return card.id;
    }
    return cards.isEmpty ? null : cards.first.id;
  }

  static TechnologyCardViewModel? selectedCard(
    List<TechnologyCardViewModel> cards,
    TechnologyId? selectedTechnologyId,
  ) {
    final selectedId = selectedTechnologyIdFor(cards, selectedTechnologyId);
    if (selectedId == null) return null;
    for (final card in cards) {
      if (card.id == selectedId) return card;
    }
    return null;
  }

  static TechnologyCardViewModel? nextCard({
    required List<TechnologyCardViewModel> cards,
    required TechnologyId? selectedTechnologyId,
    required GamepadMapDirection direction,
  }) {
    if (cards.isEmpty) return null;
    final step = switch (direction) {
      GamepadMapDirection.up || GamepadMapDirection.left => -1,
      GamepadMapDirection.down || GamepadMapDirection.right => 1,
    };
    final selectedId = selectedTechnologyIdFor(cards, selectedTechnologyId);
    final selectedIndex = cards.indexWhere((card) => card.id == selectedId);
    final currentIndex = selectedIndex < 0 ? 0 : selectedIndex;
    final nextIndex = (currentIndex + step) % cards.length;
    return cards[nextIndex];
  }

  static void revealTreeCard({
    required bool Function() isMounted,
    required List<TechnologyCardViewModel> cards,
    required TechnologyCardViewModel card,
    required bool compact,
    required ScrollController verticalController,
    required ScrollController horizontalController,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!isMounted() ||
          !verticalController.hasClients ||
          !horizontalController.hasClients) {
        return;
      }
      final metrics = TechnologyTreeBoardMetrics.fromCards(
        cards,
        compact: compact,
      );
      final rect = metrics.rects[card.id];
      if (rect == null) return;
      unawaited(
        horizontalController.animateTo(
          _centeredOffset(horizontalController.position, rect.center.dx),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        ),
      );
      unawaited(
        verticalController.animateTo(
          _centeredOffset(verticalController.position, rect.center.dy),
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
        ),
      );
    });
  }

  static int _compareCards(
    TechnologyCardViewModel a,
    TechnologyCardViewModel b,
  ) {
    final column = a.treeColumn.compareTo(b.treeColumn);
    if (column != 0) return column;
    return a.treeRow.compareTo(b.treeRow);
  }

  static double _centeredOffset(ScrollPosition position, double center) {
    return (center - position.viewportDimension / 2)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
  }
}
