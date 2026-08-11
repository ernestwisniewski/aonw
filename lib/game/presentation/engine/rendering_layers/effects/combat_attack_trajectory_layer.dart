import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/effects/combat_hex_alert_layer.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map/unit_anchored_hex_motion_tracker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

typedef CityWorldPositionResolver = Vector2? Function(String cityId);

extension CityMarkerWorldPositionResolver on CityMarkerLayer {
  Vector2? worldPositionForCity(String cityId) =>
      markerPositionForTesting(cityId);
}

/// Connects an attacking unit to its target for the target alert's lifetime.
class CombatAttackTrajectoryLayer extends Component with LayerAttachment {
  CombatAttackTrajectoryLayer({
    UnitWorldPositionResolver unitPositionFor = _missingPosition,
    CityWorldPositionResolver cityPositionFor = _missingPosition,
  }) : _unitPositionFor = unitPositionFor,
       _cityPositionFor = cityPositionFor;

  final UnitWorldPositionResolver _unitPositionFor;
  final CityWorldPositionResolver _cityPositionFor;
  final Map<String, CombatAttackTrajectoryOverlay> _trajectories = {};
  final List<String> _pendingRemovalIds = [];

  void show({
    required Component parent,
    required String attackerUnitId,
    required String targetId,
    required int fromCol,
    required int fromRow,
    required int toCol,
    required int toRow,
    bool reduceMotion = false,
  }) {
    ensureAttachedTo(parent);
    final id = trajectoryId(attackerUnitId, targetId);
    final existing = _trajectories[id];
    if (existing != null && existing.attackerUnitId == attackerUnitId) {
      existing
        ..refresh(
          fromCol: fromCol,
          fromRow: fromRow,
          toCol: toCol,
          toRow: toRow,
          reduceMotion: reduceMotion,
        )
        ..priority = _priorityFor(toCol, toRow);
      return;
    }
    existing?.removeFromParent();

    final created = CombatAttackTrajectoryOverlay(
      attackerUnitId: attackerUnitId,
      targetId: targetId,
      fromCol: fromCol,
      fromRow: fromRow,
      toCol: toCol,
      toRow: toRow,
      reduceMotion: reduceMotion,
      unitPositionFor: _unitPositionFor,
      cityPositionFor: _cityPositionFor,
    )..priority = _priorityFor(toCol, toRow);
    _trajectories[id] = created;
    unawaited(Future<void>.value(attachedOwner.add(created)));
  }

  void bindTargetAlert(String targetId) {
    _trajectories[targetId]?.bindTargetAlert();
  }

  void syncTargetAlerts({
    required bool Function(String targetId) hasTargetAlert,
  }) {
    _pendingRemovalIds.clear();
    for (final entry in _trajectories.entries) {
      final trajectory = entry.value;
      if (hasTargetAlert(trajectory.targetId)) {
        trajectory.bindTargetAlert();
        continue;
      }
      if (trajectory.isTargetAlertBound) {
        _pendingRemovalIds.add(entry.key);
      }
    }
    _removePendingTrajectories();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pendingRemovalIds.clear();
    for (final entry in _trajectories.entries) {
      final trajectory = entry.value..advance(dt);
      if (trajectory.hasTimedOut) _pendingRemovalIds.add(entry.key);
    }
    _removePendingTrajectories();
  }

  void _removePendingTrajectories() {
    for (final id in _pendingRemovalIds) {
      _trajectories.remove(id)?.removeFromParent();
    }
    _pendingRemovalIds.clear();
  }

