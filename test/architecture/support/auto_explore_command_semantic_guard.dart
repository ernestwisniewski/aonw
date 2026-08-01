part of 'movement_command_boundary_guard.dart';

const _autoExploreNeutralPaths = {
  autoExplorePhasePath,
  autoExploreStatePath,
  autoExploreResultPath,
  autoExploreGuardPath,
  autoExploreResolverPath,
  autoExplorePlannerDependencyPath,
  autoExploreTargetDependencyPath,
};

const _autoExploreForbiddenNeutralTypes = {
  'PersistentGameState',
  'GameRuntimeState',
  'DomainState',
  'CanonicalGameSnapshot',
  'MatchSessionState',
  'GameClientState',
  'GameSave',
  'PersistentUnitActionResolver',
  'PersistentMoveUnitResolver',
  'PersistentAutoExploreCommandResolver',
  'DomainMoveUnitResolver',
  'MapDefinition',
  'MapReadView',
  'MapTileSource',
  'WorldMap',
  'WorldMapReadView',
};

const _autoExploreExpectedImports = <String, Set<String>>{
  autoExplorePhasePath: {},
  autoExploreStatePath: {
    'package:aonw_core/game/domain/movement/movement_command_state.dart',
    'package:aonw_core/game/domain/state/canonical_game_snapshot.dart',
  },
  autoExploreResultPath: {
    'package:aonw_core/game/domain/diplomacy/diplomacy_state.dart',
    'package:aonw_core/game/domain/event/game_event.dart',
    'package:aonw_core/game/domain/fog/fog_of_war_state.dart',
    'package:aonw_core/game/domain/movement/movement_command_execution.dart',
    'package:aonw_core/game/domain/state/canonical_game_snapshot.dart',
    'package:aonw_core/game/domain/unit/game_unit.dart',
  },
  autoExploreGuardPath: {
    'package:aonw_core/game/domain/command/game_command.dart',
    'package:aonw_core/game/domain/movement/auto_explore_command_state.dart',
    'package:aonw_core/game/domain/unit/game_unit.dart',
    'package:aonw_core/game/domain/unit/game_unit_type.dart',
    'package:aonw_core/map/domain/map_read_view.dart',
  },
  autoExploreResolverPath: {
    'package:aonw_core/game/domain/command/game_command.dart',
    'package:aonw_core/game/domain/fog/fog_of_war_service.dart',
    'package:aonw_core/game/domain/movement/auto_explore_command_guard.dart',
    'package:aonw_core/game/domain/movement/auto_explore_command_phase.dart',
    'package:aonw_core/game/domain/movement/auto_explore_command_result.dart',
    'package:aonw_core/game/domain/movement/auto_explore_command_state.dart',
    'package:aonw_core/game/domain/movement/movement_command_resolver.dart',
    'package:aonw_core/game/domain/movement/movement_command_result.dart',
    'package:aonw_core/game/domain/movement/movement_command_state.dart',
    'package:aonw_core/game/domain/movement/'
        'movement_command_visibility_mode.dart',
    'package:aonw_core/game/domain/movement/'
        'movement_hidden_obstacle_rules.dart',
    'package:aonw_core/game/domain/movement/scout_auto_explore_planner.dart',
    'package:aonw_core/game/domain/movement/scout_auto_explore_target.dart',
    'package:aonw_core/game/domain/movement/'
        'unit_movement_visibility_rules.dart',
    'package:aonw_core/game/domain/state/canonical_game_snapshot.dart',
    'package:aonw_core/game/domain/state/'
        'persisted_interaction_unit_rules.dart',
    'package:aonw_core/game/domain/unit/game_unit.dart',
    'package:aonw_core/map/domain/map_read_view.dart',
    'package:aonw_core/map/domain/map_tile_view.dart',
  },
  autoExplorePlannerDependencyPath: {
    'package:aonw_core/game/domain/command.dart',
    'package:aonw_core/game/domain/fog.dart',
    'package:aonw_core/game/domain/hex.dart',
    'package:aonw_core/game/domain/movement/'
        'movement_command_path_constraints.dart',
    'package:aonw_core/game/domain/movement/scout_auto_explore_target.dart',
    'package:aonw_core/game/domain/movement/unit_movement_pathfinder.dart',
    'package:aonw_core/game/domain/unit.dart',
    'package:aonw_core/map/domain/map_read_view.dart',
    'package:aonw_core/map/domain/map_tile_view.dart',
  },
  autoExploreTargetDependencyPath: {
    'package:aonw_core/game/domain/command/game_command.dart',
    'package:aonw_core/game/domain/movement/'
        'movement_command_path_constraints.dart',
  },
};

List<String> autoExploreClosedImportViolations(Map<String, String> sources) {
  final violations = <String>[];
  for (final entry in _autoExploreExpectedImports.entries) {
    final source = sources[entry.key];
    if (source == null) {
      violations.add('${entry.key} must exist');
      continue;
    }
    final imports = _autoExploreImportUris(source, entry.key);
    if (!_sameSet(imports, entry.value)) {
      violations.add('${entry.key} imports $imports instead of ${entry.value}');
    }
    if (_autoExploreNeutralPaths.contains(entry.key)) {
      final types = _autoExploreNamedTypes(source, entry.key);
      final forbidden = types.intersection(_autoExploreForbiddenNeutralTypes);
      if (forbidden.isNotEmpty) {
        violations.add('${entry.key} references forbidden $forbidden');
      }
    }
  }
  return violations..sort();
}

