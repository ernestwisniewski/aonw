part of 'authoritative_turn_movement_transport_guard.dart';

List<String> _forwardingViolations(
  Map<String, ResolvedUnitResult> resolvedUnits,
) {
  final violations = <String>[];
  final localUnit = resolvedUnits[_localResolverPath]?.unit;
  final serverUnit = resolvedUnits[_serverTurnsPath]?.unit;
  final canonicalUnit = resolvedUnits[_canonicalPipelinePath]?.unit;

  final localForwarding = _methodForwardingAudit(
    localUnit,
    ownerName: 'LocalCommandResolver',
    methodName: '_finalizeSimultaneousTurn',
    calledType: 'QueuedMovementEffectBuilder',
    calledMember: 'fromExecutions',
    provenance: const _ProvenanceExpectation(
      leafOwner: 'TurnMovementDelta',
      leafMember: 'executions',
      intermediateMembers: [('CanonicalTurnPipelineResult', 'movementDelta')],
      sourceOwner: 'CanonicalTurnPipeline',
      sourceMember: 'simultaneousFinalize',
    ),
  );
  if (!localForwarding.preservesProvenance) {
    violations.add(
      'LocalCommandResolver._finalizeSimultaneousTurn must forward '
      'TurnMovementDelta.executions directly to '
      'QueuedMovementEffectBuilder.fromExecutions.',
    );
  }
  if (localForwarding.hasDirectLeaf && !localForwarding.preservesProvenance) {
    violations.add(
      'LocalCommandResolver._finalizeSimultaneousTurn must preserve the '
      'CanonicalTurnPipeline result receiver provenance.',
    );
  }
  final serverForwarding = _constructorForwardingAudit(
    serverUnit,
    ownerName: 'ServerCommandReducerTurns',
    methodName: '_finalizeSimultaneousTurn',
    constructedType: '_CommandApplication',
    constructorName: 'accept',
    argumentName: 'movementExecutions',
    provenance: const _ProvenanceExpectation(
      leafOwner: 'TurnMovementDelta',
      leafMember: 'executions',
      intermediateMembers: [('CanonicalTurnPipelineResult', 'movementDelta')],
      sourceOwner: 'CanonicalTurnPipeline',
      sourceMember: 'simultaneousFinalize',
    ),
  );
  if (!serverForwarding.preservesProvenance) {
    violations.add(
      'ServerCommandReducerTurns._finalizeSimultaneousTurn must forward '
      'TurnMovementDelta.executions directly as movementExecutions.',
    );
  }
  if (serverForwarding.hasDirectLeaf && !serverForwarding.preservesProvenance) {
    violations.add(
      'ServerCommandReducerTurns._finalizeSimultaneousTurn must preserve the '
      'CanonicalTurnPipeline result receiver provenance.',
    );
  }
  final canonicalForwarding = _constructorForwardingAudit(
    canonicalUnit,
    ownerName: 'CanonicalTurnPipeline',
    methodName: 'simultaneousFinalize',
    constructedType: 'TurnMovementDelta',
    constructorName: null,
    argumentName: 'executions',
    provenance: const _ProvenanceExpectation(
      leafOwner: 'CanonicalTurnSuffixResult',
      leafMember: 'movementExecutions',
      sourceOwner: 'CanonicalTurnSuffix',
      sourceMember: 'finalizeAfterEconomy',
    ),
  );
  if (!canonicalForwarding.preservesProvenance) {
    violations.add(
      'CanonicalTurnPipeline.simultaneousFinalize must forward '
      'CanonicalTurnSuffixResult.movementExecutions directly into '
      'TurnMovementDelta.',
    );
  }
  if (canonicalForwarding.hasDirectLeaf &&
      !canonicalForwarding.preservesProvenance) {
    violations.add(
      'CanonicalTurnPipeline.simultaneousFinalize must preserve the '
      'CanonicalTurnSuffix result receiver provenance.',
    );
  }
  return violations;
}

List<String> _engineMovementForwardingViolations(
  Map<String, ResolvedUnitResult> resolvedUnits,
) {
  final forwarding = _constructorForwardingAudit(
    resolvedUnits[_serverDomainEnginePath]?.unit,
    ownerName: '_ServerCommandReducerUnitAction',
    methodName: '_applyDomainCommandEngine',
    constructedType: '_CommandApplication',
    constructorName: 'accept',
    argumentName: 'movementExecutions',
    provenance: const _ProvenanceExpectation(
      leafOwner: 'MovementExecutionDelta',
      leafMember: 'executions',
      intermediateMembers: [('GameEngineAccepted', 'movementDelta')],
      sourceOwner: 'GameEngine',
      sourceMember: 'apply',
    ),
  );
  return forwarding.preservesProvenance
      ? const []
      : const [
          '_ServerCommandReducerUnitAction._applyDomainCommandEngine must '
              'forward MovementExecutionDelta.executions directly as '
              'movementExecutions.',
        ];
}

