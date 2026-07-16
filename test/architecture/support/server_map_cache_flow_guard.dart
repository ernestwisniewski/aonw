part of '../world_map_projection_boundary_test.dart';

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
