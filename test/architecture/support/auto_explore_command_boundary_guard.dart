part of 'movement_command_boundary_guard.dart';

const autoExplorePhasePath =
    '${movementLibraryPath}auto_explore_command_phase.dart';
const autoExploreStatePath =
    '${movementLibraryPath}auto_explore_command_state.dart';
const autoExploreResultPath =
    '${movementLibraryPath}auto_explore_command_result.dart';
const autoExploreGuardPath =
    '${movementLibraryPath}auto_explore_command_guard.dart';
const autoExploreResolverPath = movementAutoExploreKernelPath;
const autoExplorePersistentAdapterPath =
    '${movementLibraryPath}persistent_auto_explore_command_resolver.dart';
const autoExplorePlannerDependencyPath =
    '${movementLibraryPath}scout_auto_explore_planner.dart';
const autoExploreTargetDependencyPath =
    '${movementLibraryPath}scout_auto_explore_target.dart';
const autoExploreDiagnosticWorkloadPath =
    'tool/performance/auto_explore_workload.dart';
const autoExploreLocalCallSite =
    'lib/game/domain/reducer/movement/movement_reducer_auto_explore.dart';
const autoExploreServerCallSite =
    'server/lib/src/multiplayer/server_command_reducer_auto_explore.dart';
const autoExploreTurnContinuationCallSite =
    'packages/aonw_core/lib/game/domain/turn/movement/'
    'turn_auto_explore_advancer.dart';

const _autoExploreResultFields = {
  'accepted': 'bool',
  'reason': 'String?',
  'units': 'List<GameUnit>',
  'fogOfWar': 'FogOfWarState',
  'diplomacy': 'DiplomacyState',
  'interaction': 'PersistedInteractionState',
  'events': 'List<GameEvent>',
  'execution': 'MovementCommandExecution?',
};

const _autoExploreAcceptedParameters = [
  _ParameterShape('units', 'List<GameUnit>', required: true),
  _ParameterShape('fogOfWar', 'FogOfWarState', required: true),
  _ParameterShape('diplomacy', 'DiplomacyState', required: true),
  _ParameterShape('interaction', 'PersistedInteractionState', required: true),
  _ParameterShape('events', 'Iterable<GameEvent>', defaultValue: 'const []'),
  _ParameterShape('execution', 'MovementCommandExecution?'),
];

const _autoExploreRejectedParameters = [
  _ParameterShape('units', 'List<GameUnit>', required: true),
  _ParameterShape('fogOfWar', 'FogOfWarState', required: true),
  _ParameterShape('diplomacy', 'DiplomacyState', required: true),
  _ParameterShape('interaction', 'PersistedInteractionState', required: true),
  _ParameterShape('reason', 'String?', required: true),
];

const _autoExploreOwnedParameters = [
  _ParameterShape('accepted', 'bool', required: true),
  _ParameterShape('reason', 'String?', required: true),
  _ParameterShape('units', 'List<GameUnit>', required: true),
  _ParameterShape('fogOfWar', 'FogOfWarState', required: true),
  _ParameterShape('diplomacy', 'DiplomacyState', required: true),
  _ParameterShape('interaction', 'PersistedInteractionState', required: true),
  _ParameterShape('events', 'List<GameEvent>', required: true),
  _ParameterShape('execution', 'MovementCommandExecution?', required: true),
];

const _autoExploreResolveParameters = [
  _ParameterShape('state', 'AutoExploreCommandState', required: true),
  _ParameterShape('command', 'AutoExploreUnitCommand', required: true),
  _ParameterShape('actorPlayerId', 'String', required: true),
  _ParameterShape('mapData', 'MapTraversalView', required: true),
  _ParameterShape('phase', 'AutoExploreCommandPhase', required: true),
  _ParameterShape('canAct', 'bool', defaultValue: 'true'),
];

const _persistentAutoExploreResultFields = {
  'accepted': 'bool',
  'state': 'PersistentGameState',
  'events': 'List<GameEvent>',
  'execution': 'MovementCommandExecution?',
  'reason': 'String?',
};

