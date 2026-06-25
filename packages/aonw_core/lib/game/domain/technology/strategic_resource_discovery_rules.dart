import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology/resource_visibility_rules.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/map/domain/map_data.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

class StrategicResourceDiscovery {
  final String playerId;
  final ResourceType resourceType;
  final int controlledCount;
  final int rivalControlledCount;
  final int unclaimedCount;
  final CityHex? nearestUnclaimedHex;

  const StrategicResourceDiscovery({
    required this.playerId,
    required this.resourceType,
    required this.controlledCount,
    required this.rivalControlledCount,
    required this.unclaimedCount,
    this.nearestUnclaimedHex,
  });

  bool get hasAnySource =>
      controlledCount > 0 || rivalControlledCount > 0 || unclaimedCount > 0;

  StrategicResourceDiscoveredEvent toEvent() {
    return StrategicResourceDiscoveredEvent(
      playerId: playerId,
      resourceType: resourceType,
      controlledCount: controlledCount,
      rivalControlledCount: rivalControlledCount,
      unclaimedCount: unclaimedCount,
      pressure: StrategicResourceDiscoveryPressure.fromCounts(
        controlledCount: controlledCount,
        rivalControlledCount: rivalControlledCount,
        unclaimedCount: unclaimedCount,
      ),
      nearestUnclaimedCol: nearestUnclaimedHex?.col,
      nearestUnclaimedRow: nearestUnclaimedHex?.row,
    );
  }
}

abstract final class StrategicResourceDiscoveryRules {
  static List<StrategicResourceDiscovery> discoveriesForTechnology({
    required String playerId,
    required TechnologyId technologyId,
    required PersistentGameState state,
    required MapData mapData,
  }) {
    final resources = [
      for (final resource in ResourceType.values)
        if (ResourceVisibilityRules.revealTechnologyFor(resource) ==
            technologyId)
          resource,
    ];
    if (resources.isEmpty) return const [];

    return [
      for (final resource in resources)
        _discoveryForResource(
          playerId: playerId,
          resourceType: resource,
          state: state,
          mapData: mapData,
        ),
    ].where((discovery) => discovery.hasAnySource).toList(growable: false);
  }

  static List<StrategicResourceDiscoveredEvent> eventsForTechnology({
    required String playerId,
    required TechnologyId technologyId,
    required PersistentGameState state,
    required MapData mapData,
  }) {
    return [
      for (final discovery in discoveriesForTechnology(
        playerId: playerId,
        technologyId: technologyId,
        state: state,
        mapData: mapData,
      ))
        discovery.toEvent(),
    ];
  }

  static StrategicResourceDiscovery _discoveryForResource({
    required String playerId,
    required ResourceType resourceType,
    required PersistentGameState state,
    required MapData mapData,
  }) {
    var controlledCount = 0;
    var rivalControlledCount = 0;
    final unclaimed = <CityHex>[];

    for (final tile in mapData.tiles) {
      if (!tile.resources.contains(resourceType)) continue;
      final owner = _ownerOfTile(tile.col, tile.row, state.cities);
      if (owner == playerId) {
        controlledCount++;
      } else if (owner != null) {
        rivalControlledCount++;
      } else {
        unclaimed.add(CityHex(col: tile.col, row: tile.row));
      }
    }

    return StrategicResourceDiscovery(
      playerId: playerId,
      resourceType: resourceType,
      controlledCount: controlledCount,
      rivalControlledCount: rivalControlledCount,
      unclaimedCount: unclaimed.length,
      nearestUnclaimedHex: _nearestToPlayerCities(
        playerId: playerId,
        cities: state.cities,
        candidates: unclaimed,
      ),
    );
  }

  static String? _ownerOfTile(int col, int row, Iterable<GameCity> cities) {
    for (final city in cities) {
      if (city.controlsTile(col, row)) return city.ownerPlayerId;
    }
    return null;
  }

  static CityHex? _nearestToPlayerCities({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<CityHex> candidates,
  }) {
    final ownCenters = [
      for (final city in cities)
        if (city.ownerPlayerId == playerId) city.center.toCoordinate(),
    ];

    CityHex? best;
    var bestDistance = 0;
    for (final candidate in candidates) {
      if (ownCenters.isEmpty) return candidate;
      final distance = ownCenters
          .map(
            (center) => HexDistance.between(center, candidate.toCoordinate()),
          )
          .reduce((a, b) => a < b ? a : b);
      if (best == null || distance < bestDistance) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }
}
