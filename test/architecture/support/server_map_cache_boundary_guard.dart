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
  );
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
  if (flow.validationCalls.length != 1) {
    violations.add(
      '$path _loadServerMap must validate tile invariants exactly once; '
      'found ${flow.validationCalls.length}',
    );
  }
  if (flow.indexedViewCalls.length != 1) {
    violations.add(
      '$path _loadServerMap must call indexedReadView exactly once; '
      'found ${flow.indexedViewCalls.length}',
    );
  }
  if (!_validServerMapFlow(flow)) {
    violations.add(
      '$path _loadServerMap must directly validate, index, and cache '
      'sourceMapData in order within one block',
    );
  }
  if (flow.mapViewDeclarations.length != 1 ||
      !_isServerIndexedMapViewDeclaration(
        flow.mapViewDeclarations.singleOrNull,
      )) {
    violations.add(
      '$path _loadServerMap must assign sourceMapData.indexedReadView() '
      'to one final mapView',
    );
  }
  if (flow.loadedMapCalls.length != 1 ||
      !_receivesSourceMapAndView(flow.loadedMapCalls.singleOrNull)) {
    violations.add(
      '$path _loadServerMap must cache sourceMapData with the same mapView',
    );
  }

  final loadedMap = _classDeclarationNamed(unit, '_LoadedServerMap');
  if (loadedMap == null) {
    violations.add('$path must declare _LoadedServerMap');
  } else {
    final mapViewFields = <VariableDeclaration>[];
    for (final field in loadedMap.body.members.whereType<FieldDeclaration>()) {
      mapViewFields.addAll(
        field.fields.variables.where(
          (variable) => variable.name.lexeme == 'mapView',
        ),
      );
    }
    if (mapViewFields.length != 1) {
      violations.add('$path _LoadedServerMap must declare one mapView field');
    } else {
      final fields = mapViewFields.single.parent as VariableDeclarationList;
      if (!fields.isFinal || fields.type?.toSource() != 'MapReadView') {
        violations.add(
          '$path _LoadedServerMap.mapView must be final MapReadView',
        );
      }
    }
  }
  return violations;
}

List<String> _serverReducerLibraryDependencyViolations(
  Map<String, String> sources, {
  required Set<String> forbiddenTypeNames,
}) {
  return [
    for (final entry in sources.entries)
      ..._economyMapDependencyViolations(
        entry.value,
        entry.key,
        forbiddenTypeNames: forbiddenTypeNames,
      ),
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
  if (flow.validationCalls.length != 1 ||
      flow.indexedViewCalls.length != 1 ||
      flow.loadedMapCalls.length != 1 ||
      flow.mapViewDeclarations.length != 1) {
    return false;
  }
  final validation = flow.validationCalls.single;
  final indexing = flow.indexedViewCalls.single;
  final loadedMapArguments = flow.loadedMapCalls.single;
  final loadedMapCall = loadedMapArguments.parent;
  if (validation.parent is! ExpressionStatement ||
      loadedMapCall?.parent is! ReturnStatement ||
      validation.argumentList.arguments.length != 1) {
    return false;
  }
  final validationArgument = validation.argumentList.arguments.single;
  final indexedTarget = indexing.target;
  if (validationArgument is! SimpleIdentifier ||
      validationArgument.name != 'sourceMapData' ||
      indexedTarget is! SimpleIdentifier ||
      indexedTarget.name != 'sourceMapData' ||
      !_isServerIndexedMapViewDeclaration(flow.mapViewDeclarations.single) ||
      !_receivesSourceMapAndView(loadedMapArguments)) {
    return false;
  }
  final validationStatement = validation.parent! as ExpressionStatement;
  final indexingStatement = _variableDeclarationStatementFor(indexing);
  final loadedMapStatement = loadedMapCall!.parent! as ReturnStatement;
  if (validationStatement.parent is! Block ||
      indexingStatement == null ||
      indexingStatement.parent is! Block ||
      loadedMapStatement.parent is! Block ||
      !identical(validationStatement.parent, indexingStatement.parent) ||
      !identical(indexingStatement.parent, loadedMapStatement.parent)) {
    return false;
  }
  final block = validationStatement.parent! as Block;
  final validationIndex = block.statements.indexOf(validationStatement);
  final indexingIndex = block.statements.indexOf(indexingStatement);
  final loadedMapIndex = block.statements.indexOf(loadedMapStatement);
  return validationIndex >= 0 &&
      validationIndex < indexingIndex &&
      indexingIndex < loadedMapIndex;
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

bool _receivesSourceMapAndView(ArgumentList? argumentList) {
  if (argumentList == null) return false;
  final arguments = argumentList.arguments;
  return arguments.length == 2 &&
      arguments[0] is SimpleIdentifier &&
      (arguments[0] as SimpleIdentifier).name == 'sourceMapData' &&
      arguments[1] is SimpleIdentifier &&
      (arguments[1] as SimpleIdentifier).name == 'mapView';
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

final class _ServerMapCacheFlowVisitor extends RecursiveAstVisitor<void> {
  final List<MethodInvocation> validationCalls = [];
  final List<MethodInvocation> indexedViewCalls = [];
  final List<VariableDeclaration> mapViewDeclarations = [];
  final List<ArgumentList> loadedMapCalls = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
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
