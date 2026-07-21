part of '../running_match_snapshot_codec_boundary_test.dart';

List<String> _codecBoundaryViolations(CompilationUnit unit) => [
  ..._codecShapeViolations(unit),
  ..._decodeFlowViolations(unit),
  ..._encodeFlowViolations(unit),
];

List<String> _codecShapeViolations(CompilationUnit unit) {
  final codec = _singleClass(unit, 'RunningMatchSnapshotCodec');
  final decoded = _singleClass(unit, 'DecodedRunningMatchSnapshot');
  final decode = _singleMethod(codec, 'decode');
  final encode = _singleMethod(codec, 'encode');
  return [
    if (codec == null)
      'must declare exactly one RunningMatchSnapshotCodec'
    else if (codec.finalKeyword == null)
      'RunningMatchSnapshotCodec must be final',
    if (decoded == null)
      'must declare exactly one DecodedRunningMatchSnapshot'
    else if (decoded.finalKeyword == null)
      'DecodedRunningMatchSnapshot must be final',
    if (!_hasExactDecodeContract(decode))
      'decode must require exactly named WireMatch and WireSnapshot',
    if (!_hasExactEncodeContract(encode))
      'encode must require one positional source and optional legacy parts',
    if (!_hasFinalField(decoded, 'wire', 'WireSnapshot') ||
        !_hasFinalField(decoded, 'save', 'GameSave') ||
        !_hasFinalField(decoded, 'state', 'PersistentGameState'))
      'decoded snapshot must retain final wire, save, and state values',
  ];
}

List<String> _decodeFlowViolations(CompilationUnit unit) {
  final codec = _singleClass(unit, 'RunningMatchSnapshotCodec');
  final decoded = _singleClass(unit, 'DecodedRunningMatchSnapshot');
  final decode = _singleMethod(codec, 'decode');
  if (decode == null) return const ['must declare decode'];

  return [
    ..._decodeLifecycleGuardViolations(decode.body),
    ..._decodeLazyWrapperViolations(decoded, decode.body),
  ];
}

List<String> _decodeLifecycleGuardViolations(FunctionBody body) {
  final lifecycleGuard = _firstStatementIf(body);
  final heuristicCollector = _PhaseHeuristicCollector()..collect(body);
  return [
    if (!_isExactRunningLifecycleGuard(lifecycleGuard))
      'decode must reject a non-running match as its first statement',
    if (heuristicCollector.found)
      'decode must not infer lifecycle from snapshot phase',
  ];
}

List<String> _decodeLazyWrapperViolations(
  ClassDeclaration? decoded,
  FunctionBody body,
) {
  final constructions = _constructions(body, 'DecodedRunningMatchSnapshot');
  return [
    if (!_constructsOnlyLazyRawWrapper(body, constructions))
      'decode must construct only the lazy raw-wire wrapper',
    if (!_hasLazyLegacyParsers(decoded))
      'legacy save and state parsing must remain lazy on the decoded wrapper',
    if (!_lifecycleGuardPrecedesConstruction(body, constructions))
      'lifecycle rejection must precede legacy parsing and construction',
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

bool _constructsOnlyLazyRawWrapper(
  FunctionBody body,
  List<_ConstructionReference> constructions,
) {
  final saveDecodes = _targetedInvocations(
    body,
    target: 'GameSave',
    method: 'fromJson',
  );
  final stateDecodes = _targetedInvocations(
    body,
    target: 'PersistentGameState',
    method: 'fromJson',
  );
  final conversions = [
    ..._methodInvocations(body, 'toCanonical'),
    ..._methodInvocations(body, 'toLegacy'),
  ];
  final conversionReferences = _ConversionReferenceCollector()..collect(body);
  final constructionArguments = constructions.length == 1
      ? _namedArgumentSources(constructions.single.arguments)
      : const <String, String>{};
  final returned = _secondReturnedExpression(body);
  return constructions.length == 1 &&
      identical(returned, constructions.single.node) &&
      saveDecodes.isEmpty &&
      stateDecodes.isEmpty &&
      conversions.isEmpty &&
      !conversionReferences.found &&
      _sameStringMap(constructionArguments, const {'wire': 'snapshot'});
}

bool _hasLazyLegacyParsers(ClassDeclaration? decoded) {
  return _hasLazyLegacyParser(
        decoded,
        fieldName: 'save',
        fieldType: 'GameSave',
        decoderType: 'GameSave',
        wireField: 'wire.save',
      ) &&
      _hasLazyLegacyParser(
        decoded,
        fieldName: 'state',
        fieldType: 'PersistentGameState',
        decoderType: 'PersistentGameState',
        wireField: 'wire.state',
      );
}

bool _lifecycleGuardPrecedesConstruction(
  FunctionBody body,
  List<_ConstructionReference> constructions,
) {
  final lifecycleGuard = _firstStatementIf(body);
  return lifecycleGuard != null &&
      constructions.length == 1 &&
      lifecycleGuard.end < constructions.single.node.offset &&
      identical(_secondReturnedExpression(body), constructions.single.node);
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

Expression? _secondReturnedExpression(FunctionBody body) {
  if (body is! BlockFunctionBody || body.block.statements.length != 2) {
    return null;
  }
  final second = body.block.statements[1];
  return second is ReturnStatement ? second.expression : null;
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

bool _hasExactDecodeContract(MethodDeclaration? method) {
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
  if (body is! BlockFunctionBody || body.block.statements.isEmpty) {
    return null;
  }
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
