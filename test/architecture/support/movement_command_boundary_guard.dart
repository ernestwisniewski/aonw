import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

part 'auto_explore_command_boundary_guard.dart';
part 'auto_explore_command_semantic_guard.dart';
part 'movement_path_contract_guard.dart';

const movementLibraryPath = 'packages/aonw_core/lib/game/domain/movement/';
const movementKernelPath =
    '${movementLibraryPath}movement_command_resolver.dart';
const movementAutoExploreKernelPath =
    '${movementLibraryPath}auto_explore_command_resolver.dart';
const movementStatePath = '${movementLibraryPath}movement_command_state.dart';
const movementResultPath = '${movementLibraryPath}movement_command_result.dart';
const movementExecutionPath =
    '${movementLibraryPath}movement_command_execution.dart';
const movementVisibilityPath =
    '${movementLibraryPath}unit_movement_visibility_rules.dart';
const movementVisibilityModePath =
    '${movementLibraryPath}movement_command_visibility_mode.dart';
const movementPersistentAdapterPath =
    '${movementLibraryPath}persistent_move_unit_resolver.dart';
const movementDomainAdapterPath =
    '${movementLibraryPath}domain_move_unit_resolver.dart';
const movementLocalCallSite =
    'lib/game/domain/reducer/movement/movement_reducer_direct_move.dart';
const movementLegacyVisibilityPath =
    'lib/game/domain/movement/unit_movement_visibility_rules.dart';
const movementServerCallSite =
    'server/lib/src/multiplayer/server_command_reducer_movement.dart';
const movementServerReducerPath =
    'server/lib/src/multiplayer/server_command_reducer.dart';
const movementMctsConsumerPath =
    'packages/aonw_core/lib/ai/mcts/mcts_simulator.dart';
const movementMctsProjectionConsumerPath =
    'packages/aonw_core/lib/ai/mcts/'
    'mcts_simulated_movement_command_applier.dart';
const movementEconomyConsumerPath =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';
const movementDiagnosticWorkloadPath =
    'tool/performance/movement_command_workload.dart';

Map<String, String> movementRuntimeSources(Map<String, String> sources) => {
  for (final entry in sources.entries)
    if (entry.key != movementDiagnosticWorkloadPath) entry.key: entry.value,
};

const _stateFields = {
  'units': 'List<GameUnit>',
  'cities': 'List<GameCity>',
  'fogOfWar': 'FogOfWarState',
  'diplomacy': 'DiplomacyState',
  'playerIds': 'Iterable<String>',
};

const _resultFields = {
  'accepted': 'bool',
  'reason': 'String?',
  'units': 'List<GameUnit>',
  'fogOfWar': 'FogOfWarState',
  'diplomacy': 'DiplomacyState',
  'events': 'List<GameEvent>',
  'execution': 'MovementCommandExecution?',
};

const _executionFields = {
  'unitId': 'String',
  'fromCol': 'int',
  'fromRow': 'int',
  'steps': 'List<UnitMovementStep>',
};

const _resolverParameters = [
  _ParameterShape('state', 'MovementCommandState', required: true),
  _ParameterShape('command', 'MoveUnitCommand', required: true),
  _ParameterShape('actorPlayerId', 'String', required: true),
  _ParameterShape('mapData', 'MapTraversalView', required: true),
  _ParameterShape('canAct', 'bool', defaultValue: 'true'),
  _ParameterShape(
    'visibilityMode',
    'MovementCommandVisibilityMode',
    defaultValue: 'MovementCommandVisibilityMode.authoritative',
  ),
  _ParameterShape(
    'pathConstraints',
    'MovementCommandPathConstraints',
    defaultValue: 'const MovementCommandPathConstraints.none()',
  ),
];

