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
      'running decode must delegate directly to the lossless decoder after '
          'lifecycle rejection',
  ];
}

List<String> _losslessDecodeFlowViolations(CompilationUnit unit) {
  final decoded = _singleClass(unit, 'DecodedRunningMatchSnapshot');
  final decode = _singleMethod(
    _singleClass(unit, 'LosslessMatchSnapshotDecoder'),
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
      'lossless decode must directly construct the lazy raw-wire wrapper',
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
      '_losslessMatchSnapshotDecoder.decode(snapshot)';
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
