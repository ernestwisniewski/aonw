import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/domain/movement.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/map_pill.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/unit_move_preview.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';

class UnitMovePreviewLayerEntry {
  final String id;
  final UnitMovementPlan preview;
  final int travelledUpToIndex;
  final GameUnitType? unitType;
  final UnitMovePreviewRouteKind routeKind;
  final bool dimmed;
  final bool subdued;
  final bool showCostLabel;
  final bool showConfirmationHint;
  final bool showTargetPulse;
  final bool showTargetArrow;
  final bool showConfirmedTarget;

  const UnitMovePreviewLayerEntry({
    required this.id,
    required this.preview,
    this.travelledUpToIndex = 0,
    this.unitType,
    this.routeKind = UnitMovePreviewRouteKind.movement,
    this.dimmed = false,
    this.subdued = false,
    this.showCostLabel = true,
    this.showConfirmationHint = false,
    this.showTargetPulse = false,
    this.showTargetArrow = false,
    this.showConfirmedTarget = false,
  });
}

class UnitMovePreviewLayer extends Component with LayerAttachment {
  static const int routePriority = MapPriority.movePreviewRoute;
  static const int pillPriority = MapPriority.movePreviewPill;

  final Map<String, UnitMovePreview> _routes = {};
  final Map<String, MapPillComponent> _pills = {};
  final Map<String, UnitMovePreviewLayerEntry> _entries = {};
  final Map<String, String> _routeSignatures = {};
  final String Function(int turns)? turnCostLabelBuilder;
  final String Function(int turns)? confirmationLabelBuilder;
  final String? confirmationLabel;
  bool _showCostLabel = true;
  bool _dimmed = false;

  UnitMovePreviewLayer({
    this.turnCostLabelBuilder,
    this.confirmationLabelBuilder,
    this.confirmationLabel,
  });

  bool get showCostLabel => _showCostLabel;

  bool get dimmed => _dimmed;

  set showCostLabel(bool value) {
    if (_showCostLabel == value) return;
    _showCostLabel = value;
    _syncPillsForCurrentEntries();
  }

  set dimmed(bool value) {
    if (_dimmed == value) return;
    _dimmed = value;
    for (final component in _routes.values) {
      component.dimmed = value;
    }
  }

  Iterable<MapPillComponent> get pillsForTesting =>
      _pills.values.toList(growable: false);

  MapPillComponent? pillForTesting(String id) => _pills[id];

  void sync({
    required Component parent,
    required UnitMovementPlan? preview,
    int travelledUpToIndex = 0,
    GameUnitType? unitType,
    UnitMovePreviewRouteKind routeKind = UnitMovePreviewRouteKind.movement,
    bool dimmed = false,
    bool showConfirmationHint = false,
    bool showTargetPulse = false,
    bool showTargetArrow = false,
    bool showConfirmedTarget = false,
  }) {
    syncMany(
      parent: parent,
      previews: preview == null
          ? const []
          : [
              UnitMovePreviewLayerEntry(
                id: preview.unitId,
                preview: preview,
                travelledUpToIndex: travelledUpToIndex,
                unitType: unitType,
                routeKind: routeKind,
                dimmed: dimmed,
                showConfirmationHint: showConfirmationHint,
                showTargetPulse: showTargetPulse,
                showTargetArrow: showTargetArrow,
                showConfirmedTarget: showConfirmedTarget,
              ),
            ],
    );
  }

