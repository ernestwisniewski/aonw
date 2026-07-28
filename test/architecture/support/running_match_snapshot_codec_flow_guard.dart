part of '../running_match_snapshot_codec_boundary_test.dart';

List<String> _runningDecodeFlowViolations(CompilationUnit unit) {
  final decode = _singleMethod(
    _singleClass(unit, 'RunningMatchSnapshotCodec'),
    'decode',
  );
  if (decode == null) return const ['must declare decode'];
  final lifecycleGuard = _firstStatementIf(decode.body);
  final heuristicCollector = _PhaseHeuristicCollector()..collect(decode.body);
  return [
    if (!_isExactRunningLifecycleGuard(lifecycleGuard))
      'decode must reject a non-running match as its first statement',
    if (heuristicCollector.found)
      'decode must not infer lifecycle from snapshot phase',
    if (!_delegatesDirectlyAfterLifecycleGuard(decode.body))
      'running decode must delegate directly to the lossless codec after '
          'lifecycle rejection',
  ];
}

List<String> _losslessDecodeFlowViolations(CompilationUnit unit) {
  final decoded = _singleClass(unit, 'DecodedRunningMatchSnapshot');
  final decode = _singleMethod(
    _singleClass(unit, 'LosslessMatchSnapshotCodec'),
    'decode',
  );
  final returned = decode == null
      ? null
      : _singleReturnedExpression(decode.body);
  final constructions = _constructions(unit, 'DecodedRunningMatchSnapshot');
  final constructsExactWrapper =
      returned?.toSource() == 'DecodedRunningMatchSnapshot._(wire: snapshot)' &&
      constructions.length == 1 &&
      identical(returned, constructions.single.node);
  return [
    if (!constructsExactWrapper)
      'lossless codec decode must directly construct the lazy raw-wire '
          'wrapper',
    if (!_hasLazyLegacyParsers(decoded))
      'legacy save and state parsing must remain lazy on the decoded wrapper',
  ];
}

IfStatement? _firstStatementIf(FunctionBody body) {
  if (body is! BlockFunctionBody || body.block.statements.isEmpty) return null;
  final first = body.block.statements.first;
  return first is IfStatement ? first : null;
}

bool _isExactRunningLifecycleGuard(IfStatement? lifecycleGuard) {
  if (lifecycleGuard == null) return false;
  final directThrow = _singleDirectThrow(lifecycleGuard.thenStatement);
  final errorConstructions = directThrow == null
      ? const <_ConstructionReference>[]
      : _constructions(directThrow.expression, 'StateError');
  return lifecycleGuard.expression.toSource() == "match.state != 'running'" &&
      lifecycleGuard.elseStatement == null &&
      errorConstructions.length == 1 &&
      identical(errorConstructions.single.node, directThrow?.expression);
}

bool _delegatesDirectlyAfterLifecycleGuard(FunctionBody body) {
  if (body is! BlockFunctionBody || body.block.statements.length != 2) {
    return false;
  }
  final returned = body.block.statements[1];
  if (returned is! ReturnStatement) return false;
  return returned.expression?.toSource() ==
      '_losslessMatchSnapshotCodec.decode(snapshot)';
}

Expression? _singleReturnedExpression(FunctionBody body) {
  if (body is ExpressionFunctionBody) return null;
  if (body is! BlockFunctionBody || body.block.statements.length != 1) {
    return null;
  }
  final statement = body.block.statements.single;
  return statement is ReturnStatement ? statement.expression : null;
}

ThrowExpression? _singleDirectThrow(Statement statement) {
  final direct = statement is Block
      ? (statement.statements.length == 1 ? statement.statements.single : null)
      : statement;
  if (direct is! ExpressionStatement || direct.expression is! ThrowExpression) {
    return null;
  }
  return direct.expression as ThrowExpression;
}

List<String> _encodeFlowViolations(CompilationUnit unit) {
  final codec = _singleClass(unit, 'RunningMatchSnapshotCodec');
  final encode = _singleMethod(codec, 'encode');
  if (encode == null) return const ['must declare encode'];

  final copyCalls = _targetedInvocations(
    encode.body,
    target: 'source.wire',
    method: 'copyWith',
  );
  final returned = _lastReturnedExpression(encode.body);
  final copyArguments = copyCalls.length == 1
      ? _namedArgumentSources(copyCalls.single.argumentList)
      : const <String, String>{};
  final createsWireSnapshot = _constructions(
    encode.body,
    'WireSnapshot',
  ).isNotEmpty;
  final conversions = [
    ..._methodInvocations(encode.body, 'toLegacy'),
    ..._methodInvocations(encode.body, 'toCanonical'),
  ];
  final conversionReferences = _ConversionReferenceCollector()
    ..collect(encode.body);
  final canonicalReferences = _CanonicalReferenceCollector()
    ..collect(encode.body);
  final unchangedReturn = _unchangedWireReturn(encode.body);

  return [
    if (!unchangedReturn)
      'encode must return source.wire when replacements are absent',
    if (copyCalls.length != 1 || !identical(returned, copyCalls.single))
      'encode must return source.wire.copyWith directly',
    if (!_sameStringMap(copyArguments, const {
      'save': 'save?.toJson()',
      'state': 'state?.toJson()',
    }))
      'encode must patch only optional save and state JSON',
    if (createsWireSnapshot) 'encode must not construct a WireSnapshot',
    if (conversions.isNotEmpty ||
        conversionReferences.found ||
        canonicalReferences.found)
      'encode must not use legacy or canonical conversion',
  ];
}

