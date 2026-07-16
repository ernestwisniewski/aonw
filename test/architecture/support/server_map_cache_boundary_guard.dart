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
