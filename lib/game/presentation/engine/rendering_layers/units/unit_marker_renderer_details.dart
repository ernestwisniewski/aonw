part of 'unit_marker_renderer.dart';

void _drawUnitDetails(
  Canvas canvas,
  UnitMarkerRenderModel model, {
  required Offset center,
  required double statusTop,
  required double statusWidth,
}) {
  _drawStatusBars(
    canvas,
    model,
    center: center,
    top: statusTop,
    width: statusWidth,
  );
  _drawWorkBadge(canvas, model, center: center, top: statusTop);
  _drawStateBadge(canvas, model, center: center);
  _drawArtifactBadge(canvas, model, center: center);
}

void _drawStatusBars(
  Canvas canvas,
  UnitMarkerRenderModel model, {
  required Offset center,
  required double top,
  required double width,
}) {
  if (!model.paintsIdentityBadge && !model.paintsHealthBar) return;

  if (model.paintsTypeBadge) {
    MarkerHealthBar.paintTypeIconBadge(
      canvas,
      center: center,
      top: top,
      width: width,
      icon: model.typeIcon,
      backgroundColor: model.playerColor,
      active: model.selected || model.attackTarget,
      activePulse: model.typeIconPulse,
      activeColor: model.attackTarget ? HudPalette.danger : null,
    );
  } else if (model.paintsOwnerColor) {
    MarkerHealthBar.paintOwnerIndicator(
      canvas,
      center: center,
      top: top,
      width: width,
      color: model.playerColor,
    );
  }
  if (!model.paintsHealthBar) return;
  MarkerHealthBar.paint(
    canvas,
    center: center,
    top: top,
    width: width,
    fraction: model.healthFraction,
  );
}

void _drawStateBadge(
  Canvas canvas,
  UnitMarkerRenderModel model, {
  required Offset center,
}) {
  final badge = model.stateBadge;
  if (badge == null || !model.paintsStateBadge) return;

  UnitMarkerBadgePainter.paintStateBadge(
    canvas,
    center: center,
    badge: badge,
    onCity: model.onCity,
  );
}

void _drawArtifactBadge(
  Canvas canvas,
  UnitMarkerRenderModel model, {
  required Offset center,
}) {
  if (!model.carryingArtifact) return;

  UnitMarkerBadgePainter.paintArtifactBadge(
    canvas,
    center: center,
    onCity: model.onCity,
  );
}

void _drawWorkBadge(
  Canvas canvas,
  UnitMarkerRenderModel model, {
  required Offset center,
  required double top,
}) {
  final label = model.workBadgeLabel;
  if (label == null || label.isEmpty) return;

  UnitMarkerBadgePainter.paintWorkBadge(
    canvas,
    center: center,
    top: top,
    playerColor: model.playerColor,
    label: label,
    statusBarsExtentAboveTop: _statusBarsExtentAboveTop,
    gapAboveBars: _workBadgeGapAboveBars,
  );
}