const _persistentAutoExploreResultParameters = [
  _ParameterShape('accepted', 'bool', required: true),
  _ParameterShape('state', 'PersistentGameState', required: true),
  _ParameterShape('events', 'List<GameEvent>', defaultValue: 'const []'),
  _ParameterShape('execution', 'MovementCommandExecution?'),
  _ParameterShape('reason', 'String?'),
];

const _persistentAutoExploreResolveParameters = [
  _ParameterShape('state', 'PersistentGameState', required: true),
  _ParameterShape('command', 'AutoExploreUnitCommand', required: true),
  _ParameterShape('actorPlayerId', 'String', required: true),
  _ParameterShape('mapData', 'MapTraversalView', required: true),
  _ParameterShape('phase', 'AutoExploreCommandPhase', required: true),
  _ParameterShape('canAct', 'bool', defaultValue: 'true'),
];

Map<String, String> autoExploreRuntimeSources(Map<String, String> sources) => {
  for (final entry in sources.entries)
    if (entry.key != autoExploreDiagnosticWorkloadPath) entry.key: entry.value,
};

List<String> autoExplorePublicApiViolations(Map<String, String> sources) => [
  ...autoExplorePhaseShapeViolations(sources[autoExplorePhasePath]),
  ..._dataClassViolations(
    sources[autoExploreStatePath],
    className: 'AutoExploreCommandState',
    expectedFields: const {
      'movement': 'MovementCommandState',
      'interaction': 'PersistedInteractionState',
    },
    expectedConstructors: const {
      '': [
        _ParameterShape('movement', 'MovementCommandState', required: true),
        _ParameterShape(
          'interaction',
          'PersistedInteractionState',
          required: true,
        ),
      ],
    },
    expectedPublicMethods: const {},
  ),
  ...autoExploreResultShapeViolations(sources[autoExploreResultPath]),
  ...autoExploreGuardShapeViolations(sources[autoExploreGuardPath]),
  ...autoExploreResolverShapeViolations(sources[autoExploreResolverPath]),
  ...autoExplorePersistentAdapterShapeViolations(
    sources[autoExplorePersistentAdapterPath],
  ),
];

List<String> autoExplorePhaseShapeViolations(String? source) {
  if (source == null) return const ['auto-explore phase must exist'];
  final unit = parseString(content: source, path: autoExplorePhasePath).unit;
  final enums = unit.declarations.whereType<EnumDeclaration>().where(
    (declaration) =>
        declaration.namePart.typeName.lexeme == 'AutoExploreCommandPhase',
  );
  final phase = enums.length == 1 ? enums.single : null;
  final members = phase?.body.members ?? const <ClassMember>[];
  final policy = members.length == 1 && members.single is MethodDeclaration
      ? members.single as MethodDeclaration
      : null;
  return [
    if (unit.declarations.length != 1 || phase == null)
      'auto-explore phase file must declare only its enum',
    if (phase == null ||
        !_sameList(
          phase.body.constants
              .map((constant) => constant.name.lexeme)
              .toList(growable: false),
          const ['direct', 'continuation'],
        ))
      'AutoExploreCommandPhase must expose direct then continuation',
    if (!_isExactContinuationPolicy(policy))
      'AutoExploreCommandPhase must contain only the reviewed continuation '
          'policy getter',
  ];
}

bool _isExactContinuationPolicy(MethodDeclaration? policy) {
  if (policy == null ||
      policy.name.lexeme != 'isContinuation' ||
      !policy.isGetter ||
      policy.isStatic ||
      policy.returnType?.toSource() != 'bool') {
    return false;
  }
  final body = policy.body;
  if (body is! ExpressionFunctionBody) return false;
  final expression = body.expression;
  return expression is BinaryExpression &&
      expression.operator.lexeme == '==' &&
      expression.leftOperand is ThisExpression &&
      expression.rightOperand is SimpleIdentifier &&
      (expression.rightOperand as SimpleIdentifier).name == 'continuation';
}

