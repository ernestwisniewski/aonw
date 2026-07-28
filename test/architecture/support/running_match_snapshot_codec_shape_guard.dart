part of '../running_match_snapshot_codec_boundary_test.dart';

List<String> _codecShapeViolations(
  CompilationUnit codecUnit,
  CompilationUnit losslessUnit,
) {
  final codec = _singleClass(codecUnit, 'RunningMatchSnapshotCodec');
  final losslessCodec = _singleClass(
    losslessUnit,
    'LosslessMatchSnapshotCodec',
  );
  final decoder = _singleClass(losslessUnit, 'LosslessMatchSnapshotDecoder');
  final decoded = _singleClass(losslessUnit, 'DecodedRunningMatchSnapshot');
  final runningDecode = _singleMethod(codec, 'decode');
  final losslessDecode = _singleMethod(losslessCodec, 'decode');
  final canonical = _singleMethod(losslessCodec, 'canonical');
  final losslessEncode = _singleMethod(losslessCodec, 'encodeCanonical');
  final validatedCanonical = _singleMethod(
    codec,
    'canonicalWithValidatedRoster',
  );
  final encode = _singleMethod(codec, 'encode');
  final encodeInitial = _singleMethod(codec, 'encodeInitial');
  final encodeCanonical = _singleMethod(codec, 'encodeCanonical');
  return [
    ..._nominalTypeViolations(codec, losslessCodec, decoder, decoded),
    ..._decodeContractViolations(
      runningDecode,
      losslessDecode,
      canonical,
      validatedCanonical,
    ),
    ..._encodeContractViolations(
      encode,
      encodeInitial,
      encodeCanonical,
      losslessEncode,
    ),
    ..._decodedWrapperShapeViolations(decoded, codecUnit),
  ];
}

List<String> _nominalTypeViolations(
  ClassDeclaration? codec,
  ClassDeclaration? losslessCodec,
  ClassDeclaration? decoder,
  ClassDeclaration? decoded,
) => [
  if (codec == null)
    'must declare exactly one RunningMatchSnapshotCodec'
  else if (codec.finalKeyword == null)
    'RunningMatchSnapshotCodec must be final',
  if (losslessCodec == null)
    'must declare exactly one LosslessMatchSnapshotCodec'
  else if (losslessCodec.finalKeyword == null)
    'LosslessMatchSnapshotCodec must be final',
  if (decoder == null)
    'must declare exactly one LosslessMatchSnapshotDecoder'
  else if (decoder.finalKeyword == null)
    'LosslessMatchSnapshotDecoder must be final',
  if (decoded == null)
    'must declare exactly one DecodedRunningMatchSnapshot'
  else if (decoded.finalKeyword == null)
    'DecodedRunningMatchSnapshot must be final',
];

List<String> _decodeContractViolations(
  MethodDeclaration? runningDecode,
  MethodDeclaration? losslessDecode,
  MethodDeclaration? canonical,
  MethodDeclaration? validatedCanonical,
) => [
  if (!_hasExactRunningDecodeContract(runningDecode))
    'decode must require exactly named WireMatch and WireSnapshot',
  if (!_hasExactLosslessDecodeContract(losslessDecode))
    'lossless codec decode must require exactly one WireSnapshot',
  if (!_hasExactCanonicalContract(canonical))
    'canonical must require exactly one decoded snapshot',
  if (!_hasExactValidatedCanonicalContract(validatedCanonical))
    'canonicalWithValidatedRoster must require one decoded source and named '
        'WireMatch',
];

List<String> _encodeContractViolations(
  MethodDeclaration? encode,
  MethodDeclaration? encodeInitial,
  MethodDeclaration? encodeCanonical,
  MethodDeclaration? losslessEncode,
) => [
  if (!_hasExactEncodeContract(encode))
    'encode must require one positional source and optional legacy parts',
  if (!_hasExactInitialEncodeContract(encodeInitial))
    'encodeInitial must require exactly named WireMatch and canonical '
        'snapshot',
  if (!_hasExactCanonicalEncodeContract(encodeCanonical))
    'encodeCanonical must require decoded source and canonical successor',
  if (!_hasExactLosslessEncodeContract(losslessEncode))
    'encodeCanonical must require exactly one canonical snapshot',
];

List<String> _decodedWrapperShapeViolations(
  ClassDeclaration? decoded,
  CompilationUnit codecUnit,
) => [
  if (!_hasFinalField(decoded, 'wire', 'WireSnapshot') ||
      !_hasFinalField(decoded, 'save', 'GameSave') ||
      !_hasFinalField(decoded, 'state', 'PersistentGameState'))
    'decoded snapshot must retain final wire, save, and state values',
  if (!_hasExactLosslessCodecBinding(codecUnit))
    'running codec must bind exactly one const lossless codec',
];

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

bool _hasExactCanonicalContract(MethodDeclaration? method) {
  if (method == null ||
      method.returnType?.toSource() != 'CanonicalGameSnapshot') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  return parameters.length == 1 &&
      _isRequiredPositionalParameter(
        parameters.single,
        name: 'snapshot',
        type: 'DecodedRunningMatchSnapshot',
      );
}

bool _hasExactValidatedCanonicalContract(MethodDeclaration? method) {
  if (method == null ||
      method.returnType?.toSource() != 'CanonicalGameSnapshot') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 2) return false;
  return _isRequiredPositionalParameter(
        parameters[0],
        name: 'source',
        type: 'DecodedRunningMatchSnapshot',
      ) &&
      _isNamedParameter(
        parameters[1],
        name: 'match',
        type: 'WireMatch',
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

bool _hasExactCanonicalEncodeContract(MethodDeclaration? method) {
  if (method == null || method.returnType?.toSource() != 'WireSnapshot') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  return parameters.length == 2 &&
      _isRequiredPositionalParameter(
        parameters[0],
        name: 'source',
        type: 'DecodedRunningMatchSnapshot',
      ) &&
      _isRequiredPositionalParameter(
        parameters[1],
        name: 'next',
        type: 'CanonicalGameSnapshot',
      );
}

bool _hasExactLosslessEncodeContract(MethodDeclaration? method) {
  if (method == null ||
      method.returnType?.toSource() !=
          '({GameSave save, PersistentGameState state})') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  return parameters.length == 1 &&
      _isRequiredPositionalParameter(
        parameters.single,
        name: 'snapshot',
        type: 'CanonicalGameSnapshot',
      );
}

bool _hasExactInitialEncodeContract(MethodDeclaration? method) {
  if (method == null || method.returnType?.toSource() != 'WireSnapshot') {
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
        type: 'CanonicalGameSnapshot',
        required: true,
      );
}

bool _hasExactLosslessCodecBinding(CompilationUnit unit) {
  final declarations = unit.declarations
      .whereType<TopLevelVariableDeclaration>()
      .where(
        (declaration) =>
            declaration.toSource() ==
            'const LosslessMatchSnapshotCodec '
                '_losslessMatchSnapshotCodec = '
                'LosslessMatchSnapshotCodec();',
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
