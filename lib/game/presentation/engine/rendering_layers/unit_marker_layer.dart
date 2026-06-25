import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/marker_health_fraction.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_marker_layer_animator.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_sprite.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

enum _CityUnitMarkerPlacement { none, primary, companion }

class UnitMarkerLayer extends Component with LayerAttachment {
  final MapData mapData;
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

  bool isMarkerSelectedForTesting(String unitId) =>
      _markers[unitId]?.selected ?? false;

  bool isMarkerPendingActionTargetForTesting(String unitId) =>
      _markers[unitId]?.pendingActionTargetForTesting ?? false;

  bool isMarkerAttackTargetForTesting(String unitId) =>
      _markers[unitId]?.attackTargetForTesting ?? false;

  bool markerHasFocusPulseForTesting(String unitId) =>
      _markers[unitId]?.hasFocusPulseForTesting ?? false;

  bool markerHasAttackTargetTintForTesting(String unitId) =>
      _markers[unitId]?.hasAttackTargetTintForTesting ?? false;

  bool markerReduceMotionForTesting(String unitId) =>
      _markers[unitId]?.reduceMotionForTesting ?? false;

  bool markerShowPeripheralDetailsForTesting(String unitId) =>
      _markers[unitId]?.showPeripheralDetailsForTesting ?? false;

  bool markerShowOwnerColorForTesting(String unitId) =>
      _markers[unitId]?.showOwnerColorForTesting ?? false;

  bool markerShowHealthBarForTesting(String unitId) =>
      _markers[unitId]?.showHealthBarForTesting ?? false;

  bool markerShowTypeBadgeForTesting(String unitId) =>
      _markers[unitId]?.showTypeBadgeForTesting ?? false;

  bool markerShowStateBadgeForTesting(String unitId) =>
      _markers[unitId]?.showStateBadgeForTesting ?? false;

  UnitMarkerStateBadge? markerStateBadgeForTesting(String unitId) =>
      _markers[unitId]?.stateBadgeForTesting;

  bool markerIsExhaustedForTesting(String unitId) =>
      _markers[unitId]?.exhaustedForTesting ?? false;

  UnitSpriteAction? markerActionForTesting(String unitId) =>
      _markers[unitId]?.spriteActionForTesting;

  bool markerAnimatesSpriteForTesting(String unitId) =>
      _markers[unitId]?.animatesSpriteForTesting ?? false;

  bool markerCompactWorkVisualForTesting(String unitId) =>
      _markers[unitId]?.compactWorkVisualForTesting ?? false;

  UnitSpriteSize? markerSpriteRenderSizeForTesting(String unitId) =>
      _markers[unitId]?.spriteRenderSizeForTesting;

  double? markerWorldScaleForTesting(String unitId) =>
      _markers[unitId]?.markerWorldScaleForTesting;

  double? markerSpriteScaleForTesting(String unitId) =>
      _markers[unitId]?.spriteScaleForTesting;

  bool markerAnimateIdleForTesting(String unitId) =>
      _markers[unitId]?.animateIdleForTesting ?? false;

  double? markerTacticalViewEmphasisForTesting(String unitId) =>
      _markers[unitId]?.tacticalViewEmphasisForTesting;

  String? markerWorkBadgeForTesting(String unitId) =>
      _markers[unitId]?.workBadgeLabelForTesting;

  bool markerCarriesArtifactForTesting(String unitId) =>
      _markers[unitId]?.carryingArtifactForTesting ?? false;

  double? markerHealthFractionForTesting(String unitId) =>
      _markers[unitId]?.healthFractionForTesting;

  Vector2? markerPositionForTesting(String unitId) =>
      worldPositionForUnit(unitId);

  Vector2? worldPositionForUnit(String unitId) =>
      _markers[unitId]?.position.clone();

  bool hasMarkerForTesting(String unitId) => _markers.containsKey(unitId);

  void pinPendingMovePositions(Set<String> unitIds) {
    _animator.pinPendingMovePositions(unitIds);
  }

  void retainPendingAnimationMarkers(Set<String> unitIds) {
    _animator.retainPendingAnimationMarkers(unitIds);
  }

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

