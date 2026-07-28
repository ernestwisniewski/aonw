part of '../running_match_snapshot_codec_boundary_test.dart';

List<String> _losslessConversionFlowViolations(CompilationUnit unit) {
  final codec = _singleClass(unit, 'LosslessMatchSnapshotCodec');
  return [
    if (!_hasExactLegacySnapshotAdapterBinding(unit))
      'lossless codec must bind exactly one const legacy adapter',
    if (!_hasExactCanonicalLegacyHelper(unit))
      'legacy-parts helper must own the only direct canonical adapter call',
    if (!_hasExactLosslessCanonicalFlow(_singleMethod(codec, 'canonical')))
      'lossless canonical must delegate directly to the legacy-parts helper',
    if (!_hasExactLosslessEncodeFlow(
      unit,
      _singleMethod(codec, 'encodeCanonical'),
    ))
      'lossless encodeCanonical must verify an exact legacy round-trip before '
          'returning parts',
  ];
}

bool _hasExactLegacySnapshotAdapterBinding(CompilationUnit unit) {
  final declarations = unit.declarations
      .whereType<TopLevelVariableDeclaration>()
      .where(
        (declaration) =>
            declaration.toSource() ==
            'const _legacyGameSnapshotAdapter = '
                'LegacyGameSnapshotAdapter();',
      );
  return declarations.length == 1;
}

bool _hasExactCanonicalLegacyHelper(CompilationUnit unit) {
  final declaration = _singleTopLevelFunction(
    unit,
    '_canonicalFromLegacyParts',
  );
  final body = declaration?.functionExpression.body;
  if (body == null) return false;
  final returned = _singleReturnedExpression(body);
  final conversions = _targetedInvocations(
    unit,
    target: '_legacyGameSnapshotAdapter',
    method: 'toCanonical',
  );
  return conversions.length == 1 &&
      identical(returned, conversions.single) &&
      conversions.single.argumentList.arguments.length == 3 &&
      _sameStringMap(
        _namedArgumentSources(conversions.single.argumentList),
        const {
          'save': 'save',
          'state': 'state',
          'eventLogOffset': 'eventLogOffset',
        },
      );
}

bool _hasExactLosslessCanonicalFlow(MethodDeclaration? method) {
  if (method == null) return false;
  final returned = _singleReturnedExpression(method.body);
  final conversions = _methodInvocations(
    method.body,
    '_canonicalFromLegacyParts',
  );
  return conversions.length == 1 &&
      conversions.single.target == null &&
      identical(returned, conversions.single) &&
      conversions.single.argumentList.arguments.length == 3 &&
      _sameStringMap(
        _namedArgumentSources(conversions.single.argumentList),
        const {
          'save': 'snapshot.save',
          'state': 'snapshot.state',
          'eventLogOffset': 'snapshot.eventLogOffset',
        },
      );
}

bool _hasExactLosslessEncodeFlow(
  CompilationUnit unit,
  MethodDeclaration? method,
) {
  if (method == null || method.body is! BlockFunctionBody) return false;
  final body = method.body as BlockFunctionBody;
  if (body.block.statements.length != 4) return false;
  final legacy = _singleLocalInitializer(body.block.statements.first, 'legacy');
  final represented = _singleLocalInitializer(
    body.block.statements[1],
    'represented',
  );
  final conversions = _targetedInvocations(
    unit,
    target: '_legacyGameSnapshotAdapter',
    method: 'toLegacy',
  );
  final roundTrips = _methodInvocations(
    method.body,
    '_canonicalFromLegacyParts',
  );
  return conversions.length == 1 &&
      identical(legacy, conversions.single) &&
      _hasSingleArgument(conversions, 'snapshot') &&
      roundTrips.length == 1 &&
      roundTrips.single.target == null &&
      identical(represented, roundTrips.single) &&
      roundTrips.single.argumentList.arguments.length == 3 &&
      _sameStringMap(
        _namedArgumentSources(roundTrips.single.argumentList),
        const {
          'save': 'legacy.save',
          'state': 'legacy.state',
          'eventLogOffset': 'legacy.eventLogOffset',
        },
      ) &&
      _hasExactRepresentabilityGuard(body.block.statements[2]) &&
      _lastReturnedExpression(method.body)?.toSource() ==
          '(save: legacy.save, state: legacy.state)';
}

bool _hasExactRepresentabilityGuard(Statement statement) {
  if (statement is! IfStatement ||
      statement.expression.toSource() != 'represented != snapshot' ||
      statement.elseStatement != null) {
    return false;
  }
  final thrown = _singleDirectThrow(statement.thenStatement);
  if (thrown == null || thrown.expression is! MethodInvocation) return false;
  final error = thrown.expression as MethodInvocation;
  final arguments = error.argumentList.arguments;
  return error.target?.toSource() == 'ArgumentError' &&
      error.methodName.name == 'value' &&
      arguments.length == 3 &&
      arguments[0].toSource() == 'snapshot' &&
      arguments[1].toSource() == "'snapshot'";
}

