part of '../world_map_combat_boundary_test.dart';

const _cityTargets = [
  _Target(
    path: 'lib/game/domain/reducer/city/city_founding_reducer.dart',
    owner: 'CityFoundingReducer',
    boundaries: [
      _Boundary.method(
        'startCityFounding',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'toggleControlledHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path: 'lib/game/domain/city_selection_projector.dart',
    owner: 'CitySelectionProjector',
    boundaries: [
      _Boundary.method('project', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'city_founding_command_resolver.dart',
    owner: 'CityFoundingCommandResolver',
    boundaries: [
      _Boundary.method(
        'foundCity',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'domain_city_founding_resolver.dart',
    owner: 'DomainCityFoundingResolver',
    boundaries: [
      _Boundary.method(
        'foundCity',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'city_initial_territory_selector.dart',
    owner: 'CityInitialTerritorySelector',
    boundaries: [
      _Boundary.method('select', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'city_expansion_command_resolver.dart',
    owner: 'CityExpansionCommandResolver',
    boundaries: [
      _Boundary.method(
        'selectExpansionHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'domain_city_expansion_resolver.dart',
    owner: 'DomainCityExpansionResolver',
    boundaries: [
      _Boundary.method(
        'selectExpansionHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'worker_command_resolver.dart',
    owner: 'WorkerCommandResolver',
    boundaries: [
      _Boundary.method(
        'selectWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'confirmWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'assignWorkerToHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'domain_worker_command_resolver.dart',
    owner: 'DomainWorkerCommandResolver',
    boundaries: [
      _Boundary.method(
        'selectWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'confirmWorkerImprovement',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'assignWorkerToHex',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'rush_production_command_resolver.dart',
    owner: 'RushProductionCommandResolver',
    boundaries: [
      _Boundary.method('resolve', parameter: 'mapTiles', type: 'MapTileLookup'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/'
        'domain_city_production_resolver.dart',
    owner: 'DomainCityProductionResolver',
    boundaries: [
      _Boundary.method(
        'startBuilding',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'startUnitProduction',
        parameter: 'mapView',
        type: 'MapReadView',
      ),
      _Boundary.method(
        'startWonder',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
      _Boundary.method(
        'rushProduction',
        parameter: 'mapTiles',
        type: 'MapTileLookup',
      ),
    ],
  ),
];
