import 'dart:async';

import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_marker.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/field_improvement_sprite_catalog.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/map/rendering/tile/hex_tile_metrics.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class FieldImprovementMarkerLayer extends Component with LayerAttachment {
  final Map<String, FieldImprovementMarker> _markers = {};

  void sync({
    required Component parent,
    required Iterable<FieldImprovement> improvements,
    required Iterable<GameCity> cities,
    ResearchState research = ResearchState.empty,
    TechnologyRuleset technologyRuleset = TechnologyRulesets.standard,
    CityHex? selectedHex,
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final visibleImprovements = improvements.toList(growable: false);
    final citiesList = cities.toList(growable: false);
    final cityById = {for (final city in citiesList) city.id: city};
    final improvementKeys = {
      for (final improvement in visibleImprovements) _keyFor(improvement),
    };

    for (final entry in _markers.entries.toList()) {
      if (improvementKeys.contains(entry.key)) continue;
      entry.value.removeFromParent();
      _markers.remove(entry.key);
    }

    for (final improvement in visibleImprovements) {
      final key = _keyFor(improvement);
      final position = worldPositionFor(
        improvement.hex.col,
        improvement.hex.row,
      );
      final eraColumn = _eraColumnForImprovement(
        improvement,
        cities: citiesList,
        cityById: cityById,
        research: research,
        technologyRuleset: technologyRuleset,
      );
      final marker = _markers[key];
      final selected = selectedHex == improvement.hex;
      if (marker == null) {
        final created = FieldImprovementMarker(
          position: position,
          type: improvement.type,
          eraColumn: eraColumn,
          selected: selected,
        )..priority = _priorityFor(improvement.hex);
        _markers[key] = created;
        unawaited(Future<void>.value(owner.add(created)));
      } else {
        marker
          ..setWorldPosition(position)
          ..type = improvement.type
          ..eraColumn = eraColumn
          ..selected = selected
          ..priority = _priorityFor(improvement.hex);
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

  static Vector2 worldPositionFor(int col, int row) {
    final hexRadius = MapConfig.defaultConfig.hexRadius;
    final tileCenter = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: hexRadius,
    );
    final topFaceCenterY =
        (tileCenter.y + HexTileMetrics.topCenterAnchorOffsetY(hexRadius)) *
        HexGrid.perspectiveY;
    return Vector2(tileCenter.x, topFaceCenterY);
  }

  int _eraColumnForImprovement(
    FieldImprovement improvement, {
    required List<GameCity> cities,
    required Map<String, GameCity> cityById,
    required ResearchState research,
    required TechnologyRuleset technologyRuleset,
  }) {
    final ownerPlayerId = _ownerPlayerIdFor(
      improvement,
      cities: cities,
      cityById: cityById,
    );
    if (ownerPlayerId == null) return 0;
    return _eraColumnForResearch(
      research.forPlayer(ownerPlayerId),
      technologyRuleset,
    );
  }

  String? _ownerPlayerIdFor(
    FieldImprovement improvement, {
    required List<GameCity> cities,
    required Map<String, GameCity> cityById,
  }) {
    final builtByCityId = improvement.builtByCityId;
    if (builtByCityId != null) {
      final builder = cityById[builtByCityId];
      if (builder != null) return builder.ownerPlayerId;
    }
    for (final city in cities) {
      if (city.controlsHex(improvement.hex)) return city.ownerPlayerId;
    }
    return null;
  }

  int _eraColumnForResearch(
    PlayerResearchState playerResearch,
    TechnologyRuleset technologyRuleset,
  ) {
    var dominantEra = TechnologyEra.foundation;
    for (final id in playerResearch.unlockedTechnologyIds) {
      final definition = technologyRuleset.technologies[id];
      if (definition == null || definition.era.index <= dominantEra.index) {
        continue;
      }
      dominantEra = definition.era;
    }
    return _eraColumnFor(dominantEra);
  }

  int _eraColumnFor(TechnologyEra era) {
    return switch (era) {
      TechnologyEra.foundation || TechnologyEra.settlement => 0,
      TechnologyEra.expansion || TechnologyEra.specialization => 1,
      TechnologyEra.industry => 2,
      TechnologyEra.strategy => 3,
    };
  }

  static int _priorityFor(CityHex hex) {
    return MapPriority.perTile(
      MapPriority.fieldImprovement,
      col: hex.col,
      row: hex.row,
    );
  }

  static String _keyFor(FieldImprovement improvement) {
    return _keyForHex(improvement.hex.col, improvement.hex.row);
  }

  static String _keyForHex(int col, int row) => '$col:$row';

  int get markerCountForTesting => _markers.length;

  FieldImprovementType? markerTypeForTesting(int col, int row) =>
      _markers[_keyForHex(col, row)]?.type;

  int? markerEraColumnForTesting(int col, int row) =>
      _markers[_keyForHex(col, row)]?.eraColumn;

  Vector2? markerPositionForTesting(int col, int row) =>
      _markers[_keyForHex(col, row)]?.position.clone();

  int? markerPriorityForTesting(int col, int row) =>
      _markers[_keyForHex(col, row)]?.priority;

  bool markerSelectedForTesting(int col, int row) =>
      _markers[_keyForHex(col, row)]?.selected ?? false;

  Color? markerRimColorForTesting(int col, int row) =>
      _markers[_keyForHex(col, row)]?.effectiveRimColor;

  Iterable<FieldImprovementType> get improvementTypesForTesting =>
      FieldImprovementSpriteCatalog.improvementTypes;
}
