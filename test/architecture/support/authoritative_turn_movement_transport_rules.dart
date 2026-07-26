part of 'authoritative_turn_movement_transport_guard.dart';

List<String> _constructorViolations(
  _TransportFacts facts, {
  required String typeName,
  required Map<String, int> expected,
}) {
  final actual = facts.constructorCounts[typeName] ?? const {};
  if (_sameCounts(actual, expected)) return const [];
  return [
    '$typeName constructor sites changed; expected '
        '${_displayCounts(expected)}, found ${_displayCounts(actual)}.',
  ];
}

List<String> _referenceViolations(_TransportFacts facts) {
  final violations = <String>[];
  for (final entry in _expectedReferences.entries) {
    final actual = facts.referenceCounts[entry.key] ?? const {};
    if (_sameCounts(actual, entry.value)) continue;
    violations.add(
      '${entry.key} reference sites changed; expected '
      '${_displayCounts(entry.value)}, found ${_displayCounts(actual)}.',
    );
  }
  return violations;
}

List<String> _envelopeViolations(
  Map<String, ResolvedUnitResult> resolvedUnits,
) {
  final violations = <String>[];
  for (final requirement in const [
    (_wireEventPath, 'WireEvent'),
    (_wireAckPath, 'WireCommandAck'),
  ]) {
    final unit = resolvedUnits[requirement.$1]?.unit;
    if (unit == null) {
      violations.add('${requirement.$1} must resolve for envelope audit.');
      continue;
    }
    final classes = unit.declarations.whereType<ClassDeclaration>().where(
      (declaration) => declaration.namePart.typeName.lexeme == requirement.$2,
    );
    final parameters = <FormalParameter>[];
    for (final declaration in classes) {
      for (final constructor
          in declaration.body.members.whereType<ConstructorDeclaration>()) {
        parameters.addAll(
          constructor.parameters.parameters.where(
            (parameter) => parameter.name?.lexeme == 'movementExecutions',
          ),
        );
      }
    }
    if (parameters.length != 1 ||
        !_isRequiredNonNullableNamedType(
          parameters.singleOrNull,
          'WireMovementExecutionList',
        )) {
      violations.add(
        '${requirement.$1}::${requirement.$2}.movementExecutions must be '
        'exactly one required non-null WireMovementExecutionList parameter.',
      );
    }
  }
  return violations;
}

bool _isRequiredNonNullableNamedType(
  FormalParameter? parameter,
  String typeName,
) {
  if (parameter == null || !parameter.isRequiredNamed) return false;
  final normalized = parameter is DefaultFormalParameter
      ? parameter.parameter
      : parameter;
  final type = switch (normalized) {
    SimpleFormalParameter(:final type) => type,
    FieldFormalParameter(:final type) => type,
    _ => null,
  };
  if (type is! NamedType || type.question != null) return false;
  return _interfaceName(type) == typeName;
}

List<String> _projectorEgressViolations(
  Map<String, ResolvedUnitResult> resolvedUnits,
) {
  final unit = resolvedUnits[_viewProjectorPath]?.unit;
  final violations = <String>[];
  for (final requirement in const [
    (
      methodName: 'eventFor',
      envelopeType: 'WireEvent',
      canonicalType: 'WireEvent',
    ),
    (
      methodName: '_ackForPrepared',
      envelopeType: 'WireCommandAck',
      canonicalType: 'WireCommandAck',
    ),
  ]) {
    final method = _method(
      unit,
      'PlayerMatchViewProjector',
      requirement.methodName,
    );
    if (method != null &&
        _constructorArgumentIsDirectProjectedMovement(
          method,
          envelopeType: requirement.envelopeType,
          canonicalType: requirement.canonicalType,
        )) {
      continue;
    }
    violations.add(
      'PlayerMatchViewProjector.${requirement.methodName} must forward '
      'PlayerMatchMovementAudience.projectForRecipient directly as the '
      'movementExecutions argument.',
    );
  }
  return violations;
}

bool _constructorArgumentIsDirectProjectedMovement(
  MethodDeclaration method, {
  required String envelopeType,
  required String canonicalType,
}) {
  final canonicalElement = _parameterElement(method, 'canonical');
  if (canonicalElement is! FormalParameterElement ||
      canonicalElement.type.element?.baseElement.displayName != canonicalType) {
    return false;
  }
  final constructors = _InstanceCreationCollector(envelopeType);
  method.accept(constructors);
  if (constructors.nodes.length != 1) return false;
  final arguments = constructors.nodes.single.argumentList.arguments
      .whereType<NamedExpression>()
      .where((argument) => argument.name.label.name == 'movementExecutions')
      .toList();
  if (arguments.length != 1) return false;
  final expression = arguments.single.expression;
  if (expression is! MethodInvocation ||
      _elementMemberKey(expression.methodName.element) !=
          'PlayerMatchMovementAudience.projectForRecipient') {
    return false;
  }
  final positional = expression.argumentList.arguments.where(
    (argument) => argument is! NamedExpression,
  );
  if (positional.length != 1) return false;
  return _isDirectNamedMemberOfElement(
    positional.single,
    memberName: 'movementExecutions',
    receiverElement: canonicalElement,
  );
}