  void _upsertMarker(
    Component parent,
    GameUnit unit,
    String? selectedUnitId,
    String? pendingActionUnitId,
    String? skippedTurnUnitId,
    Set<String> attackTargetUnitIds,
    Map<String, _CityUnitMarkerPlacement> cityPlacements,
    Map<String, int> artifactExcavationTurnsByUnitId,
  ) {
    final cityPlacement =
        cityPlacements[unit.id] ?? _CityUnitMarkerPlacement.none;
    final onCity = cityPlacement != _CityUnitMarkerPlacement.none;
    final healthFraction = MarkerHealthFraction.forUnit(unit);
    final position = _unitWorldPosition(unit, cityPlacement: cityPlacement);
    final selected = unit.id == selectedUnitId;
    final pendingActionTarget = unit.id == pendingActionUnitId;
    final attackTarget = attackTargetUnitIds.contains(unit.id);
    final skippedTurn = unit.id == skippedTurnUnitId;
    final exhausted = _isExhausted(unit);

    final existing = _markers[unit.id];
    if (existing == null) {
      final created = UnitMarker(
        position: position,
        colorValue: colorForPlayer(unit.ownerPlayerId),
        unitType: unit.type,
        onTap: () => onUnitTapped?.call(unit.id),
        selected: selected,
        pendingActionTarget: pendingActionTarget,
        attackTarget: attackTarget,
        healthFraction: healthFraction,
        onCity: onCity,
        fortified: unit.isFortified,
        skippedTurn: skippedTurn,
        exhausted: exhausted,
        carryingArtifact: unit.isCarryingArtifact,
        showPeripheralDetails: _showPeripheralDetails,
        showOwnerColor: _showOwnerColor,
        showHealthBar: _showHealthBar,
        showTypeBadge: _showTypeBadge,
        showStateBadge: _showStateBadge,
        markerWorldScale: _markerWorldScale,
        spriteScale: _spriteScale,
        tacticalViewEmphasis: _tacticalViewEmphasis,
        animateIdle: _animateIdle,
        reduceMotion: _reduceMotion,
      );
      _applyPriority(created, unit);
      _syncWorkState(created, unit, artifactExcavationTurnsByUnitId[unit.id]);
      _markers[unit.id] = created;
      unawaited(Future<void>.value(parent.add(created)));
    } else {
      existing
        ..position = position
        ..unitType = unit.type
        ..selected = selected
        ..pendingActionTarget = pendingActionTarget
        ..attackTarget = attackTarget
        ..healthFraction = healthFraction
        ..onCity = onCity
        ..fortified = unit.isFortified
        ..skippedTurn = skippedTurn
        ..exhausted = exhausted
        ..carryingArtifact = unit.isCarryingArtifact
        ..markerWorldScale = _markerWorldScale
        ..spriteScale = _spriteScale
        ..tacticalViewEmphasis = _tacticalViewEmphasis
        ..animateIdle = _animateIdle
        ..reduceMotion = _reduceMotion;
      _applyDetailVisibility(existing);
      _applyPriority(existing, unit);
      _syncWorkState(existing, unit, artifactExcavationTurnsByUnitId[unit.id]);
    }
  }

  void _syncMarkerWithoutMoving(
    Component parent,
    GameUnit unit,
    String? selectedUnitId,
    String? pendingActionUnitId,
    String? skippedTurnUnitId,
    Set<String> attackTargetUnitIds,
    Map<String, _CityUnitMarkerPlacement> cityPlacements,
    Map<String, int> artifactExcavationTurnsByUnitId,
  ) {
    final cityPlacement =
        cityPlacements[unit.id] ?? _CityUnitMarkerPlacement.none;
    final onCity = cityPlacement != _CityUnitMarkerPlacement.none;
    final healthFraction = MarkerHealthFraction.forUnit(unit);
    final selected = unit.id == selectedUnitId;
    final pendingActionTarget = unit.id == pendingActionUnitId;
    final attackTarget = attackTargetUnitIds.contains(unit.id);
    final skippedTurn = unit.id == skippedTurnUnitId;
    final exhausted = _isExhausted(unit);
    final existing = _markers[unit.id];
    if (existing != null) {
      existing
        ..unitType = unit.type
        ..selected = selected
        ..pendingActionTarget = pendingActionTarget
        ..attackTarget = attackTarget
        ..healthFraction = healthFraction
        ..onCity = onCity
        ..fortified = unit.isFortified
        ..skippedTurn = skippedTurn
        ..exhausted = exhausted
        ..carryingArtifact = unit.isCarryingArtifact
        ..markerWorldScale = _markerWorldScale
        ..spriteScale = _spriteScale
        ..tacticalViewEmphasis = _tacticalViewEmphasis
        ..animateIdle = _animateIdle
        ..reduceMotion = _reduceMotion;
      _applyDetailVisibility(existing);
      _applyPriority(existing, unit);
      _syncWorkState(existing, unit, artifactExcavationTurnsByUnitId[unit.id]);
      return;
    }

    final created = UnitMarker(
      position: _unitWorldPosition(unit, cityPlacement: cityPlacement),
      colorValue: colorForPlayer(unit.ownerPlayerId),
      unitType: unit.type,
      onTap: () => onUnitTapped?.call(unit.id),
      selected: selected,
      pendingActionTarget: pendingActionTarget,
      attackTarget: attackTarget,
      healthFraction: healthFraction,
      onCity: onCity,
      fortified: unit.isFortified,
      skippedTurn: skippedTurn,
      exhausted: exhausted,
      carryingArtifact: unit.isCarryingArtifact,
      showPeripheralDetails: _showPeripheralDetails,
      showOwnerColor: _showOwnerColor,
      showHealthBar: _showHealthBar,
      showTypeBadge: _showTypeBadge,
      showStateBadge: _showStateBadge,
      markerWorldScale: _markerWorldScale,
      spriteScale: _spriteScale,
      tacticalViewEmphasis: _tacticalViewEmphasis,
      animateIdle: _animateIdle,
      reduceMotion: _reduceMotion,
    );
    _applyPriority(created, unit);
    _syncWorkState(created, unit, artifactExcavationTurnsByUnitId[unit.id]);
    _markers[unit.id] = created;
    unawaited(Future<void>.value(parent.add(created)));
  }

