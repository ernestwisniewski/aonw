import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

List<String> saveSnapshotSerializationBoundaryViolations({
  required String persistenceSource,
  required String protocolSource,
}) {
  final persistenceUnit = parseString(content: persistenceSource).unit;
  final protocolUnit = parseString(content: protocolSource).unit;
  final violations = <String>{};

  _addSnapshotAccessViolations(
    violations,
    method: _method(
      persistenceUnit,
      className: 'SaveSnapshotCodec',
      methodName: 'toJson',
    ),
    requiredProperty: 'rawPersistentState',
    allowedProperties: _persistenceSnapshotProperties,
    allowedInvocations: _persistenceInvocations,
    allowedConstructors: const {},
    allowedToJsonTargets: const {
      'snapshot.rawPersistentState',
      'snapshot.save',
    },
    allowedMapTargets: const {},
  );
  _addSnapshotAccessViolations(
    violations,
    method: _method(
      protocolUnit,
      className: 'SnapshotCodec',
      methodName: '_stateToJson',
    ),
    requiredProperty: 'playerCountries',
    allowedProperties: _protocolSnapshotProperties,
    allowedInvocations: _protocolInvocations,
    allowedConstructors: const {'MapEntry'},
    allowedToJsonTargets: const {
      'artifact',
      'city',
      'improvement',
      'snapshot.research',
      'snapshot.runtimeState',
      'snapshot.wonderRegistry',
      'unit',
    },
    allowedMapTargets: const {
      'snapshot.artifacts',
      'snapshot.cities',
      'snapshot.fieldImprovements',
      'snapshot.playerCountries',
      'snapshot.units',
    },
  );
  violations.addAll(
    _namesIn(
      persistenceUnit,
    ).union(_namesIn(protocolUnit)).intersection(_semanticSerializationNames),
  );
  return violations.toList()..sort();
}

void _addSnapshotAccessViolations(
  Set<String> violations, {
  required MethodDeclaration method,
  required String requiredProperty,
  required Set<String> allowedProperties,
  required Set<String> allowedInvocations,
  required Set<String> allowedConstructors,
  required Set<String> allowedToJsonTargets,
  required Set<String> allowedMapTargets,
}) {
  final parameter = _snapshotParameter(method);
  if (parameter == null) {
    violations.add('SaveSnapshot parameter');
    return;
  }
  final collector = _SnapshotAccessCollector(
    parameterName: parameter.name!.lexeme,
    allowedInvocations: allowedInvocations,
    allowedConstructors: allowedConstructors,
    allowedToJsonTargets: allowedToJsonTargets,
    allowedMapTargets: allowedMapTargets,
  );
  method.body.accept(collector);
  if (!collector.properties.contains(requiredProperty)) {
    violations.add(requiredProperty);
  }
  for (final property in collector.properties.difference(allowedProperties)) {
    violations.add(property);
  }
  if (collector.bareReferences > 0) {
    violations.add('snapshot');
  }
  violations.addAll(collector.callViolations);
}

SimpleFormalParameter? _snapshotParameter(MethodDeclaration method) {
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 1) return null;
  final parameter = parameters.single;
  return parameter is SimpleFormalParameter &&
          parameter.name != null &&
          parameter.type?.toSource() == 'SaveSnapshot'
      ? parameter
      : null;
}

MethodDeclaration _method(
  CompilationUnit unit, {
  required String className,
  required String methodName,
}) {
  final declaration = unit.declarations
      .whereType<ClassDeclaration>()
      .singleWhere(
        (candidate) => candidate.namePart.typeName.lexeme == className,
      );
  return declaration.body.members.whereType<MethodDeclaration>().singleWhere(
    (method) => method.name.lexeme == methodName,
  );
}

const _persistenceSnapshotProperties = {
  'eventLogOffset',
  'rawPersistentState',
  'save',
};

const _persistenceInvocations = {'toJson'};

