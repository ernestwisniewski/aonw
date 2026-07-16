part of '../world_map_projection_boundary_test.dart';

const _serverReducerPath =
    'server/lib/src/multiplayer/server_command_reducer.dart';
const _serverMapCachePath =
    'server/lib/src/multiplayer/server_command_reducer_map_cache.dart';
const _serverReducerTurnsPath =
    'server/lib/src/multiplayer/server_command_reducer_turns.dart';
const _serverReducerOutcomePath =
    'server/lib/src/multiplayer/server_command_reducer_outcome.dart';
final List<String> _serverReducerLibraryPaths = List<String>.unmodifiable([
  _serverReducerPath,
  ..._libraryPartPaths(
    _serverReducerPath,
    File(_serverReducerPath).readAsStringSync(),
  ),
]);

const _serverReducerMapContracts = [
  (
    path: _serverReducerTurnsPath,
    method: '_submitTurn',
    parameter: 'mapView',
    type: 'MapReadView',
  ),
  (
    path: _serverReducerTurnsPath,
    method: '_finalizeSimultaneousTurn',
    parameter: 'mapView',
    type: 'MapReadView',
  ),
  (
    path: _serverReducerOutcomePath,
    method: '_gameOutcome',
    parameter: 'mapView',
    type: 'MapReadView',
  ),
];

List<String> _serverMapCacheBoundaryViolations({
  String? source,
  String path = _serverMapCachePath,
  Set<String>? forbiddenTypeNames,
}) {
  forbiddenTypeNames ??= typeNamesBackedBy(productionDartSources(), const {
    'MapData',
    'WorldMap',
    'WorldMapReadView',
    'LegacyWorldMapAdapter',
  });
  final isProduction = source == null;
  final sources = isProduction
      ? <String, String>{
          for (final libraryPath in _serverReducerLibraryPaths)
            libraryPath: File(libraryPath).readAsStringSync(),
        }
      : <String, String>{path: source};
  source = sources[path];
  if (source == null) return ['$path must exist in the server reducer library'];
  final violations = _serverReducerLibraryDependencyViolations(
    sources,
    forbiddenTypeNames: forbiddenTypeNames,
  )..addAll(_serverMapLoadCallViolations(sources, cachePath: path));
  if (isProduction) {
    violations.addAll(_serverReducerMapContractViolations(sources));
  }
  final unit = parseString(content: source, path: path).unit;
  final methodCollector = _NamedMethodCollector('_loadServerMap');
  unit.accept(methodCollector);
  if (methodCollector.methods.length != 1) {
    return [
      ...violations,
      '$path must declare exactly one _loadServerMap method',
    ];
  }

  final flow = _ServerMapCacheFlowVisitor();
  methodCollector.methods.single.accept(flow);
  violations
    ..addAll(_serverMapCacheFlowViolations(flow, path))
    ..addAll(_loadedServerMapViolations(unit, path));
  return violations;
}

List<String> _serverMapCacheFlowViolations(
  _ServerMapCacheFlowVisitor flow,
  String path,
) {
  return [
    if (flow.loadAssetMapCalls.length != 1 ||
        !_isSourceMapDataLoad(flow.loadAssetMapCalls.singleOrNull))
      '$path _loadServerMap must load sourceMapData exactly once',
    if (flow.validationCalls.length != 1)
      '$path _loadServerMap must validate tile invariants exactly once; '
          'found ${flow.validationCalls.length}',
    if (flow.indexedViewCalls.length != 1)
      '$path _loadServerMap must call indexedReadView exactly once; '
          'found ${flow.indexedViewCalls.length}',
    if (!_validServerMapFlow(flow))
      '$path _loadServerMap must directly validate, index, and cache '
          'sourceMapData in order within one block',
    if (flow.mapViewDeclarations.length != 1 ||
        !_isServerIndexedMapViewDeclaration(
          flow.mapViewDeclarations.singleOrNull,
        ))
      '$path _loadServerMap must assign sourceMapData.indexedReadView() '
          'to one final mapView',
    if (flow.loadedMapCalls.length != 1 ||
        !_receivesOnlyMapView(flow.loadedMapCalls.singleOrNull))
      '$path _loadServerMap must cache only the same mapView',
    if (flow.sourceMapDataReferences.any(
      (reference) => !_isAllowedSourceMapDataReference(reference, flow),
    ))
      '$path _loadServerMap must not retain or alias sourceMapData',
  ];
}