List<String> autoExploreResultShapeViolations(String? source) {
  if (source == null) return const ['auto-explore result must exist'];
  final unit = parseString(content: source, path: autoExploreResultPath).unit;
  final result = _singleClass(unit, 'AutoExploreCommandResult');
  final accepted = _singleConstructor(result, 'accepted');
  final rejected = _singleConstructor(result, 'rejected');
  final owned = _singleConstructor(result, '_owned');
  return [
    ..._autoExploreResultDeclarationViolations(unit, result),
    ..._autoExploreAcceptedResultViolations(accepted),
    ..._autoExploreRejectedResultViolations(rejected),
    ..._autoExploreOwnedResultViolations(owned),
  ];
}

List<String> _autoExploreResultDeclarationViolations(
  CompilationUnit unit,
  ClassDeclaration? result,
) => [
  if (!_hasExactTopLevelClasses(unit, const {'AutoExploreCommandResult'}))
    'auto-explore result file must declare only its result class',
  if (!_isOnlyFinalClass(result))
    'AutoExploreCommandResult must remain a final class',
  if (!_hasExactFinalFields(result, _autoExploreResultFields))
    'AutoExploreCommandResult must expose its exact immutable fields',
  if (!_sameSet(_constructorNames(result), const {
    'accepted',
    'rejected',
    '_owned',
  }))
    'AutoExploreCommandResult must keep its exact constructors',
  if (_publicMethodNames(result).isNotEmpty)
    'AutoExploreCommandResult must not expose public methods',
];

List<String> _autoExploreAcceptedResultViolations(
  ConstructorDeclaration? accepted,
) => [
  if (accepted == null) 'accepted result constructor must exist',
  if (accepted?.factoryKeyword == null)
    'accepted result constructor must remain a factory',
  if (accepted?.constKeyword != null)
    'accepted result constructor must not claim const ownership',
  if (accepted != null &&
      !_hasExactNamedParameters(accepted, _autoExploreAcceptedParameters))
    'accepted result must expose the exact owned-output contract',
  if (!_autoExploreOwnsUnmodifiableEvents(accepted))
    'accepted result must own a defensive unmodifiable event list',
];

List<String> _autoExploreRejectedResultViolations(
  ConstructorDeclaration? rejected,
) => [
  if (rejected == null) 'rejected result constructor must exist',
  if (rejected?.constKeyword == null)
    'rejected result constructor must remain const',
  if (rejected?.factoryKeyword != null)
    'rejected result constructor must not become a factory',
  if (rejected != null &&
      !_hasExactNamedParameters(
        rejected,
        _autoExploreRejectedParameters,
        inferredFieldTypes: _autoExploreResultFields,
      ))
    'rejected result must expose the exact borrowed rollback contract',
];

List<String> _autoExploreOwnedResultViolations(ConstructorDeclaration? owned) =>
    [
      if (owned == null) 'private owned result constructor must exist',
      if (owned?.constKeyword == null)
        'private owned result constructor must remain const',
      if (owned != null &&
          !_hasExactNamedParameters(
            owned,
            _autoExploreOwnedParameters,
            inferredFieldTypes: _autoExploreResultFields,
          ))
        'private owned result constructor must initialize the exact field set',
    ];

List<String> autoExploreGuardShapeViolations(String? source) {
  if (source == null) return const ['auto-explore guard must exist'];
  final unit = parseString(content: source, path: autoExploreGuardPath).unit;
  final aliases = unit.declarations.whereType<GenericTypeAlias>().where(
    (alias) => alias.name.lexeme == 'AutoExploreCommandGuardResult',
  );
  final alias = aliases.length == 1 ? aliases.single : null;
  final guard = _singleClass(unit, 'AutoExploreCommandGuard');
  final validate = _singleMethod(guard, 'validate');
  return [
    ..._autoExploreGuardDeclarationViolations(unit, alias, guard),
    ..._autoExploreGuardMethodViolations(validate),
  ];
}

List<String> _autoExploreGuardDeclarationViolations(
  CompilationUnit unit,
  GenericTypeAlias? alias,
  ClassDeclaration? guard,
) => [
  ..._autoExploreGuardFileViolations(unit, alias, guard),
  ..._autoExploreGuardClassViolations(guard),
];

