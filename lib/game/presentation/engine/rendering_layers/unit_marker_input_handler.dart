import 'package:flame/components.dart';
import 'package:flutter/material.dart';

abstract final class UnitMarkerInputHandler {
  static const double hitSlop = 7.0;

  static bool containsLocalPoint({
    required Vector2 point,
    required bool markerContainsPoint,
    required Rect typeIconRect,
    required Rect artifactBadgeRect,
    required bool carryingArtifact,
  }) {
    if (markerContainsPoint) return true;
    final offset = Offset(point.x, point.y);
    if (carryingArtifact &&
        artifactBadgeRect.inflate(hitSlop).contains(offset)) {
      return true;
    }
    return typeIconRect.inflate(hitSlop).contains(offset);
  }

  static void handleTap(VoidCallback? onTap) {
    onTap?.call();
  }
}
