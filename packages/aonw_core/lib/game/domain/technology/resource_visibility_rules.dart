import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/technology/research_state.dart';
import 'package:aonw_core/game/domain/technology/technology_id.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';

abstract final class ResourceVisibilityRules {
  static const _revealTechnologyByResource = <ResourceType, TechnologyId>{
    ResourceType.horses: TechnologyId.animalHusbandry,
    ResourceType.coal: TechnologyId.coalMining,
    ResourceType.oil: TechnologyId.combustion,
    ResourceType.aluminium: TechnologyId.flight,
    ResourceType.uranium: TechnologyId.nuclearPhysics,
  };

  static TechnologyId? revealTechnologyFor(ResourceType resource) {
    return _revealTechnologyByResource[resource];
  }

  static bool isRevealed({
    required ResourceType resource,
    required String playerId,
    required ResearchState research,
  }) {
    final technologyId = revealTechnologyFor(resource);
    if (technologyId == null) return true;
    return research.forPlayer(playerId).hasUnlocked(technologyId);
  }

  static Set<ResourceType> visibleResourceTypes({
    required String playerId,
    required ResearchState research,
  }) {
    return {
      for (final resource in ResourceType.values)
        if (isRevealed(
          resource: resource,
          playerId: playerId,
          research: research,
        ))
          resource,
    };
  }

  static List<ResourceType> visibleResources({
    required Iterable<ResourceType> resources,
    required String playerId,
    required ResearchState research,
  }) {
    return [
      for (final resource in resources)
        if (isRevealed(
          resource: resource,
          playerId: playerId,
          research: research,
        ))
          resource,
    ];
  }

  static WorldTile visibleTile({
    required WorldTile tile,
    required String playerId,
    required ResearchState research,
  }) {
    return tile.copyWith(
      resources: visibleResources(
        resources: tile.resources,
        playerId: playerId,
        research: research,
      ),
    );
  }

  static WorldMap visibleMap({
    required WorldMap mapData,
    required String playerId,
    required ResearchState research,
  }) {
    return WorldMap(
      cols: mapData.cols,
      rows: mapData.rows,
      tiles: [
        for (final tile in mapData.tiles)
          visibleTile(tile: tile, playerId: playerId, research: research),
      ],
      mapName: mapData.mapName,
      defaultZoom: mapData.defaultZoom,
    );
  }
}
