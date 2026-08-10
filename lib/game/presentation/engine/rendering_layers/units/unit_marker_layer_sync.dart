part of 'unit_marker_layer.dart';

extension _UnitMarkerLayerSync on UnitMarkerLayer {
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
}