List<String> movementResolverShapeViolations(String? source) {
  if (source == null) return const ['movement resolver source must exist'];
  final unit = parseString(content: source, path: movementKernelPath).unit;
  final resolver = _singleClass(unit, 'MovementCommandResolver');
  final constructor = _singleConstructor(resolver, '');
  final resolve = _singleMethod(resolver, 'resolve');
  return [
    if (!_hasExactTopLevelClasses(unit, const {'MovementCommandResolver'}))
      'movement resolver file must declare only MovementCommandResolver',
    if (!_isOnlyFinalClass(resolver))
      'MovementCommandResolver must be a final class',
    if (!_hasExactFinalFields(resolver, const {
      'fogOfWarService': 'FogOfWarService',
    }))
      'MovementCommandResolver must own only final fogOfWarService',
    if (!_sameSet(_constructorNames(resolver), const {''}) ||
        !_sameSet(_publicMethodNames(resolver), const {'method:resolve'}))
      'MovementCommandResolver must expose only its constructor and resolve',
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
      'MovementCommandResolver constructor must expose only fogOfWarService',
    if (resolve == null ||
        resolve.isStatic ||
        resolve.returnType?.toSource() != 'MovementCommandResult' ||
        !_hasExactNamedParameters(resolve, _resolverParameters))
      'resolve must expose the exact bounded movement command contract',
  ];
}

List<String> movementStateShapeViolations(String? source) =>
    _dataClassViolations(
      source,
      className: 'MovementCommandState',
      expectedFields: _stateFields,
      expectedConstructors: const {
        '': [
          _ParameterShape('units', 'List<GameUnit>', required: true),
          _ParameterShape('cities', 'List<GameCity>', required: true),
          _ParameterShape('fogOfWar', 'FogOfWarState', required: true),
          _ParameterShape('diplomacy', 'DiplomacyState', required: true),
          _ParameterShape('playerIds', 'Iterable<String>', required: true),
        ],
      },
      expectedPublicMethods: const {},
    );

List<String> movementResultShapeViolations(String? source) =>
    _dataClassViolations(
      source,
      className: 'MovementCommandResult',
      expectedFields: _resultFields,
      expectedConstructors: const {
        'accepted': [
          _ParameterShape('units', 'List<GameUnit>', required: true),
          _ParameterShape('fogOfWar', 'FogOfWarState', required: true),
          _ParameterShape('diplomacy', 'DiplomacyState', required: true),
          _ParameterShape(
            'events',
            'List<GameEvent>',
            defaultValue: 'const []',
          ),
          _ParameterShape('execution', 'MovementCommandExecution?'),
        ],
        'rejected': [
          _ParameterShape('units', 'List<GameUnit>', required: true),
          _ParameterShape('fogOfWar', 'FogOfWarState', required: true),
          _ParameterShape('diplomacy', 'DiplomacyState', required: true),
          _ParameterShape('reason', 'String?', required: true),
        ],
      },
      expectedPublicMethods: const {},
    );

List<String> movementExecutionShapeViolations(String? source) {
  if (source == null) return const ['movement execution source must exist'];
  final unit = parseString(content: source, path: movementExecutionPath).unit;
  final execution = _singleClass(unit, 'MovementCommandExecution');
  final constructor = _singleUnnamedConstructor(execution);
  return [
    if (!_hasExactTopLevelClasses(unit, const {'MovementCommandExecution'}))
      'movement execution file must declare only MovementCommandExecution',
    if (!_isOnlyFinalClass(execution))
      'MovementCommandExecution must be a final class',
    if (!_hasExactFinalFields(execution, _executionFields))
      'MovementCommandExecution must expose only immutable path fields',
    if (!_sameSet(_constructorNames(execution), const {''}) ||
        !_sameSet(_publicMethodNames(execution), const {'getter:destination'}))
      'MovementCommandExecution must expose only destination as derived API',
    if (constructor == null ||
        !_hasExactNamedParameters(constructor, const [
          _ParameterShape('unitId', 'String', required: true),
          _ParameterShape('fromCol', 'int', required: true),
          _ParameterShape('fromRow', 'int', required: true),
          _ParameterShape(
            'steps',
            'Iterable<UnitMovementStep>',
            required: true,
          ),
        ], inferredFieldTypes: _executionFields))
      'MovementCommandExecution constructor must require the exact path input',
    if (!_ownsUnmodifiableSteps(constructor))
      'MovementCommandExecution must own an unmodifiable copy of steps',
  ];
}

