part of '../participant_resignation_integration_test.dart';

List<String> _selectiveSnapshotPatchViolations(CompilationUnit unit) {
  final method = _runningResignationMethod(unit);
  if (method == null) return const [];
  final nextSave = _variableInitializer(method.body, 'nextSave');
  final nextSaveCall = nextSave is MethodInvocation ? nextSave : null;
  final nextPersistentState = _variableInitializer(
    method.body,
    'nextPersistentState',
  );
  final persistentCall = nextPersistentState is MethodInvocation
      ? nextPersistentState
      : null;
  final persistentArguments = persistentCall == null
      ? const <String, String>{}
      : _namedArguments(persistentCall.argumentList);
  final runtimeExpression = persistentArguments['runtimeState'];
  final runtimeCall = _methodInvocations(method.body, 'copyWith')
      .where(
        (call) =>
            call.target?.toSource() == 'persistentState.runtimeState' &&
            call.toSource() == runtimeExpression,
      )
      .toList();
  final runtimeArguments = runtimeCall.length == 1
      ? _namedArguments(runtimeCall.single.argumentList)
      : const <String, String>{};
  return [
    if (nextSaveCall?.target?.toSource() != 'save' ||
        !_sameStringMap(
          nextSaveCall == null
              ? const <String, String>{}
              : _namedArguments(nextSaveCall.argumentList),
          const {'playerStates': 'transition.session.turnStatesByPlayerId'},
        ))
      'save patch must write only canonical turn states',
    if (persistentCall?.target?.toSource() != 'persistentState' ||
        persistentArguments.keys.toSet().difference({
          'runtimeState',
        }).isNotEmpty ||
        runtimeCall.length != 1 ||
        !_sameStringMap(runtimeArguments, const {
          'submittedPlayerIds': 'transition.session.submittedPlayerIds',
          'afkPlayerIds': 'transition.session.afkPlayerIds',
          'kickedPlayerIds': 'transition.session.kickedPlayerIds',
        }))
      'runtime patch must write only submitted, AFK, and kicked session slices',
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
