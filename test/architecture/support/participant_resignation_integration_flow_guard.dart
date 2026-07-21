part of '../participant_resignation_integration_test.dart';

List<String> _allViolations(CompilationUnit unit) => [
  ..._earlyNoOpViolations(unit),
  ..._codecFlowViolations(unit),
  ..._selectiveSnapshotPatchViolations(unit),
  ..._lifecycleDecisionViolations(unit),
];

List<String> _earlyNoOpViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) {
    return const ['must declare _runningStateAfterParticipantResigned'];
  }
  final statements = switch (method.body) {
    BlockFunctionBody(:final block) => block.statements,
    _ => const <Statement>[],
  };
  final persistentStateIndex = statements.indexWhere(
    (statement) => _statementDeclares(statement, 'persistentState'),
  );
  final earlyReturnIndex = statements.indexWhere(
    (statement) => statement is IfStatement && _isKickedNoOp(statement),
  );
  final decodedSnapshot = _variableInitializer(method.body, 'decodedSnapshot');
  final persistentState = _variableInitializer(method.body, 'persistentState');
  final save = _variableInitializer(method.body, 'save');
  final canonicalSnapshot = _variableInitializer(
    method.body,
    'canonicalSnapshot',
  );
  return [
    if (persistentState?.toSource() != 'decodedSnapshot.state' ||
        persistentStateIndex < 0 ||
        earlyReturnIndex != persistentStateIndex + 1 ||
        decodedSnapshot == null ||
        decodedSnapshot.offset >= persistentState!.offset ||
        save?.toSource() != 'decodedSnapshot.save' ||
        canonicalSnapshot?.toSource() != 'decodedSnapshot.canonical' ||
        statements[earlyReturnIndex].offset >= save!.offset ||
        statements[earlyReturnIndex].offset >= canonicalSnapshot!.offset)
      'already-kicked return must immediately follow state access and '
          'precede save/canonical access',
  ];
}

bool _statementDeclares(Statement statement, String name) {
  return statement is VariableDeclarationStatement &&
      statement.variables.variables.any(
        (variable) => variable.name.lexeme == name,
      );
}

bool _isKickedNoOp(IfStatement statement) {
  if (statement.expression.toSource() !=
          'persistentState.runtimeState.isKicked(player.id)' ||
      statement.elseStatement != null) {
    return false;
  }
  final thenStatement = statement.thenStatement;
  final returned = switch (thenStatement) {
    ReturnStatement() => thenStatement,
    Block(:final statements)
        when statements.length == 1 && statements.single is ReturnStatement =>
      statements.single as ReturnStatement,
    _ => null,
  };
  return returned?.expression?.toSource() == 'state';
}
