import 'dart:math' as math;

import 'package:aonw/game/presentation/widgets/bottom_toolbar/view_models.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flutter/material.dart';

class TechnologyPathSelection {
  final TechnologyId? targetId;
  final Set<TechnologyId> ids;
  final Set<({TechnologyId parent, TechnologyId child})> edges;

  const TechnologyPathSelection({
    required this.targetId,
    required this.ids,
    required this.edges,
  });

  static const empty = TechnologyPathSelection(
    targetId: null,
    ids: {},
    edges: {},
  );

  factory TechnologyPathSelection.from(
    List<TechnologyCardViewModel> cards, {
    required TechnologyId? targetId,
  }) {
    if (targetId == null) return empty;
    final byId = {for (final card in cards) card.id: card};
    if (!byId.containsKey(targetId)) return empty;

    final ids = <TechnologyId>{};
    final edges = <({TechnologyId parent, TechnologyId child})>{};
    final visited = <TechnologyId>{};

    void visit(TechnologyId technologyId) {
      if (!visited.add(technologyId)) return;
      final card = byId[technologyId];
      if (card == null) return;
      ids.add(technologyId);
      for (final prerequisiteId in card.prerequisiteIds) {
        if (!byId.containsKey(prerequisiteId)) continue;
        edges.add((parent: prerequisiteId, child: technologyId));
        visit(prerequisiteId);
      }
    }

    visit(targetId);
    return TechnologyPathSelection(targetId: targetId, ids: ids, edges: edges);
  }
}

class TechnologyTreePainter extends CustomPainter {
  final List<TechnologyCardViewModel> cards;
  final Map<TechnologyId, Rect> rects;
  final TechnologyPathSelection selectedPath;
  final Animation<double> pathAnimation;

  TechnologyTreePainter({
    required this.cards,
    required this.rects,
    required this.selectedPath,
    required this.pathAnimation,
  }) : super(repaint: pathAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final byId = {for (final card in cards) card.id: card};
    final selectedConnectors = <Path>[];

    for (final card in cards) {
      final childRect = rects[card.id];
      if (childRect == null) continue;
      for (final prerequisiteId in card.prerequisiteIds) {
        final parentRect = rects[prerequisiteId];
        final parentCard = byId[prerequisiteId];
        if (parentRect == null || parentCard == null) continue;

        final path = _connectorPath(
          parentCard,
          card,
          parentRect,
          childRect,
          size,
        );
        final paint = Paint()
          ..color = _lineColor(parentCard, card)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, paint);
        if (selectedPath.edges.contains((
          parent: prerequisiteId,
          child: card.id,
        ))) {
          selectedConnectors.add(path);
        }
      }
    }

    if (selectedConnectors.isEmpty) return;

