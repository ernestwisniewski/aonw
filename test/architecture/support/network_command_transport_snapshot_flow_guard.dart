part of '../network_command_transport_snapshot_boundary_test.dart';

List<String> _networkResultFlowViolations(
  CompilationUnit unit,
  CompilationUnit clientInteractionUnit,
) {
  final transport = _classNamed(unit, 'NetworkCommandTransport');
  if (transport == null) {
    return const ['NetworkCommandTransport must remain declared.'];
  }

  final violations = <String>[];
  final dispatch = _methodNamed(transport, '_dispatch');
  final clientOnly = clientInteractionUnit.declarations
      .whereType<ExtensionDeclaration>()
      .expand((extension) => extension.body.members)
      .whereType<MethodDeclaration>()
      .singleWhere((method) => method.name.lexeme == '_dispatchClientOnly');
  final reload = _methodNamed(transport, '_reloadAfterStaleCommand');
  final recovery = _methodNamed(transport, '_snapshotRecoveryResult');
  final allResults = [
    ..._resultCreations(transport),
    ..._resultCreations(clientOnly),
  ];
  final dispatchResults = _resultCreations(dispatch);
  final serverManaged = dispatchResults.where(
    (creation) => _insideIfCalling(creation, 'isServerManaged'),
  );
  final rejected = dispatchResults.where(_insideRejectedAckBranch);
  final accepted = dispatchResults.where(
    (creation) =>
        !_insideIfCalling(creation, 'isServerManaged') &&
        !_insideRejectedAckBranch(creation),
  );

  if (allResults.length != 6) {
    violations.add(
      'NetworkCommandTransport must keep exactly six reviewed result sites.',
    );
  }
  if (serverManaged.length != 1 ||
      !_isTransientResult(serverManaged.singleOrNull)) {
    violations.add(
      'Server-managed commands must return explicit snapshot: null and use '
      'the false storedSnapshot default.',
    );
  }
  final clientOnlyResults = _resultCreations(clientOnly);
  if (clientOnlyResults.length != 1 ||
      !_isTransientResult(clientOnlyResults.singleOrNull)) {
    violations.add(
      'Client-only commands must return explicit snapshot: null and use the '
      'false storedSnapshot default.',
    );
  }
  if (rejected.length != 1 || !_isStoredSnapshotResult(rejected.singleOrNull)) {
    violations.add(
      'Rejected acknowledgements must return snapshot and '
      'storedSnapshot: true.',
    );
  }
  if (accepted.length != 1 || !_isStoredSnapshotResult(accepted.singleOrNull)) {
    violations.add(
      'Accepted acknowledgements must return snapshot and '
      'storedSnapshot: true.',
    );
  }
  if (!_hasSingleStoredSnapshotResult(reload)) {
    violations.add(
      'Stale-command reload must return snapshot and storedSnapshot: true.',
    );
  }
  if (!_hasSingleStoredSnapshotResult(recovery)) {
    violations.add(
      'Stale-ack recovery must return snapshot and storedSnapshot: true.',
    );
  }
  if (_methodInvocationCount(dispatch, '_reloadAfterStaleCommand') != 1 ||
      _methodInvocationCount(dispatch, '_snapshotRecoveryResult') != 1) {
    violations.add(
      'Dispatch must retain both reviewed stale snapshot recovery routes.',
    );
  }
  return violations;
}

List<_ResultConstruction> _resultCreations(AstNode? node) {
  if (node == null) return const [];
  final collector = _ResultConstructionCollector('CommandTransportResult');
  node.accept(collector);
  return collector.nodes;
}

bool _isTransientResult(_ResultConstruction? creation) {
  if (creation == null) return false;
  final arguments = _namedArguments(creation);
  return arguments['snapshot'] is NullLiteral &&
      !arguments.containsKey('storedSnapshot');
}

bool _isStoredSnapshotResult(_ResultConstruction? creation) {
  if (creation == null) return false;
  final arguments = _namedArguments(creation);
  final snapshot = arguments['snapshot'];
  final storedSnapshot = arguments['storedSnapshot'];
  return snapshot is SimpleIdentifier &&
      snapshot.name == 'snapshot' &&
      storedSnapshot is BooleanLiteral &&
      storedSnapshot.value;
}

bool _hasSingleStoredSnapshotResult(MethodDeclaration? method) {
  final results = _resultCreations(method);
  return results.length == 1 && _isStoredSnapshotResult(results.single);
}

Map<String, Expression> _namedArguments(_ResultConstruction creation) {
  return {
    for (final argument
        in creation.arguments.arguments.whereType<NamedExpression>())
      argument.name.label.name: argument.expression,
  };
}

bool _insideIfCalling(_ResultConstruction creation, String methodName) {
  AstNode? current = creation.node.parent;
  while (current != null && current is! MethodDeclaration) {
    if (current case IfStatement(:final expression, :final thenStatement)
        when _containsNode(thenStatement, creation.node) &&
            _methodInvocationCount(expression, methodName) == 1) {
      return true;
    }
    current = current.parent;
  }
  return false;
}

bool _insideRejectedAckBranch(_ResultConstruction creation) {
  AstNode? current = creation.node.parent;
  while (current != null && current is! MethodDeclaration) {
    if (current case IfStatement(:final expression, :final thenStatement)
        when _containsNode(thenStatement, creation.node) &&
            _isNegatedAcceptedCondition(expression)) {
      return true;
    }
    current = current.parent;
  }
  return false;
}

bool _isNegatedAcceptedCondition(Expression expression) {
  if (expression is! PrefixExpression || expression.operator.lexeme != '!') {
    return false;
  }
  final collector = _NamedReferenceCollector('accepted');
  expression.operand.accept(collector);
  return collector.nodes.length == 1;
}

bool _containsNode(AstNode container, AstNode node) {
  return node.offset >= container.offset && node.end <= container.end;
}

int _methodInvocationCount(AstNode? node, String methodName) {
  if (node == null) return 0;
  final collector = _MethodInvocationCollector(methodName);
  node.accept(collector);
  return collector.nodes.length;
}
