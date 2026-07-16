part of '../world_foundation_boundary_test.dart';

List<String> _mapDraftFreezeViolations(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  final mapDrafts = unit.declarations
      .whereType<ClassDeclaration>()
      .where(
        (declaration) => declaration.namePart.typeName.lexeme == 'MapDraft',
      )
      .toList();
  if (mapDrafts.length != 1) return ['$path must declare one MapDraft'];
  final freezes = mapDrafts.single.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == 'freeze')
      .toList();
  if (freezes.length != 1) return ['$path must declare one MapDraft.freeze'];

  final freeze = freezes.single;
  final visitor = _MapDraftFreezeVisitor();
  freeze.accept(visitor);
  final violations = <String>[];
  if (freeze.returnType?.toSource() != 'WorldMap' ||
      visitor.tileViewFactoryCalls != 1 ||
      visitor.returnedTileViewFactoryCalls != 1) {
    violations.add(
      '$path MapDraft.freeze must return one WorldMap.fromTileViews call',
    );
  }
  if (visitor.persistenceProjectionCalls != 0) {
    violations.add('$path MapDraft.freeze must not call toMapData');
  }
  return violations;
}

final class _MapDraftFreezeVisitor extends RecursiveAstVisitor<void> {
  int tileViewFactoryCalls = 0;
  int returnedTileViewFactoryCalls = 0;
  int persistenceProjectionCalls = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'fromTileViews' &&
        node.realTarget?.toSource() == 'WorldMap') {
      tileViewFactoryCalls += 1;
      if (_isDirectlyReturned(node)) returnedTileViewFactoryCalls += 1;
    }
    if (node.methodName.name == 'toMapData') {
      persistenceProjectionCalls += 1;
    }
    super.visitMethodInvocation(node);
  }
}

bool _isDirectlyReturned(Expression expression) {
  final parent = expression.parent;
  return (parent is ReturnStatement &&
          identical(parent.expression, expression)) ||
      (parent is ExpressionFunctionBody &&
          identical(parent.expression, expression));
}

List<String> _converterViolations(
  Map<String, String> sources, {
  required Set<String> allowedPaths,
}) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    if (allowedPaths.contains(entry.key)) continue;
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final declaredTypes = <String, String>{};
    unit
      ..accept(_DeclaredTypeCollector(declaredTypes))
      ..accept(_ConverterVisitor(entry.key, violations, declaredTypes));
  }
  return violations;
}

final class _DeclaredTypeCollector extends RecursiveAstVisitor<void> {
  _DeclaredTypeCollector(this.types);

  final Map<String, String> types;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final declaration = node.parent;
    final owner = declaration?.parent;
    if (declaration is VariableDeclarationList &&
        (owner is TopLevelVariableDeclaration || owner is FieldDeclaration)) {
      final type = declaration.type?.toSource();
      if (type != null) types[node.name.lexeme] = type;
    }
    super.visitVariableDeclaration(node);
  }
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  _IdentifierCollector(this.names);

  final Set<String> names;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

final class _ConverterVisitor extends RecursiveAstVisitor<void> {
  _ConverterVisitor(this.path, this.violations, this.declaredTypes);

  final String path;
  final List<String> violations;
  final Map<String, String> declaredTypes;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkCallable(
      name: node.name.lexeme,
      returnType: node.returnType?.toSource() ?? '',
      parameters: node.functionExpression.parameters,
      nodes: [node.functionExpression.body],
      offset: node.offset,
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkCallable(
      name: node.name.lexeme,
      returnType: node.returnType?.toSource() ?? '',
      parameters: node.parameters,
      receiverType: _extensionReceiverType(node),
      nodes: [node.body],
      offset: node.offset,
    );
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration &&
        node.parent is! MethodDeclaration) {
      _checkCallable(
        name: '<closure>',
        returnType: '',
        parameters: node.parameters,
        nodes: [node.body],
        offset: node.offset,
      );
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkCallable(
      name: node.name?.lexeme ?? '<unnamed>',
      returnType: '',
      parameters: node.parameters,
      nodes: [...node.initializers, node.body],
      offset: node.offset,
    );
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final declaration = node.parent;
    final owner = declaration?.parent;
    final initializer = node.initializer;
    if (initializer != null &&
        declaration is VariableDeclarationList &&
        (owner is TopLevelVariableDeclaration || owner is FieldDeclaration)) {
      _checkCallable(
        name: node.name.lexeme,
        returnType: declaration.type?.toSource() ?? '',
        parameters: null,
        nodes: [initializer],
        offset: node.offset,
      );
    }
    super.visitVariableDeclaration(node);
  }

