import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'movement_command_boundary_guard.dart';

const _persistentResultFields = {
  'accepted': 'bool',
  'state': 'PersistentGameState',
  'events': 'List<GameEvent>',
  'execution': 'MovementCommandExecution?',
  'reason': 'String?',
};

const _domainResultFields = {
  'accepted': 'bool',
  'state': 'DomainState',
  'events': 'List<GameEvent>',
  'execution': 'MovementCommandExecution?',
  'reason': 'String?',
};

const _persistentResultParameters = [
  _AdapterParameter('accepted', 'bool', required: true),
  _AdapterParameter('state', 'PersistentGameState', required: true),
  _AdapterParameter('events', 'List<GameEvent>', defaultValue: 'const []'),
  _AdapterParameter('execution', 'MovementCommandExecution?'),
  _AdapterParameter('reason', 'String?'),
];

const _domainResultParameters = [
  _AdapterParameter('accepted', 'bool', required: true),
  _AdapterParameter('state', 'DomainState', required: true),
  _AdapterParameter('events', 'List<GameEvent>', defaultValue: 'const []'),
  _AdapterParameter('execution', 'MovementCommandExecution?'),
  _AdapterParameter('reason', 'String?'),
];

const _resolveParameters = [
  _AdapterParameter('state', 'STATE', required: true),
  _AdapterParameter('command', 'MoveUnitCommand', required: true),
  _AdapterParameter('actorPlayerId', 'String', required: true),
  _AdapterParameter('mapData', 'MapTraversalView', required: true),
  _AdapterParameter('canAct', 'bool', defaultValue: 'true'),
  _AdapterParameter(
    'visibilityMode',
    'MovementCommandVisibilityMode',
    defaultValue: 'MovementCommandVisibilityMode.authoritative',
  ),
];

List<String> movementAdapterPublicApiViolations(
  Map<String, String> sources,
) => [
  ..._adapterFileViolations(
    sources[movementPersistentAdapterPath],
    path: movementPersistentAdapterPath,
    resultClass: 'PersistentMoveUnitResult',
    resultFields: _persistentResultFields,
    resultParameters: _persistentResultParameters,
    resolverClass: 'PersistentMoveUnitResolver',
    resolverField: const MapEntry('fogOfWarService', 'FogOfWarService'),
    resolverParameter: const _AdapterParameter(
      'fogOfWarService',
      'FogOfWarService',
      defaultValue: 'const FogOfWarService()',
    ),
    stateType: 'PersistentGameState',
    resultType: 'PersistentMoveUnitResult',
  ),
  ..._adapterFileViolations(
    sources[movementDomainAdapterPath],
    path: movementDomainAdapterPath,
    resultClass: 'DomainMoveUnitResult',
    resultFields: _domainResultFields,
    resultParameters: _domainResultParameters,
    resolverClass: 'DomainMoveUnitResolver',
    resolverField: const MapEntry('commandResolver', 'MovementCommandResolver'),
    resolverParameter: const _AdapterParameter(
      'commandResolver',
      'MovementCommandResolver',
      defaultValue: 'const MovementCommandResolver()',
    ),
    stateType: 'DomainState',
    resultType: 'DomainMoveUnitResult',
  ),
];

List<String> _adapterFileViolations(
  String? source, {
  required String path,
  required String resultClass,
  required Map<String, String> resultFields,
  required List<_AdapterParameter> resultParameters,
  required String resolverClass,
  required MapEntry<String, String> resolverField,
  required _AdapterParameter resolverParameter,
  required String stateType,
  required String resultType,
}) {
  if (source == null) return ['$path must exist'];
  final unit = parseString(content: source, path: path).unit;
  final result = _singleClass(unit, resultClass);
  final resolver = _singleClass(unit, resolverClass);
  final constructor = _singleConstructor(result);
  final resolverConstructor = _singleConstructor(resolver);
  final resolve = _singleMethod(resolver, 'resolve');
  final exactResolveParameters = [
    for (final parameter in _resolveParameters)
      parameter.name == 'state'
          ? _AdapterParameter('state', stateType, required: true)
          : parameter,
  ];

  return [
    if (!_hasExactTopLevelClasses(unit, {resultClass, resolverClass}))
      '$path must declare only $resultClass and $resolverClass',
    ..._classShapeViolations(
      result,
      className: resultClass,
      fields: resultFields,
      publicMethods: const {},
    ),
    if (constructor == null ||
        constructor.constKeyword == null ||
        !_hasExactNamedParameters(
          constructor,
          resultParameters,
          inferredFieldTypes: resultFields,
        ))
      '$resultClass constructor must expose its exact result contract',
    ..._classShapeViolations(
      resolver,
      className: resolverClass,
      fields: {resolverField.key: resolverField.value},
      publicMethods: const {'method:resolve'},
    ),
    if (resolverConstructor == null ||
        resolverConstructor.constKeyword == null ||
        !_hasExactNamedParameters(
          resolverConstructor,
          [resolverParameter],
          inferredFieldTypes: {resolverField.key: resolverField.value},
        ))
      '$resolverClass constructor must expose only ${resolverField.key}',
    if (resolve == null ||
        resolve.isStatic ||
        resolve.returnType?.toSource() != resultType ||
        !_hasExactNamedParameters(resolve, exactResolveParameters))
      '$resolverClass.resolve must expose its exact adapter contract',
  ];
}

