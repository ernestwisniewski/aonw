part of '../game_outcome_boundary_test.dart';

List<String> _canonicalSnapshotFieldViolations(CompilationUnit unit) {
  final application = _singleClass(unit, '_CommandApplication');
  if (application == null) {
    return ['must declare exactly one _CommandApplication class'];
  }
  final fields = <({FieldDeclaration declaration, VariableDeclaration field})>[
    for (final declaration
        in application.body.members.whereType<FieldDeclaration>())
      for (final field in declaration.fields.variables)
        if (field.name.lexeme == 'canonicalSnapshot')
          (declaration: declaration, field: field),
  ];
  if (fields.length != 1) {
    return [
      '_CommandApplication must declare exactly one canonicalSnapshot field',
    ];
  }
  final field = fields.single;
  return [
    if (!field.declaration.fields.isFinal)
      '_CommandApplication.canonicalSnapshot must be final',
    if (field.declaration.fields.type?.toSource() != 'CanonicalGameSnapshot?')
      '_CommandApplication.canonicalSnapshot must have type '
          'CanonicalGameSnapshot?',
  ];
}

Map<String, CompilationUnit> _serverReducerUnits() {
  final root = _unitAt(_serverReducerPath);
  final paths = <String>{_serverReducerPath};
  for (final directive in root.directives.whereType<PartDirective>()) {
    final uri = directive.uri.stringValue;
    expect(uri, isNotNull, reason: 'reducer part URI must be static');
    paths.add(Uri.parse(_serverReducerPath).resolve(uri!).path);
  }
  final sortedPaths = paths.toList()..sort();
  return {for (final path in sortedPaths) path: _unitAt(path)};
}

List<String> _canonicalSnapshotDeclarationViolations(
  Map<String, CompilationUnit> sources,
) {
  var allowedFunctions = 0;
  var otherFunctions = 0;
  var methods = 0;
  var variables = 0;
  var parameters = 0;
  for (final entry in sources.entries) {
    final declarations = _NamedDeclarationCollector('_canonicalSnapshot')
      ..collect(entry.value);
    for (final function in declarations.functions) {
      if (entry.key == _serverTurnsPath && function.parent is CompilationUnit) {
        allowedFunctions++;
      } else {
        otherFunctions++;
      }
    }
    methods += declarations.methods.length;
    variables += declarations.variables.length;
    parameters += declarations.parameters.length;
  }
  return [
    if (allowedFunctions != 1)
      '$_serverTurnsPath must declare exactly one top-level '
          '_canonicalSnapshot function; found $allowedFunctions',
    if (otherFunctions != 0)
      'reducer library must not declare other _canonicalSnapshot '
          'functions; found $otherFunctions',
    if (methods != 0)
      'reducer library must not declare _canonicalSnapshot methods; '
          'found $methods',
    if (variables != 0)
      'reducer library must not declare _canonicalSnapshot variables; '
          'found $variables',
    if (parameters != 0)
      'reducer library must not declare _canonicalSnapshot parameters; '
          'found $parameters',
  ];
}

List<String> _canonicalSnapshotReferenceViolations(
  Map<String, CompilationUnit> sources,
) {
  const allowlist = {
    _serverOutcomePath: {'_acceptedReduction': 1},
  };
  final violations = <String>[];
  final paths = sources.keys.toList()..sort();
  for (final path in paths) {
    final unit = sources[path]!;
    final expectedMethods = allowlist[path] ?? const <String, int>{};
    final expectedTotal = expectedMethods.values.fold<int>(
      0,
      (total, count) => total + count,
    );
    final allReferences = _SymbolReferenceCollector('_canonicalSnapshot')
      ..collect(unit);
    if (allReferences.references.length != expectedTotal) {
      violations.add(
        '$path must contain $expectedTotal _canonicalSnapshot references; '
        'found ${allReferences.references.length}',
      );
    }
    for (final entry in expectedMethods.entries) {
      final method = _singleMethod(unit, entry.key);
      if (method == null) {
        violations.add('$path must declare exactly one ${entry.key} method');
        continue;
      }
      final methodReferences = _SymbolReferenceCollector('_canonicalSnapshot')
        ..collect(method.body);
      if (methodReferences.references.length != entry.value) {
        violations.add(
          '$path::${entry.key} must contain ${entry.value} '
          '_canonicalSnapshot references; found '
          '${methodReferences.references.length}',
        );
      }
    }
  }
  for (final path in allowlist.keys.where(
    (path) => !sources.containsKey(path),
  )) {
    violations.add('$path must be included in the reducer source set');
  }
  return violations;
}