    final glowPaint = Paint()
      ..color = SurfaceElevation.flat.fill(
        background: GameUiTheme.scienceAccent,
        alpha: 102,
      )
      ..strokeWidth = 5.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final dashPaint = Paint()
      ..color = GameUiTheme.scienceAccent
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (final path in selectedConnectors) {
      _drawDashedPath(canvas, path, glowPaint, pathAnimation.value);
      _drawDashedPath(canvas, path, dashPaint, pathAnimation.value);
    }
  }

  Path _connectorPath(
    TechnologyCardViewModel parent,
    TechnologyCardViewModel child,
    Rect parentRect,
    Rect childRect,
    Size size,
  ) {
    final points = _connectorPoints(parent, child, parentRect, childRect, size);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    return path;
  }

  static List<Offset> _connectorPoints(
    TechnologyCardViewModel parent,
    TechnologyCardViewModel child,
    Rect parentRect,
    Rect childRect,
    Size size,
  ) {
    final start = Offset(parentRect.right, parentRect.center.dy);
    final end = Offset(childRect.left, childRect.center.dy);
    final skippedColumns = child.treeColumn - parent.treeColumn > 1;
    if (skippedColumns) {
      final hDistance = end.dx - start.dx;
      final xInset = math.min(18.0, math.max(10.0, hDistance / 5));
      final exitParent = Offset(start.dx + xInset, start.dy);
      final enterChild = Offset(end.dx - xInset, end.dy);
      final detourY = _skipColumnDetourY(parentRect, childRect, size);
      return [
        start,
        exitParent,
        Offset(exitParent.dx, detourY),
        Offset(enterChild.dx, detourY),
        enterChild,
        end,
      ];
    }

    final midX = start.dx + (end.dx - start.dx) / 2;
    return [start, Offset(midX, start.dy), Offset(midX, end.dy), end];
  }

  static double _skipColumnDetourY(Rect parentRect, Rect childRect, Size size) {
    const laneInset = 9.0;
    final sameRow = (parentRect.center.dy - childRect.center.dy).abs() < 0.001;
    if (sameRow) {
      final below = math.max(parentRect.bottom, childRect.bottom) + laneInset;
      if (below < size.height - laneInset) return below;
      return math.min(parentRect.top, childRect.top) - laneInset;
    }

    final parentIsUpper = parentRect.center.dy < childRect.center.dy;
    final upper = parentIsUpper ? parentRect : childRect;
    final lower = parentIsUpper ? childRect : parentRect;
    final betweenRows = (upper.bottom + lower.top) / 2;
    if (betweenRows > upper.bottom && betweenRows < lower.top) {
      return betweenRows;
    }

    final below = math.max(parentRect.bottom, childRect.bottom) + laneInset;
    if (below < size.height - laneInset) return below;
    return math.min(parentRect.top, childRect.top) - laneInset;
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double animationValue,
  ) {
    const dashLength = 12.0;
    const gapLength = 8.0;
    const patternLength = dashLength + gapLength;
    final animatedOffset = animationValue * patternLength;

    for (final metric in path.computeMetrics()) {
      var distance = -animatedOffset;
      while (distance < metric.length) {
        final start = math.max(0.0, distance);
        final end = math.min(metric.length, distance + dashLength);
        if (end > 0 && start < metric.length && end > start) {
          canvas.drawPath(metric.extractPath(start, end), paint);
        }
        distance += patternLength;
      }
    }
  }

  Color _lineColor(
    TechnologyCardViewModel parent,
    TechnologyCardViewModel child,
  ) {
    if (parent.state == TechnologyCardState.researched ||
        child.state == TechnologyCardState.active) {
      return SurfaceElevation.flat.strokeColor(
        color: GameUiTheme.gold,
        alpha: 150,
      );
    }
    return SurfaceElevation.flat.strokeColor(
      color: GameUiTheme.border,
      alpha: 58,
    );
  }

  @override
  bool shouldRepaint(TechnologyTreePainter oldDelegate) {
    return oldDelegate.cards != cards ||
        oldDelegate.rects != rects ||
        oldDelegate.selectedPath.targetId != selectedPath.targetId ||
        oldDelegate.selectedPath.edges != selectedPath.edges ||
        oldDelegate.pathAnimation != pathAnimation;
  }
}

@visibleForTesting
TechnologyId? technologyTreeSelectedPathTargetForTesting(
  CustomPainter? painter,
) {
  if (painter is TechnologyTreePainter) {
    return painter.selectedPath.targetId;
  }
  return null;
}

@visibleForTesting
Set<({TechnologyId parent, TechnologyId child})>
technologyTreeSelectedPathEdgesForTesting(CustomPainter? painter) {
  if (painter is TechnologyTreePainter) {
    return Set.unmodifiable(painter.selectedPath.edges);
  }
  return const {};
}

@visibleForTesting
List<Offset> technologyTreeConnectorPointsForTesting({
  required TechnologyCardViewModel parent,
  required TechnologyCardViewModel child,
  required Rect parentRect,
  required Rect childRect,
  required Size size,
}) {
  return TechnologyTreePainter._connectorPoints(
    parent,
    child,
    parentRect,
    childRect,
    size,
  );
}