  void syncMany({
    required Component parent,
    required Iterable<UnitMovePreviewLayerEntry> previews,
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final entries = previews.toList(growable: false);
    _dimmed = entries.any((entry) => entry.dimmed);
    final liveIds = {for (final entry in entries) entry.id};
    for (final entry in _routes.entries.toList()) {
      if (liveIds.contains(entry.key)) continue;
      entry.value.removeFromParent();
      _routes.remove(entry.key);
      _routeSignatures.remove(entry.key);
    }
    for (final entry in _pills.entries.toList()) {
      if (liveIds.contains(entry.key)) continue;
      entry.value.removeFromParent();
      _pills.remove(entry.key);
    }
    for (final entry in _entries.keys.toList()) {
      if (liveIds.contains(entry)) continue;
      _entries.remove(entry);
    }
    for (final entry in entries) {
      final signature = _signatureFor(entry);
      final existing = _routes[entry.id];
      _entries[entry.id] = entry;
      if (existing != null && _routeSignatures[entry.id] == signature) {
        _applyMutableState(existing, entry);
        _syncPill(owner, entry);
        continue;
      }

      existing?.removeFromParent();
      final component = _buildComponent(entry)..priority = routePriority;
      _routes[entry.id] = component;
      _routeSignatures[entry.id] = signature;
      unawaited(Future<void>.value(owner.add(component)));
      _syncPill(owner, entry);
    }
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  UnitMovePreview _buildComponent(UnitMovePreviewLayerEntry entry) {
    final preview = entry.preview;
    return UnitMovePreview(
      points: [
        for (final coord in preview.path)
          _tileWorldCenter(coord.col, coord.row),
      ],
      cumulativeCosts: [for (final step in preview.steps) step.cumulativeCost],
      totalCost: preview.totalCost,
      availableMovementPoints: preview.availableMovementPoints,
      canMoveNow: preview.canMoveNow,
      unitType: entry.unitType,
      routeKind: entry.routeKind,
      dimmed: entry.dimmed,
      subdued: entry.subdued,
      showTargetPulse: entry.showTargetPulse,
      showTargetArrow: entry.showTargetArrow,
      showConfirmedTarget: entry.showConfirmedTarget,
      travelledUpToIndex: entry.travelledUpToIndex,
    );
  }

  void _applyMutableState(
    UnitMovePreview component,
    UnitMovePreviewLayerEntry entry,
  ) {
    component
      ..dimmed = entry.dimmed
      ..subdued = entry.subdued
      ..showTargetPulse = entry.showTargetPulse
      ..showTargetArrow = entry.showTargetArrow
      ..showConfirmedTarget = entry.showConfirmedTarget
      ..priority = routePriority;
  }

  String _signatureFor(UnitMovePreviewLayerEntry entry) {
    final preview = entry.preview;
    final buffer = StringBuffer()
      ..write(preview.totalCost)
      ..write('|')
      ..write(preview.availableMovementPoints)
      ..write('|')
      ..write(preview.canMoveNow)
      ..write('|')
      ..write(entry.travelledUpToIndex)
      ..write('|')
      ..write(entry.unitType?.name ?? '-')
      ..write('|')
      ..write(entry.routeKind.name)
      ..write('|');
    for (final coord in preview.path) {
      buffer
        ..write(coord.col)
        ..write(',')
        ..write(coord.row)
        ..write(';');
    }
    buffer.write('|');
    for (final step in preview.steps) {
      buffer
        ..write(step.cumulativeCost)
        ..write(';');
    }
    return buffer.toString();
  }

  void _syncPillsForCurrentEntries() {
    final owner = attachedOwner;
    for (final entry in _entries.values) {
      _syncPill(owner, entry);
    }
  }

  void _syncPill(Component owner, UnitMovePreviewLayerEntry entry) {
    if (!_showCostLabel || !entry.showCostLabel) {
      _clearPill(entry.id);
      return;
    }

    final label = _pillLabelFor(entry);
    final position = _tileWorldCenter(
      entry.preview.targetCol,
      entry.preview.targetRow,
    );
    final existing = _pills[entry.id];
    if (existing != null) {
      existing
        ..position = position
        ..priority = pillPriority
        ..updatePresentation(label: label, tone: _pillToneFor(entry.preview));
      return;
    }

    final component = MapPillComponent(
      label: label,
      tone: _pillToneFor(entry.preview),
      priority: pillPriority,
    )..position = position;
    _pills[entry.id] = component;
    unawaited(Future<void>.value(owner.add(component)));
  }

  void _clearPill(String id) {
    _pills.remove(id)?.removeFromParent();
  }

  String _pillLabelFor(UnitMovePreviewLayerEntry entry) {
    if (entry.showTargetArrow && entry.showConfirmationHint) {
      final turns = _estimatedTurnCost(entry);
      final localized = confirmationLabelBuilder?.call(turns);
      if (localized != null && localized.isNotEmpty) return localized;
      final confirm = confirmationLabel;
      if (confirm != null && confirm.isNotEmpty) {
        return '$confirm (${_turnCostLabel(entry)})';
      }
    }
    return _turnCostLabel(entry);
  }

  String _turnCostLabel(UnitMovePreviewLayerEntry entry) {
    final turns = _estimatedTurnCost(entry);
    final label = turnCostLabelBuilder?.call(turns);
    if (label != null && label.isNotEmpty) return label;
    return turns == 1 ? '1 turn' : '$turns turns';
  }

  int _estimatedTurnCost(UnitMovePreviewLayerEntry entry) {
    final preview = entry.preview;
    if (preview.totalCost <= 0) return 0;
    final movementPerTurn = entry.unitType == null
        ? math.max(1, preview.availableMovementPoints)
        : UnitMovementBalance.maxMovementPointsForType(entry.unitType!);
    return (preview.totalCost / movementPerTurn).ceil();
  }

  MapPillTone _pillToneFor(UnitMovementPlan preview) {
    return preview.canMoveNow ? MapPillTone.gold : MapPillTone.warning;
  }

  void clear() {
    for (final component in _routes.values) {
      component.removeFromParent();
    }
    for (final component in _pills.values) {
      component.removeFromParent();
    }
    _routes.clear();
    _pills.clear();
    _entries.clear();
    _routeSignatures.clear();
  }

  Vector2 _tileWorldCenter(int col, int row) {
    final center = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultConfig.hexRadius,
    );
    return Vector2(center.x, center.y * HexGrid.perspectiveY - 12);
  }
}
