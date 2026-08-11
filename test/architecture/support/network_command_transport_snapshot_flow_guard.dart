part of '../network_command_transport_snapshot_boundary_test.dart';

List<String> _networkResultFlowViolations(
  CompilationUnit unit,
  CompilationUnit snapshotUnit,
  CompilationUnit acknowledgedPresentation,
) {
  final transport = _classNamed(unit, 'NetworkCommandTransport');
  if (transport == null) {
    return const ['NetworkCommandTransport must remain declared.'];
  }

  final violations = <String>[];
  final dispatch = _methodNamed(transport, '_dispatch');
  final reload = _methodNamedAnywhere(snapshotUnit, '_reloadAfterStaleCommand');
  final recovery = _methodNamedAnywhere(
    snapshotUnit,
    '_snapshotRecoveryResult',
  );
  final allResults = _resultCreations(snapshotUnit);
  final acknowledgedResults = _resultCreations(acknowledgedPresentation);

  if (allResults.length != 2 || acknowledgedResults.length != 1) {
    violations.add(
      'Network transport must keep two recovery result sites and one shared '
      'acknowledgment result site.',
    );
  }
  if ([
    ...allResults,
    ...acknowledgedResults,
  ].any((result) => !_isStoredSnapshotResult(result))) {
    violations.add(
      'Every network result must expose the canonical stored snapshot.',
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
  if (_methodInvocationCount(dispatch, 'acknowledgedCommandTransportResult') !=
      2) {
    violations.add(
      'Dispatch must retain both reviewed acknowledgment result routes.',
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

int _methodInvocationCount(AstNode? node, String methodName) {
  if (node == null) return 0;
  final collector = _MethodInvocationCollector(methodName);
  node.accept(collector);
  return collector.nodes.length;
}
