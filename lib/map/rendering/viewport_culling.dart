import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// Rejects positioned children whose bounds cannot affect the current camera
/// clip. The margin keeps labels, shadows, and short movement effects alive
/// just outside the viewport while avoiding full render-tree traversal for the
/// rest of the map.
mixin ViewportCullingParent on Component {
  static const double defaultCullMargin = 96.0;

  @override
  void renderChild(Canvas canvas, Component child) {
    if (_isOutsideViewport(canvas, child)) return;
    super.renderChild(canvas, child);
  }

  bool _isOutsideViewport(Canvas canvas, Component child) {
    if (child is! PositionComponent || child.size.x <= 0 || child.size.y <= 0) {
      return false;
    }
    final visibleBounds = canvas.getLocalClipBounds();
    if (visibleBounds.isEmpty) return true;
    return !visibleBounds.overlaps(child.toRect().inflate(defaultCullMargin));
  }
}

/// World root used by map games so direct marker components are culled before
/// Flame enters their render trees. Tap targets are additionally bucketed so
/// Flame gesture dispatch does not linearly scan every marker on pointer down.
class ViewportCullingWorld extends World with ViewportCullingParent {
  static const double _hitBucketSize = 192.0;
  static const double _hitBoundsMargin = 96.0;

  final Map<(int, int), List<PositionComponent>> _tapTargetsByBucket = {};
  final List<Component> _eventBranches = [];
  bool _spatialHitIndexDirty = true;
  int _indexedChildCount = -1;

  void invalidateSpatialHitTestIndex() {
    _spatialHitIndexDirty = true;
  }

  void refreshSpatialHitTestIndex() {
    _tapTargetsByBucket.clear();
    _eventBranches.clear();
    for (final child in children) {
      if (child is PositionComponent && child is TapCallbacks) {
        _indexTapTarget(child);
      } else if (child.children.isNotEmpty) {
        _eventBranches.add(child);
      }
    }
    _indexedChildCount = children.length;
    _spatialHitIndexDirty = false;
  }

  void refreshSpatialHitTestIndexIfNeeded() {
    if (_spatialHitIndexDirty || _indexedChildCount != children.length) {
      refreshSpatialHitTestIndex();
    }
  }

  void _indexTapTarget(PositionComponent component) {
    final bounds = component.toRect().inflate(_hitBoundsMargin);
    final minCol = (bounds.left / _hitBucketSize).floor();
    final maxCol = (bounds.right / _hitBucketSize).floor();
    final minRow = (bounds.top / _hitBucketSize).floor();
    final maxRow = (bounds.bottom / _hitBucketSize).floor();
    for (var col = minCol; col <= maxCol; col++) {
      for (var row = minRow; row <= maxRow; row++) {
        (_tapTargetsByBucket[(col, row)] ??= []).add(component);
      }
    }
  }

  @override
  Iterable<Component> componentsAtLocation<T>(
    T locationContext,
    List<T>? nestedContexts,
    T? Function(CoordinateTransform transform, T context) transformContext,
    bool Function(Component component, T context) checkContains,
  ) sync* {
    if (locationContext is! Vector2) {
      yield* super.componentsAtLocation(
        locationContext,
        nestedContexts,
        transformContext,
        checkContains,
      );
      return;
    }

    refreshSpatialHitTestIndexIfNeeded();
    nestedContexts?.add(locationContext);
    final bucketKey = (
      (locationContext.x / _hitBucketSize).floor(),
      (locationContext.y / _hitBucketSize).floor(),
    );
    final bucket =
        _tapTargetsByBucket[bucketKey] ?? const <PositionComponent>[];
    for (final child in bucket.reversed) {
      yield* _componentsAtChild(
        child,
        locationContext as T,
        nestedContexts,
        transformContext,
        checkContains,
      );
    }
    for (final child in _eventBranches.reversed) {
      yield* _componentsAtChild(
        child,
        locationContext as T,
        nestedContexts,
        transformContext,
        checkContains,
      );
    }
    if (checkContains(this, locationContext)) yield this;
    nestedContexts?.removeLast();
  }

  Iterable<Component> _componentsAtChild<T>(
    Component child,
    T locationContext,
    List<T>? nestedContexts,
    T? Function(CoordinateTransform transform, T context) transformContext,
    bool Function(Component component, T context) checkContains,
  ) sync* {
    T? childContext = locationContext;
    if (child is CoordinateTransform) {
      childContext = transformContext(
        child as CoordinateTransform,
        locationContext,
      );
    }
    if (childContext == null) return;
    yield* child.componentsAtLocation(
      childContext,
      nestedContexts,
      transformContext,
      checkContains,
    );
  }
}
