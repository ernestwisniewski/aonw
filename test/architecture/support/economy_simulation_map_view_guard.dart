part of '../world_map_projection_boundary_test.dart';

final _economySimulationMapPaths = _discoverEconomySimulationMapPaths();
const _economySimulationPath =
    '$_coreLib/ai/simulation/economy_simulation.dart';
const _economyCommandApplierPath =
    '$_coreLib/ai/simulation/economy_simulation_command_applier.dart';

List<String> _discoverEconomySimulationMapPaths() {
  final paths = <String>{};
  final directory = Directory('$_coreLib/ai/simulation');
  for (final entry in directory.listSync(recursive: true)) {
    if (entry is File && _isEconomySimulationSourcePath(entry.path)) {
      paths.add(_workspaceRelativePath(entry.path));
    }
  }
  paths.addAll(
    _libraryPartPaths(
      _economySimulationPath,
      File(_economySimulationPath).readAsStringSync(),
    ),
  );
  final sortedPaths = paths.toList()..sort();
  return List.unmodifiable(sortedPaths);
}

List<String> _libraryPartPaths(String libraryPath, String source) {
  final unit = parseString(content: source, path: libraryPath).unit;
  final directory = File(libraryPath).parent.path;
  return [
    for (final directive in unit.directives.whereType<PartDirective>())
      if (directive.uri.stringValue case final String uri)
        _workspaceRelativePath('$directory/$uri'),
  ];
}

bool _isEconomySimulationSourcePath(String path) {
  final normalized = path.replaceAll('\\', '/');
  final name = normalized.split('/').last;
  return name == 'economy_simulation.dart' ||
      (name.startsWith('economy_simulation_') &&
          name.endsWith('.dart') &&
          !name.endsWith('.g.dart') &&
          !name.endsWith('.freezed.dart'));
}

String _workspaceRelativePath(String path) {
  final normalized = File(path).absolute.path.replaceAll('\\', '/');
  final root = '${Directory.current.absolute.path.replaceAll('\\', '/')}/';
  return normalized.startsWith(root) ? normalized.substring(root.length) : path;
}

List<String> _economySimulationMapViewViolations() {
  final sources = {
    for (final path in _economySimulationMapPaths)
      path: File(path).readAsStringSync(),
  };
  final forbiddenTypeNames = typeNamesBackedBy(productionDartSources(), const {
    'WorldMap',
    'WorldMapReadView',
    'LegacyWorldMapAdapter',
  });
  final violations = <String>[];
  for (final entry in sources.entries) {
    violations.addAll(
      _economyMapDependencyViolations(
        entry.value,
        entry.key,
        forbiddenTypeNames: forbiddenTypeNames,
      ),
    );
  }
  violations
    ..addAll(_economyIndexedReadViewViolations(sources))
    ..addAll(
      _economyRunMapViewViolations(
        sources[_economySimulationPath]!,
        _economySimulationPath,
      ),
    )
    ..addAll(
      _economyCommandApplierMapViewViolations(
        sources[_economyCommandApplierPath]!,
        _economyCommandApplierPath,
      ),
    );
  return violations;
}

List<String> _economyMapDependencyViolations(
  String source,
  String path, {
  Set<String> forbiddenTypeNames = const {
    'WorldMap',
    'WorldMapReadView',
    'LegacyWorldMapAdapter',
  },
}) {
  final unit = parseString(content: source, path: path).unit;
  final forbiddenIdentifiers = _ForbiddenMapIdentifierVisitor(
    forbiddenTypeNames,
  );
  unit.accept(forbiddenIdentifiers);
  final forbiddenImports = unit.directives
      .whereType<ImportDirective>()
      .map((directive) => directive.uri.stringValue)
      .whereType<String>()
      .where(
        (uri) =>
            uri.endsWith('/world_map.dart') ||
            uri.endsWith('/world_map_read_view.dart') ||
            uri.endsWith('/legacy_world_map_adapter.dart'),
      );
  return [
    for (final identifier in forbiddenIdentifiers.identifiers)
      '$path must not reference $identifier',
    for (final uri in forbiddenImports) '$path must not import $uri',
  ];
}

List<String> _economyIndexedReadViewViolations(Map<String, String> sources) {
  var invocationCount = 0;
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final visitor = _IndexedReadViewInvocationVisitor();
    unit.accept(visitor);
    invocationCount += visitor.invocationCount;
  }
  return invocationCount == 1
      ? const []
      : [
          'economy simulation sources must call indexedReadView exactly once; '
              'found $invocationCount',
        ];
}