List<String> movementVisibilityModeShapeViolations(String? source) {
  if (source == null) return const ['movement visibility mode must exist'];
  final unit = parseString(
    content: source,
    path: movementVisibilityModePath,
  ).unit;
  final matches = unit.declarations.whereType<EnumDeclaration>().where(
    (declaration) =>
        declaration.namePart.typeName.lexeme == 'MovementCommandVisibilityMode',
  );
  final mode = matches.length == 1 ? matches.single : null;
  final constants =
      mode?.body.constants
          .map((constant) => constant.name.lexeme)
          .toList(growable: false) ??
      const <String>[];
  final publicMembers = {
    for (final member
        in mode?.body.members.whereType<MethodDeclaration>() ??
            const <MethodDeclaration>[])
      if (!member.name.lexeme.startsWith('_'))
        '${member.isGetter ? 'getter' : 'method'}:${member.name.lexeme}',
  };
  return [
    if (unit.declarations.length != 1 || mode == null)
      'movement visibility mode file must declare only its enum',
    if (mode == null ||
        !_sameList(constants, const [
          'authoritative',
          'unrestrictedPathing',
          'unrestricted',
        ]))
      'MovementCommandVisibilityMode must expose the three exact modes',
    if (!_sameSet(publicMembers, const {
      'getter:ignoresPathingFog',
      'getter:ignoresDynamicFog',
    }))
      'visibility mode must expose only its two policy getters',
    if (mode?.body.members.any((member) => member is! MethodDeclaration) ==
        true)
      'visibility mode must not add fields or constructors',
  ];
}

List<String> _dataClassViolations(
  String? source, {
  required String className,
  required Map<String, String> expectedFields,
  required Map<String, List<_ParameterShape>> expectedConstructors,
  required Set<String> expectedPublicMethods,
}) {
  if (source == null) return ['$className source must exist'];
  final unit = parseString(content: source).unit;
  final declaration = _singleClass(unit, className);
  return [
    if (!_hasExactTopLevelClasses(unit, {className}))
      '$className file must declare only $className',
    if (!_isOnlyFinalClass(declaration)) '$className must be a final class',
    if (!_hasExactFinalFields(declaration, expectedFields))
      '$className must expose its exact immutable field set',
    if (!_sameSet(
          _constructorNames(declaration),
          expectedConstructors.keys.toSet(),
        ) ||
        !_sameSet(_publicMethodNames(declaration), expectedPublicMethods))
      '$className must not widen its public API',
    ..._constructorContractViolations(
      declaration,
      className: className,
      expectedFields: expectedFields,
      expectedConstructors: expectedConstructors,
    ),
  ];
}

List<String> _constructorContractViolations(
  ClassDeclaration? declaration, {
  required String className,
  required Map<String, String> expectedFields,
  required Map<String, List<_ParameterShape>> expectedConstructors,
}) {
  final violations = <String>[];
  for (final entry in expectedConstructors.entries) {
    final constructor = _singleConstructor(declaration, entry.key);
    if (constructor == null) {
      violations.add(
        '$className.${entry.key} constructor must be declared exactly once',
      );
    } else if (constructor.constKeyword == null ||
        !_hasExactNamedParameters(
          constructor,
          entry.value,
          inferredFieldTypes: expectedFields,
        )) {
      violations.add(
        '$className.${entry.key} constructor must expose its exact contract',
      );
    }
  }
  return violations;
}

bool _hasExactTopLevelClasses(CompilationUnit unit, Set<String> expected) {
  if (unit.declarations.length != expected.length) return false;
  final classes = unit.declarations.whereType<ClassDeclaration>().toList();
  return classes.length == expected.length &&
      _sameSet({
        for (final declaration in classes) declaration.namePart.typeName.lexeme,
      }, expected);
}

bool _isOnlyFinalClass(ClassDeclaration? declaration) {
  return declaration != null &&
      declaration.finalKeyword != null &&
      declaration.abstractKeyword == null &&
      declaration.baseKeyword == null &&
      declaration.interfaceKeyword == null &&
      declaration.mixinKeyword == null &&
      declaration.sealedKeyword == null &&
      declaration.extendsClause == null &&
      declaration.withClause == null &&
      declaration.implementsClause == null &&
      declaration.namePart.typeParameters == null;
}

bool _hasExactFinalFields(
  ClassDeclaration? declaration,
  Map<String, String> expected,
) {
  if (declaration == null) return false;
  final actual = <String, String>{};
  for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
    if (field.isStatic || !field.fields.isFinal || field.fields.isLate) {
      return false;
    }
    final type = field.fields.type?.toSource();
    if (type == null) return false;
    for (final variable in field.fields.variables) {
      if (actual.containsKey(variable.name.lexeme)) return false;
      actual[variable.name.lexeme] = type;
    }
  }
  return _sameStringMap(actual, expected);
}