List<String> _classShapeViolations(
  ClassDeclaration? declaration, {
  required String className,
  required Map<String, String> fields,
  required Set<String> publicMethods,
}) => [
  if (!_isFinalClass(declaration)) '$className must remain a final class',
  if (!_hasExactFinalFields(declaration, fields))
    '$className must expose only its reviewed final fields',
  if (!_sameSet(_constructorNames(declaration), const {''}) ||
      !_sameSet(_publicMethodNames(declaration), publicMethods))
    '$className must not widen its public API',
];

bool _hasExactTopLevelClasses(CompilationUnit unit, Set<String> expected) {
  final classes = unit.declarations.whereType<ClassDeclaration>().toList();
  return unit.declarations.length == expected.length &&
      classes.length == expected.length &&
      _sameSet({
        for (final declaration in classes) declaration.namePart.typeName.lexeme,
      }, expected);
}

bool _isFinalClass(ClassDeclaration? declaration) =>
    declaration != null &&
    declaration.finalKeyword != null &&
    declaration.abstractKeyword == null &&
    declaration.baseKeyword == null &&
    declaration.interfaceKeyword == null &&
    declaration.mixinKeyword == null &&
    declaration.sealedKeyword == null &&
    declaration.extendsClause == null &&
    declaration.withClause == null &&
    declaration.implementsClause == null &&
    declaration.namePart.typeParameters == null;

bool _hasExactFinalFields(
  ClassDeclaration? declaration,
  Map<String, String> expected,
) {
  if (declaration == null) return false;
  final actual = <String, String>{};
  for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
    if (field.isStatic || !field.fields.isFinal || field.fields.isLate) {
      return false;
    }
    final type = field.fields.type?.toSource();
    if (type == null) return false;
    for (final variable in field.fields.variables) {
      if (actual.containsKey(variable.name.lexeme)) return false;
      actual[variable.name.lexeme] = type;
    }
  }
  return actual.length == expected.length &&
      actual.entries.every((entry) => expected[entry.key] == entry.value);
}

Set<String> _constructorNames(ClassDeclaration? declaration) => {
  for (final constructor
      in declaration?.body.members.whereType<ConstructorDeclaration>() ??
          const <ConstructorDeclaration>[])
    constructor.name?.lexeme ?? '',
};

Set<String> _publicMethodNames(ClassDeclaration? declaration) => {
  for (final method
      in declaration?.body.members.whereType<MethodDeclaration>() ??
          const <MethodDeclaration>[])
    if (!method.name.lexeme.startsWith('_'))
      '${method.isGetter
          ? 'getter'
          : method.isSetter
          ? 'setter'
          : 'method'}:${method.name.lexeme}',
};

ClassDeclaration? _singleClass(CompilationUnit unit, String name) {
  final matches = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
  return matches.length == 1 ? matches.single : null;
}

ConstructorDeclaration? _singleConstructor(ClassDeclaration? declaration) {
  final matches =
      declaration?.body.members.whereType<ConstructorDeclaration>().where(
        (constructor) => constructor.name == null,
      ) ??
      const <ConstructorDeclaration>[];
  return matches.length == 1 ? matches.single : null;
}

MethodDeclaration? _singleMethod(ClassDeclaration? declaration, String name) {
  final matches =
      declaration?.body.members.whereType<MethodDeclaration>().where(
        (method) => method.name.lexeme == name,
      ) ??
      const <MethodDeclaration>[];
  return matches.length == 1 ? matches.single : null;
}

bool _hasExactNamedParameters(
  dynamic declaration,
  List<_AdapterParameter> expected, {
  Map<String, String> inferredFieldTypes = const {},
}) {
  final FormalParameterList? list = switch (declaration) {
    MethodDeclaration(:final parameters) => parameters,
    ConstructorDeclaration(:final parameters) => parameters,
    _ => null,
  };
  final parameters = list?.parameters ?? const <FormalParameter>[];
  if (parameters.length != expected.length) return false;
  for (var index = 0; index < parameters.length; index++) {
    final parameter = parameters[index];
    if (parameter is! DefaultFormalParameter || !parameter.isNamed) {
      return false;
    }
    final normalized = parameter.parameter;
    final name = normalized.name?.lexeme;
    final type = switch (normalized) {
      SimpleFormalParameter(:final type) => type,
      FieldFormalParameter(:final type) => type,
      _ => null,
    };
    final shape = expected[index];
    if (name != shape.name ||
        (type?.toSource() ?? inferredFieldTypes[name]) != shape.type ||
        (normalized.requiredKeyword != null) != shape.required ||
        parameter.defaultValue?.toSource() != shape.defaultValue) {
      return false;
    }
  }
  return true;
}

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);

final class _AdapterParameter {
  const _AdapterParameter(
    this.name,
    this.type, {
    this.required = false,
    this.defaultValue,
  });

  final String name;
  final String type;
  final bool required;
  final String? defaultValue;
}
