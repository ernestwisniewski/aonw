import 'dart:async';
import 'dart:ui';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_territory_overlay.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:flame/components.dart';

class CityTerritoryOverlayLayer extends Component with LayerAttachment {
  final int Function(String playerId) colorForPlayer;
  CityTerritoryOverlay? _component;
  double _zoomEmphasis = 0;

  CityTerritoryOverlayLayer({required this.colorForPlayer}) {
    priority = MapPriority.territory;
  }

  set zoomEmphasis(double value) {
    final next = value.clamp(0.0, 1.0).toDouble();
    if (_zoomEmphasis == next) return;
    _zoomEmphasis = next;
    _component?.zoomEmphasis = next;
  }

  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    bool Function(CityHex hex)? canShowHex,
    String? selectedCityId,
    bool strategicView = false,
  }) {
    ensureAttachedTo(parent);
    final territories = <CityTerritory>[];
    for (final city in cities) {
      final color = Color(colorForPlayer(city.ownerPlayerId));
      final visibleHexes = canShowHex == null
          ? city.territoryHexes
          : city.territoryHexes.where(canShowHex).toList();
      if (visibleHexes.isEmpty) continue;
      territories.add(
        CityTerritory(
          color: color,
          center: city.center,
          hexes: visibleHexes,
          selected: city.id == selectedCityId,
        ),
      );
    }
    if (territories.isEmpty) {
      _component?.updateTerritories(
        territories: const [],
        strategicView: strategicView,
      );
      return;
    }

    _ensureOverlay()
      ..zoomEmphasis = _zoomEmphasis
      ..updateTerritories(
        territories: territories,
        strategicView: strategicView,
      );
  }

  CityTerritoryOverlay _ensureOverlay() {
    final existing = _component;
    if (existing != null) return existing;
    final component = CityTerritoryOverlay(
      territories: const [],
      strategicView: false,
      zoomEmphasis: _zoomEmphasis,
    );
    _component = component;
    unawaited(Future<void>.value(add(component)));
    return component;
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  List<CityTerritory> get territoriesForTesting =>
      _component?.territories ?? const [];

  CityTerritoryOverlay? get componentForTesting => _component;

  bool get strategicViewForTesting => _component?.strategicView ?? false;

  double get zoomEmphasisForTesting =>
      _component?.zoomEmphasis ?? _zoomEmphasis;
}