const _protocolSnapshotProperties = {
  'artifacts',
  'cities',
  'fieldImprovements',
  'fogOfWar',
  'playerColors',
  'playerCountries',
  'playerGold',
  'playerStabilityNet',
  'playerWarWeariness',
  'research',
  'runtimeState',
  'units',
  'wonderRegistry',
};

const _protocolInvocations = {
  '_fogOfWarToJson',
  'MapEntry',
  'map',
  'toJson',
  'toList',
};

const _semanticSerializationNames = {
  'canonical',
  'CanonicalGameSnapshot',
  'effectivePlayerCountries',
  'LegacyGameSnapshotAdapter',
  'persistentState',
  'toCanonical',
  'toLegacy',
};

Set<String> _namesIn(AstNode node) {
  final collector = _NameCollector();
  node.accept(collector);
  return collector.names;
}

final class _NameCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

final class _SnapshotAccessCollector extends RecursiveAstVisitor<void> {
  _SnapshotAccessCollector({
    required this.parameterName,
    required this.allowedInvocations,
    required this.allowedConstructors,
    required this.allowedToJsonTargets,
    required this.allowedMapTargets,
  });

  final String parameterName;
  final Set<String> allowedInvocations;
  final Set<String> allowedConstructors;
  final Set<String> allowedToJsonTargets;
  final Set<String> allowedMapTargets;
  final Set<String> properties = {};
  final Set<String> callViolations = {};
  var bareReferences = 0;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != parameterName) {
      super.visitSimpleIdentifier(node);
      return;
    }
    final parent = node.parent;
    if (parent case PrefixedIdentifier(
      prefix: final prefix,
      identifier: final identifier,
    ) when identical(prefix, node)) {
      properties.add(identifier.name);
    } else if (parent case PropertyAccess(
      target: final target,
      propertyName: final propertyName,
    ) when identical(target, node)) {
      properties.add(propertyName.name);
    } else {
      bareReferences += 1;
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    final allowedShape = switch (name) {
      'toJson' || 'toList' =>
        node.argumentList.arguments.isEmpty &&
            (name == 'toJson'
                ? allowedToJsonTargets.contains(_targetPath(node.target))
                : node.target is MethodInvocation &&
                      _isAllowedMap(node.target! as MethodInvocation)),
      'map' => _isAllowedMap(node),
      '_fogOfWarToJson' =>
        node.target == null &&
            node.argumentList.arguments.length == 1 &&
            _isParameterProperty(
              node.argumentList.arguments.single,
              parameterName,
              'fogOfWar',
            ),
      'MapEntry' =>
        node.target == null && node.argumentList.arguments.length == 2,
      _ => false,
    };
    if (!allowedInvocations.contains(name) || !allowedShape) {
      callViolations.add(name);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    callViolations.add('function invocation');
    super.visitFunctionExpressionInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final name = node.constructorName.type.toSource();
    if (!allowedConstructors.contains(name)) {
      callViolations.add(name);
    }
    super.visitInstanceCreationExpression(node);
  }

  bool _isAllowedMap(MethodInvocation node) =>
      node.methodName.name == 'map' &&
      allowedMapTargets.contains(_targetPath(node.target)) &&
      node.argumentList.arguments.length == 1 &&
      node.argumentList.arguments.single is FunctionExpression;
}

String? _targetPath(Expression? target) => switch (target) {
  SimpleIdentifier(:final name) => name,
  PrefixedIdentifier(prefix: final prefix, identifier: final identifier) =>
    '${prefix.name}.${identifier.name}',
  PropertyAccess(
    target: final SimpleIdentifier receiver,
    propertyName: final property,
  ) =>
    '${receiver.name}.${property.name}',
  _ => null,
};

bool _isParameterProperty(
  Expression expression,
  String parameterName,
  String propertyName,
) {
  return switch (expression) {
    PrefixedIdentifier(prefix: final prefix, identifier: final identifier) =>
      prefix.name == parameterName && identifier.name == propertyName,
    PropertyAccess(
      target: final SimpleIdentifier target,
      propertyName: final property,
    ) =>
      target.name == parameterName && property.name == propertyName,
    _ => false,
  };
}