_ForwardingAudit _methodForwardingAudit(
  CompilationUnit? unit, {
  required String ownerName,
  required String methodName,
  required String calledType,
  required String calledMember,
  required _ProvenanceExpectation provenance,
}) {
  final method = _method(unit, ownerName, methodName);
  if (method == null) return const _ForwardingAudit.missing();
  final calls = _InvocationCollector(calledType, calledMember);
  method.accept(calls);
  if (calls.nodes.length != 1) return const _ForwardingAudit.missing();
  final positional = calls.nodes.single.argumentList.arguments
      .where((argument) => argument is! NamedExpression)
      .toList();
  if (positional.isEmpty) return const _ForwardingAudit.missing();
  return _forwardingAudit(positional.first, method, provenance);
}

_ForwardingAudit _constructorForwardingAudit(
  CompilationUnit? unit, {
  required String ownerName,
  required String methodName,
  required String constructedType,
  required String? constructorName,
  required String argumentName,
  required _ProvenanceExpectation provenance,
}) {
  final method = _method(unit, ownerName, methodName);
  if (method == null) return const _ForwardingAudit.missing();
  final constructors = _InstanceCreationCollector(
    constructedType,
    constructorName: constructorName,
  );
  method.accept(constructors);
  if (constructors.nodes.length != 1) {
    return const _ForwardingAudit.missing();
  }
  final arguments = constructors.nodes.single.argumentList.arguments
      .whereType<NamedExpression>()
      .where((argument) => argument.name.label.name == argumentName)
      .toList();
  if (arguments.length != 1) return const _ForwardingAudit.missing();
  return _forwardingAudit(arguments.single.expression, method, provenance);
}

_ForwardingAudit _forwardingAudit(
  Expression expression,
  MethodDeclaration method,
  _ProvenanceExpectation provenance,
) {
  return _ForwardingAudit(
    hasDirectLeaf: _isDirectMember(
      expression,
      ownerName: provenance.leafOwner,
      memberName: provenance.leafMember,
    ),
    preservesProvenance: _matchesProvenance(expression, method, provenance),
  );
}

bool _matchesProvenance(
  Expression expression,
  MethodDeclaration method,
  _ProvenanceExpectation expectation,
) {
  final initializers = _FinalLocalInitializerCollector();
  method.accept(initializers);
  var current = _unwrapExpression(expression);
  if (!_isDirectMember(
    current,
    ownerName: expectation.leafOwner,
    memberName: expectation.leafMember,
  )) {
    return false;
  }
  final leafTarget = _directMemberTarget(current);
  if (leafTarget == null) return false;
  current = leafTarget;

  for (final member in expectation.intermediateMembers) {
    current = _expandedFinalLocal(current, initializers.byElementId);
    if (!_isDirectMember(
      current,
      ownerName: member.$1,
      memberName: member.$2,
    )) {
      return false;
    }
    final intermediateTarget = _directMemberTarget(current);
    if (intermediateTarget == null) return false;
    current = intermediateTarget;
  }

  current = _expandedFinalLocal(current, initializers.byElementId);
  return current is MethodInvocation &&
      _elementMemberKey(current.methodName.element) ==
          '${expectation.sourceOwner}.${expectation.sourceMember}';
}

Expression _expandedFinalLocal(
  Expression expression,
  Map<int, Expression> initializers,
) {
  var current = _unwrapExpression(expression);
  final expandedElementIds = <int>{};
  while (true) {
    final element = _expressionElement(current);
    final initializer = element == null ? null : initializers[element.id];
    if (initializer == null || !expandedElementIds.add(element!.id)) {
      return current;
    }
    current = _unwrapExpression(initializer);
  }
}

Expression _unwrapExpression(Expression expression) {
  var current = expression;
  while (current is ParenthesizedExpression) {
    current = current.expression;
  }
  return current;
}

Expression? _directMemberTarget(Expression expression) {
  final unwrapped = _unwrapExpression(expression);
  return switch (unwrapped) {
    PrefixedIdentifier(:final prefix) => prefix,
    PropertyAccess(:final realTarget) => realTarget,
    _ => null,
  };
}

final class _ProvenanceExpectation {
  const _ProvenanceExpectation({
    required this.leafOwner,
    required this.leafMember,
    this.intermediateMembers = const [],
    required this.sourceOwner,
    required this.sourceMember,
  });

  final String leafOwner;
  final String leafMember;
  final List<(String, String)> intermediateMembers;
  final String sourceOwner;
  final String sourceMember;
}

final class _ForwardingAudit {
  const _ForwardingAudit({
    required this.hasDirectLeaf,
    required this.preservesProvenance,
  });

  const _ForwardingAudit.missing()
    : hasDirectLeaf = false,
      preservesProvenance = false;

  final bool hasDirectLeaf;
  final bool preservesProvenance;
}

bool _sameCounts(Map<String, int> first, Map<String, int> second) {
  if (first.length != second.length) return false;
  for (final entry in first.entries) {
    if (second[entry.key] != entry.value) return false;
  }
  return true;
}

String _displayCounts(Map<String, int> counts) {
  final entries = counts.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return entries.map((entry) => '${entry.key} (${entry.value})').join(', ');
}