List<String> _canonicalSnapshotProviderViolations(
  Map<String, CompilationUnit> sources,
) {
  const methodName = '_finalizeSimultaneousTurn';
  final turns = sources[_serverTurnsPath];
  if (turns == null) {
    return ['$_serverTurnsPath must be included in the reducer source set'];
  }
  final method = _singleMethod(turns, methodName);
  if (method == null) {
    return ['$_serverTurnsPath must declare exactly one $methodName method'];
  }

  final allArguments = <NamedExpression>[];
  for (final unit in sources.values) {
    final arguments = _NamedArgumentCollector('canonicalSnapshot')
      ..collect(unit);
    allArguments.addAll(arguments.arguments);
  }
  final forwardings = allArguments
      .where(_isAcceptFactoryCanonicalSnapshotForwarding)
      .toList();
  final allProviders = allArguments
      .where((argument) => !forwardings.contains(argument))
      .toList();
  final acceptInvocations = _MethodInvocationCollector('accept')
    ..collect(method.body);
  final methodAccepts = acceptInvocations.invocations.where((invocation) {
    final target = invocation.target;
    return target is SimpleIdentifier && target.name == '_CommandApplication';
  }).toList();
  final methodProviders = [
    for (final invocation in methodAccepts)
      ..._namedArguments(invocation.argumentList, 'canonicalSnapshot'),
  ];

  final violations = <String>[
    if (forwardings.length != 1)
      '_CommandApplication.accept must forward canonicalSnapshot exactly '
          'once; found ${forwardings.length}',
    if (allProviders.length != 1)
      'reducer library must provide canonicalSnapshot to '
          '_CommandApplication.accept exactly once; found '
          '${allProviders.length}',
    if (methodAccepts.length != 1)
      '$methodName must construct exactly one _CommandApplication.accept; '
          'found ${methodAccepts.length}',
    if (methodProviders.length != 1)
      '$methodName must provide canonicalSnapshot to '
          '_CommandApplication.accept exactly once; found '
          '${methodProviders.length}',
  ];
  if (methodProviders.length == 1 &&
      !_isResultSnapshot(methodProviders.single.expression)) {
    violations.add('$methodName must pass canonicalSnapshot: result.snapshot');
  }
  return violations;
}

bool _isResultSnapshot(Expression expression) =>
    expression is PrefixedIdentifier &&
    expression.prefix.name == 'result' &&
    expression.identifier.name == 'snapshot';

bool _isAcceptFactoryCanonicalSnapshotForwarding(NamedExpression argument) {
  final value = argument.expression;
  final creation = argument.parent?.parent;
  final constructor = argument.thisOrAncestorOfType<ConstructorDeclaration>();
  final owner = constructor?.parent?.parent;
  final canonicalSnapshotParameters =
      constructor?.parameters.parameters.where((parameter) {
        final normalized = parameter is DefaultFormalParameter
            ? parameter.parameter
            : parameter;
        return normalized.name?.lexeme == 'canonicalSnapshot';
      }).toList() ??
      const <FormalParameter>[];
  if (value is! SimpleIdentifier ||
      value.name != 'canonicalSnapshot' ||
      creation is! MethodInvocation ||
      creation.target != null ||
      creation.methodName.name != '_CommandApplication' ||
      constructor?.factoryKeyword == null ||
      constructor?.name?.lexeme != 'accept' ||
      owner is! ClassDeclaration ||
      owner.namePart.typeName.lexeme != '_CommandApplication' ||
      canonicalSnapshotParameters.length != 1) {
    return false;
  }
  final body = constructor!.body;
  final creations = _MethodInvocationCollector('_CommandApplication')
    ..collect(body);
  return _factoryBodyReturnsOnly(body, creation) &&
      creations.invocations.length == 1 &&
      identical(creations.invocations.single, creation);
}

