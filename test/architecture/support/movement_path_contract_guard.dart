part of 'movement_command_boundary_guard.dart';

const movementPathConstraintsPath =
    '${movementLibraryPath}movement_command_path_constraints.dart';
const movementScoutAutoExploreTargetPath =
    '${movementLibraryPath}scout_auto_explore_target.dart';

const _pathConstraintsFields = {'excludedHexes': 'Set<HexCoordinate>'};

List<String> movementPublicApiViolations(Map<String, String> sources) => [
  ...movementResolverShapeViolations(sources[movementKernelPath]),
  ...movementStateShapeViolations(sources[movementStatePath]),
  ...movementResultShapeViolations(sources[movementResultPath]),
  ...movementExecutionShapeViolations(sources[movementExecutionPath]),
  ...movementPathConstraintsShapeViolations(
    sources[movementPathConstraintsPath],
  ),
  ...movementScoutAutoExploreTargetShapeViolations(
    sources[movementScoutAutoExploreTargetPath],
  ),
  ...movementVisibilityModeShapeViolations(sources[movementVisibilityModePath]),
];

List<String> movementPathConstraintsShapeViolations(String? source) {
  if (source == null) return const ['movement path constraints must exist'];
  final unit = parseString(
    content: source,
    path: movementPathConstraintsPath,
  ).unit;
  final constraints = _singleClass(unit, 'MovementCommandPathConstraints');
  final none = _singleConstructor(constraints, 'none');
  final excluding = _singleConstructor(constraints, 'excluding');
  final excludes = _singleMethod(constraints, 'excludes');
  return [
    ..._pathConstraintsDeclarationViolations(unit, constraints),
    ..._pathConstraintsNoneViolations(none),
    ..._pathConstraintsExcludingViolations(excluding),
    ..._pathConstraintsMethodViolations(excludes),
  ];
}

List<String> _pathConstraintsDeclarationViolations(
  CompilationUnit unit,
  ClassDeclaration? constraints,
) => [
  if (!_hasExactTopLevelClasses(unit, const {'MovementCommandPathConstraints'}))
    'movement path constraints file must declare only its value type',
  if (!_isOnlyFinalClass(constraints))
    'MovementCommandPathConstraints must be a final class',
  if (!_hasExactFinalFields(constraints, _pathConstraintsFields))
    'MovementCommandPathConstraints must expose only excludedHexes',
  if (!_sameSet(_constructorNames(constraints), const {'none', 'excluding'}) ||
      !_sameSet(_publicMethodNames(constraints), const {'method:excludes'}))
    'MovementCommandPathConstraints must not widen its public API',
];

List<String> _pathConstraintsNoneViolations(ConstructorDeclaration? none) => [
  if (none == null ||
      none.constKeyword == null ||
      !_hasExactNamedParameters(none, const []))
    'MovementCommandPathConstraints.none must be canonical const',
  if (!_ownsCanonicalEmptyExcludedHexes(none))
    'MovementCommandPathConstraints.none must own the canonical empty set',
];

List<String> _pathConstraintsExcludingViolations(
  ConstructorDeclaration? excluding,
) => [
  if (excluding == null ||
      excluding.constKeyword != null ||
      !_hasExactNamedParameters(excluding, const [
        _ParameterShape(
          'excludedHexes',
          'Iterable<HexCoordinate>',
          required: true,
        ),
      ]))
    'MovementCommandPathConstraints.excluding must require excludedHexes',
  if (!_ownsUnmodifiableExcludedHexes(excluding))
    'MovementCommandPathConstraints must own an unmodifiable exclusion copy',
];

List<String> _pathConstraintsMethodViolations(MethodDeclaration? excludes) => [
  if (excludes == null ||
      excludes.isStatic ||
      excludes.returnType?.toSource() != 'bool' ||
      !_hasExactRequiredPositionalParameters(excludes, const [
        _ParameterShape('col', 'int'),
        _ParameterShape('row', 'int'),
      ]))
    'MovementCommandPathConstraints.excludes must expose exact coordinates',
];

List<String> movementScoutAutoExploreTargetShapeViolations(String? source) {
  return _dataClassViolations(
    source,
    className: 'ScoutAutoExploreTarget',
    expectedFields: const {
      'command': 'MoveUnitCommand',
      'pathConstraints': 'MovementCommandPathConstraints',
    },
    expectedConstructors: const {
      '': [
        _ParameterShape('command', 'MoveUnitCommand', required: true),
        _ParameterShape(
          'pathConstraints',
          'MovementCommandPathConstraints',
          required: true,
        ),
      ],
    },
    expectedPublicMethods: const {},
  );
}

bool _ownsCanonicalEmptyExcludedHexes(ConstructorDeclaration? constructor) {
  if (constructor == null) return false;
  final matching = constructor.initializers
      .whereType<ConstructorFieldInitializer>()
      .where((initializer) => initializer.fieldName.name == 'excludedHexes')
      .toList();
  return matching.length == 1 &&
      matching.single.expression.toSource() == 'const {}';
}

bool _ownsUnmodifiableExcludedHexes(ConstructorDeclaration? constructor) {
  if (constructor == null) return false;
  final matching = constructor.initializers
      .whereType<ConstructorFieldInitializer>()
      .where((initializer) => initializer.fieldName.name == 'excludedHexes')
      .toList();
  return matching.length == 1 &&
      matching.single.expression.toSource() ==
          'Set<HexCoordinate>.unmodifiable(excludedHexes)';
}

bool _hasExactRequiredPositionalParameters(
  MethodDeclaration declaration,
  List<_ParameterShape> expected,
) {
  final parameters = declaration.parameters?.parameters ?? const [];
  if (parameters.length != expected.length) return false;
  for (var index = 0; index < parameters.length; index++) {
    final parameter = parameters[index];
    if (parameter is! SimpleFormalParameter ||
        parameter.name?.lexeme != expected[index].name ||
        parameter.type?.toSource() != expected[index].type) {
      return false;
    }
  }
  return true;
}
