import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/units/marker_health_fraction.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_marker_layer_animator.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_sprite.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

part 'unit_marker_layer_animation_lifecycle.dart';
part 'unit_marker_layer_placement.dart';
part 'unit_marker_layer_sync.dart';
part 'unit_marker_layer_testing.dart';

enum _CityUnitMarkerPlacement { none, primary, companion }

class UnitMarkerLayer extends Component with LayerAttachment {
  final WorldMap mapData;
  final int Function(String playerId) colorForPlayer;
  final void Function(String unitId)? onUnitTapped;
  final Map<String, UnitMarker> _markers = {};
  late final UnitMarkerLayerAnimator _animator;
  bool _reduceMotion;
  bool _showPeripheralDetails = true;
  bool _showOwnerColor = true;
  bool _showHealthBar = true;
  bool _showTypeBadge = true;
  bool _showStateBadge = true;
  double _markerWorldScale = 1.0;
  double _spriteScale = 1.0;
  double _tacticalViewEmphasis = 0.0;
  bool _animateIdle = true;
  Set<String> _visibleUnitIds = const {};

  Set<String> get animatingUnitIds => _animator.animatingUnitIds;

  UnitMarkerLayer({
    required this.mapData,
    required this.colorForPlayer,
    this.onUnitTapped,
    bool reduceMotion = false,
  }) : _reduceMotion = reduceMotion {
    _animator = UnitMarkerLayerAnimator(
      markerFor: (unitId) => _markers[unitId],
      worldPositionFor: _worldPositionFor,
      reduceMotion: _reduceMotion,
    );
  }

  bool get reduceMotion => _reduceMotion;

  bool get showPeripheralDetails => _showPeripheralDetails;

  set showPeripheralDetails(bool value) {
    setDetailVisibility(
      showPeripheralDetails: value,
      showOwnerColor: value,
      showHealthBar: value,
      showTypeBadge: value,
      showStateBadge: value,
    );
  }

  void setDetailVisibility({
    required bool showPeripheralDetails,
    required bool showOwnerColor,
    required bool showHealthBar,
    required bool showTypeBadge,
    required bool showStateBadge,
  }) {
    if (_showPeripheralDetails == showPeripheralDetails &&
        _showOwnerColor == showOwnerColor &&
        _showHealthBar == showHealthBar &&
        _showTypeBadge == showTypeBadge &&
        _showStateBadge == showStateBadge) {
      return;
    }
    _showPeripheralDetails = showPeripheralDetails;
    _showOwnerColor = showOwnerColor;
    _showHealthBar = showHealthBar;
    _showTypeBadge = showTypeBadge;
    _showStateBadge = showStateBadge;
    for (final marker in _markers.values) {
      _applyDetailVisibility(marker);
    }
  }

  void _applyDetailVisibility(UnitMarker marker) {
    marker
      ..showPeripheralDetails = _showPeripheralDetails
      ..showOwnerColor = _showOwnerColor
      ..showHealthBar = _showHealthBar
      ..showTypeBadge = _showTypeBadge
      ..showStateBadge = _showStateBadge;
  }

  bool get showOwnerColor => _showOwnerColor;

  bool get showHealthBar => _showHealthBar;

  bool get showTypeBadge => _showTypeBadge;

  bool get showStateBadge => _showStateBadge;

  double get markerWorldScale => _markerWorldScale;

  set markerWorldScale(double value) {
    final next = value.isFinite ? value.clamp(1.0, 3.0).toDouble() : 1.0;
    if (_markerWorldScale == next) return;
    _markerWorldScale = next;
    for (final marker in _markers.values) {
      marker.markerWorldScale = next;
    }
  }

  double get spriteScale => _spriteScale;

  set spriteScale(double value) {
    final next = value.isFinite ? value.clamp(0.5, 1.0).toDouble() : 1.0;
    if (_spriteScale == next) return;
    _spriteScale = next;
    for (final marker in _markers.values) {
      marker.spriteScale = next;
    }
  }

  bool get animateIdle => _animateIdle;

  set animateIdle(bool value) {
    if (_animateIdle == value) return;
    _animateIdle = value;
    for (final marker in _markers.values) {
      marker.animateIdle = value;
    }
  }

  double get tacticalViewEmphasis => _tacticalViewEmphasis;

  set tacticalViewEmphasis(double value) {
    final next = value.isFinite ? value.clamp(0.0, 1.0).toDouble() : 0.0;
    if (_tacticalViewEmphasis == next) return;
    _tacticalViewEmphasis = next;
    for (final marker in _markers.values) {
      marker.tacticalViewEmphasis = next;
    }
  }

  set showOwnerColor(bool value) {
    if (_showOwnerColor == value) return;
    _showOwnerColor = value;
    for (final marker in _markers.values) {
      marker.showOwnerColor = value;
    }
  }

  set showHealthBar(bool value) {
    if (_showHealthBar == value) return;
    _showHealthBar = value;
    for (final marker in _markers.values) {
      marker.showHealthBar = value;
    }
  }