  void clear() {
    for (final trajectory in _trajectories.values) {
      trajectory.removeFromParent();
    }
    _trajectories.clear();
    _pendingRemovalIds.clear();
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  int trajectoryCountForTesting() => _trajectories.length;

  ({Vector2 from, Vector2 to})? endpointsForTesting(
    String attackerUnitId,
    String targetId,
  ) {
    final trajectory = _trajectoryFor(attackerUnitId, targetId);
    if (trajectory == null) return null;
    return (
      from: trajectory.fromGridPositionForTesting,
      to: trajectory.toGridPositionForTesting,
    );
  }

  double? dashProgressForTesting(String attackerUnitId, String targetId) =>
      _trajectoryFor(attackerUnitId, targetId)?.dashProgressForTesting;

  int? geometryRevisionForTesting(String attackerUnitId, String targetId) =>
      _trajectoryFor(attackerUnitId, targetId)?.geometryRevisionForTesting;

  static String trajectoryId(String attackerUnitId, String targetId) =>
      targetId;

  CombatAttackTrajectoryOverlay? _trajectoryFor(
    String attackerUnitId,
    String targetId,
  ) {
    final trajectory = _trajectories[trajectoryId(attackerUnitId, targetId)];
    return trajectory?.attackerUnitId == attackerUnitId ? trajectory : null;
  }

  static int _priorityFor(int col, int row) =>
      MapPriority.perTile(MapPriority.combatIntentOverlay, col: col, row: row);

  static Vector2? _missingPosition(String _) => null;
}

bool hasCombatAttackedTargetAlert(
  CombatHexAlertLayer alertLayer,
  String targetId,
) =>
    alertLayer.hasAlertForTesting('defender:$targetId') ||
    alertLayer.hasAlertForTesting(targetId);

class CombatAttackTrajectoryOverlay extends Component {
  CombatAttackTrajectoryOverlay({
    required this.attackerUnitId,
    required this.targetId,
    required int fromCol,
    required int fromRow,
    required int toCol,
    required int toRow,
    required this.reduceMotion,
    required UnitWorldPositionResolver unitPositionFor,
    required CityWorldPositionResolver cityPositionFor,
  }) : _unitPositionFor = unitPositionFor,
       _cityPositionFor = cityPositionFor,
       _fromWorldPosition = UnitMarkerLayer.worldPositionFor(fromCol, fromRow),
       _toWorldPosition = CityMarkerLayer.worldPositionFor(toCol, toRow) {
    _syncEndpoints();
    _rebuildCurve();
    _rebuildDash();
  }

  final String attackerUnitId;
  final String targetId;
  final UnitWorldPositionResolver _unitPositionFor;
  final CityWorldPositionResolver _cityPositionFor;
  bool reduceMotion;

  final Vector2 _fromWorldPosition;
  final Vector2 _toWorldPosition;
  final Vector2 _fromGridPosition = Vector2.zero();
  final Vector2 _toGridPosition = Vector2.zero();
  final Vector2 _controlGridPosition = Vector2.zero();
  final Path _curvePath = Path();
  final Path _dashPath = Path();
  double _elapsed = 0;
  bool _targetAlertBound = false;
  int _geometryRevision = 0;

  void refresh({
    required int fromCol,
    required int fromRow,
    required int toCol,
    required int toRow,
    required bool reduceMotion,
  }) {
    final fromPosition =
        _unitPositionFor(attackerUnitId) ??
        UnitMarkerLayer.worldPositionFor(fromCol, fromRow);
    final toPosition =
        _unitPositionFor(targetId) ??
        _cityPositionFor(targetId) ??
        CityMarkerLayer.worldPositionFor(toCol, toRow);
    _fromWorldPosition.setFrom(fromPosition);
    _toWorldPosition.setFrom(toPosition);
    this.reduceMotion = reduceMotion;
    _elapsed = 0;
    _rebuildCurve();
    _rebuildDash();
  }

  void advance(double dt) {
    final geometryChanged = _syncEndpoints();
    if (geometryChanged) _rebuildCurve();
    _elapsed += dt;
    if (geometryChanged || !reduceMotion) _rebuildDash();
  }

  void bindTargetAlert() {
    _targetAlertBound = true;
  }

  bool _syncEndpoints() {
    var changed = false;
    final attackerPosition = _unitPositionFor(attackerUnitId);
    if (attackerPosition != null &&
        !_samePosition(attackerPosition, _fromWorldPosition)) {
      _fromWorldPosition.setFrom(attackerPosition);
      changed = true;
    }
    final targetPosition =
        _unitPositionFor(targetId) ?? _cityPositionFor(targetId);
    if (targetPosition != null &&
        !_samePosition(targetPosition, _toWorldPosition)) {
      _toWorldPosition.setFrom(targetPosition);
      changed = true;
    }
    return changed;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas
      ..drawPath(_curvePath, _threadPaint)
      ..drawPath(_dashPath, _dashPaint);
  }