Expression? _singleLocalInitializer(Statement statement, String name) {
  if (statement is! VariableDeclarationStatement ||
      !statement.variables.isFinal ||
      statement.variables.variables.length != 1) {
    return null;
  }
  final variable = statement.variables.variables.single;
  return variable.name.lexeme == name ? variable.initializer : null;
}

List<String> _rawCanonicalPatchFlowViolations(CompilationUnit unit) => [
  if (!_hasExactCanonicalPartsFlow(
    _singleTopLevelFunction(unit, '_encodeCanonicalParts'),
  ))
    '_encodeCanonicalParts must preserve only the reviewed raw fields',
  if (!_hasExactRawFieldPreservationFlow(
    _singleTopLevelFunction(unit, '_preserveRawFields'),
  ))
    '_preserveRawFields must retain raw extensions and preserve reviewed '
        'field presence',
];

FunctionDeclaration? _singleTopLevelFunction(
  CompilationUnit unit,
  String name,
) {
  final declarations = unit.declarations.whereType<FunctionDeclaration>().where(
    (declaration) => declaration.name.lexeme == name,
  );
  return declarations.length == 1 ? declarations.single : null;
}

bool _hasExactCanonicalPartsFlow(FunctionDeclaration? declaration) {
  final body = declaration?.functionExpression.body;
  if (body == null || !_unchangedWireReturn(body)) return false;
  final copies = _targetedInvocations(
    body,
    target: 'source.wire',
    method: 'copyWith',
  );
  if (copies.length != 1 ||
      !identical(_lastReturnedExpression(body), copies.single)) {
    return false;
  }
  return _sameStringMap(
        _namedArgumentSources(copies.single.argumentList),
        const {
          'save':
              "save == null ? null : _preserveRawFields(save.toJson(), "
              "source.wire.save, const {'players'})",
          'state':
              "state == null ? null : _preserveRawFields(state.toJson(), "
              "source.wire.state, const {'playerColors', 'playerCountries'})",
        },
      ) &&
      copies.single.argumentList.arguments.length == 2;
}

bool _hasExactRawFieldPreservationFlow(FunctionDeclaration? declaration) {
  final body = declaration?.functionExpression.body;
  if (body is! BlockFunctionBody || body.block.statements.length != 4) {
    return false;
  }
  final statements = body.block.statements;
  return _hasExactPreservedMapInitializer(statements[0]) &&
      _hasExactRawExtensionLoop(statements[1]) &&
      _hasExactRawFieldLoop(statements[2]) &&
      statements[3] is ReturnStatement &&
      (statements[3] as ReturnStatement).expression?.toSource() == 'preserved';
}

bool _hasExactPreservedMapInitializer(Statement statement) {
  final initializer = _singleLocalInitializer(statement, 'preserved');
  return initializer?.toSource() == 'Map<String, dynamic>.from(candidate)';
}

bool _hasExactRawExtensionLoop(Statement statement) {
  if (statement is! ForStatement ||
      statement.forLoopParts is! ForEachPartsWithDeclaration ||
      statement.body is! Block) {
    return false;
  }
  final parts = statement.forLoopParts as ForEachPartsWithDeclaration;
  final variable = parts.loopVariable;
  final body = statement.body as Block;
  return variable.isFinal &&
      variable.name.lexeme == 'entry' &&
      parts.iterable.toSource() == 'raw.entries' &&
      body.statements.length == 1 &&
      body.statements.single.toSource() ==
          'preserved.putIfAbsent(entry.key, () => entry.value);';
}

bool _hasExactRawFieldLoop(Statement statement) {
  if (statement is! ForStatement ||
      statement.forLoopParts is! ForEachPartsWithDeclaration ||
      statement.body is! Block) {
    return false;
  }
  final parts = statement.forLoopParts as ForEachPartsWithDeclaration;
  final variable = parts.loopVariable;
  final body = statement.body as Block;
  if (!variable.isFinal ||
      variable.name.lexeme != 'field' ||
      parts.iterable.toSource() != 'fields' ||
      body.statements.length != 1 ||
      body.statements.single is! IfStatement) {
    return false;
  }
  return _hasExactRawFieldBranch(body.statements.single as IfStatement);
}

bool _hasExactRawFieldBranch(IfStatement branch) {
  final containsCalls = _targetedInvocations(
    branch.expression,
    target: 'raw',
    method: 'containsKey',
  );
  return _hasSingleArgument(containsCalls, 'field') &&
      identical(branch.expression, containsCalls.single) &&
      _singleStatementSource(branch.thenStatement) ==
          'preserved[field] = raw[field];' &&
      branch.elseStatement != null &&
      _singleStatementSource(branch.elseStatement!) ==
          'preserved.remove(field);';
}

String? _singleStatementSource(Statement statement) {
  if (statement is Block) {
    if (statement.statements.length != 1) return null;
    return statement.statements.single.toSource();
  }
  return statement.toSource();
}