List<String> _autoExploreGuardFileViolations(
  CompilationUnit unit,
  GenericTypeAlias? alias,
  ClassDeclaration? guard,
) => [
  if (unit.declarations.length != 2)
    'auto-explore guard file must have exactly two declarations',
  if (alias == null) 'auto-explore guard file must declare its result alias',
  if (guard == null) 'auto-explore guard file must declare its guard class',
  if (alias?.type.toSource() !=
      '({int? unitIndex, GameUnit? unit, String? reason})')
    'AutoExploreCommandGuardResult must expose its exact record shape',
];

List<String> _autoExploreGuardClassViolations(ClassDeclaration? guard) => [
  if (guard?.abstractKeyword == null || guard?.finalKeyword == null)
    'AutoExploreCommandGuard must remain abstract final',
  if (guard?.extendsClause != null ||
      guard?.withClause != null ||
      guard?.implementsClause != null)
    'AutoExploreCommandGuard must not inherit or implement',
  if (!_hasExactFinalFields(guard, const {}))
    'AutoExploreCommandGuard must not own fields',
  if (_constructorNames(guard).isNotEmpty)
    'AutoExploreCommandGuard must not expose constructors',
  if (!_sameSet(_publicMethodNames(guard), const {'method:validate'}))
    'AutoExploreCommandGuard must expose only validate',
];

List<String> _autoExploreGuardMethodViolations(MethodDeclaration? validate) => [
  if (validate == null) 'AutoExploreCommandGuard.validate must exist',
  if (validate?.isStatic != true)
    'AutoExploreCommandGuard.validate must remain static',
  if (validate?.returnType?.toSource() != 'AutoExploreCommandGuardResult')
    'AutoExploreCommandGuard.validate must return its guard record',
  if (validate != null &&
      !_hasExactNamedParameters(validate, const [
        _ParameterShape('state', 'AutoExploreCommandState', required: true),
        _ParameterShape('command', 'AutoExploreUnitCommand', required: true),
        _ParameterShape('actorPlayerId', 'String', required: true),
        _ParameterShape('mapData', 'MapTraversalView', required: true),
        _ParameterShape('canAct', 'bool', required: true),
      ]))
    'AutoExploreCommandGuard.validate must expose its exact bounded API',
];

List<String> autoExploreResolverShapeViolations(String? source) {
  if (source == null) return const ['auto-explore resolver must exist'];
  final unit = parseString(content: source, path: autoExploreResolverPath).unit;
  final resolver = _singleClass(unit, 'AutoExploreCommandResolver');
  final constructor = _singleConstructor(resolver, '');
  final resolve = _singleMethod(resolver, 'resolve');
  return [
    if (!_hasExactTopLevelClasses(unit, const {'AutoExploreCommandResolver'}))
      'auto-explore resolver file must declare only its resolver',
    if (!_isOnlyFinalClass(resolver) ||
        !_hasExactFinalFields(resolver, const {
          'fogOfWarService': 'FogOfWarService',
        }) ||
        !_sameSet(_constructorNames(resolver), const {''}) ||
        !_sameSet(_publicMethodNames(resolver), const {'method:resolve'}))
      'AutoExploreCommandResolver must expose only its reviewed API',
    if (constructor == null ||
        constructor.constKeyword == null ||
        !_hasExactNamedParameters(
          constructor,
          const [
            _ParameterShape(
              'fogOfWarService',
              'FogOfWarService',
              defaultValue: 'const FogOfWarService()',
            ),
          ],
          inferredFieldTypes: const {'fogOfWarService': 'FogOfWarService'},
        ))
      'AutoExploreCommandResolver constructor must expose only fog service',
    if (resolve == null ||
        resolve.isStatic ||
        resolve.returnType?.toSource() != 'AutoExploreCommandResult' ||
        !_hasExactNamedParameters(resolve, _autoExploreResolveParameters))
      'AutoExploreCommandResolver.resolve must expose its exact contract',
  ];
}

