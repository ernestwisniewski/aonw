part of '../player_view_state_boundary_test.dart';

void _expectCanonicalProjectionInputs({
  required CompilationUnit matchUnit,
  required ClassDeclaration matchProjector,
  required ClassDeclaration stateProjector,
}) {
  final preparedSnapshot = _classNamed(
    matchUnit,
    'PreparedPlayerMatchSnapshot',
  );
  expect(_fieldTypes(preparedSnapshot), {
    'wire': 'WireSnapshot',
    'publicSave': 'Map<String, dynamic>?',
    'canonicalSnapshot': 'CanonicalGameSnapshot?',
  });
  expect(_parameterTypes(_methodNamed(stateProjector, 'project')), {
    'domain': 'DomainState',
    'recipientPlayerId': 'String',
    'knownDiplomacyPlayerIds': 'Set<String>',
  });

  const legacyContainers = {'PersistentGameState', 'GameRuntimeState'};
  expect(
    _fieldAndParameterTypes(matchProjector).intersection(legacyContainers),
    isEmpty,
  );
  expect(
    _fieldAndParameterTypes(stateProjector).intersection(legacyContainers),
    isEmpty,
  );
}

void _expectSnapshotPreparationOrder(ClassDeclaration snapshotProjector) {
  final prepareSnapshot = _methodNamed(snapshotProjector, 'prepare');
  expect(_identifierCount(prepareSnapshot.body, '_decodeSnapshot'), 1);
  final prepareBody = prepareSnapshot.body as BlockFunctionBody;
  final lifecycleReturn = prepareBody.block.statements
      .whereType<IfStatement>()
      .singleWhere(
        (statement) =>
            statement.expression.toSource() == 'canonical.save.isEmpty',
      );
  final validateState = _singleCall(
    prepareSnapshot.body,
    'validateSnapshotState',
  );
  final validateSave = _singleCall(
    prepareSnapshot.body,
    'validateGameSaveEnvelope',
  );
  final decode = _singleCall(prepareSnapshot.body, '_decodeSnapshot');
  final validateRoster = _singleCall(
    prepareSnapshot.body,
    'validateCanonicalRoster',
  );
  expect(
    [
      validateState.offset,
      lifecycleReturn.offset,
      validateSave.offset,
      decode.offset,
      validateRoster.offset,
    ],
    orderedEquals(
      [
        validateState.offset,
        lifecycleReturn.offset,
        validateSave.offset,
        decode.offset,
        validateRoster.offset,
      ]..sort(),
    ),
  );
}

void _expectFanoutPreparationBoundary(
  ClassDeclaration matchProjector,
  ClassDeclaration snapshotProjector,
) {
  expect(_preparationWrapperViolations(matchProjector), isEmpty);
  expect(_prepareMessageContractViolations(matchProjector), isEmpty);

  for (final method
      in matchProjector.body.members.whereType<MethodDeclaration>()) {
    final methodName = method.name.lexeme;
    expect(
      _identifierCount(method.body, '_decodeSnapshot'),
      methodName == '_snapshots' ? 1 : 0,
      reason:
          '$methodName must not decode outside the reviewed snapshot '
          'capability injection.',
    );
    if (!const {
      'prepareSnapshot',
      'prepareMessage',
      'snapshotFor',
      'messageFor',
      'ackFor',
      'projectMessage',
      '_snapshots',
    }.contains(methodName)) {
      expect(
        _projectionCapabilityReferences(method.body),
        isEmpty,
        reason: '$methodName must project an already-prepared snapshot.',
      );
    }
  }
  for (final method
      in snapshotProjector.body.members.whereType<MethodDeclaration>()) {
    expect(
      _identifierCount(method.body, '_decodeSnapshot'),
      method.name.lexeme == 'prepare' ? 1 : 0,
      reason: '${method.name.lexeme} must preserve the decode-once boundary.',
    );
  }
}

void _expectLosslessDecoderBoundary(CompilationUnit matchUnit) {
  final wrapper = _functionNamed(matchUnit, '_decodePlayerMatchSnapshot');
  expect(
    _singleReturnedExpression(wrapper.functionExpression.body)?.toSource(),
    '_playerMatchSnapshotDecoder.decode(snapshot)',
  );
  expect(_identifierCount(matchUnit, '_decodePlayerMatchSnapshot'), 1);
  expect(_identifierCount(matchUnit, '_playerMatchSnapshotDecoder'), 1);
  expect(_identifierCount(matchUnit, 'LosslessMatchSnapshotDecoder'), 1);
  expect(_identifierCount(matchUnit, 'RunningMatchSnapshotCodec'), 0);
  expect(
    instanceMemberReferenceCountsByPath(
      productionDartSources(),
      'LosslessMatchSnapshotDecoder',
      'decode',
    ),
    {_projectorPath: 1},
  );
}

Map<String, String> _preparationWrapperViolations(ClassDeclaration projector) {
  const expectedReturns = {
    'snapshotFor': 'projectSnapshot(prepareSnapshot(canonical), recipient)',
    'ackFor':
        '_events.ackFor(canonical, prepareSnapshot(canonical.snapshot), '
        'recipient)',
    'messageFor': 'projectMessage(prepareMessage(canonical), recipient).wire',
  };
  return {
    for (final method in projector.body.members.whereType<MethodDeclaration>())
      if (expectedReturns[method.name.lexeme] case final expected?)
        if (_singleReturnedExpression(method.body)?.toSource() != expected)
          method.name.lexeme: expected,
  };
}

Map<String, String> _prepareMessageContractViolations(
  ClassDeclaration projector,
) {
  final method = _methodNamed(projector, 'prepareMessage');
  const expectedInitializers = {
    'snapshot':
        'canonical.snapshot == null ? null : '
        'prepareSnapshot(canonical.snapshot!)',
    'ackSnapshot':
        'canonical.ack == null ? null : '
        'canonical.ack!.snapshot == canonical.snapshot ? snapshot : '
        'prepareSnapshot(canonical.ack!.snapshot)',
  };
  final violations = <String, String>{};
  for (final entry in expectedInitializers.entries) {
    if (_localVariableInitializer(method, entry.key) != entry.value) {
      violations[entry.key] = entry.value;
    }
  }
  if (_identifierCount(method.body, 'prepareSnapshot') != 2) {
    violations['prepareSnapshot'] = 'exactly two guarded call sites';
  }
  if (_blockReturnExpression(method.body)?.toSource() !=
      'PreparedPlayerMatchMessage.prepared(canonical: canonical, '
          'snapshot: snapshot, ackSnapshot: ackSnapshot)') {
    violations['return'] = 'construct the prepared message from local values';
  }
  return violations;
}

String? _localVariableInitializer(MethodDeclaration method, String name) {
  final body = method.body;
  if (body is! BlockFunctionBody) return null;
  for (final statement in body.block.statements) {
    if (statement is! VariableDeclarationStatement) continue;
    for (final variable in statement.variables.variables) {
      if (variable.name.lexeme == name) {
        return variable.initializer?.toSource();
      }
    }
  }
  return null;
}

Expression? _blockReturnExpression(FunctionBody body) {
  if (body is! BlockFunctionBody) return null;
  final returns = body.block.statements.whereType<ReturnStatement>();
  return returns.length == 1 ? returns.single.expression : null;
}