List<String> _serverMapLoadCallViolations(
  Map<String, String> sources, {
  required String cachePath,
}) {
  final calls = <({String path, MethodInvocation invocation})>[];
  final references = <({String path, SimpleIdentifier reference})>[];
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _NamedInvocationCollector('loadAssetMap');
    unit.accept(collector);
    calls.addAll(
      collector.invocations.map(
        (invocation) => (path: entry.key, invocation: invocation),
      ),
    );
    references.addAll(
      collector.references.map(
        (reference) => (path: entry.key, reference: reference),
      ),
    );
  }
  final violations = <String>[
    if (references.length != 1)
      '$cachePath server reducer library must reference loadAssetMap exactly '
          'once; found ${references.length}',
  ];
  if (calls.length != 1) {
    violations.add(
      '$cachePath server reducer library must call loadAssetMap exactly once; '
      'found ${calls.length}',
    );
    return violations;
  }
  if (calls.single.path != cachePath) {
    violations.add(
      '$cachePath server reducer library must call loadAssetMap only in '
      '_loadServerMap',
    );
  }
  return violations;
}

bool _isAllowedSourceMapDataReference(
  SimpleIdentifier reference,
  _ServerMapCacheFlowVisitor flow,
) {
  for (final validation in flow.validationCalls) {
    if (identical(validation.argumentList.arguments.singleOrNull, reference)) {
      return true;
    }
  }
  for (final indexing in flow.indexedViewCalls) {
    if (identical(indexing.target, reference)) return true;
  }
  final parent = reference.parent;
  if (parent is PrefixedIdentifier &&
      identical(parent.prefix, reference) &&
      parent.identifier.name == 'mapName') {
    final assignment = parent.parent;
    return assignment is AssignmentExpression &&
        identical(assignment.leftHandSide, parent) &&
        assignment.operator.lexeme == '??=';
  }
  if (parent is PropertyAccess &&
      identical(parent.target, reference) &&
      parent.propertyName.name == 'mapName') {
    final assignment = parent.parent;
    return assignment is AssignmentExpression &&
        identical(assignment.leftHandSide, parent) &&
        assignment.operator.lexeme == '??=';
  }
  return false;
}

List<String> _loadedServerMapViolations(CompilationUnit unit, String path) {
  final loadedMap = _classDeclarationNamed(unit, '_LoadedServerMap');
  if (loadedMap == null) return ['$path must declare _LoadedServerMap'];
  final cachedFields = <VariableDeclaration>[];
  for (final field in loadedMap.body.members.whereType<FieldDeclaration>()) {
    cachedFields.addAll(field.fields.variables);
  }
  if (cachedFields.length != 1 ||
      cachedFields.single.name.lexeme != 'mapView') {
    return [
      '$path _LoadedServerMap must cache only one mapView field; found '
          '${cachedFields.map((field) => field.name.lexeme).toList()}',
    ];
  }
  final fields = cachedFields.single.parent as VariableDeclarationList;
  final violations = <String>[
    if (!fields.isFinal || fields.type?.toSource() != 'MapReadView')
      '$path _LoadedServerMap.mapView must be final MapReadView',
  ];
  final constructors = loadedMap.body.members
      .whereType<ConstructorDeclaration>()
      .toList();
  if (constructors.length != 1 ||
      !_isMapViewOnlyConstructor(constructors.single)) {
    violations.add(
      '$path _LoadedServerMap must construct from only its mapView field',
    );
  }
  return violations;
}

bool _isMapViewOnlyConstructor(ConstructorDeclaration constructor) {
  final parameters = constructor.parameters.parameters;
  if (parameters.length != 1) return false;
  final parameter = _normalizedParameter(parameters.single);
  return parameter is FieldFormalParameter &&
      parameter.name.lexeme == 'mapView';
}

List<String> _serverReducerLibraryDependencyViolations(
  Map<String, String> sources, {
  required Set<String> forbiddenTypeNames,
}) {
  return [
    for (final entry in sources.entries) ...[
      ..._economyMapDependencyViolations(
        entry.value,
        entry.key,
        forbiddenTypeNames: forbiddenTypeNames,
      ),
      ...sourceSymbolReferenceViolations(
        entry.value,
        entry.key,
        symbol: 'legacyMapData',
      ),
    ],
  ];
}

