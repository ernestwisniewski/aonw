import 'dart:async';
import 'dart:math' as math;

import 'package:aonw/game/presentation/engine/rendering_layers/map/map_pill.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/units/unit_move_preview.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/movement.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/map/domain/map_config.dart';
import 'package:flame/components.dart';

class UnitMovePreviewLayerEntry {
  final String id;
  final UnitMovementPlan preview;
  final List<UnitMovementStep>? displaySteps;
  final int travelledUpToIndex;
  final Set<int> roadSegmentIndices;
  final GameUnitType? unitType;
  final int? maxMovementPointsPerTurn;
  final bool dimmed;
  final bool subdued;
  final bool showCostLabel;
  final bool showTargetOutline;

  UnitMovePreviewLayerEntry({
    required this.id,
    required this.preview,
    this.displaySteps,
    this.travelledUpToIndex = 0,
    this.roadSegmentIndices = const {},
    this.unitType,
    this.maxMovementPointsPerTurn,
    this.dimmed = false,
    this.subdued = false,
    this.showCostLabel = true,
    this.showTargetOutline = false,
  }) : assert(
         displaySteps == null ||
             (travelledUpToIndex >= 0 &&
                 travelledUpToIndex < displaySteps.length &&
                 preview.steps.isNotEmpty &&
                 displaySteps[travelledUpToIndex].col ==
                     preview.steps.first.col &&
                 displaySteps[travelledUpToIndex].row ==
                     preview.steps.first.row),
         'displaySteps must join the remaining preview at travelledUpToIndex',
       );
}

class UnitMovePreviewLayer extends Component with LayerAttachment {
  static const int routePriority = MapPriority.movePreviewRoute;
  static const int pillPriority = MapPriority.movePreviewPill;

  final Map<String, UnitMovePreview> _routes = {};
  final Map<String, MapPillComponent> _pills = {};
  final Map<String, UnitMovePreviewLayerEntry> _entries = {};
  final Map<String, String> _routeSignatures = {};
  final String Function(int turns)? turnCostLabelBuilder;
  bool _showCostLabel = true;
  bool _dimmed = false;

  UnitMovePreviewLayer({this.turnCostLabelBuilder});

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
    bool dimmed = false,
    bool showTargetOutline = false,
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
                dimmed: dimmed,
                showTargetOutline: showTargetOutline,
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
    final displaySteps = entry.displaySteps ?? preview.steps;
    return UnitMovePreview(
      points: [
        for (final step in displaySteps) _tileWorldCenter(step.col, step.row),
      ],
      reachablePoints: [
        for (var index = 0; index < displaySteps.length; index++)
          _isDisplayStepReachable(entry, index),
      ],
      turnBoundaryPointIndices: _turnBoundaryPointIndices(entry),
      roadSegmentIndices: entry.roadSegmentIndices,
      unitType: entry.unitType,
      dimmed: entry.dimmed,
      subdued: entry.subdued,
      showTargetOutline: entry.showTargetOutline,
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
      ..showTargetOutline = entry.showTargetOutline
      ..priority = routePriority;
  }

  String _signatureFor(UnitMovePreviewLayerEntry entry) {
    final displaySteps = entry.displaySteps ?? entry.preview.steps;
    final buffer = StringBuffer()
      ..write(entry.travelledUpToIndex)
      ..write('|')
      ..write(entry.unitType?.name ?? '-')
      ..write('|')
      ..writeAll(_turnBoundaryPointIndices(entry), ',')
      ..write('|')
      ..writeAll(entry.roadSegmentIndices.toList()..sort(), ',')
      ..write('|');
    for (var index = 0; index < displaySteps.length; index++) {
      final step = displaySteps[index];
      buffer
        ..write(step.col)
        ..write(',')
        ..write(step.row)
        ..write(':')
        ..write(_isDisplayStepReachable(entry, index))
        ..write(';');
    }
    return buffer.toString();
  }

  bool _isDisplayStepReachable(
    UnitMovePreviewLayerEntry entry,
    int displayIndex,
  ) {
    if (entry.displaySteps == null) {
      return entry.preview.canReachStepThisTurn(
        entry.preview.steps[displayIndex],
      );
    }
    final previewIndex = displayIndex - entry.travelledUpToIndex;
    if (previewIndex < 0) return true;
    if (previewIndex >= entry.preview.steps.length) return false;
    return entry.preview.canReachStepThisTurn(
      entry.preview.steps[previewIndex],
    );
  }

  List<int> _turnBoundaryPointIndices(UnitMovePreviewLayerEntry entry) {
    final preview = entry.preview;
    if (preview.steps.length < 3) return const [];

    final displayOffset = entry.displaySteps == null
        ? 0
        : entry.travelledUpToIndex;
    final lastDisplayIndex =
        (entry.displaySteps?.length ?? preview.steps.length) - 1;
    final fullTurnMovement = _movementUnitsPerTurn(entry);
    var remainingMovement = preview.availableMovementUnits;
    final boundaries = <int>[];

    for (
      var previewIndex = 1;
      previewIndex < preview.steps.length;
      previewIndex++
    ) {
      final step = preview.steps[previewIndex];
      if (remainingMovement <= 0) {
        final displayIndex = displayOffset + previewIndex - 1;
        if (displayIndex > 0 && displayIndex < lastDisplayIndex) {
          boundaries.add(displayIndex);
        }
        remainingMovement = step.enterCost >= fullTurnMovement
            ? 0
            : fullTurnMovement - step.enterCost;
      } else if (step.enterCost <= remainingMovement) {
        remainingMovement -= step.enterCost;
      } else {
        remainingMovement = 0;
      }
    }
    return boundaries;
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
    return preview.estimatedTurns(_movementUnitsPerTurn(entry));
  }

  int _movementUnitsPerTurn(UnitMovePreviewLayerEntry entry) {
    return entry.maxMovementPointsPerTurn ??
        (entry.unitType == null
            ? math.max(1, entry.preview.availableMovementUnits)
            : UnitMovementBalance.maxMovementUnitsForType(entry.unitType!));
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
    return HexGeometry.projectedTopFaceCenter(
      col: col,
      row: row,
      perspectiveY: HexGrid.perspectiveY,
      hexRadius: MapConfig.defaultConfig.hexRadius,
    );
  }
}
