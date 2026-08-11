import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:flame/components.dart';

typedef UnitWorldPositionResolver = Vector2? Function(String unitId);

/// Converts live unit-marker movement into the coordinate space of a hex-grid
/// child.
///
/// Map cues are rendered below [HexGrid], whose Y axis is scaled for the
/// isometric perspective. Unit markers already expose projected world
/// positions, so their vertical displacement must be normalized before it is
/// applied to a grid cue.
final class UnitAnchoredHexMotionTracker {
  UnitAnchoredHexMotionTracker({
    required UnitWorldPositionResolver unitPositionFor,
  }) : _unitPositionFor = unitPositionFor;

  final UnitWorldPositionResolver _unitPositionFor;

  String? _unitId;
  Vector2? _unitPositionOrigin;
  Vector2 _gridOffset = Vector2.zero();

  void anchorTo(String? unitId) {
    _unitId = unitId;
    _unitPositionOrigin = _trackedUnitPosition();
    _gridOffset = Vector2.zero();
  }

  Vector2 currentGridOffset() {
    final current = _trackedUnitPosition();
    if (current == null) return _gridOffset.clone();

    final origin = _unitPositionOrigin;
    if (origin == null) {
      _unitPositionOrigin = current.clone();
      return _gridOffset.clone();
    }

    _gridOffset = Vector2(
      current.x - origin.x,
      (current.y - origin.y) / HexGrid.perspectiveY,
    );
    return _gridOffset.clone();
  }

  Vector2? _trackedUnitPosition() {
    final unitId = _unitId;
    return unitId == null ? null : _unitPositionFor(unitId);
  }
}
