part of '../running_match_snapshot_codec_boundary_test.dart';

List<String> _codecBoundaryViolations(
  CompilationUnit codecUnit,
  CompilationUnit decoderUnit,
) => [
  ..._codecShapeViolations(codecUnit, decoderUnit),
  ..._runningDecodeFlowViolations(codecUnit),
  ..._losslessDecodeFlowViolations(decoderUnit),
  ..._encodeFlowViolations(codecUnit),
];

List<String> _codecShapeViolations(
  CompilationUnit codecUnit,
  CompilationUnit decoderUnit,
) {
  final codec = _singleClass(codecUnit, 'RunningMatchSnapshotCodec');
  final decoder = _singleClass(decoderUnit, 'LosslessMatchSnapshotDecoder');
  final decoded = _singleClass(decoderUnit, 'DecodedRunningMatchSnapshot');
  final runningDecode = _singleMethod(codec, 'decode');
  final losslessDecode = _singleMethod(decoder, 'decode');
  final encode = _singleMethod(codec, 'encode');
  return [
    if (codec == null)
      'must declare exactly one RunningMatchSnapshotCodec'
    else if (codec.finalKeyword == null)
      'RunningMatchSnapshotCodec must be final',
    if (decoder == null)
      'must declare exactly one LosslessMatchSnapshotDecoder'
    else if (decoder.finalKeyword == null)
      'LosslessMatchSnapshotDecoder must be final',
    if (decoded == null)
      'must declare exactly one DecodedRunningMatchSnapshot'
    else if (decoded.finalKeyword == null)
      'DecodedRunningMatchSnapshot must be final',
    if (!_hasExactRunningDecodeContract(runningDecode))
      'decode must require exactly named WireMatch and WireSnapshot',
    if (!_hasExactLosslessDecodeContract(losslessDecode))
      'lossless decode must require exactly one WireSnapshot',
    if (!_hasExactEncodeContract(encode))
      'encode must require one positional source and optional legacy parts',
    if (!_hasFinalField(decoded, 'wire', 'WireSnapshot') ||
        !_hasFinalField(decoded, 'save', 'GameSave') ||
        !_hasFinalField(decoded, 'state', 'PersistentGameState'))
      'decoded snapshot must retain final wire, save, and state values',
    if (!_hasExactLosslessDecoderBinding(codecUnit))
      'running codec must bind exactly one const lossless decoder',
  ];
}

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

bool _hasExactRunningDecodeContract(MethodDeclaration? method) {
  if (method == null ||
      method.returnType?.toSource() != 'DecodedRunningMatchSnapshot') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 2) return false;
  return _isNamedParameter(
        parameters[0],
        name: 'match',
        type: 'WireMatch',
        required: true,
      ) &&
      _isNamedParameter(
        parameters[1],
        name: 'snapshot',
        type: 'WireSnapshot',
        required: true,
      );
}

bool _hasExactLosslessDecodeContract(MethodDeclaration? method) {
  if (method == null ||
      method.returnType?.toSource() != 'DecodedRunningMatchSnapshot') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  return parameters.length == 1 &&
      _isRequiredPositionalParameter(
        parameters.single,
        name: 'snapshot',
        type: 'WireSnapshot',
      );
}

bool _hasExactEncodeContract(MethodDeclaration? method) {
  if (method == null || method.returnType?.toSource() != 'WireSnapshot') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 3 ||
      !_isRequiredPositionalParameter(
        parameters[0],
        name: 'source',
        type: 'DecodedRunningMatchSnapshot',
      )) {
    return false;
  }
  return _isNamedParameter(
        parameters[1],
        name: 'save',
        type: 'GameSave?',
        required: false,
      ) &&
      _isNamedParameter(
        parameters[2],
        name: 'state',
        type: 'PersistentGameState?',
        required: false,
      );
}