Set<String> _constructorNames(ClassDeclaration? declaration) {
  if (declaration == null) return const {};
  return {
    for (final constructor
        in declaration.body.members.whereType<ConstructorDeclaration>())
      constructor.name?.lexeme ?? '',
  };
}

Set<String> _publicMethodNames(ClassDeclaration? declaration) {
  if (declaration == null) return const {};
  return {
    for (final method
        in declaration.body.members.whereType<MethodDeclaration>())
      if (!method.name.lexeme.startsWith('_'))
        '${method.isGetter
            ? 'getter'
            : method.isSetter
            ? 'setter'
            : 'method'}:${method.name.lexeme}',
  };
}

bool _ownsUnmodifiableSteps(ConstructorDeclaration? constructor) {
  if (constructor == null) return false;
  final matching = constructor.initializers
      .whereType<ConstructorFieldInitializer>()
      .where((initializer) => initializer.fieldName.name == 'steps')
      .toList();
  return matching.length == 1 &&
      matching.single.expression.toSource() ==
          'List<UnitMovementStep>.unmodifiable(steps)';
}

bool _hasExactNamedParameters(
  dynamic declaration,
  List<_ParameterShape> expected, {
  Map<String, String> inferredFieldTypes = const {},
}) {
  final FormalParameterList? list = switch (declaration) {
    MethodDeclaration(:final parameters) => parameters,
    ConstructorDeclaration(:final parameters) => parameters,
    _ => null,
  };
  final parameters = list?.parameters ?? const <FormalParameter>[];
  if (parameters.length != expected.length) return false;
  for (var index = 0; index < parameters.length; index++) {
    if (!_isNamedParameter(
      parameters[index],
      expected[index],
      inferredFieldTypes: inferredFieldTypes,
    )) {
      return false;
    }
  }
  return true;
}

bool _isNamedParameter(
  FormalParameter parameter,
  _ParameterShape expected, {
  required Map<String, String> inferredFieldTypes,
}) {
  if (parameter is! DefaultFormalParameter || !parameter.isNamed) return false;
  final normalized = parameter.parameter;
  final name = normalized.name?.lexeme;
  final type = switch (normalized) {
    SimpleFormalParameter(:final type) => type,
    FieldFormalParameter(:final type) => type,
    _ => null,
  };
  final typeSource = type?.toSource() ?? inferredFieldTypes[name];
  return name == expected.name &&
      typeSource == expected.type &&
      (normalized.requiredKeyword != null) == expected.required &&
      parameter.defaultValue?.toSource() == expected.defaultValue;
}

ClassDeclaration? _singleClass(CompilationUnit unit, String name) {
  final matches = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
  return matches.length == 1 ? matches.single : null;
}

MethodDeclaration? _singleMethod(ClassDeclaration? declaration, String name) {
  final matches =
      declaration?.body.members.whereType<MethodDeclaration>().where(
        (method) => method.name.lexeme == name,
      ) ??
      const <MethodDeclaration>[];
  return matches.length == 1 ? matches.single : null;
}

ConstructorDeclaration? _singleUnnamedConstructor(
  ClassDeclaration? declaration,
) => _singleConstructor(declaration, '');

ConstructorDeclaration? _singleConstructor(
  ClassDeclaration? declaration,
  String name,
) {
  final matches =
      declaration?.body.members.whereType<ConstructorDeclaration>().where(
        (constructor) => (constructor.name?.lexeme ?? '') == name,
      ) ??
      const <ConstructorDeclaration>[];
  return matches.length == 1 ? matches.single : null;
}

bool _sameStringMap(Map<String, String> left, Map<String, String> right) {
  if (left.length != right.length) return false;
  return left.entries.every((entry) => right[entry.key] == entry.value);
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

bool _sameList(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

final class _ParameterShape {
  const _ParameterShape(
    this.name,
    this.type, {
    this.required = false,
    this.defaultValue,
  });

  final String name;
  final String type;
  final bool required;
  final String? defaultValue;
}
