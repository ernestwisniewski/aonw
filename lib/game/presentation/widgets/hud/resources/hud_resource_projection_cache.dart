import 'dart:collection';

import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:flutter/foundation.dart';

typedef HudResourceProjections = ({
  EmpireResourceNetwork network,
  StrategicResourceProductionProjection production,
});

final class HudResourceProjectionCache {
  HudResourceProjectionCache({this.maxEntries = 8}) : assert(maxEntries > 0);

  static final Expando<HudResourceProjectionCache> _ownerCaches = Expando();

  factory HudResourceProjectionCache.forOwner(Object owner) =>
      _ownerCaches[owner] ??= HudResourceProjectionCache();

  final int maxEntries;
  final LinkedHashMap<_HudResourceProjectionKey, HudResourceProjections>
  _entries = LinkedHashMap();
  int _computeCount = 0;

  HudResourceProjections forPlayer({
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
  }) {
    final key = _HudResourceProjectionKey(
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      research: state.research,
      resourceTradeAgreements: state.resourceTradeAgreements,
    );
    final cached = _entries.remove(key);
    if (cached != null) {
      _entries[key] = cached;
      return cached;
    }
    _computeCount++;
    final computed = computeForPlayer(
      state: state,
      playerId: playerId,
      mapData: mapData,
      cityRuleset: cityRuleset,
    );
    _entries[key] = computed;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return computed;
  }

  static HudResourceProjections computeForPlayer({
    required GameClientState state,
    required String playerId,
    required WorldMap mapData,
    required CityRuleset cityRuleset,
  }) => (
    network: EmpireResourceNetworkRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      mapTiles: mapData,
      research: state.research,
      ruleset: cityRuleset,
      resourceTradeAgreements: state.resourceTradeAgreements,
    ),
    production: StrategicResourceProductionRules.forPlayer(
      playerId: playerId,
      cities: state.cities,
      fieldImprovements: state.fieldImprovements,
      mapTiles: mapData,
      research: state.research,
    ),
  );

  @visibleForTesting
  int get debugComputeCount => _computeCount;
}

final class _HudResourceProjectionKey {
  const _HudResourceProjectionKey({
    required this.playerId,
    required this.mapData,
    required this.cityRuleset,
    required this.cities,
    required this.fieldImprovements,
    required this.research,
    required this.resourceTradeAgreements,
  });

  final String playerId;
  final WorldMap mapData;
  final CityRuleset cityRuleset;
  final List<GameCity> cities;
  final List<FieldImprovement> fieldImprovements;
  final ResearchState research;
  final List<ResourceTradeAgreement> resourceTradeAgreements;

  @override
  bool operator ==(Object other) =>
      other is _HudResourceProjectionKey &&
      other.playerId == playerId &&
      identical(other.mapData, mapData) &&
      identical(other.cityRuleset, cityRuleset) &&
      identical(other.cities, cities) &&
      identical(other.fieldImprovements, fieldImprovements) &&
      identical(other.research, research) &&
      identical(other.resourceTradeAgreements, resourceTradeAgreements);

  @override
  int get hashCode => Object.hash(
    playerId,
    identityHashCode(mapData),
    identityHashCode(cityRuleset),
    identityHashCode(cities),
    identityHashCode(fieldImprovements),
    identityHashCode(research),
    identityHashCode(resourceTradeAgreements),
  );
}