bool _hasExactLosslessDecoderBinding(CompilationUnit unit) {
  final declarations = unit.declarations
      .whereType<TopLevelVariableDeclaration>()
      .where(
        (declaration) =>
            declaration.toSource() ==
            'const LosslessMatchSnapshotDecoder '
                '_losslessMatchSnapshotDecoder = '
                'LosslessMatchSnapshotDecoder();',
      );
  return declarations.length == 1;
}

bool _isRequiredPositionalParameter(
  FormalParameter parameter, {
  required String name,
  required String type,
}) {
  return parameter is SimpleFormalParameter &&
      parameter.name?.lexeme == name &&
      parameter.type?.toSource() == type &&
      parameter.requiredKeyword == null;
}

bool _isNamedParameter(
  FormalParameter parameter, {
  required String name,
  required String type,
  required bool required,
}) {
  if (parameter is! DefaultFormalParameter || !parameter.isNamed) return false;
  final normalized = parameter.parameter;
  return normalized is SimpleFormalParameter &&
      normalized.name?.lexeme == name &&
      normalized.type?.toSource() == type &&
      (normalized.requiredKeyword != null) == required &&
      parameter.defaultValue == null;
}

bool _hasFinalField(ClassDeclaration? declaration, String name, String type) {
  if (declaration == null) return false;
  final fields = declaration.body.members.whereType<FieldDeclaration>().where(
    (field) =>
        field.fields.variables.any((variable) => variable.name.lexeme == name),
  );
  if (fields.length != 1) return false;
  final field = fields.single.fields;
  return field.isFinal &&
      field.type?.toSource() == type &&
      field.variables.length == 1;
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

FieldDeclaration? _singleField(ClassDeclaration? declaration, String name) {
  if (declaration == null) return null;
  final fields = declaration.body.members.whereType<FieldDeclaration>().where(
    (field) =>
        field.fields.variables.any((variable) => variable.name.lexeme == name),
  );
  if (fields.length != 1 || fields.single.fields.variables.length != 1) {
    return null;
  }
  return fields.single;
}

ClassDeclaration? _singleClass(CompilationUnit unit, String name) {
  final declarations = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
  return declarations.length == 1 ? declarations.single : null;
}

MethodDeclaration? _singleMethod(ClassDeclaration? declaration, String name) {
  if (declaration == null) return null;
  final methods = declaration.body.members.whereType<MethodDeclaration>().where(
    (method) => method.name.lexeme == name && !method.isStatic,
  );
  return methods.length == 1 ? methods.single : null;
}

List<MethodInvocation> _targetedInvocations(
  AstNode node, {
  required String target,
  required String method,
}) {
  return _methodInvocations(
    node,
    method,
  ).where((call) => call.target?.toSource() == target).toList();
}

List<MethodInvocation> _methodInvocations(AstNode node, String name) {
  final collector = _MethodInvocationCollector(name)..collect(node);
  return collector.invocations;
}

List<_ConstructionReference> _constructions(AstNode node, String type) {
  final collector = _ConstructionCollector(type)..collect(node);
  return collector.references;
}

bool _hasSingleArgument(List<MethodInvocation> calls, String expected) {
  return calls.length == 1 &&
      calls.single.argumentList.arguments.length == 1 &&
      calls.single.argumentList.arguments.single.toSource() == expected;
}

Expression? _lastReturnedExpression(FunctionBody body) {
  if (body is ExpressionFunctionBody) return body.expression;
  if (body is! BlockFunctionBody || body.block.statements.isEmpty) return null;
  final statement = body.block.statements.last;
  return statement is ReturnStatement ? statement.expression : null;
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

Map<String, String> _namedArgumentSources(ArgumentList arguments) {
  return {
    for (final argument in arguments.arguments.whereType<NamedExpression>())
      argument.name.label.name: argument.expression.toSource(),
  };
}

bool _sameStringMap(Map<String, String> actual, Map<String, String> expected) {
  if (actual.length != expected.length) return false;
  return expected.entries.every((entry) => actual[entry.key] == entry.value);
}
