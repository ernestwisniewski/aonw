part of '../participant_resignation_integration_test.dart';

List<String> _allViolations(CompilationUnit unit) => [
  ..._canonicalFlowViolations(unit),
  ..._codecFlowViolations(unit),
  ..._canonicalPatchViolations(unit),
  ..._legacyAccessViolations(unit),
  ..._lifecycleDecisionViolations(unit),
];

List<String> _canonicalFlowViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) {
    return const ['must declare _runningStateAfterParticipantResigned'];
  }
  final statements = _blockStatements(method);
  final participant = _variableDeclaration(method.body, 'player');
  final decoded = _variableDeclaration(method.body, 'decodedSnapshot');
  final canonical = _variableDeclaration(method.body, 'canonicalSnapshot');
  final transition = _variableDeclaration(method.body, 'transition');
  final nextSnapshot = _variableDeclaration(method.body, 'nextSnapshot');
  final participantIndex = _statementIndexDeclaring(statements, 'player');
  final decodedIndex = _statementIndexDeclaring(statements, 'decodedSnapshot');
  final canonicalIndex = _statementIndexDeclaring(
    statements,
    'canonicalSnapshot',
  );
  final earlyReturnIndex = statements.indexWhere(
    (statement) => statement is IfStatement && _isKickedNoOp(statement),
  );
  final transitionIndex = _statementIndexDeclaring(statements, 'transition');
  final nextSnapshotIndex = _statementIndexDeclaring(
    statements,
    'nextSnapshot',
  );
  final encode = _targetedInvocations(
    method.body,
    target: '_runningMatchSnapshotCodec',
    method: 'encodeCanonical',
  );
  final encodeIndex = _statementIndexContaining(
    statements,
    encode.length == 1 ? encode.single : null,
  );
  final hasParticipantFirst =
      _isParticipantLookup(participant?.initializer) && participantIndex == 0;
  final hasImmediateKickedNoOp =
      _isKickedNoOpAt(statements, earlyReturnIndex) &&
      canonicalIndex >= 0 &&
      earlyReturnIndex == canonicalIndex + 1;
  final hasDependencyOrder = _hasCanonicalDependencyOrder(
    participantIndex: participantIndex,
    decodedIndex: decodedIndex,
    canonicalIndex: canonicalIndex,
    earlyReturnIndex: earlyReturnIndex,
    transitionIndex: transitionIndex,
    nextSnapshotIndex: nextSnapshotIndex,
    encodeIndex: encodeIndex,
    participant: participant,
    decoded: decoded,
    canonical: canonical,
    transition: transition,
    nextSnapshot: nextSnapshot,
  );
  return [
    if (!hasParticipantFirst)
      'resignation must require the participant before snapshot access',
    if (!hasImmediateKickedNoOp)
      'already-kicked return must immediately follow roster validation',
    if (!hasDependencyOrder)
      'resignation canonical flow must preserve dependency order',
  ];
}

bool _hasCanonicalDependencyOrder({
  required int participantIndex,
  required int decodedIndex,
  required int canonicalIndex,
  required int earlyReturnIndex,
  required int transitionIndex,
  required int nextSnapshotIndex,
  required int encodeIndex,
  required VariableDeclaration? participant,
  required VariableDeclaration? decoded,
  required VariableDeclaration? canonical,
  required VariableDeclaration? transition,
  required VariableDeclaration? nextSnapshot,
}) {
  return _hasCanonicalFlowPrefix(
        participantIndex,
        decodedIndex,
        canonicalIndex,
        earlyReturnIndex,
      ) &&
      _hasCanonicalFlowTail(
        transitionIndex,
        earlyReturnIndex,
        nextSnapshotIndex,
        encodeIndex,
      ) &&
      _hasAllCanonicalFlowDeclarations(
        participant,
        decoded,
        canonical,
        transition,
        nextSnapshot,
      );
}

bool _hasCanonicalFlowPrefix(
  int participantIndex,
  int decodedIndex,
  int canonicalIndex,
  int earlyReturnIndex,
) {
  return participantIndex == 0 &&
      decodedIndex == 1 &&
      canonicalIndex == 2 &&
      earlyReturnIndex == 3;
}

bool _hasCanonicalFlowTail(
  int transitionIndex,
  int earlyReturnIndex,
  int nextSnapshotIndex,
  int encodeIndex,
) {
  return transitionIndex == earlyReturnIndex + 1 &&
      nextSnapshotIndex > transitionIndex &&
      encodeIndex > nextSnapshotIndex;
}

bool _hasAllCanonicalFlowDeclarations(
  VariableDeclaration? participant,
  VariableDeclaration? decoded,
  VariableDeclaration? canonical,
  VariableDeclaration? transition,
  VariableDeclaration? nextSnapshot,
) {
  return participant != null &&
      decoded != null &&
      canonical != null &&
      transition != null &&
      nextSnapshot != null;
}

bool _isParticipantLookup(Expression? initializer) {
  if (initializer is! MethodInvocation) return false;
  return initializer.target?.toSource() == '_stateAccess' &&
      initializer.methodName.name == 'requireParticipant' &&
      _positionalArguments(initializer.argumentList).join(',') ==
          'state,userIdentifier' &&
      _namedArguments(initializer.argumentList).isEmpty;
}

bool _isKickedNoOpAt(List<Statement> statements, int index) {
  if (index < 0 || index >= statements.length) return false;
  final statement = statements[index];
  return statement is IfStatement && _isKickedNoOp(statement);
}

bool _isKickedNoOp(IfStatement statement) {
  if (statement.expression.toSource() !=
          'canonicalSnapshot.session.isKicked(player.id)' ||
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