List<String> autoExploreResolverForwardingViolations(String? source) {
  if (source == null) return const ['auto-explore resolver must exist'];
  final unit = parseString(content: source, path: autoExploreResolverPath).unit;
  final targetCalls = _autoExploreCalls(unit, 'targetFor');
  final commandCalls = _autoExploreCalls(unit, 'commandFor');
  final visibilityCalls = _autoExploreCalls(unit, 'visibilityForActor');
  final planningUnitCalls = _autoExploreCalls(unit, 'planningUnitsForActor');
  final cityCalls = _autoExploreCalls(unit, 'canPlanThroughCity');
  final movementCalls = _autoExploreCalls(unit, 'resolve')
      .where(
        (call) =>
            call.target?.toSource().startsWith('MovementCommandResolver(') ??
            false,
      )
      .toList();
  return [
    ..._autoExploreTargetMethodViolations(targetCalls, commandCalls),
    ..._autoExploreTargetArgumentViolations(targetCalls),
    ..._autoExploreExactInvocationViolations(
      calls: visibilityCalls,
      expectedArguments: const {
        'fogOfWar': 'movement.fogOfWar',
        'actorPlayerId': 'actorPlayerId',
      },
      message: 'target scan must reuse visibilityForActor exactly',
    ),
    ..._autoExploreExactInvocationViolations(
      calls: planningUnitCalls,
      expectedArguments: const {
        'units': 'movement.units',
        'movingUnit': 'unit',
        'actorPlayerId': 'actorPlayerId',
        'visibility': 'visibility',
      },
      message:
          'target scan must derive actor-known units from the canonical '
          'rule',
    ),
    ..._autoExploreExactInvocationViolations(
      calls: cityCalls,
      expectedArguments: const {
        'cities': 'movement.cities',
        'diplomacy': 'movement.diplomacy',
        'unit': 'unit',
        'tile': 'tile',
        'visibility': 'visibility',
      },
      message:
          'target scan must apply the dynamic city visibility policy '
          'exactly',
    ),
    ..._autoExploreExactInvocationViolations(
      calls: movementCalls,
      expectedArguments: const {
        'state': '_movementStateWithUnits(state.movement, primedUnits)',
        'command': 'target.command',
        'actorPlayerId': 'actorPlayerId',
        'mapData': 'mapData',
        'visibilityMode': 'MovementCommandVisibilityMode.unrestrictedPathing',
        'pathConstraints': 'target.pathConstraints',
      },
      message:
          'movement must receive full state, unrestricted pathing, and '
          'exact target constraints',
    ),
  ];
}

List<String> _autoExploreTargetMethodViolations(
  List<MethodInvocation> targetCalls,
  List<MethodInvocation> commandCalls,
) => [
  if (targetCalls.length != 1 || commandCalls.isNotEmpty)
    'auto-explore must call targetFor exactly once and never commandFor',
];

List<String> _autoExploreTargetArgumentViolations(
  List<MethodInvocation> targetCalls,
) => [
  if (targetCalls.length == 1 &&
      !_sameStringMap(_autoExploreArguments(targetCalls.single), const {
        'unit': 'unit',
        'mapData': 'mapData',
        'units': 'knownUnits',
        'fogOfWar': 'movement.fogOfWar',
        'canEnterTile': 'canEnterTile',
      }))
    'targetFor must receive only actor-known units and bounded inputs',
];

List<String> _autoExploreExactInvocationViolations({
  required List<MethodInvocation> calls,
  required Map<String, String> expectedArguments,
  required String message,
}) {
  if (calls.length != 1) return [message];
  if (!_sameStringMap(_autoExploreArguments(calls.single), expectedArguments)) {
    return [message];
  }
  return const [];
}

Set<String> _autoExploreImportUris(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  return {
    for (final directive in unit.directives.whereType<ImportDirective>())
      ?directive.uri.stringValue,
  };
}

Set<String> _autoExploreNamedTypes(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  return {
    for (final node in _autoExploreDescendants(unit).whereType<NamedType>())
      node.name.lexeme,
  };
}

List<MethodInvocation> _autoExploreCalls(CompilationUnit unit, String name) =>
    _autoExploreDescendants(unit)
        .whereType<MethodInvocation>()
        .where((call) => call.methodName.name == name)
        .toList(growable: false);

Map<String, String> _autoExploreArguments(MethodInvocation call) => {
  for (final argument
      in call.argumentList.arguments.whereType<NamedExpression>())
    argument.name.label.name: argument.expression.toSource(),
};

bool _autoExploreOwnsUnmodifiableEvents(ConstructorDeclaration? constructor) {
  if (constructor == null) return false;
  final creations = _autoExploreDescendants(constructor)
      .whereType<InstanceCreationExpression>()
      .where(
        (creation) =>
            creation.constructorName.type.toSource() == 'List<GameEvent>' &&
            creation.constructorName.name?.name == 'unmodifiable',
      )
      .toList(growable: false);
  if (creations.length != 1) return false;
  final arguments = creations.single.argumentList.arguments;
  return arguments.length == 1 &&
      arguments.single is SimpleIdentifier &&
      (arguments.single as SimpleIdentifier).name == 'events';
}

Iterable<AstNode> _autoExploreDescendants(AstNode node) sync* {
  yield node;
  for (final child in node.childEntities.whereType<AstNode>()) {
    yield* _autoExploreDescendants(child);
  }
}