bool _factoryBodyReturnsOnly(FunctionBody body, Expression expression) {
  if (body is ExpressionFunctionBody) {
    return identical(body.expression, expression);
  }
  if (body is! BlockFunctionBody || body.block.statements.length != 1) {
    return false;
  }
  final statement = body.block.statements.single;
  return statement is ReturnStatement &&
      identical(statement.expression, expression);
}

List<String> _acceptedReductionCanonicalFlowViolations(CompilationUnit unit) {
  const methodName = '_acceptedReduction';
  final method = _singleMethod(unit, methodName);
  if (method == null) return ['must declare exactly one $methodName method'];

  final violations = <String>[
    if (_methodContractFor(method) !=
        const _MethodContract(
          requiredNamed: _acceptedReductionRequiredParameters,
          optionalNamed: {},
        ))
      '_acceptedReduction must require exactly '
          'match/decodedSnapshot/nextSave/result/mapView',
  ];
  final variables = _NamedVariableCollector('canonicalSnapshot')
    ..collect(method.body);
  if (variables.variables.length != 1) {
    violations.add(
      '$methodName must declare exactly one canonicalSnapshot local variable',
    );
    return violations;
  }
  final initializer = variables.variables.single.initializer;
  if (initializer is! BinaryExpression || initializer.operator.lexeme != '??') {
    violations.add('$methodName canonicalSnapshot must use a lazy ?? fallback');
    return violations;
  }

  if (initializer.leftOperand.toSource() != 'result.canonicalSnapshot') {
    violations.add(
      '$methodName canonicalSnapshot must prefer result.canonicalSnapshot',
    );
  }
  final fallback = initializer.rightOperand;
  if (fallback is! MethodInvocation ||
      fallback.methodName.name != '_canonicalSnapshot') {
    violations.add(
      '$methodName canonicalSnapshot fallback must directly call '
      '_canonicalSnapshot',
    );
  }

  final conversions = _MethodInvocationCollector('_canonicalSnapshot')
    ..collect(method.body);
  if (conversions.invocations.length != 1) {
    violations.add(
      '$methodName must call _canonicalSnapshot exactly once; found '
      '${conversions.invocations.length}',
    );
  } else if (fallback is MethodInvocation &&
      !identical(conversions.invocations.single, fallback)) {
    violations.add(
      '$methodName must call _canonicalSnapshot only as the lazy fallback',
    );
  }

  final outcomes = _MethodInvocationCollector('_gameOutcome')
    ..collect(method.body);
  if (outcomes.invocations.length != 1) {
    violations.add(
      '$methodName must call _gameOutcome exactly once; found '
      '${outcomes.invocations.length}',
    );
    return violations;
  }
  final arguments = outcomes.invocations.single.argumentList;
  final domain = _namedArgument(arguments, 'domain');
  final session = _namedArgument(arguments, 'session');
  if (domain?.toSource() != 'canonicalSnapshot.domain') {
    violations.add('$methodName must pass domain: canonicalSnapshot.domain');
  }
  if (session?.toSource() != 'canonicalSnapshot.session') {
    violations.add('$methodName must pass session: canonicalSnapshot.session');
  }
  return violations;
}

List<String> _serverOutcomeViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_gameOutcome');
  if (method == null) {
    return ['must declare exactly one _gameOutcome method'];
  }
  final contract = _methodContractFor(method);
  final namedTypes = _NamedTypeCollector()..collect(method);
  return [
    if (contract !=
        const _MethodContract(
          requiredNamed: _serverOutcomeRequiredParameters,
          optionalNamed: {},
        ))
      '_gameOutcome must require exactly match/domain/session/mapView with '
          'canonical types',
    for (final type in namedTypes.names.intersection(const {
      'GameSave',
      'PersistentGameState',
    }))
      '_gameOutcome must not reference $type',
  ];
}