  set showTypeBadge(bool value) {
    if (_showTypeBadge == value) return;
    _showTypeBadge = value;
    for (final marker in _markers.values) {
      marker.showTypeBadge = value;
    }
  }

  set showStateBadge(bool value) {
    if (_showStateBadge == value) return;
    _showStateBadge = value;
    for (final marker in _markers.values) {
      marker.showStateBadge = value;
    }
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _animator.reduceMotion = value;
    for (final marker in _markers.values) {
      marker.reduceMotion = value;
    }
  }

  Vector2? worldPositionForUnit(String unitId) =>
      _markers[unitId]?.position.clone();

  void sync({
    required Component parent,
    required Iterable<GameUnit> units,
    required String? selectedUnitId,
    PendingPlayerAction? pendingAction,
    String? pendingActionUnitId,
    Set<String> attackTargetUnitIds = const {},
    Set<({int col, int row})> cityTiles = const {},
    Map<String, int> artifactExcavationTurnsByUnitId = const {},
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final visibleUnits = units.toList(growable: false);
    final cityPlacements = _cityUnitPlacements(visibleUnits, cityTiles);
    final unitIds = visibleUnits.map((unit) => unit.id).toSet();
    _visibleUnitIds = unitIds;
    final resolvedPendingActionUnitId =
        pendingActionUnitId ??
        UnitMarkerLayer.pendingActionUnitId(pendingAction);
    final skippedTurnUnitId = pendingAction is PendingUnitTurnSkip
        ? pendingAction.unitId
        : null;
    for (final entry in _markers.entries.toList()) {
      if (unitIds.contains(entry.key)) continue;
      if (_animator.isRetained(entry.key)) continue;
      entry.value.removeFromParent();
      _markers.remove(entry.key);
    }

    for (final unit in visibleUnits) {
      if (_animator.isAnimating(unit.id)) continue;
      if (_animator.isPositionLocked(unit.id)) {
        _syncMarkerWithoutMoving(
          owner,
          unit,
          selectedUnitId,
          resolvedPendingActionUnitId,
          skippedTurnUnitId,
          attackTargetUnitIds,
          cityPlacements,
          artifactExcavationTurnsByUnitId,
        );
        continue;
      }
      _upsertMarker(
        owner,
        unit,
        selectedUnitId,
        resolvedPendingActionUnitId,
        skippedTurnUnitId,
        attackTargetUnitIds,
        cityPlacements,
        artifactExcavationTurnsByUnitId,
      );
    }
  }

  @override
  void onRemove() {
    _releaseAllAnimationLifecycleState();
    for (final marker in _markers.values) {
      marker.removeFromParent();
    }
    _markers.clear();
    super.onRemove();
  }

  void animateMove({
    required String unitId,
    int? fromCol,
    int? fromRow,
    required List<UnitMovementStep> steps,
    bool retainAtDestination = false,
    required VoidCallback onComplete,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    void completeMove() {
      if (!retainAtDestination) _removeMarkerIfNoLongerVisible(unitId);
      onComplete();
    }

    _animator.animateMove(
      unitId: unitId,
      fromCol: fromCol,
      fromRow: fromRow,
      steps: steps,
      retainAtDestination: retainAtDestination,
      onError: onError,
      onComplete: () {
        if (_reduceMotion) {
          completeMove();
        } else {
          scheduleMicrotask(completeMove);
        }
      },
    );
  }

  void animateCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    bool defenderRetaliated = true,
    required VoidCallback onComplete,
    void Function(Object error, StackTrace stackTrace)? onError,
  }) {
    _animator.animateCombat(
      attackerUnitId: attackerUnitId,
      defenderUnitId: defenderUnitId,
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
      defenderRetaliated: defenderRetaliated,
      onComplete: onComplete,
      onError: onError,
    );
  }

  void _removeMarkerIfNoLongerVisible(String unitId) {
    if (_visibleUnitIds.contains(unitId) || _animator.isRetained(unitId)) {
      return;
    }
    _markers.remove(unitId)?.removeFromParent();
  }

  Vector2 _worldPositionFor(int col, int row) => worldPositionFor(col, row);

  static Vector2 worldPositionFor(
    int col,
    int row, {
    bool onCity = false,
    bool cityCompanionSide = false,
  }) {
    final tileCenter = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultConfig.hexRadius,
    );
    final position = Vector2(
      tileCenter.x,
      tileCenter.y * HexGrid.perspectiveY - 12,
    );
    if (!onCity) return position;
    return position + (cityCompanionSide ? Vector2(-26, 26) : Vector2(26, 26));
  }

  static String? pendingActionUnitId(PendingPlayerAction? pendingAction) {
    return switch (pendingAction) {
      PendingWorkerActionSelection(:final unitId) => unitId,
      PendingMerchantTradeRouteSelection(:final unitId) => unitId,
      PendingMerchantMoveToCitySelection(:final unitId) => unitId,
      PendingUnitTurnSkip(:final unitId) => unitId,
      PendingAttackTargeting(:final attackerUnitId) => attackerUnitId,
      PendingCommanderMergeSelection(:final commanderUnitId) => commanderUnitId,
      _ => null,
    };
  }
}