  bool get hasTimedOut => !_targetAlertBound && _elapsed >= _bindingWindow;

  bool get isTargetAlertBound => _targetAlertBound;

  double get dashProgressForTesting {
    if (reduceMotion) return 0.72;
    return (_elapsed / _dashTravelDuration) % 1.0;
  }

  Vector2 get fromGridPositionForTesting => _fromGridPosition.clone();

  Vector2 get toGridPositionForTesting => _toGridPosition.clone();

  int get geometryRevisionForTesting => _geometryRevision;

  static const double _bindingWindow = 1.28;
  static const double _dashTravelDuration = 0.82;
  static const double _dashLength = 10.0;
  static final Paint _threadPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.65
    ..strokeCap = StrokeCap.round
    ..color = HudPalette.danger.withAlpha(238);
  static final Paint _dashPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.15
    ..strokeCap = StrokeCap.round
    ..color = HudPalette.textBright;

  void _rebuildCurve() {
    _fromGridPosition.setValues(
      _fromWorldPosition.x,
      _fromWorldPosition.y / HexGrid.perspectiveY,
    );
    _toGridPosition.setValues(
      _toWorldPosition.x,
      _toWorldPosition.y / HexGrid.perspectiveY,
    );
    final dx = _toGridPosition.x - _fromGridPosition.x;
    final dy = _toGridPosition.y - _fromGridPosition.y;
    final distance = math.sqrt(dx * dx + dy * dy);
    final bend = math.min(30.0, math.max(8.0, distance * 0.13));
    final inverseDistance = distance <= 0.001 ? 0.0 : 1 / distance;
    final perpendicularX = distance <= 0.001 ? 0.0 : -dy * inverseDistance;
    final perpendicularY = distance <= 0.001 ? -1.0 : dx * inverseDistance;
    _controlGridPosition.setValues(
      (_fromGridPosition.x + _toGridPosition.x) / 2 + perpendicularX * bend,
      (_fromGridPosition.y + _toGridPosition.y) / 2 + perpendicularY * bend,
    );
    _curvePath
      ..reset()
      ..moveTo(_fromGridPosition.x, _fromGridPosition.y)
      ..quadraticBezierTo(
        _controlGridPosition.x,
        _controlGridPosition.y,
        _toGridPosition.x,
        _toGridPosition.y,
      );
    _geometryRevision += 1;
  }

  void _rebuildDash() {
    final progress = dashProgressForTesting;
    final inverse = 1 - progress;
    final pointX =
        _fromGridPosition.x * (inverse * inverse) +
        _controlGridPosition.x * (2 * inverse * progress) +
        _toGridPosition.x * (progress * progress);
    final pointY =
        _fromGridPosition.y * (inverse * inverse) +
        _controlGridPosition.y * (2 * inverse * progress) +
        _toGridPosition.y * (progress * progress);
    final tangentX =
        (_controlGridPosition.x - _fromGridPosition.x) * (2 * inverse) +
        (_toGridPosition.x - _controlGridPosition.x) * (2 * progress);
    final tangentY =
        (_controlGridPosition.y - _fromGridPosition.y) * (2 * inverse) +
        (_toGridPosition.y - _controlGridPosition.y) * (2 * progress);
    final tangentLength = math.sqrt(tangentX * tangentX + tangentY * tangentY);
    final scale = tangentLength <= 0.001
        ? _dashLength / 2
        : _dashLength / (2 * tangentLength);
    final halfX = tangentLength <= 0.001 ? _dashLength / 2 : tangentX * scale;
    final halfY = tangentLength <= 0.001 ? 0.0 : tangentY * scale;
    _dashPath
      ..reset()
      ..moveTo(pointX - halfX, pointY - halfY)
      ..lineTo(pointX + halfX, pointY + halfY);
  }

  static bool _samePosition(Vector2 a, Vector2 b) => a.x == b.x && a.y == b.y;
}
