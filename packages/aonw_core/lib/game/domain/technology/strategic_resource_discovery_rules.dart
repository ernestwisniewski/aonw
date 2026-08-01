import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/game/domain/hex.dart';
import 'package:aonw_core/game/domain/state.dart';
import 'package:aonw_core/game/domain/technology/resource_visibility_rules.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/map/domain/map_tile_view.dart';
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
    required DomainState state,
    required MapTileCatalog mapData,
  }) {
    return discoveriesForTechnologyFromCities(
      playerId: playerId,
      technologyId: technologyId,
      cities: state.cities,
      mapData: mapData,
    );
  }

  static List<StrategicResourceDiscovery> discoveriesForTechnologyFromCities({
    required String playerId,
    required TechnologyId technologyId,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapData,
  }) {
    final resources = [
      for (final resource in ResourceType.values)
        if (ResourceVisibilityRules.revealTechnologyFor(resource) ==
            technologyId)
          resource,
    ];
    if (resources.isEmpty) return const [];
    final cityList = List<GameCity>.unmodifiable(cities);

    return [
      for (final resource in resources)
        _discoveryForResource(
          playerId: playerId,
          resourceType: resource,
          cities: cityList,
          mapData: mapData,
        ),
    ].where((discovery) => discovery.hasAnySource).toList(growable: false);
  }

  static List<StrategicResourceDiscoveredEvent> eventsForTechnology({
    required String playerId,
    required TechnologyId technologyId,
    required DomainState state,
    required MapTileCatalog mapData,
  }) {
    return eventsForTechnologyFromCities(
      playerId: playerId,
      technologyId: technologyId,
      cities: state.cities,
      mapData: mapData,
    );
  }

  static List<StrategicResourceDiscoveredEvent> eventsForTechnologyFromCities({
    required String playerId,
    required TechnologyId technologyId,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapData,
  }) {
    return [
      for (final discovery in discoveriesForTechnologyFromCities(
        playerId: playerId,
        technologyId: technologyId,
        cities: cities,
        mapData: mapData,
      ))
        discovery.toEvent(),
    ];
  }

  static StrategicResourceDiscovery _discoveryForResource({
    required String playerId,
    required ResourceType resourceType,
    required Iterable<GameCity> cities,
    required MapTileCatalog mapData,
  }) {
    var controlledCount = 0;
    var rivalControlledCount = 0;
    final unclaimed = <CityHex>[];

    for (final tile in mapData.tileViews) {
      if (!tile.resources.contains(resourceType)) continue;
      final owner = _ownerOfTile(tile.col, tile.row, cities);
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
        cities: cities,
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
      if (best == null ||
          distance < bestDistance ||
          (distance == bestDistance && _compareHexes(candidate, best) < 0)) {
        best = candidate;
        bestDistance = distance;
      }
    }
    return best;
  }

  static int _compareHexes(CityHex left, CityHex right) {
    final col = left.col.compareTo(right.col);
    if (col != 0) return col;
    return left.row.compareTo(right.row);
  }
}
