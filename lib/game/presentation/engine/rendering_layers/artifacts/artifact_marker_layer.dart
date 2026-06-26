import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/artifacts/artifact_marker.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw_core/game/domain/artifact.dart';
import 'package:flame/components.dart';

class ArtifactMarkerLayer extends Component with LayerAttachment {
  final void Function(WorldArtifact artifact)? onArtifactTapped;
  final Map<String, ArtifactMarker> _markers = {};
  double _markerWorldScale = 1.0;

  ArtifactMarkerLayer({this.onArtifactTapped});

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
    required Iterable<WorldArtifact> artifacts,
    CityHex? selectedHex,
    Set<CityHex> occupiedHexes = const {},
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final visibleArtifacts = artifacts
        .where((artifact) => _hexFor(artifact) != null)
        .toList(growable: false);
    final artifactIds = {for (final artifact in visibleArtifacts) artifact.id};

    for (final entry in _markers.entries.toList()) {
      if (artifactIds.contains(entry.key)) continue;
      entry.value.removeFromParent();
      _markers.remove(entry.key);
    }

    for (final artifact in visibleArtifacts) {
      final hex = _hexFor(artifact)!;
      final occupied = occupiedHexes.contains(hex);
      final position = worldPositionFor(hex.col, hex.row, occupied: occupied);
      final selected = selectedHex == hex;
      final marker = _markers[artifact.id];
      if (marker == null) {
        final created = ArtifactMarker(
          position: position,
          type: artifact.type,
          onTap: () => onArtifactTapped?.call(artifact),
          selected: selected,
          markerWorldScale: _markerWorldScale,
        )..priority = _priorityFor(hex);
        _markers[artifact.id] = created;
        unawaited(Future<void>.value(owner.add(created)));
      } else {
        marker
          ..setWorldPosition(position)
          ..type = artifact.type
          ..onTap = () {
            onArtifactTapped?.call(artifact);
          }
          ..selected = selected
          ..markerWorldScale = _markerWorldScale
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
    final position = Vector2(tileCenter.x, topFaceCenterY - 7);
    return occupied ? position + Vector2(-24, -24) : position;
  }

  static CityHex? _hexFor(WorldArtifact artifact) {
    final location = artifact.location;
    return switch (location.kind) {
      WorldArtifactLocationKind.map || WorldArtifactLocationKind.excavation =>
        switch ((location.col, location.row)) {
          (final int col, final int row) => CityHex(col: col, row: row),
          _ => null,
        },
      WorldArtifactLocationKind.carried ||
      WorldArtifactLocationKind.stored => null,
    };
  }

  static int _priorityFor(CityHex hex) {
    return MapPriority.perTile(
      MapPriority.artifact,
      col: hex.col,
      row: hex.row,
    );
  }

  int get markerCountForTesting => _markers.length;

  WorldArtifactType? markerTypeForTesting(String artifactId) =>
      _markers[artifactId]?.type;

  bool markerSelectedForTesting(String artifactId) =>
      _markers[artifactId]?.selected ?? false;

  Vector2? markerPositionForTesting(String artifactId) =>
      _markers[artifactId]?.position.clone();

  int? markerPriorityForTesting(String artifactId) =>
      _markers[artifactId]?.priority;

  double? markerWorldScaleForTesting(String artifactId) =>
      _markers[artifactId]?.markerWorldScale;
}