List<String> _serverReducerMapContractViolations(Map<String, String> sources) {
  final violations = <String>[];
  for (final contract in _serverReducerMapContracts) {
    final source = sources[contract.path];
    if (source == null) {
      violations.add('${contract.path} must remain part of server reducer');
      continue;
    }
    final unit = parseString(content: source, path: contract.path).unit;
    final collector = _NamedMethodCollector(contract.method);
    unit.accept(collector);
    if (collector.methods.length != 1) {
      violations.add(
        '${contract.path} must declare exactly one ${contract.method}',
      );
      continue;
    }
    final parameters = collector.methods.single.parameters?.parameters;
    final matching = parameters
        ?.where(
          (parameter) =>
              _normalizedParameter(parameter).name?.lexeme ==
              contract.parameter,
        )
        .toList();
    if (matching == null || matching.length != 1) {
      violations.add(
        '${contract.path} ${contract.method} must declare one '
        '${contract.parameter} parameter',
      );
      continue;
    }
    final parameter = _normalizedParameter(matching.single);
    final type = parameter is SimpleFormalParameter
        ? parameter.type?.toSource()
        : null;
    if (type != contract.type) {
      violations.add(
        '${contract.path} ${contract.method}.${contract.parameter} must '
        'have type ${contract.type}; found ${type ?? '<inferred>'}',
      );
    }
  }
  return violations;
}

FormalParameter _normalizedParameter(FormalParameter parameter) {
  return parameter is DefaultFormalParameter ? parameter.parameter : parameter;
}

bool _validServerMapFlow(_ServerMapCacheFlowVisitor flow) {
  if (flow.loadAssetMapCalls.length != 1) return false;
  if (flow.validationCalls.length != 1) return false;
  if (flow.indexedViewCalls.length != 1) return false;
  if (flow.loadedMapCalls.length != 1) return false;
  if (flow.mapViewDeclarations.length != 1) return false;
  final validation = flow.validationCalls.single;
  final indexing = flow.indexedViewCalls.single;
  final loadedMapArguments = flow.loadedMapCalls.single;
  return _hasServerMapCallShape(
        load: flow.loadAssetMapCalls.single,
        validation: validation,
        indexing: indexing,
        mapViewDeclaration: flow.mapViewDeclarations.single,
        loadedMapArguments: loadedMapArguments,
      ) &&
      _hasOrderedServerMapStatements(
        load: flow.loadAssetMapCalls.single,
        validation: validation,
        indexing: indexing,
        loadedMapArguments: loadedMapArguments,
      );
}

bool _hasServerMapCallShape({
  required MethodInvocation load,
  required MethodInvocation validation,
  required MethodInvocation indexing,
  required VariableDeclaration mapViewDeclaration,
  required ArgumentList loadedMapArguments,
}) {
  final validationArguments = validation.argumentList.arguments;
  final validationArgument = validationArguments.singleOrNull;
  final indexedTarget = indexing.target;
  return _isSourceMapDataLoad(load) &&
      validationArgument is SimpleIdentifier &&
      validationArgument.name == 'sourceMapData' &&
      indexedTarget is SimpleIdentifier &&
      indexedTarget.name == 'sourceMapData' &&
      _isServerIndexedMapViewDeclaration(mapViewDeclaration) &&
      _receivesOnlyMapView(loadedMapArguments);
}

bool _hasOrderedServerMapStatements({
  required MethodInvocation load,
  required MethodInvocation validation,
  required MethodInvocation indexing,
  required ArgumentList loadedMapArguments,
}) {
  final loadStatement = _sourceMapDataLoadStatement(load);
  final validationStatement = validation.parent;
  final indexingStatement = _variableDeclarationStatementFor(indexing);
  final loadedMapStatement = loadedMapArguments.parent?.parent;
  if (loadStatement == null) return false;
  if (validationStatement is! ExpressionStatement) return false;
  if (indexingStatement == null) return false;
  if (loadedMapStatement is! ReturnStatement) return false;
  final block = validationStatement.parent;
  if (block is! Block) return false;
  if (!identical(block, loadStatement.parent)) return false;
  if (!identical(block, indexingStatement.parent)) return false;
  if (!identical(block, loadedMapStatement.parent)) return false;
  final loadIndex = block.statements.indexOf(loadStatement);
  final validationIndex = block.statements.indexOf(validationStatement);
  final indexingIndex = block.statements.indexOf(indexingStatement);
  final loadedMapIndex = block.statements.indexOf(loadedMapStatement);
  return loadIndex >= 0 &&
      loadIndex < validationIndex &&
      validationIndex >= 0 &&
      validationIndex < indexingIndex &&
      indexingIndex < loadedMapIndex;
}

