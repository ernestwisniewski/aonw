part of '../participant_resignation_integration_test.dart';

List<String> _codecFlowViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) return const [];
  return [
    ..._decodeViolations(method),
    ..._validatedCanonicalViolations(method),
    ..._transitionViolations(method),
    ..._encodeViolations(method),
  ];
}

List<String> _decodeViolations(MethodDeclaration method) {
  final decodedSnapshot = _variableInitializer(method.body, 'decodedSnapshot');
  final calls = _methodInvocations(method.body, 'decode')
      .where((call) => call.target?.toSource() == '_runningMatchSnapshotCodec')
      .toList();
  final decode = calls.length == 1 ? calls.single : null;
  final arguments = decode == null
      ? const <String, String>{}
      : _namedArguments(decode.argumentList);
  return [
    if (decode == null ||
        decodedSnapshot?.toSource() != decode.toSource() ||
        decode.argumentList.arguments.length != 2 ||
        !_sameStringMap(arguments, const {
          'match': 'state.match',
          'snapshot': 'state.snapshot',
        }))
      'resignation must decode the running snapshot exactly once',
  ];
}

List<String> _validatedCanonicalViolations(MethodDeclaration method) {
  final canonicalSnapshot = _variableInitializer(
    method.body,
    'canonicalSnapshot',
  );
  final calls = _targetedInvocations(
    method.body,
    target: '_runningMatchSnapshotCodec',
    method: 'canonicalWithValidatedRoster',
  );
  final validation = calls.length == 1 ? calls.single : null;
  final positional = validation == null
      ? const <String>[]
      : _positionalArguments(validation.argumentList);
  final named = validation == null
      ? const <String, String>{}
      : _namedArguments(validation.argumentList);
  return [
    if (!_isInitializerInvocation(canonicalSnapshot, validation) ||
        positional.length != 1 ||
        positional.single != 'decodedSnapshot' ||
        !_sameStringMap(named, const {'match': 'state.match'}) ||
        validation?.argumentList.arguments.length != 2 ||
        _targetMemberReferenceCount(
              method.body,
              target: 'decodedSnapshot',
              member: 'canonical',
            ) !=
            0)
      'canonical snapshot must come from validated roster exactly once',
  ];
}

List<String> _transitionViolations(MethodDeclaration method) {
  final calls = _methodInvocations(method.body, 'apply')
      .where(
        (call) => call.target?.toSource() == 'ParticipantResignationTransition',
      )
      .toList();
  final arguments = calls.length == 1
      ? _namedArguments(calls.single.argumentList)
      : const <String, String>{};
  const orderedWireHumans =
      '[for (final matchPlayer in state.match.players) '
      'if (matchPlayer.kind == WirePlayerKind.human) matchPlayer.id]';
  return [
    if (!_sameStringMap(arguments, const {
      'domain': 'canonicalSnapshot.domain',
      'session': 'canonicalSnapshot.session',
      'actorPlayerId': 'player.id',
      'orderedHumanPlayerIds': orderedWireHumans,
    }))
      'transition must receive canonical state and Wire human order',
  ];
}

List<String> _encodeViolations(MethodDeclaration method) {
  return [
    ..._codecEncodeCallViolations(method),
    ..._runningStateSnapshotViolations(method),
  ];
}

List<String> _codecEncodeCallViolations(MethodDeclaration method) {
  final calls = _targetedInvocations(
    method.body,
    target: '_runningMatchSnapshotCodec',
    method: 'encodeCanonical',
  );
  final encode = calls.length == 1 ? calls.single : null;
  final positionalArguments = encode == null
      ? const <String>[]
      : _positionalArguments(encode.argumentList);
  return [
    if (encode == null ||
        encode.argumentList.arguments.length != 2 ||
        positionalArguments.length != 2 ||
        positionalArguments[0] != 'decodedSnapshot' ||
        positionalArguments[1] != 'nextSnapshot' ||
        _namedArguments(encode.argumentList).isNotEmpty)
      'resignation must encode the validated canonical transition exactly '
          'once',
  ];
}

List<String> _runningStateSnapshotViolations(MethodDeclaration method) {
  final calls = _targetedInvocations(
    method.body,
    target: '_runningMatchSnapshotCodec',
    method: 'encodeCanonical',
  );
  final encode = calls.length == 1 ? calls.single : null;
  final runningState = _variableInitializer(method.body, 'runningState');
  final runningStateCall = runningState is MethodInvocation
      ? runningState
      : null;
  final snapshotExpression = runningStateCall == null
      ? null
      : _namedExpression(runningStateCall.argumentList, 'snapshot');
  return [
    if (runningStateCall?.target?.toSource() != 'state' ||
        runningStateCall?.methodName.name != 'copyWith' ||
        encode == null ||
        snapshotExpression == null ||
        !_usesCodecEncodeResult(method.body, snapshotExpression, encode))
      'running state must use the canonical codec result',
  ];
}

bool _usesCodecEncodeResult(
  AstNode body,
  Expression snapshotExpression,
  MethodInvocation encode,
) {
  if (snapshotExpression.offset == encode.offset &&
      snapshotExpression.length == encode.length) {
    return true;
  }
  if (snapshotExpression case SimpleIdentifier(:final name)) {
    final initializer = _variableInitializer(body, name);
    return initializer?.offset == encode.offset &&
        initializer?.length == encode.length;
  }
  return false;
}
