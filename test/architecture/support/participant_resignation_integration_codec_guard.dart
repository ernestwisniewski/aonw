part of '../participant_resignation_integration_test.dart';

List<String> _codecFlowViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) return const [];
  return [
    ..._decodeViolations(method),
    ..._decodedValueViolations(method),
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

List<String> _decodedValueViolations(MethodDeclaration method) {
  final persistentState = _variableInitializer(method.body, 'persistentState');
  final save = _variableInitializer(method.body, 'save');
  final canonicalSnapshot = _variableInitializer(
    method.body,
    'canonicalSnapshot',
  );
  return [
    if (persistentState?.toSource() != 'decodedSnapshot.state' ||
        save?.toSource() != 'decodedSnapshot.save' ||
        canonicalSnapshot?.toSource() != 'decodedSnapshot.canonical' ||
        _targetMemberReferenceCount(
              method.body,
              target: 'decodedSnapshot',
              member: 'canonical',
            ) !=
            1)
      'resignation must source state, save, and canonical data from '
          'decodedSnapshot',
    if (_directLegacyDecodeCalls(method.body).isNotEmpty ||
        _methodInvocations(method.body, 'toCanonical').isNotEmpty ||
        _methodInvocations(method.body, 'toLegacy').isNotEmpty ||
        method.body.toSource().contains('_lifecycleSnapshotAdapter'))
      'running resignation must not bypass the snapshot codec',
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
  final calls = _methodInvocations(method.body, 'encode')
      .where((call) => call.target?.toSource() == '_runningMatchSnapshotCodec')
      .toList();
  final encode = calls.length == 1 ? calls.single : null;
  final namedArguments = encode == null
      ? const <String, String>{}
      : _namedArguments(encode.argumentList);
  final positionalArguments = encode == null
      ? const <Expression>[]
      : encode.argumentList.arguments
            .whereType<Expression>()
            .where((argument) => argument is! NamedExpression)
            .toList();
  return [
    if (encode == null ||
        encode.argumentList.arguments.length != 3 ||
        positionalArguments.length != 1 ||
        positionalArguments.single.toSource() != 'decodedSnapshot' ||
        !_sameStringMap(namedArguments, const {
          'save': 'nextSave',
          'state': 'nextPersistentState',
        }))
      'resignation must encode the same decoded snapshot exactly once',
  ];
}

List<String> _runningStateSnapshotViolations(MethodDeclaration method) {
  final calls = _methodInvocations(method.body, 'encode')
      .where((call) => call.target?.toSource() == '_runningMatchSnapshotCodec')
      .toList();
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
      'running state must use the codec-encoded snapshot',
  ];
}

List<MethodInvocation> _directLegacyDecodeCalls(AstNode node) {
  return _methodInvocations(node, 'fromJson')
      .where(
        (call) => const {
          'GameSave',
          'PersistentGameState',
        }.contains(call.target?.toSource()),
      )
      .toList();
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