List<String> _economyRunMapViewViolations(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  final declaration = _classDeclarationNamed(unit, 'EconomySimulation');
  if (declaration == null) return ['$path must declare EconomySimulation'];
  final runMethods = declaration.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == 'run')
      .toList();
  if (runMethods.length != 1) {
    return ['$path must declare exactly one EconomySimulation.run'];
  }

  final visitor = _EconomyRunMapViewVisitor();
  runMethods.single.accept(visitor);
  final violations = <String>[];
  if (visitor.indexedReadInvocations.length != 1) {
    violations.add(
      '$path EconomySimulation.run must call indexedReadView exactly once; '
      'found ${visitor.indexedReadInvocations.length}',
    );
  }
  if (visitor.mapViewDeclarations.length != 1 ||
      !_isIndexedMapViewDeclaration(visitor.mapViewDeclarations.singleOrNull)) {
    violations.add(
      '$path EconomySimulation.run must assign mapData.indexedReadView() '
      'to one final mapView',
    );
  }
  if (!_validatesAndIndexesLocalMapData(visitor)) {
    violations.add(
      '$path EconomySimulation.run must use local mapData only for the '
      'tile-invariant pre-pass and indexed mapView',
    );
  }
  if (visitor.sourceMapDataSelectors.length != 1) {
    violations.add(
      '$path EconomySimulation.run must read config.mapData only once; '
      'found ${visitor.sourceMapDataSelectors.length}',
    );
  }
  if (visitor.commandApplierCalls.length != 1 ||
      !_receivesLocalMapView(visitor.commandApplierCalls.singleOrNull)) {
    violations.add(
      '$path EconomySimulation.run must construct one command applier with '
      'the local mapView',
    );
  }
  return violations;
}

bool _validatesAndIndexesLocalMapData(_EconomyRunMapViewVisitor visitor) {
  if (visitor.tileValidationInvocations.length != 1 ||
      visitor.indexedReadInvocations.length != 1) {
    return false;
  }
  final validation = visitor.tileValidationInvocations.single;
  final indexed = visitor.indexedReadInvocations.single;
  if (validation.offset >= indexed.offset ||
      validation.argumentList.arguments.length != 1) {
    return false;
  }
  final validationArgument = validation.argumentList.arguments.single;
  final indexedTarget = indexed.target;
  if (validationArgument is! SimpleIdentifier ||
      validationArgument.name != 'mapData' ||
      indexedTarget is! SimpleIdentifier ||
      indexedTarget.name != 'mapData') {
    return false;
  }
  final allowedReferences = {validationArgument, indexedTarget};
  return visitor.localMapDataReferences.length == allowedReferences.length &&
      visitor.localMapDataReferences.every(allowedReferences.contains);
}

bool _isIndexedMapViewDeclaration(VariableDeclaration? declaration) {
  if (declaration == null || declaration.name.lexeme != 'mapView') return false;
  final variables = declaration.parent;
  if (variables is! VariableDeclarationList || !variables.isFinal) return false;
  final initializer = declaration.initializer;
  return initializer is MethodInvocation &&
      initializer.methodName.name == 'indexedReadView' &&
      initializer.argumentList.arguments.isEmpty &&
      initializer.target is SimpleIdentifier &&
      (initializer.target! as SimpleIdentifier).name == 'mapData';
}

bool _receivesLocalMapView(ArgumentList? arguments) {
  if (arguments == null) return false;
  final mapViewArguments = arguments.arguments
      .whereType<NamedExpression>()
      .where((argument) => argument.name.label.name == 'mapView');
  if (mapViewArguments.length != 1) return false;
  final expression = mapViewArguments.single.expression;
  return expression is SimpleIdentifier && expression.name == 'mapView';
}

