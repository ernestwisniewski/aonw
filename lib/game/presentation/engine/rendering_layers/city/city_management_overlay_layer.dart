import 'dart:async';

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_management_overlay.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/runtime.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/tile_yield.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flame/components.dart';

part 'city_management_growth_overlay.dart';
part 'city_management_worked_hex_overlay.dart';
part 'city_management_worker_overlay.dart';

class CityManagementOverlayLayer extends Component with LayerAttachment {
  CityManagementOverlay? _component;
  List<CityManagementOverlayHex> _overlayHexes = const [];

  CityManagementOverlayLayer() {
    priority = MapPriority.cityManagementOverlay;
  }

  List<CityManagementOverlayHex> get overlayHexesForTesting => _overlayHexes;

  void sync({
    required Component parent,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    bool Function(CityHex hex)? canShowHex,
    bool dimmed = false,
  }) {
    ensureAttachedTo(parent);

    final pending = state.pendingAction;
    final cityId = switch (pending) {
      PendingCityWorkedHexSelection(:final cityId) => cityId,
      PendingCityExpansionSelection(:final cityId) => cityId,
      _ => null,
    };

    final overlayHexes = cityId == null
        ? _selectedWorkerImprovementHexes(
            state: state,
            mapData: mapData,
            cityRuleset: cityRuleset,
            canShowHex: canShowHex,
          )
        : _cityWorkedHexes(
            cityId: cityId,
            pending: pending!,
            state: state,
            mapData: mapData,
            cityRuleset: cityRuleset,
            canShowHex: canShowHex,
          );

    if (overlayHexes.isEmpty) {
      clear();
      return;
    }
    _overlayHexes = overlayHexes;
    final existing = _component;
    if (existing != null) {
      existing.updateHexes(hexes: overlayHexes, dimmed: dimmed);
      return;
    }

    final component = CityManagementOverlay(
      hexes: overlayHexes,
      dimmed: dimmed,
    );
    _component = component;
    unawaited(Future<void>.value(add(component)));
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
    _overlayHexes = const [];
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  CityManagementOverlay? get componentForTesting => _component;

  List<CityManagementOverlayHex> _cityWorkedHexes({
    required String cityId,
    required PendingPlayerAction pending,
    required GameClientState state,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
    required bool Function(CityHex hex)? canShowHex,
  }) {
    final city = state.cityById(cityId);
    if (city == null) return const [];

    return switch (pending) {
      PendingCityWorkedHexSelection() => _workedHexes(
        city: city,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
        canShowHex: canShowHex,
      ),
      PendingCityExpansionSelection() => _cityExpansionHexes(
        city: city,
        state: state,
        mapData: mapData,
        cityRuleset: cityRuleset,
        canShowHex: canShowHex,
      ),
      _ => const <CityManagementOverlayHex>[],
    };
  }
}