_MethodContract _methodContract(
  CompilationUnit unit, {
  required String ownerName,
  required String methodName,
}) {
  final owner = _singleClass(unit, ownerName);
  if (owner == null) return const _MethodContract.missing();
  final methods = owner.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == methodName)
      .toList();
  if (methods.length != 1) return const _MethodContract.missing();
  return _methodContractFor(methods.single);
}

_MethodContract _methodContractFor(MethodDeclaration method) {
  final requiredNamed = <String, String?>{};
  final optionalNamed = <String, String?>{};
  final positional = <String, String?>{};
  for (final parameter
      in method.parameters?.parameters ?? const <FormalParameter>[]) {
    final normalized = parameter is DefaultFormalParameter
        ? parameter.parameter
        : parameter;
    final name = normalized.name?.lexeme ?? '<unnamed>';
    final type = switch (normalized) {
      SimpleFormalParameter(:final type) => type?.toSource(),
      FieldFormalParameter(:final type) => type?.toSource(),
      _ => null,
    };
    if (parameter is DefaultFormalParameter &&
        normalized.requiredKeyword != null) {
      requiredNamed[name] = type;
    } else if (parameter is DefaultFormalParameter && parameter.isNamed) {
      optionalNamed[name] = type;
    } else {
      positional[name] = type;
    }
  }
  return _MethodContract(
    requiredNamed: requiredNamed,
    optionalNamed: optionalNamed,
    positional: positional,
  );
}

Expression? _namedArgument(ArgumentList arguments, String name) {
  final matches = _namedArguments(arguments, name);
  return matches.length == 1 ? matches.single.expression : null;
}

List<NamedExpression> _namedArguments(ArgumentList arguments, String name) =>
    arguments.arguments
        .whereType<NamedExpression>()
        .where((argument) => argument.name.label.name == name)
        .toList();

ClassDeclaration? _singleClass(CompilationUnit unit, String name) {
  final declarations = unit.declarations
      .whereType<ClassDeclaration>()
      .where((declaration) => declaration.namePart.typeName.lexeme == name)
      .toList();
  return declarations.length == 1 ? declarations.single : null;
}

MethodDeclaration? _singleMethod(CompilationUnit unit, String name) {
  final collector = _NamedMethodCollector(name)..collect(unit);
  return collector.methods.length == 1 ? collector.methods.single : null;
}

CompilationUnit _unitAt(String path) {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: '$path must exist');
  return _parse(file.readAsStringSync(), path);
}

CompilationUnit _parse(String source, String path) =>
    parseString(content: source, path: path).unit;

final class _MethodContract {
  const _MethodContract({
    required this.requiredNamed,
    required this.optionalNamed,
    this.positional = const {},
  });

  const _MethodContract.missing()
    : requiredNamed = const {'<missing>': null},
      optionalNamed = const {},
      positional = const {};

  final Map<String, String?> requiredNamed;
  final Map<String, String?> optionalNamed;
  final Map<String, String?> positional;

  @override
  bool operator ==(Object other) =>
      other is _MethodContract &&
      _sameMap(requiredNamed, other.requiredNamed) &&
      _sameMap(optionalNamed, other.optionalNamed) &&
      _sameMap(positional, other.positional);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(requiredNamed.entries),
    Object.hashAllUnordered(optionalNamed.entries),
    Object.hashAllUnordered(positional.entries),
  );

  @override
  String toString() =>
      '_MethodContract(requiredNamed: $requiredNamed, '
      'optionalNamed: $optionalNamed, positional: $positional)';
}

bool _sameMap(Map<String, String?> left, Map<String, String?> right) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!right.containsKey(entry.key) || right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