List<String> _economyCommandApplierMapViewViolations(
  String source,
  String path,
) {
  final unit = parseString(content: source, path: path).unit;
  final declaration = _classDeclarationNamed(
    unit,
    '_EconomySimulationCommandApplier',
  );
  if (declaration == null) {
    return ['$path must declare _EconomySimulationCommandApplier'];
  }
  final mapViewFields = <VariableDeclaration>[];
  for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
    mapViewFields.addAll(
      field.fields.variables.where(
        (variable) => variable.name.lexeme == 'mapView',
      ),
    );
  }
  final violations = <String>[];
  if (mapViewFields.length != 1) {
    violations.add('$path command applier must declare one mapView field');
  } else {
    final fields = mapViewFields.single.parent as VariableDeclarationList;
    if (!fields.isFinal || fields.type?.toSource() != 'MapReadView') {
      violations.add('$path command applier mapView must be final MapReadView');
    }
  }

  final engineSnapshotFields = <VariableDeclaration>[];
  for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
    engineSnapshotFields.addAll(
      field.fields.variables.where(
        (variable) => variable.name.lexeme == 'engineSnapshot',
      ),
    );
  }
  if (engineSnapshotFields.length != 1) {
    violations.add(
      '$path command applier must declare one engineSnapshot field',
    );
  } else {
    final fields =
        engineSnapshotFields.single.parent as VariableDeclarationList;
    if (fields.type?.toSource() != 'CanonicalGameSnapshot') {
      violations.add(
        '$path command applier engineSnapshot must be CanonicalGameSnapshot',
      );
    }
  }

  final constructors = declaration.body.members
      .whereType<ConstructorDeclaration>()
      .where((constructor) => constructor.name == null)
      .toList();
  final parameters = constructors.singleOrNull?.parameters.parameters;
  final hasFieldConstructor =
      constructors.length == 1 &&
      parameters?.length == 2 &&
      parameters![0] is FieldFormalParameter &&
      parameters[1] is FieldFormalParameter &&
      (parameters[0] as FieldFormalParameter).name.lexeme == 'mapView' &&
      (parameters[1] as FieldFormalParameter).name.lexeme == 'engineSnapshot';
  if (!hasFieldConstructor) {
    violations.add(
      '$path command applier must have one constructor over mapView and '
      'engineSnapshot',
    );
  }
  return violations;
}

final class _EconomyRunMapViewVisitor extends RecursiveAstVisitor<void> {
  final List<VariableDeclaration> mapViewDeclarations = [];
  final List<MethodInvocation> indexedReadInvocations = [];
  final List<MethodInvocation> tileValidationInvocations = [];
  final List<ArgumentList> commandApplierCalls = [];
  final List<SimpleIdentifier> localMapDataReferences = [];
  final List<SimpleIdentifier> sourceMapDataSelectors = [];

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == 'mapView') mapViewDeclarations.add(node);
    super.visitVariableDeclaration(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'indexedReadView') {
      indexedReadInvocations.add(node);
    }
    if (node.methodName.name == 'validateMapDataTileInvariants') {
      tileValidationInvocations.add(node);
    }
    if (node.methodName.name == '_economySimulationCommandApplierForSetup') {
      commandApplierCalls.add(node.argumentList);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme ==
        '_EconomySimulationCommandApplier') {
      commandApplierCalls.add(node.argumentList);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'mapData') {
      if (_isMapDataSelector(node)) {
        sourceMapDataSelectors.add(node);
      } else if (!_isNonValueIdentifier(node)) {
        localMapDataReferences.add(node);
      }
    }
    super.visitSimpleIdentifier(node);
  }
}

final class _IndexedReadViewInvocationVisitor
    extends RecursiveAstVisitor<void> {
  int invocationCount = 0;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name == 'indexedReadView' && _isMethodReference(node)) {
      invocationCount += 1;
    }
    super.visitSimpleIdentifier(node);
  }
}

bool _isMethodReference(SimpleIdentifier node) {
  final parent = node.parent;
  return (parent is MethodInvocation && identical(parent.methodName, node)) ||
      (parent is PrefixedIdentifier && identical(parent.identifier, node)) ||
      (parent is PropertyAccess && identical(parent.propertyName, node));
}

bool _isMapDataSelector(SimpleIdentifier node) {
  final parent = node.parent;
  return (parent is PrefixedIdentifier && identical(parent.identifier, node)) ||
      (parent is PropertyAccess && identical(parent.propertyName, node));
}

bool _isNonValueIdentifier(SimpleIdentifier node) {
  final parent = node.parent;
  return parent is Label ||
      (parent is MethodInvocation && identical(parent.methodName, node));
}

final class _ForbiddenMapIdentifierVisitor extends RecursiveAstVisitor<void> {
  _ForbiddenMapIdentifierVisitor(this.forbiddenNames);

  final Set<String> forbiddenNames;
  final Set<String> identifiers = {};

  @override
  void visitNamedType(NamedType node) {
    _addIfForbidden(node.name.lexeme);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    _addIfForbidden(node.name);
    super.visitSimpleIdentifier(node);
  }

  void _addIfForbidden(String name) {
    if (forbiddenNames.contains(name)) {
      identifiers.add(name);
    }
  }
}
