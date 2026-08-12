import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/resource/resource_economy_ruleset.dart';
import 'package:aonw_core/game/domain/resource/strategic_resource_bundle.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:aonw_core/map/domain/map_read_view.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

final class StrategicResourceProductionSource {
  const StrategicResourceProductionSource({
    required this.cityId,
    required this.hex,
    required this.resource,
    required this.amountPerTurn,
  });

  final String cityId;
  final CityHex hex;
  final ResourceType resource;
  final int amountPerTurn;
}

final class StrategicResourceProductionProjection {
  const StrategicResourceProductionProjection({
    required this.playerId,
    required this.output,
    required this.sources,
  });

  static const empty = StrategicResourceProductionProjection(
    playerId: '',
    output: StrategicResourceBundle.empty,
    sources: [],
  );

  final String playerId;
  final StrategicResourceBundle output;
  final List<StrategicResourceProductionSource> sources;
}

abstract final class StrategicResourceProductionRules {
  static StrategicResourceProductionProjection forPlayer({
    required String playerId,
    required Iterable<GameCity> cities,
    required Iterable<FieldImprovement> fieldImprovements,
    required MapTileLookup mapTiles,
    required ResearchState research,
    ResourceEconomyRuleset ruleset = ResourceEconomyRuleset.standard,
  }) {
    if (playerId.isEmpty) return StrategicResourceProductionProjection.empty;

    final improvementsByHex = <String, FieldImprovement>{
      for (final improvement in fieldImprovements)
        _hexKey(improvement.hex): improvement,
    };
    final amounts = <ResourceType, int>{};
    final sources = <StrategicResourceProductionSource>[];
    final visitedHexes = <String>{};
    final playerCities = _orderedPlayerCities(cities, playerId);

    for (final city in playerCities) {
      for (final hex in _orderedTerritory(city)) {
        final key = _hexKey(hex);
        if (!visitedHexes.add(key)) continue;
        for (final source in _sourcesAtHex(
          city: city,
          hex: hex,
          mapTiles: mapTiles,
          improvement: improvementsByHex[key],
          playerId: playerId,
          research: research,
          ruleset: ruleset,
        )) {
          amounts[source.resource] =
              (amounts[source.resource] ?? 0) + source.amountPerTurn;
          sources.add(source);
        }
      }
    }
    return StrategicResourceProductionProjection(
      playerId: playerId,
      output: StrategicResourceBundle(amounts),
      sources: List.unmodifiable(sources),
    );
  }
}

List<GameCity> _orderedPlayerCities(
  Iterable<GameCity> cities,
  String playerId,
) =>
    cities.where((city) => city.ownerPlayerId == playerId).toList()
      ..sort((left, right) => left.id.compareTo(right.id));

List<CityHex> _orderedTerritory(GameCity city) =>
    city.territoryHexes.toList()..sort((left, right) {
      final col = left.col.compareTo(right.col);
      return col != 0 ? col : left.row.compareTo(right.row);
    });

List<StrategicResourceProductionSource> _sourcesAtHex({
  required GameCity city,
  required CityHex hex,
  required MapTileLookup mapTiles,
  required FieldImprovement? improvement,
  required String playerId,
  required ResearchState research,
  required ResourceEconomyRuleset ruleset,
}) {
  final tile = mapTiles.tileAt(hex.col, hex.row);
  if (tile == null || improvement == null) return const [];
  return [
    for (final resource in tile.resources)
      if (_canExtract(
        resource: resource,
        improvement: improvement,
        playerId: playerId,
        research: research,
        ruleset: ruleset,
      ))
        StrategicResourceProductionSource(
          cityId: city.id,
          hex: hex,
          resource: resource,
          amountPerTurn: ruleset.extractionFor(resource)!.amountPerTurn,
        ),
  ];
}

bool _canExtract({
  required ResourceType resource,
  required FieldImprovement improvement,
  required String playerId,
  required ResearchState research,
  required ResourceEconomyRuleset ruleset,
}) {
  final extraction = ruleset.extractionFor(resource);
  return extraction != null &&
      extraction.improvement == improvement.type &&
      ResourceVisibilityRules.isRevealed(
        resource: resource,
        playerId: playerId,
        research: research,
      );
}

String _hexKey(CityHex hex) => '${hex.col}:${hex.row}';
