import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

part 'support/world_map_combat_boundary_fixtures.dart';
part 'support/world_map_combat_application_targets.dart';
part 'support/world_map_combat_city_targets.dart';
part 'support/world_map_combat_interaction_targets.dart';
part 'support/world_map_combat_turn_combat_targets.dart';
part 'support/world_map_combat_movement_targets.dart';

const _targets = [
  ..._applicationTargets,
  ..._cityTargets,
  ..._interactionTargets,
  ..._turnCombatTargets,
  ..._movementTargets,
];

void main() {
  test('migrated gameplay boundaries declare canonical map APIs', () {
    final sources = productionDartSources();
    final mapDataTypeNames = mapDataBackedTypeNames(sources);
    final mapBoundaryTypeNames = typeNamesBackedBy(
      sources,
      _mapBoundaryRootTypeNames,
    );
    for (final target in _targets) {
      expect(
        _violations(
          File(target.path).readAsStringSync(),
          target,
          mapDataTypeNames: mapDataTypeNames,
          mapBoundaryTypeNames: mapBoundaryTypeNames,
        ),
        isEmpty,
        reason: target.path,
      );
    }
  });

  _registerWorldMapCombatBoundaryFixtures();
}

List<String> _violations(
  String source,
  _Target target, {
  Set<String> mapDataTypeNames = const {'WorldMap'},
  Set<String> mapBoundaryTypeNames = _mapBoundaryRootTypeNames,
}) {
  final unit = parseString(content: source, path: target.path).unit;
  final owner = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == target.owner,
  );
  final violations = <String>[];
  if (owner.length != 1) {
    return ['${target.owner} must declare exactly one class'];
  }

  for (final boundary in target.boundaries) {
    _checkBoundary(
      owner.single,
      boundary,
      violations,
      mapDataTypeNames: mapDataTypeNames,
      mapBoundaryTypeNames: mapBoundaryTypeNames,
    );
  }
  if (_namedTypes(unit).contains('MapDefinition')) {
    violations.add('must not reference MapDefinition');
  }
  final importsMapDefinition = unit.directives
      .whereType<ImportDirective>()
      .map((directive) => directive.uri.stringValue)
      .any((uri) => uri != null && uri.endsWith('map_definition.dart'));
  if (importsMapDefinition) {
    violations.add('must not import map_definition.dart');
  }
  return violations;
}

void _checkBoundary(
  ClassDeclaration owner,
  _Boundary boundary,
  List<String> violations, {
  required Set<String> mapDataTypeNames,
  required Set<String> mapBoundaryTypeNames,
}) {
  final member = _memberFor(owner, boundary);
  final boundaryName = boundary.name.isEmpty ? '<unnamed>' : boundary.name;
  final memberLabel = '${owner.namePart.typeName.lexeme}.$boundaryName';
  if (member == null) {
    violations.add('$memberLabel must declare a public ${boundary.kind.label}');
    return;
  }

  final parameters = _parametersFor(member);
  if (parameters == null) {
    violations.add('$memberLabel must declare a parameter list');
    return;
  }
  final parameter = _parameterFor(parameters, boundary.parameter);
  if (parameter == null) {
    violations.add(
      '$memberLabel must declare a ${boundary.parameter} parameter',
    );
  } else {
    final parameterType = _parameterType(parameter, owner);
    _checkBoundaryType(
      label: '$memberLabel.${boundary.parameter}',
      type: parameterType,
      expectedType: boundary.type,
      nullable: boundary.nullable,
      violations: violations,
    );
  }

  for (final parameter in parameters.parameters) {
    final normalized = _unwrap(parameter);
    final parameterName = normalized.name?.lexeme ?? '<unnamed>';
    if (_containsAnyNamedType(
      _parameterType(normalized, owner),
      mapDataTypeNames,
    )) {
      violations.add(
        '$memberLabel must not expose WorldMap through parameter '
        '$parameterName',
      );
    }
    if (parameterName != boundary.parameter &&
        _containsAnyNamedType(
          _parameterType(normalized, owner),
          mapBoundaryTypeNames,
        )) {
      violations.add(
        '$memberLabel must not expose an additional map dependency through '
        'parameter $parameterName',
      );
    }
  }

  if (boundary.kind == _BoundaryKind.constructor && boundary.requireField) {
    final field = _fieldFor(owner, boundary.parameter);
    final fieldLabel =
        '${owner.namePart.typeName.lexeme}.${boundary.parameter} field';
    if (field == null) {
      violations.add('$fieldLabel must be declared');
      return;
    }
    final fieldType = _fieldType(owner, boundary.parameter);
    _checkBoundaryType(
      label: fieldLabel,
      type: fieldType,
      expectedType: boundary.type,
      nullable: boundary.nullable,
      violations: violations,
    );
    if (_containsAnyNamedType(fieldType, mapDataTypeNames)) {
      violations.add('$fieldLabel must not expose WorldMap');
    }
  }
}