List<String> autoExplorePersistentAdapterShapeViolations(String? source) {
  if (source == null) {
    return const ['persistent auto-explore adapter must exist'];
  }
  final unit = parseString(
    content: source,
    path: autoExplorePersistentAdapterPath,
  ).unit;
  final result = _singleClass(unit, 'PersistentAutoExploreCommandResult');
  final resolver = _singleClass(unit, 'PersistentAutoExploreCommandResolver');
  final resultConstructor = _singleConstructor(result, '');
  final resolverConstructor = _singleConstructor(resolver, '');
  final resolve = _singleMethod(resolver, 'resolve');
  return [
    ..._persistentAutoExploreFileViolations(unit),
    ..._persistentAutoExploreResultViolations(result, resultConstructor),
    ..._persistentAutoExploreResolverViolations(resolver),
    ..._persistentAutoExploreConstructorViolations(resolverConstructor),
    ..._persistentAutoExploreResolveViolations(resolve),
  ];
}

List<String> _persistentAutoExploreFileViolations(CompilationUnit unit) => [
  if (!_hasExactTopLevelClasses(unit, const {
    'PersistentAutoExploreCommandResult',
    'PersistentAutoExploreCommandResolver',
  }))
    'persistent auto-explore file must declare only result and resolver',
];

List<String> _persistentAutoExploreResultViolations(
  ClassDeclaration? result,
  ConstructorDeclaration? constructor,
) => [
  if (!_isOnlyFinalClass(result))
    'PersistentAutoExploreCommandResult must remain final',
  if (!_hasExactFinalFields(result, _persistentAutoExploreResultFields))
    'PersistentAutoExploreCommandResult must expose exact immutable fields',
  if (!_sameSet(_constructorNames(result), const {''}) ||
      _publicMethodNames(result).isNotEmpty)
    'PersistentAutoExploreCommandResult must expose only its constructor',
  if (constructor == null || constructor.constKeyword == null)
    'PersistentAutoExploreCommandResult constructor must remain const',
  if (constructor != null &&
      !_hasExactNamedParameters(
        constructor,
        _persistentAutoExploreResultParameters,
        inferredFieldTypes: _persistentAutoExploreResultFields,
      ))
    'PersistentAutoExploreCommandResult constructor must keep its contract',
];

List<String> _persistentAutoExploreResolverViolations(
  ClassDeclaration? resolver,
) => [
  if (!_isOnlyFinalClass(resolver))
    'PersistentAutoExploreCommandResolver must remain final',
  if (!_hasExactFinalFields(resolver, const {
    'fogOfWarService': 'FogOfWarService',
  }))
    'PersistentAutoExploreCommandResolver must own only fog service',
  if (!_sameSet(_constructorNames(resolver), const {''}))
    'PersistentAutoExploreCommandResolver must keep one constructor',
  if (!_sameSet(_publicMethodNames(resolver), const {'method:resolve'}))
    'PersistentAutoExploreCommandResolver must expose only resolve',
];

List<String> _persistentAutoExploreConstructorViolations(
  ConstructorDeclaration? constructor,
) => [
  if (constructor == null || constructor.constKeyword == null)
    'persistent adapter constructor must remain const',
  if (constructor != null &&
      !_hasExactNamedParameters(
        constructor,
        const [
          _ParameterShape(
            'fogOfWarService',
            'FogOfWarService',
            defaultValue: 'const FogOfWarService()',
          ),
        ],
        inferredFieldTypes: const {'fogOfWarService': 'FogOfWarService'},
      ))
    'persistent adapter constructor must expose only fog service',
];

List<String> _persistentAutoExploreResolveViolations(
  MethodDeclaration? resolve,
) => [
  if (resolve == null || resolve.isStatic)
    'persistent adapter resolve must remain an instance method',
  if (resolve?.returnType?.toSource() != 'PersistentAutoExploreCommandResult')
    'persistent adapter resolve must return its exact result',
  if (resolve != null &&
      !_hasExactNamedParameters(
        resolve,
        _persistentAutoExploreResolveParameters,
      ))
    'persistent adapter resolve must expose its exact bounded contract',
];
