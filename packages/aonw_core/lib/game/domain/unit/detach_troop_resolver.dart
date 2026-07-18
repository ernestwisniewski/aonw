import 'package:aonw_core/game/domain/city/game_city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart';
import 'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart';
import 'package:aonw_core/game/domain/entity_lookup.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_service.dart';
import 'package:aonw_core/game/domain/fog/fog_of_war_state.dart';
import 'package:aonw_core/game/domain/fog/fog_visibility_query.dart';
import 'package:aonw_core/game/domain/movement/unit_movement_cost_rules.dart';
import 'package:aonw_core/game/domain/unit/army_troop.dart';
import 'package:aonw_core/game/domain/unit/game_unit.dart';
import 'package:aonw_core/game/domain/unit/unit_detachment_rules.dart';
import 'package:aonw_core/map/domain/hex_grid_topology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';

/// Persistence-neutral result of detaching one troop from a unit.
final class DetachTroopResult {
  const DetachTroopResult._accepted({
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
  }) : accepted = true,
       reason = null;

  const DetachTroopResult._rejected({
    required this.units,
    required this.fogOfWar,
    required this.diplomacy,
    required this.reason,
  }) : accepted = false;

  final bool accepted;
  final String? reason;
  final List<GameUnit> units;
  final FogOfWarState fogOfWar;
  final DiplomacyState diplomacy;
}

/// Applies troop-detachment rules without depending on a state container.
final class DetachTroopResolver {
  const DetachTroopResolver._();

  static DetachTroopResult detachTroop({
    required List<GameUnit> units,
    required List<GameCity> cities,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required Iterable<String> playerIds,
    required DetachTroopCommand command,
    required String actorPlayerId,
    required MapTileLookup mapTiles,
    FogVisibilityQuery? visibility,
    FogOfWarService fogOfWarService = const FogOfWarService(),
  }) {
    return _resolve((
      units: units,
      cities: cities,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      playerIds: playerIds,
      command: command,
      actorPlayerId: actorPlayerId,
      mapTiles: mapTiles,
      visibility:
          visibility ??
          FogVisibilityQuery(playerId: actorPlayerId, state: fogOfWar),
    ), fogOfWarService);
  }

  static DetachTroopResult _resolve(
    _DetachTroopInput input,
    FogOfWarService fogOfWarService,
  ) {
    final sourceIndex = _unitIndexById(input.units, input.command.unitId);
    if (sourceIndex == null) {
      return _rejectInput(input, 'unit_not_found');
    }

    final source = input.units[sourceIndex];
    if (source.ownerPlayerId != input.actorPlayerId) {
      return _rejectInput(input, 'unit_not_controlled');
    }
    if (!source.canDetachTroop(input.command.troopType)) {
      return _rejectInput(input, 'troop_not_available');
    }
    if (input.mapTiles.tileAt(source.col, source.row) == null) {
      return _rejectInput(input, 'detachment_source_out_of_bounds');
    }

    final destination = _detachmentDestinationFor(
      source: source,
      units: input.units,
      mapTiles: input.mapTiles,
      visibility: input.visibility,
    );
    if (destination == null) {
      return _rejectInput(input, 'detachment_destination_unavailable');
    }

    final detachedUnitId = _nextDetachedUnitId(
      source: source,
      troopType: input.command.troopType,
      units: input.units,
    );
    final detachment = UnitDetachmentRules.detachTroop(
      source: source,
      troopType: input.command.troopType,
      detachedUnitId: detachedUnitId,
      destinationCol: destination.col,
      destinationRow: destination.row,
    );
    if (detachment == null) {
      return _rejectInput(input, 'troop_not_available');
    }

    return _accept(
      input: input,
      source: source,
      detachment: detachment,
      fogOfWarService: fogOfWarService,
    );
  }

  static DetachTroopResult _accept({
    required _DetachTroopInput input,
    required GameUnit source,
    required UnitDetachmentResult detachment,
    required FogOfWarService fogOfWarService,
  }) {
    final updatedUnits = <GameUnit>[
      for (final unit in input.units)
        if (unit.id == source.id) detachment.updatedSource else unit,
      detachment.detachedUnit,
    ];
    final updatedFog = fogOfWarService.recomputePlayer(
      current: input.fogOfWar,
      mapData: input.mapTiles,
      playerId: source.ownerPlayerId,
      units: updatedUnits,
      cities: input.cities,
    );
    final updatedDiplomacy = DiplomaticContact.mergeDiscoveredContacts(
      diplomacy: input.diplomacy,
      fogOfWar: updatedFog,
      units: updatedUnits,
      cities: input.cities,
      playerIds: input.playerIds,
    );
    return DetachTroopResult._accepted(
      units: List<GameUnit>.unmodifiable(updatedUnits),
      fogOfWar: updatedFog,
      diplomacy: updatedDiplomacy,
    );
  }

  static DetachTroopResult _rejectInput(
    _DetachTroopInput input,
    String reason,
  ) {
    return _reject(
      units: input.units,
      fogOfWar: input.fogOfWar,
      diplomacy: input.diplomacy,
      reason: reason,
    );
  }

  static DetachTroopResult _reject({
    required List<GameUnit> units,
    required FogOfWarState fogOfWar,
    required DiplomacyState diplomacy,
    required String reason,
  }) {
    return DetachTroopResult._rejected(
      units: units,
      fogOfWar: fogOfWar,
      diplomacy: diplomacy,
      reason: reason,
    );
  }

  static ({int col, int row})? _detachmentDestinationFor({
    required GameUnit source,
    required List<GameUnit> units,
    required MapTileLookup mapTiles,
    required FogVisibilityQuery visibility,
  }) {
    for (final neighbor in HexGridTopology.neighbors(
      col: source.col,
      row: source.row,
    )) {
      final tile = mapTiles.tileAt(neighbor.col, neighbor.row);
      if (tile == null) continue;
      if (!visibility.canInspectTile(tile)) continue;
      if (units.unitAt(neighbor.col, neighbor.row) != null) continue;
      if (UnitMovementCostRules.costToEnterTile(tile).blocked) continue;
      return neighbor;
    }
    return null;
  }

  static String _nextDetachedUnitId({
    required GameUnit source,
    required TroopType troopType,
    required List<GameUnit> units,
  }) {
    final prefix = '${source.id}_${troopType.name}';
    var index = 1;
    while (units.any((unit) => unit.id == '${prefix}_$index')) {
      index++;
    }
    return '${prefix}_$index';
  }

  static int? _unitIndexById(List<GameUnit> units, String unitId) {
    for (var i = 0; i < units.length; i++) {
      if (units[i].id == unitId) return i;
    }
    return null;
  }
}

typedef _DetachTroopInput = ({
  List<GameUnit> units,
  List<GameCity> cities,
  FogOfWarState fogOfWar,
  DiplomacyState diplomacy,
  Iterable<String> playerIds,
  DetachTroopCommand command,
  String actorPlayerId,
  MapTileLookup mapTiles,
  FogVisibilityQuery visibility,
});