const _mapBoundaryRootTypeNames = {
  'MapDefinition',
  'MapSurvey',
  'MapTileCatalog',
  'MapTileLookup',
  'MapTileSource',
  'MapTraversalView',
  'MapReadView',
  'WorldMap',
  'WorldMapReadView',
};

AstNode? _memberFor(ClassDeclaration owner, _Boundary boundary) {
  for (final member in owner.body.members) {
    if (boundary.kind == _BoundaryKind.method &&
        member is MethodDeclaration &&
        member.name.lexeme == boundary.name) {
      return member;
    }
    if (boundary.kind == _BoundaryKind.constructor &&
        member is ConstructorDeclaration &&
        (boundary.name.isEmpty
            ? member.name == null
            : member.name?.lexeme == boundary.name)) {
      return member;
    }
  }
  return null;
}

FormalParameterList? _parametersFor(AstNode member) {
  return switch (member) {
    MethodDeclaration(:final parameters) => parameters,
    ConstructorDeclaration(:final parameters) => parameters,
    _ => throw ArgumentError.value(member, 'member'),
  };
}

FormalParameter? _parameterFor(FormalParameterList parameters, String name) {
  for (final parameter in parameters.parameters) {
    final normalized = _unwrap(parameter);
    if (normalized.name?.lexeme == name) return normalized;
  }
  return null;
}

FormalParameter _unwrap(FormalParameter parameter) {
  return parameter is DefaultFormalParameter ? parameter.parameter : parameter;
}

TypeAnnotation? _parameterType(
  FormalParameter parameter,
  ClassDeclaration owner,
) {
  final normalized = _unwrap(parameter);
  return switch (normalized) {
    SimpleFormalParameter(:final type) => type,
    FieldFormalParameter(:final type, :final name) =>
      type ?? _fieldType(owner, name.lexeme),
    _ => null,
  };
}

VariableDeclaration? _fieldFor(ClassDeclaration owner, String name) {
  for (final member in owner.body.members.whereType<FieldDeclaration>()) {
    for (final field in member.fields.variables) {
      if (field.name.lexeme == name) return field;
    }
  }
  return null;
}

TypeAnnotation? _fieldType(ClassDeclaration owner, String name) {
  final field = _fieldFor(owner, name);
  final parent = field?.parent;
  return parent is VariableDeclarationList ? parent.type : null;
}

void _checkBoundaryType({
  required String label,
  required TypeAnnotation? type,
  required String expectedType,
  required bool nullable,
  required List<String> violations,
}) {
  final expected = nullable ? '$expectedType?' : expectedType;
  if (!_isExpectedType(type, expectedType, nullable)) {
    violations.add('$label must have type $expected; found ${_typeName(type)}');
  }
}

bool _isExpectedType(TypeAnnotation? type, String expectedType, bool nullable) {
  final expected = nullable ? '$expectedType?' : expectedType;
  return type?.toSource() == expected;
}

bool _containsAnyNamedType(TypeAnnotation? type, Set<String> names) {
  return type != null && _namedTypes(type).any(names.contains);
}

String _typeName(TypeAnnotation? type) => type?.toSource() ?? '<inferred>';

Set<String> _namedTypes(AstNode node) {
  final types = <String>{};
  node.accept(_NamedTypeCollector(types));
  return types;
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  _NamedTypeCollector(this.types);

  final Set<String> types;

  @override
  void visitNamedType(NamedType node) {
    types.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}

enum _BoundaryKind {
  method('method'),
  constructor('constructor');

  const _BoundaryKind(this.label);

  final String label;
}

final class _Boundary {
  const _Boundary.method(
    this.name, {
    required this.parameter,
    required this.type,
    this.nullable = false,
  }) : kind = _BoundaryKind.method,
       requireField = false;

  const _Boundary.constructor(
    this.name, {
    required this.parameter,
    required this.type,
    this.requireField = true,
  }) : kind = _BoundaryKind.constructor,
       nullable = false;

  final _BoundaryKind kind;
  final String name;
  final String parameter;
  final String type;
  final bool nullable;
  final bool requireField;
}

final class _Target {
  const _Target({
    required this.path,
    required this.owner,
    required this.boundaries,
  });

  final String path;
  final String owner;
  final List<_Boundary> boundaries;
}