List<String> _canonicalEncodeFlowViolations(CompilationUnit unit) {
  final method = _singleMethod(
    _singleClass(unit, 'RunningMatchSnapshotCodec'),
    'encodeCanonical',
  );
  if (method == null) return const ['must declare encodeCanonical'];
  final body = method.body;
  final previous = _localVariableInitializer(method, 'previous');
  final rosterGuards = _methodInvocations(body, '_requireMatchingRoster');
  final turnStartGuards = _methodInvocations(
    body,
    '_requireRepresentableRunningTurnStart',
  );
  final offsetGuards = _methodInvocations(
    body,
    '_requireUnchangedEventLogOffset',
  );
  final conversions = _targetedInvocations(
    body,
    target: '_losslessMatchSnapshotCodec',
    method: 'encodeCanonical',
  );
  final saveCopies = _targetedInvocations(
    body,
    target: 'legacy.save',
    method: 'copyWith',
  );
  final timeoutPolicies = _methodInvocations(
    body,
    '_preserveImplicitTurnStartedAt',
  );
  final patches = _methodInvocations(body, '_encodeCanonicalParts');
  final directConversions = [
    ..._methodInvocations(body, 'toCanonical'),
    ..._methodInvocations(body, 'toLegacy'),
  ];
  final adapterReferences = _ConversionReferenceCollector()..collect(body);

  return [
    if (previous != 'source.canonical' ||
        !_returnsRawWireForSemanticNoOpBefore(body, conversions))
      'encodeCanonical must return raw wire for a semantic no-op before '
          'conversion',
    if (!_hasExactParticipantGuard(rosterGuards, conversions))
      'encodeCanonical must reject ordered participant changes before '
          'conversion',
    if (!_hasExactEventLogOffsetGuard(offsetGuards, conversions))
      'encodeCanonical must reject event-log offset changes before '
          'conversion',
    if (!_hasExactTurnStartGuard(turnStartGuards, conversions))
      'encodeCanonical must reject unrepresentable turn starts before '
          'conversion',
    if (!_hasSingleArgument(conversions, 'next'))
      'encodeCanonical must use the shared lossless codec exactly once',
    if (!_hasExactRawSaveRosterCopy(saveCopies))
      'encodeCanonical must preserve the typed raw save roster',
    if (!_hasExactRawStateRosterAndTimeoutPolicy(timeoutPolicies))
      'encodeCanonical must preserve typed raw state roster and timeout policy',
    if (!_hasExactCanonicalPartsPatch(patches))
      'encodeCanonical must patch only through the raw-preserving helper',
    if (directConversions.isNotEmpty || adapterReferences.found)
      'encodeCanonical must not perform compatibility conversion directly',
  ];
}

String? _localVariableInitializer(
  MethodDeclaration method,
  String variableName,
) {
  final body = method.body;
  if (body is! BlockFunctionBody) return null;
  for (final statement in body.block.statements) {
    if (statement is! VariableDeclarationStatement) continue;
    for (final variable in statement.variables.variables) {
      if (variable.name.lexeme == variableName) {
        return variable.initializer?.toSource();
      }
    }
  }
  return null;
}

bool _returnsRawWireForSemanticNoOpBefore(
  FunctionBody body,
  List<MethodInvocation> conversions,
) {
  if (body is! BlockFunctionBody || conversions.length != 1) return false;
  final noOpGuards = body.block.statements.whereType<IfStatement>().where(
    (statement) => statement.expression.toSource() == 'next == previous',
  );
  if (noOpGuards.length != 1) return false;
  final guard = noOpGuards.single;
  final branch = guard.thenStatement;
  final returned = switch (branch) {
    final ReturnStatement statement => statement.expression,
    final Block block when block.statements.length == 1 =>
      switch (block.statements.single) {
        final ReturnStatement statement => statement.expression,
        _ => null,
      },
    _ => null,
  };
  return returned?.toSource() == 'source.wire' &&
      guard.offset < conversions.single.offset;
}

