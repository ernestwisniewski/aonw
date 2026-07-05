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
    required bool useTreeGeometry,
  }) {
    if (cards.isEmpty) return null;
    final selectedId = selectedTechnologyIdFor(cards, selectedTechnologyId);
    final selectedIndex = cards.indexWhere((card) => card.id == selectedId);
    final currentIndex = selectedIndex < 0 ? 0 : selectedIndex;
    if (useTreeGeometry) {
      return _nextTreeCard(cards, cards[currentIndex], direction) ??
          cards[currentIndex];
    }
    final step = switch (direction) {
      GamepadMapDirection.up || GamepadMapDirection.left => -1,
      GamepadMapDirection.down || GamepadMapDirection.right => 1,
    };
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

  static TechnologyCardViewModel? _nextTreeCard(
    List<TechnologyCardViewModel> cards,
    TechnologyCardViewModel current,
    GamepadMapDirection direction,
  ) {
    final targetColumn = switch (direction) {
      GamepadMapDirection.left => _nearestColumn(cards, current.treeColumn, -1),
      GamepadMapDirection.right => _nearestColumn(cards, current.treeColumn, 1),
      GamepadMapDirection.up || GamepadMapDirection.down => current.treeColumn,
    };
    if (targetColumn == null) return null;

    final candidates = cards.where((card) {
      if (card.id == current.id) return false;
      if (card.treeColumn != targetColumn) return false;
      return switch (direction) {
        GamepadMapDirection.up => card.treeRow < current.treeRow,
        GamepadMapDirection.down => card.treeRow > current.treeRow,
        GamepadMapDirection.left || GamepadMapDirection.right => true,
      };
    });
    TechnologyCardViewModel? best;
    for (final candidate in candidates) {
      if (best == null ||
          _treeNavigationScore(candidate, current, direction) <
              _treeNavigationScore(best, current, direction)) {
        best = candidate;
      }
    }
    return best;
  }

  static int? _nearestColumn(
    List<TechnologyCardViewModel> cards,
    int currentColumn,
    int direction,
  ) {
    int? best;
    for (final card in cards) {
      final delta = card.treeColumn - currentColumn;
      if (direction < 0 && delta >= 0) continue;
      if (direction > 0 && delta <= 0) continue;
      if (best == null ||
          (card.treeColumn - currentColumn).abs() <
              (best - currentColumn).abs()) {
        best = card.treeColumn;
      }
    }
    return best;
  }

  static int _treeNavigationScore(
    TechnologyCardViewModel candidate,
    TechnologyCardViewModel current,
    GamepadMapDirection direction,
  ) {
    final rowDistance = (candidate.treeRow - current.treeRow).abs();
    final columnDistance = (candidate.treeColumn - current.treeColumn).abs();
    final forwardDistance = switch (direction) {
      GamepadMapDirection.up || GamepadMapDirection.down => rowDistance,
      GamepadMapDirection.left || GamepadMapDirection.right => columnDistance,
    };
    return rowDistance * 10000 +
        forwardDistance * 100 +
        candidate.treeRow.abs() * 10 +
        candidate.treeColumn.abs();
  }

  static double _centeredOffset(ScrollPosition position, double center) {
    return (center - position.viewportDimension / 2)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
  }
}