  @override
  void onRemove() {
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
    required VoidCallback onComplete,
  }) {
    _animator.animateMove(
      unitId: unitId,
      fromCol: fromCol,
      fromRow: fromRow,
      steps: steps,
      onComplete: onComplete,
    );
  }

  void animateCombat({
    required String attackerUnitId,
    required String defenderUnitId,
    required bool attackerKilled,
    required bool defenderKilled,
    required VoidCallback onComplete,
  }) {
    _animator.animateCombat(
      attackerUnitId: attackerUnitId,
      defenderUnitId: defenderUnitId,
      attackerKilled: attackerKilled,
      defenderKilled: defenderKilled,
      onComplete: onComplete,
    );
  }

  Vector2 _worldPositionFor(int col, int row) {
    return worldPositionFor(col, row);
  }

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

  Vector2 _unitWorldPosition(
    GameUnit unit, {
    required _CityUnitMarkerPlacement cityPlacement,
  }) {
    return worldPositionFor(
      unit.col,
      unit.row,
      onCity: cityPlacement != _CityUnitMarkerPlacement.none,
      cityCompanionSide: cityPlacement == _CityUnitMarkerPlacement.companion,
    );
  }

  Map<String, _CityUnitMarkerPlacement> _cityUnitPlacements(
    List<GameUnit> units,
    Set<({int col, int row})> cityTiles,
  ) {
    if (cityTiles.isEmpty) return const {};
    final unitsByCityTile = <({int col, int row}), List<GameUnit>>{};
    for (final unit in units) {
      final tile = (col: unit.col, row: unit.row);
      if (!cityTiles.contains(tile)) continue;
      (unitsByCityTile[tile] ??= []).add(unit);
    }
    if (unitsByCityTile.isEmpty) return const {};

    final placements = <String, _CityUnitMarkerPlacement>{};
    for (final cityUnits in unitsByCityTile.values) {
      final hasCompanionMerchant =
          cityUnits.length > 1 &&
          cityUnits.any((unit) => unit.type == GameUnitType.merchant);
      for (final unit in cityUnits) {
        placements[unit.id] =
            hasCompanionMerchant && unit.type == GameUnitType.merchant
            ? _CityUnitMarkerPlacement.companion
            : _CityUnitMarkerPlacement.primary;
      }
    }
    return placements;
  }

  void _applyPriority(UnitMarker marker, GameUnit unit) {
    final priority = _priorityFor(unit);
    if (marker.priority != priority) {
      marker.priority = priority;
    }
  }

  void _syncWorkState(
    UnitMarker marker,
    GameUnit unit,
    int? artifactExcavationTurns,
  ) {
    if (unit.workerJob case final job?) {
      marker
        ..workBadgeLabel = '${job.remainingTurns}t'
        ..compactWorkVisual = true
        ..playWork();
      return;
    }
    if (unit.cityFoundingJob case final job?) {
      marker
        ..workBadgeLabel = '${job.remainingTurns}t'
        ..compactWorkVisual = true
        ..playWork();
      return;
    }
    if (unit.excavatingArtifactId != null) {
      marker
        ..workBadgeLabel = '${artifactExcavationTurns ?? 1}t'
        ..compactWorkVisual = true
        ..playWork();
      return;
    }
    if (unit.workerAssignment != null) {
      marker
        ..workBadgeLabel = '+50%'
        ..compactWorkVisual = true
        ..playWork(animate: false);
      return;
    }
    marker
      ..workBadgeLabel = null
      ..compactWorkVisual = false
      ..playIdle();
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

  int _priorityFor(GameUnit unit) => MapPriority.perTileUnit(
    mapRows: mapData.rows,
    col: unit.col,
    row: unit.row,
  );

  bool _isExhausted(GameUnit unit) => unit.movementPoints <= 0;
}
