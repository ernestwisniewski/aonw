import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_objective_marker.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw_core/game/domain/objective.dart';
import 'package:flame/components.dart';

class MapObjectiveMarkerLayer extends Component with LayerAttachment {
  final int Function(String playerId) colorForPlayer;
  final void Function(MapObjectiveProgress progress)? onObjectiveTapped;
  final Map<String, MapObjectiveMarker> _markers = {};
  double _markerWorldScale = 1.0;

  MapObjectiveMarkerLayer({
    required this.colorForPlayer,
    this.onObjectiveTapped,
  });

  double get markerWorldScale => _markerWorldScale;

  set markerWorldScale(double value) {
    final next = value.isFinite ? value.clamp(1.0, 2.4).toDouble() : 1.0;
    if (_markerWorldScale == next) return;
    _markerWorldScale = next;
    for (final marker in _markers.values) {
      marker.markerWorldScale = next;
    }
  }

  void sync({
    required Component parent,
    required Iterable<MapObjectiveProgress> objectives,
    Set<CityHex> occupiedHexes = const {},
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final visibleObjectives = objectives.toList(growable: false);
    final objectiveIds = {
      for (final objective in visibleObjectives) objective.definition.id,
    };

    for (final entry in _markers.entries.toList()) {
      if (objectiveIds.contains(entry.key)) continue;
      entry.value.removeFromParent();
      _markers.remove(entry.key);
    }

    for (final objective in visibleObjectives) {
      final definition = objective.definition;
      final hex = definition.hex;
      final controller = objective.controllingPlayerId;
      final position = worldPositionFor(
        hex.col,
        hex.row,
        occupied: occupiedHexes.contains(hex),
      );
      final marker = _markers[definition.id];
      if (marker == null) {
        final created = MapObjectiveMarker(
          position: position,
          type: definition.type,
          controllingPlayerId: controller,
          controlColorValue: _colorFor(controller),
          contested: objective.contested,
          completed: objective.completed,
          holdTurns: objective.holdTurns,
          requiredHoldTurns: definition.requiredHoldTurns,
          markerWorldScale: _markerWorldScale,
          onTap: () => onObjectiveTapped?.call(objective),
        )..priority = _priorityFor(hex);
        _markers[definition.id] = created;
        unawaited(Future<void>.value(owner.add(created)));
      } else {
        marker
          ..setWorldPosition(position)
          ..type = definition.type
          ..controllingPlayerId = controller
          ..controlColorValue = _colorFor(controller)
          ..contested = objective.contested
          ..completed = objective.completed
          ..holdTurns = objective.holdTurns
          ..requiredHoldTurns = definition.requiredHoldTurns
          ..markerWorldScale = _markerWorldScale
          ..onTap = () {
            onObjectiveTapped?.call(objective);
          }
          ..priority = _priorityFor(hex);
      }
    }
  }

  @override
  void onRemove() {
    for (final marker in _markers.values) {
      marker.removeFromParent();
    }
    _markers.clear();
    super.onRemove();
  }

  int? _colorFor(String? playerId) {
    if (playerId == null) return null;
    return colorForPlayer(playerId);
  }

  static Vector2 worldPositionFor(int col, int row, {bool occupied = false}) {
    final hexRadius = MapConfig.defaultConfig.hexRadius;
    final tileCenter = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: hexRadius,
    );
    final topFaceCenterY =
        (tileCenter.y + HexTileMetrics.topCenterAnchorOffsetY(hexRadius)) *
        HexGrid.perspectiveY;
    final position = Vector2(tileCenter.x, topFaceCenterY - 31);
    return occupied ? position + Vector2(22, -18) : position;
  }

  static int _priorityFor(CityHex hex) {
    return MapPriority.perTile(
      MapPriority.mapObjective,
      col: hex.col,
      row: hex.row,
    );
  }

  int get markerCountForTesting => _markers.length;

  MapObjectiveType? markerTypeForTesting(String objectiveId) =>
      _markers[objectiveId]?.type;

  String? markerControllingPlayerForTesting(String objectiveId) =>
      _markers[objectiveId]?.controllingPlayerId;

  bool markerContestedForTesting(String objectiveId) =>
      _markers[objectiveId]?.contested ?? false;

  bool markerCompletedForTesting(String objectiveId) =>
      _markers[objectiveId]?.completed ?? false;

  int? markerHoldTurnsForTesting(String objectiveId) =>
      _markers[objectiveId]?.holdTurns;

  Vector2? markerPositionForTesting(String objectiveId) =>
      _markers[objectiveId]?.position.clone();

  int? markerPriorityForTesting(String objectiveId) =>
      _markers[objectiveId]?.priority;

  double? markerWorldScaleForTesting(String objectiveId) =>
      _markers[objectiveId]?.markerWorldScale;
}
