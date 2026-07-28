part of '../participant_resignation_integration_test.dart';

List<String> _canonicalPatchViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) return const [];
  final nextSnapshot = _variableInitializer(method.body, 'nextSnapshot');
  final copy = nextSnapshot is MethodInvocation ? nextSnapshot : null;
  final canonicalCopies = _targetedInvocations(
    method.body,
    target: 'canonicalSnapshot',
    method: 'copyWith',
  );
  final arguments = copy == null
      ? const <String, String>{}
      : _namedArguments(copy.argumentList);
  return [
    if (copy?.target?.toSource() != 'canonicalSnapshot' ||
        canonicalCopies.length != 1 ||
        !identical(copy, canonicalCopies.single) ||
        copy?.argumentList.arguments.length != 1 ||
        !_sameStringMap(arguments, const {'session': 'transition.session'}))
      'canonical patch must write only the transition session',
  ];
}

List<String> _legacyAccessViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) return const [];
  final decodedPartReferences =
      _targetMemberReferenceCount(
        method.body,
        target: 'decodedSnapshot',
        member: 'save',
      ) +
      _targetMemberReferenceCount(
        method.body,
        target: 'decodedSnapshot',
        member: 'state',
      );
  const forbiddenNames = {
    'GameSave',
    'PersistentGameState',
    'GameRuntimeState',
    'runtimeState',
    'toJson',
    'toLegacy',
    'toCanonical',
  };
  final referencedForbiddenNames = _referencedForbiddenNames(
    method.body,
    forbiddenNames,
  );
  final legacyEncodeCalls = _methodInvocations(method.body, 'encode');
  return [
    if (decodedPartReferences != 0)
      'resignation must not access decoded legacy snapshot parts',
    if (referencedForbiddenNames.isNotEmpty || legacyEncodeCalls.isNotEmpty)
      'resignation must not reference legacy snapshot state or conversion APIs',
  ];
}

List<String> _lifecycleDecisionViolations(CompilationUnit unit) {
  final method =
      _methodNamed(unit, '_stateAfterResignationTransition') ??
      _runningResignationMethod(unit);
  if (method == null) return const [];
  final source = method.body.toSource();
  const cases = [
    'ParticipantResignationDisposition.unchanged',
    'ParticipantResignationDisposition.running',
    'ParticipantResignationDisposition.finished',
    'ParticipantResignationDisposition.abandoned',
  ];
  return [
    if (_methodInvocations(method.body, 'alivePlayerIds').isNotEmpty ||
        source.contains('GameOutcomeDetector') ||
        source.contains('_remainingHumanPlayers'))
      'server resignation must not resolve alive players directly',
    if (cases.any((value) => !source.contains(value)) ||
        !source.contains('_finishedStateAfterResignation') ||
        !source.contains('_stateAccess.abandonedState'))
      'server must map every typed disposition to its lifecycle overlay',
  ];
}