bool _hasExactParticipantGuard(
  List<MethodInvocation> guards,
  List<MethodInvocation> conversions,
) {
  if (guards.length != 1 || conversions.length != 1) return false;
  return guards.single.target == null &&
      guards.single.argumentList.arguments.length == 1 &&
      guards.single.argumentList.arguments.single.toSource() ==
          '_sameOrderedPlayers(next.domain.participants, '
              'previous.domain.participants) && '
              '_hasCompleteTurnStateRoster(next)' &&
      guards.single.offset < conversions.single.offset;
}

bool _hasExactTurnStartGuard(
  List<MethodInvocation> guards,
  List<MethodInvocation> conversions,
) {
  return _hasSingleArgument(guards, 'next') &&
      guards.single.target == null &&
      conversions.length == 1 &&
      guards.single.offset < conversions.single.offset;
}

bool _hasExactEventLogOffsetGuard(
  List<MethodInvocation> guards,
  List<MethodInvocation> conversions,
) {
  if (guards.length != 1 || conversions.length != 1) return false;
  final arguments = guards.single.argumentList.arguments;
  return guards.single.target == null &&
      arguments.length == 2 &&
      arguments[0].toSource() == 'previous' &&
      arguments[1].toSource() == 'next' &&
      guards.single.offset < conversions.single.offset;
}

bool _hasExactRawSaveRosterCopy(List<MethodInvocation> copies) {
  return copies.length == 1 &&
      _sameStringMap(_namedArgumentSources(copies.single.argumentList), const {
        'players': 'source.save.players',
      });
}

bool _hasExactRawStateRosterAndTimeoutPolicy(List<MethodInvocation> policies) {
  if (policies.length != 1) return false;
  return _sameStringMap(
    _namedArgumentSources(policies.single.argumentList),
    const {
      'source': 'source',
      'previous': 'previous',
      'next': 'next',
      'state':
          'legacy.state.copyWith(playerColors: source.state.playerColors, '
          'playerCountries: source.state.playerCountries)',
    },
  );
}

bool _hasExactCanonicalPartsPatch(List<MethodInvocation> patches) {
  if (patches.length != 1) return false;
  final arguments = patches.single.argumentList.arguments;
  if (arguments.length != 3 ||
      arguments.first.toSource() != 'source' ||
      arguments[1] is! NamedExpression ||
      arguments[2] is! NamedExpression) {
    return false;
  }
  return _sameStringMap(
    _namedArgumentSources(patches.single.argumentList),
    const {
      'save': 'nextSave == source.save ? null : nextSave',
      'state': 'nextState == source.state ? null : nextState',
    },
  );
}

bool _hasLazyLegacyParsers(ClassDeclaration? declaration) {
  return _hasLazyLegacyParser(
        declaration,
        fieldName: 'save',
        fieldType: 'GameSave',
        decoderType: 'GameSave',
        wireField: 'wire.save',
      ) &&
      _hasLazyLegacyParser(
        declaration,
        fieldName: 'state',
        fieldType: 'PersistentGameState',
        decoderType: 'PersistentGameState',
        wireField: 'wire.state',
      );
}

bool _hasLazyLegacyParser(
  ClassDeclaration? declaration, {
  required String fieldName,
  required String fieldType,
  required String decoderType,
  required String wireField,
}) {
  if (declaration == null) return false;
  final field = _singleField(declaration, fieldName);
  final initializer = field?.fields.variables.single.initializer;
  if (field == null ||
      !field.fields.isLate ||
      !field.fields.isFinal ||
      field.fields.type?.toSource() != fieldType ||
      initializer == null) {
    return false;
  }
  final decodes = _targetedInvocations(
    initializer,
    target: decoderType,
    method: 'fromJson',
  );
  final allDecodes = _targetedInvocations(
    declaration,
    target: decoderType,
    method: 'fromJson',
  );
  return _hasSingleArgument(decodes, wireField) &&
      allDecodes.length == 1 &&
      identical(decodes.single, allDecodes.single);
}

bool _unchangedWireReturn(FunctionBody body) {
  if (body is! BlockFunctionBody || body.block.statements.length != 2) {
    return false;
  }
  final first = body.block.statements.first;
  if (first is! IfStatement ||
      first.expression.toSource() != 'save == null && state == null' ||
      first.elseStatement != null) {
    return false;
  }
  final statement = first.thenStatement;
  final returned = switch (statement) {
    ReturnStatement() => statement.expression,
    Block(:final statements) when statements.length == 1 =>
      switch (statements.single) {
        final ReturnStatement value => value.expression,
        _ => null,
      },
    _ => null,
  };
  return returned?.toSource() == 'source.wire';
}
