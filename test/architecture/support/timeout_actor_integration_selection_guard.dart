part of '../timeout_actor_integration_test.dart';

List<String> _timeoutSelectionViolations(CompilationUnit unit) => [
  ..._timeoutSelectionShapeViolations(unit),
  ..._timeoutSelectionSourceViolations(unit),
  ..._timeoutSelectionCallViolations(unit),
  ..._timeoutSelectionForbiddenViolations(unit),
];

List<String> _timeoutSelectionShapeViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) {
    return const ['must declare exactly one _selectTimeoutActorPlayerId'];
  }
  return [
    if (method.returnType?.toSource() != 'String?' ||
        !_hasExactRequiredNamedParameters(method, const {
          'match': 'WireMatch',
          'save': 'GameSave',
          'canonicalSnapshot': 'CanonicalGameSnapshot',
        }))
      '_selectTimeoutActorPlayerId must require match/save/canonicalSnapshot',
    if (_singleMethod(unit, '_timeoutActorPlayerId') != null)
      'legacy _timeoutActorPlayerId must be removed',
  ];
}

List<String> _timeoutSelectionSourceViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) return const [];
  final active = _singleVariableInitializer(method.body, 'activePlayerIds');
  const expected =
      '{for (final player in save.players) '
      'if (player.id.isNotEmpty) player.id, '
      'for (final playerId in '
      'canonicalSnapshot.session.turnStatesByPlayerId.keys) '
      'if (playerId.isNotEmpty) playerId}';
  return [
    if (active?.toSource() != expected)
      'timeout active IDs must use save players and canonical turn states',
  ];
}

List<String> _timeoutSelectionCallViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) return const [];
  final calls = _methodInvocations(
    method.body,
    'select',
  ).where((call) => call.target?.toSource() == 'TimeoutActorSelector').toList();
  if (calls.length != 1) {
    return const [
      'timeout selection must call TimeoutActorSelector.select once',
    ];
  }
  final arguments = calls.single.argumentList;
  final returns = _ReturnCollector()..collect(method.body);
  const ordered =
      '[for (final player in match.players) '
      'if (activePlayerIds.contains(player.id)) player.id]';
  return [
    if (_namedArgumentSource(arguments, 'orderedParticipantPlayerIds') !=
        ordered)
      'timeout selection must use the filtered Wire roster',
    if (_namedArgumentSource(arguments, 'submittedPlayerIds') !=
        'canonicalSnapshot.session.submittedPlayerIds')
      'timeout selection must read submitted from canonical session',
    if (_namedArgumentSource(arguments, 'kickedPlayerIds') !=
        'canonicalSnapshot.session.kickedPlayerIds')
      'timeout selection must read kicked from canonical session',
    if (returns.statements.length != 1 ||
        !identical(returns.statements.single.expression, calls.single))
      'timeout selector result must be returned directly',
  ];
}

List<String> _timeoutSelectionForbiddenViolations(CompilationUnit unit) {
  final method = _singleMethod(unit, '_selectTimeoutActorPlayerId');
  if (method == null) return const [];
  final identifiers = _IdentifierCollector()..collect(method.body);
  return [
    if (identifiers.names.contains('runtimeState'))
      'timeout selection must not read runtimeState',
    if (identifiers.names.contains('sort'))
      'timeout selection must preserve Wire order without sort()',
  ];
}
