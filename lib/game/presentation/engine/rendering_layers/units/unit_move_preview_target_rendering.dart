part of 'unit_move_preview.dart';

extension _UnitMovePreviewTargetRendering on UnitMovePreview {
  void _drawTargetHexOutline(Canvas canvas) {
    final path = _targetHexPath();
    _drawDashedPath(
      canvas,
      path,
      _style.confirmedTargetGlowPaint,
      phase: 0,
      patternSeed: points.length,
    );
    _drawDashedPath(
      canvas,
      path,
      _style.confirmedTargetLinePaint,
      phase: 0,
      patternSeed: points.length,
    );
  }

  Path _targetHexPath() {
    final center = points.last.toOffset();
    final radius = MapConfig.defaultConfig.hexRadius * 0.86;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * HexGrid.perspectiveY * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }
}
