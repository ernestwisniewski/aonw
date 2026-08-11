import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'map_boundary_source_guard.dart';
import 'movement_command_boundary_guard.dart';

const movementKernelRootPaths = {
  movementKernelPath,
  movementStatePath,
  movementResultPath,
  movementExecutionPath,
  '${movementLibraryPath}movement_command_executor.dart',
  '${movementLibraryPath}movement_command_guard.dart',
  movementPathConstraintsPath,
  '${movementLibraryPath}movement_command_planner.dart',
  movementVisibilityModePath,
  movementVisibilityPath,
};

const movementKernelImportGraphPaths = {
  ...movementKernelRootPaths,
  '${movementLibraryPath}movement_cost.dart',
  '${movementLibraryPath}movement_hidden_obstacle_rules.dart',
  '${movementLibraryPath}queued_move_path.dart',
  '${movementLibraryPath}unit_manual_movement_rules.dart',
  '${movementLibraryPath}unit_movement_balance.dart',
  '${movementLibraryPath}unit_movement_cost_rules.dart',
  '${movementLibraryPath}unit_movement_feasibility.dart',
  '${movementLibraryPath}unit_movement_pathfinder.dart',
  '${movementLibraryPath}unit_movement_plan.dart',
  '${movementLibraryPath}unit_movement_route_search.dart',
  '${movementLibraryPath}unit_traversal_cost_resolver.dart',
};

const _pathfinderPath = '${movementLibraryPath}unit_movement_pathfinder.dart';
const _routeSearchPath =
    '${movementLibraryPath}unit_movement_route_search.dart';
const _mapTileSourceUri = 'package:aonw_core/map/domain/map_tile_source.dart';
const _pathfinderDeclarations = {
  'UnitMovementPathfinder',
  'UnitMovementTileIndex',
  '_PathNode',
  '_PathSearchResult',
};
const _routeSearchDeclarations = {
  '_UnitMovementRouteSearch',
  '_RouteNode',
  '_RouteScore',
  '_RouteSearchResult',
  '_RouteState',
};
const _routeSearchFunctions = {
  '_remainingAfterNewTurn',
  '_compareRouteNodes',
  '_compareRouteScores',
  '_compareUnitApproachPlans',
};

const movementKernelForbiddenRootTypes = {
  'PersistentGameState',
  'PersistentMoveUnitResolver',
  'PersistentMoveUnitResult',
  'DomainState',
  'DomainMoveUnitResolver',
  'DomainMoveUnitResult',
  'CanonicalGameSnapshot',
  'MatchSessionState',
  'GameClientState',
  'GameRuntimeState',
  'GameSave',
  'GameRuleset',
  'WireMatch',
  'WireSnapshot',
  'WireCommand',
  'GameCommandContext',
  'ReducerEnvironment',
  'GameStateTransition',
  'UiEffect',
  'RendererEffect',
  'AnimateUnitMoveEffect',
  'InteractionState',
  'PersistedInteractionState',
  'GameSelection',
  'UnitCommandValidator',
  'MapDefinition',
  'MapReadView',
  'MapSurvey',
  'MapTileCatalog',
  'MapTileLookup',
  'WorldMap',
  'WorldMapReadView',
  'WorldTile',
};

const _leafDependencyUris = {
  'package:aonw_core/game/domain/city/game_city.dart',
  'package:aonw_core/game/domain/command/game_command.dart',
  'package:aonw_core/game/domain/diplomacy/city_entry_policy.dart',
  'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart',
  'package:aonw_core/game/domain/diplomacy/diplomatic_contact.dart',
  'package:aonw_core/game/domain/event/game_event.dart',
  'package:aonw_core/game/domain/fog/fog_of_war_service.dart',
  'package:aonw_core/game/domain/fog/fog_of_war_state.dart',
  'package:aonw_core/game/domain/fog/fog_visibility.dart',
  'package:aonw_core/game/domain/fog/fog_visibility_query.dart',
  'package:aonw_core/game/domain/hex/hex_coordinate.dart',
  'package:aonw_core/game/domain/hex/hex_distance.dart',
  'package:aonw_core/game/domain/terrain/tile_terrain_profile.dart',
  'package:aonw_core/game/domain/terrain/tile_terrain_profile_rules.dart',
  'package:aonw_core/game/domain/transport/transport_network_index.dart',
  'package:aonw_core/game/domain/transport/transport_network_state.dart',
  'package:aonw_core/game/domain/unit/game_unit.dart',
  'package:aonw_core/game/domain/unit/game_unit_type.dart',
  'package:aonw_core/game/domain/unit/unit_movement_domain.dart',
  'package:aonw_core/map/domain/hex_grid_topology.dart',
  'package:aonw_core/map/domain/map_read_view.dart',
  'package:aonw_core/map/domain/map_tile_view.dart',
  'package:aonw_core/map/domain/terrain_type.dart',
  'package:aonw_core/util/min_binary_heap.dart',
};

Map<String, String> movementKernelImportGraph(
  Map<String, String> sources,
  Set<String> roots,
) {
  final reached = _reachableMovementPaths(sources, roots);
  return {for (final path in reached) path: sources[path]!};
}