bool _isSourceMapDataLoad(MethodInvocation? invocation) {
  if (invocation == null ||
      invocation.argumentList.arguments.length != 1 ||
      invocation.argumentList.arguments.single is! SimpleIdentifier ||
      (invocation.argumentList.arguments.single as SimpleIdentifier).name !=
          'mapName') {
    return false;
  }
  return _sourceMapDataLoadDeclaration(invocation) != null;
}

VariableDeclaration? _sourceMapDataLoadDeclaration(
  MethodInvocation invocation,
) {
  AstNode initializer = invocation;
  final parent = invocation.parent;
  if (parent is AwaitExpression && identical(parent.expression, invocation)) {
    initializer = parent;
  }
  final declaration = initializer.parent;
  return declaration is VariableDeclaration &&
          declaration.name.lexeme == 'sourceMapData' &&
          identical(declaration.initializer, initializer)
      ? declaration
      : null;
}

VariableDeclarationStatement? _sourceMapDataLoadStatement(
  MethodInvocation invocation,
) {
  final declaration = _sourceMapDataLoadDeclaration(invocation);
  final variables = declaration?.parent;
  final statement = variables?.parent;
  return statement is VariableDeclarationStatement ? statement : null;
}

VariableDeclarationStatement? _variableDeclarationStatementFor(
  MethodInvocation invocation,
) {
  final declaration = invocation.parent;
  if (declaration is! VariableDeclaration ||
      !identical(declaration.initializer, invocation)) {
    return null;
  }
  final variables = declaration.parent;
  final statement = variables?.parent;
  return statement is VariableDeclarationStatement ? statement : null;
}

bool _isServerIndexedMapViewDeclaration(VariableDeclaration? declaration) {
  if (declaration == null || declaration.name.lexeme != 'mapView') return false;
  final variables = declaration.parent;
  if (variables is! VariableDeclarationList || !variables.isFinal) return false;
  final initializer = declaration.initializer;
  return initializer is MethodInvocation &&
      initializer.methodName.name == 'indexedReadView' &&
      initializer.argumentList.arguments.isEmpty &&
      initializer.target is SimpleIdentifier &&
      (initializer.target! as SimpleIdentifier).name == 'sourceMapData';
}

bool _receivesOnlyMapView(ArgumentList? argumentList) {
  if (argumentList == null) return false;
  final arguments = argumentList.arguments;
  return arguments.length == 1 &&
      arguments.single is SimpleIdentifier &&
      (arguments.single as SimpleIdentifier).name == 'mapView';
}

final class _NamedMethodCollector extends RecursiveAstVisitor<void> {
  _NamedMethodCollector(this.name);

  final String name;
  final List<MethodDeclaration> methods = [];

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.name.lexeme == name) methods.add(node);
    super.visitMethodDeclaration(node);
  }
}

final class _NamedInvocationCollector extends RecursiveAstVisitor<void> {
  _NamedInvocationCollector(this.name);

  final String name;
  final List<MethodInvocation> invocations = [];
  final List<SimpleIdentifier> references = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == name) references.add(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == name) invocations.add(node);
    super.visitMethodInvocation(node);
  }
}

final class _ServerMapCacheFlowVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> loadAssetMapCalls = [];
  final List<MethodInvocation> validationCalls = [];
  final List<MethodInvocation> indexedViewCalls = [];
  final List<VariableDeclaration> mapViewDeclarations = [];
  final List<ArgumentList> loadedMapCalls = [];
  final List<SimpleIdentifier> sourceMapDataReferences = [];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'sourceMapData') sourceMapDataReferences.add(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'loadAssetMap') {
      loadAssetMapCalls.add(node);
    }
    if (node.methodName.name == 'validateMapDataTileInvariants') {
      validationCalls.add(node);
    }
    if (node.methodName.name == 'indexedReadView') {
      indexedViewCalls.add(node);
    }
    if (node.methodName.name == '_LoadedServerMap') {
      loadedMapCalls.add(node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == 'mapView') mapViewDeclarations.add(node);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == '_LoadedServerMap') {
      loadedMapCalls.add(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }
}
