part of 'unit_marker_layer.dart';

final Expando<VoidCallback> _animationLifecycleOwners = Expando<VoidCallback>(
  'UnitMarkerLayer animation lifecycle owner',
);

extension UnitMarkerLayerAnimationLifecycle on UnitMarkerLayer {
  void bindAnimationLifecycleOwner(VoidCallback onRemoved) {
    if (_animationLifecycleOwners[this] != null) {
      throw StateError('UnitMarkerLayer already has an animation owner');
    }
    _animationLifecycleOwners[this] = onRemoved;
  }

  void clearAnimationLifecycleOwner() {
    _animationLifecycleOwners[this] = null;
  }

  void _releaseAllAnimationLifecycleState() {
    final onRemoved = _animationLifecycleOwners[this];
    _animationLifecycleOwners[this] = null;
    onRemoved?.call();
    _animator.releaseAllAnimationState();
  }

  void pinPendingMovePositions(Set<String> unitIds) {
    _animator.pinPendingMovePositions(unitIds);
  }

  void preparePendingMoveOrigin(
    String unitId, {
    required int col,
    required int row,
  }) {
    _animator.preparePendingMoveOrigin(unitId, col: col, row: row);
  }

  void retainPendingAnimationMarkers(Set<String> unitIds) {
    _animator.retainPendingAnimationMarkers(unitIds);
  }

  void retainPendingMoveMarkers(Set<String> unitIds) {
    _animator.retainPendingMoveMarkers(unitIds);
  }

  void releasePendingAnimationState(Set<String> unitIds) {
    _animator.releaseAnimationState(unitIds);
  }

  void releaseAllAnimationState() {
    _animator.releaseAllAnimationState();
  }
}