List<String> movementKernelImportGraphViolations(
  Map<String, String> graph, {
  required Set<String> expectedPaths,
  required Set<String> forbiddenTypes,
}) {
  final violations = <String>[];
  final actualPaths = graph.keys.toSet();
  final mapTileSourceTypes = _mapTileSourceBackedTypes(graph);
  for (final path in actualPaths.difference(expectedPaths)) {
    violations.add('$path is an unexpected movement-kernel graph path');
  }
  for (final path in expectedPaths.difference(actualPaths)) {
    violations.add('$path is missing from the movement-kernel graph');
  }
  for (final entry in graph.entries) {
    violations.addAll(
      _sourceViolations(entry, graph, forbiddenTypes, mapTileSourceTypes),
    );
  }
  return violations..sort();
}

Set<String> _reachableMovementPaths(
  Map<String, String> sources,
  Set<String> roots,
) {
  final reached = <String>{};
  final pending = roots.toList();
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    final source = sources[path];
    if (source == null) throw StateError('Missing movement source: $path');
    if (!reached.add(path)) continue;
    for (final uri in _directiveUris(source, path)) {
      final dependency = _movementPathForUri(path, uri);
      if (dependency != null &&
          sources.containsKey(dependency) &&
          !reached.contains(dependency)) {
        pending.add(dependency);
      }
    }
  }
  return reached;
}

List<String> _sourceViolations(
  MapEntry<String, String> entry,
  Map<String, String> graph,
  Set<String> forbiddenTypes,
  Set<String> mapTileSourceTypes,
) {
  final violations = <String>[];
  final types = namedTypeReferencesInSource(entry.value, path: entry.key);
  if (entry.key == _pathfinderPath) {
    violations.addAll(
      _reviewedDeclarationViolations(
        entry.value,
        path: _pathfinderPath,
        expectedClasses: _pathfinderDeclarations,
      ),
    );
  } else if (entry.key == _routeSearchPath) {
    violations.addAll(
      _reviewedDeclarationViolations(
        entry.value,
        path: _routeSearchPath,
        expectedClasses: _routeSearchDeclarations,
        expectedFunctions: _routeSearchFunctions,
      ),
    );
  }
  for (final type in types.intersection(forbiddenTypes)) {
    violations.add('${entry.key} references forbidden $type');
  }
  final sourceTypes = types.intersection(mapTileSourceTypes);
  if (entry.key != _pathfinderPath && sourceTypes.isNotEmpty) {
    violations.add(
      '${entry.key} references MapTileSource outside the pathfinder leaf '
      'via ${sourceTypes.join(', ')}',
    );
  }
  for (final uri in _directiveUris(entry.value, entry.key)) {
    final dependency = _movementPathForUri(entry.key, uri);
    if (uri == _mapTileSourceUri && entry.key == _pathfinderPath ||
        _leafDependencyUris.contains(uri) ||
        dependency != null && graph.containsKey(dependency)) {
      continue;
    }
    violations.add('${entry.key} imports unapproved dependency $uri');
  }
  return violations;
}

List<String> _reviewedDeclarationViolations(
  String source, {
  required String path,
  required Set<String> expectedClasses,
  Set<String> expectedFunctions = const {},
}) {
  final unit = parseString(content: source, path: path).unit;
  final classes = unit.declarations.whereType<ClassDeclaration>().toList();
  final classNames = {
    for (final declaration in classes) declaration.namePart.typeName.lexeme,
  };
  final functions = unit.declarations.whereType<FunctionDeclaration>().toList();
  final functionNames = {
    for (final declaration in functions) declaration.name.lexeme,
  };
  return [
    if (unit.declarations.length !=
            expectedClasses.length + expectedFunctions.length ||
        classes.length != expectedClasses.length ||
        classNames.length != expectedClasses.length ||
        !classNames.containsAll(expectedClasses) ||
        functions.length != expectedFunctions.length ||
        functionNames.length != expectedFunctions.length ||
        !functionNames.containsAll(expectedFunctions))
      '$path must declare exactly the reviewed movement declarations',
  ];
}

Set<String> _directiveUris(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  final uris = <String>{};
  for (final directive in unit.directives.whereType<UriBasedDirective>()) {
    final primary = directive.uri.stringValue;
    if (primary != null) uris.add(primary);
    if (directive is NamespaceDirective) {
      for (final configuration in directive.configurations) {
        final conditional = configuration.uri.stringValue;
        if (conditional != null) uris.add(conditional);
      }
    }
  }
  return uris;
}

Set<String> _mapTileSourceBackedTypes(Map<String, String> graph) {
  final names = typeNamesBackedBy(graph, const {'MapTileSource'});
  final units = [
    for (final entry in graph.entries)
      parseString(content: entry.value, path: entry.key).unit,
  ];
  var changed = true;
  while (changed) {
    changed = false;
    for (final unit in units) {
      for (final declaration
          in unit.declarations.whereType<ClassDeclaration>()) {
        final supertypes = <NamedType>[
          if (declaration.extendsClause case final clause?) clause.superclass,
          ...?declaration.withClause?.mixinTypes,
          ...?declaration.implementsClause?.interfaces,
        ];
        if (supertypes.any((type) => names.contains(type.name.lexeme)) &&
            names.add(declaration.namePart.typeName.lexeme)) {
          changed = true;
        }
      }
    }
  }
  return names;
}

String? _movementPathForUri(String importerPath, String uri) {
  const packagePrefix = 'package:aonw_core/game/domain/movement/';
  if (uri.startsWith(packagePrefix)) {
    return '$movementLibraryPath${uri.substring(packagePrefix.length)}';
  }
  if (Uri.parse(uri).hasScheme) return null;
  final resolved = Uri.parse(importerPath).resolve(uri).path;
  return resolved.startsWith(movementLibraryPath) ? resolved : null;
}