  void _checkCallable({
    required String name,
    required String returnType,
    required FormalParameterList? parameters,
    String receiverType = '',
    required Iterable<AstNode> nodes,
    required int offset,
  }) {
    final parameterTypes = '${parameters?.toSource() ?? ''} $receiverType';
    final createdTypes = <String>{};
    final referencedTypes = <String>{};
    final visitor = _TypeUsageVisitor(
      createdTypes: createdTypes,
      referencedTypes: referencedTypes,
      declaredTypes: declaredTypes,
    );
    for (final node in nodes) {
      node.accept(visitor);
    }
    if (_crossesBoundary(
      returnType,
      parameterTypes,
      createdTypes,
      referencedTypes,
    )) {
      violations.add('$path@$offset $name converts canonical and legacy data');
    }
  }
}

String _extensionReceiverType(AstNode node) {
  for (var parent = node.parent; parent != null; parent = parent.parent) {
    if (parent is ExtensionDeclaration) {
      return parent.onClause?.extendedType.toSource() ?? '';
    }
  }
  return '';
}

final class _TypeUsageVisitor extends RecursiveAstVisitor<void> {
  _TypeUsageVisitor({
    required this.createdTypes,
    required this.referencedTypes,
    required this.declaredTypes,
  });

  final Set<String> createdTypes;
  final Set<String> referencedTypes;
  final Map<String, String> declaredTypes;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    createdTypes.add(node.constructorName.type.toSource());
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    createdTypes.add(node.methodName.name);
    final target = node.realTarget?.toSource();
    if (target != null) referencedTypes.add(target);
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    referencedTypes.add(node.toSource());
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final declaredType = declaredTypes[node.name];
    if (declaredType != null) referencedTypes.add(declaredType);
    super.visitSimpleIdentifier(node);
  }
}

bool _crossesBoundary(
  String returnType,
  String parameterTypes,
  Set<String> createdTypes,
  Set<String> referencedTypes,
) {
  return _crossesTypePair(
        canonical: 'HexCoord',
        legacy: const {'CityHex', 'HexCoordinate'},
        returnType: returnType,
        parameterTypes: parameterTypes,
        createdTypes: createdTypes,
        referencedTypes: referencedTypes,
      ) ||
      _crossesTypePair(
        canonical: 'WorldMap',
        legacy: const {'MapData'},
        returnType: returnType,
        parameterTypes: parameterTypes,
        createdTypes: createdTypes,
        referencedTypes: referencedTypes,
      );
}

bool _crossesTypePair({
  required String canonical,
  required Set<String> legacy,
  required String returnType,
  required String parameterTypes,
  required Set<String> createdTypes,
  required Set<String> referencedTypes,
}) {
  final takesCanonical = _containsType(parameterTypes, canonical);
  final takesLegacy = legacy.any((type) => _containsType(parameterTypes, type));
  final referencesCanonical = referencedTypes.any(
    (type) => _containsType(type, canonical),
  );
  final referencesLegacy = referencedTypes.any(
    (reference) => legacy.any((type) => _containsType(reference, type)),
  );
  final returnsCanonical = _containsType(returnType, canonical);
  final returnsLegacy = legacy.any((type) => _containsType(returnType, type));
  final createsCanonical = createdTypes.any(
    (type) => _containsType(type, canonical),
  );
  final createsLegacy = createdTypes.any(
    (created) => legacy.any((type) => _containsType(created, type)),
  );
  return ((takesLegacy || referencesLegacy) &&
          (returnsCanonical || createsCanonical || referencesCanonical)) ||
      ((takesCanonical || referencesCanonical) &&
          (returnsLegacy || createsLegacy || referencesLegacy));
}

bool _containsType(String source, String type) {
  return RegExp(
    '(?:^|[^A-Za-z0-9_])${RegExp.escape(type)}(?:\$|[^A-Za-z0-9_])',
  ).hasMatch(source);
}
