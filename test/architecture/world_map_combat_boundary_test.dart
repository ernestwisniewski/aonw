import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _targets = [
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_combat_resolver.dart',
    owner: 'PersistentTurnCombatResolver',
    boundaries: [_Boundary.method('resolve', nullable: true)],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/combat/persistent_combat_command_resolver.dart',
    owner: 'PersistentCombatCommandResolver',
    boundaries: [_Boundary.method('resolve')],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/turn/persistent_turn_pipeline.dart',
    owner: 'PersistentTurnPipelineRequest',
    boundaries: [_Boundary.constructor('simultaneousFinalize')],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/persistent_move_unit_resolver.dart',
    owner: 'PersistentMoveUnitResolver',
    boundaries: [_Boundary.method('resolve')],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/movement/persistent_unit_action_resolver.dart',
    owner: 'PersistentUnitActionResolver',
    boundaries: [_Boundary.method('autoExploreUnit')],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/unit/persistent_unit_detachment_resolver.dart',
    owner: 'PersistentUnitDetachmentResolver',
    boundaries: [_Boundary.method('detachTroop')],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_city_founding_resolver.dart',
    owner: 'PersistentCityFoundingResolver',
    boundaries: [_Boundary.method('foundCity')],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_city_expansion_resolver.dart',
    owner: 'PersistentCityExpansionResolver',
    boundaries: [_Boundary.method('selectExpansionHex')],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_worker_command_resolver.dart',
    owner: 'PersistentWorkerCommandResolver',
    boundaries: [
      _Boundary.method('selectWorkerImprovement'),
      _Boundary.method('confirmWorkerImprovement'),
      _Boundary.method('assignWorkerToHex'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/city/persistent_city_production_resolver.dart',
    owner: 'PersistentCityProductionResolver',
    boundaries: [
      _Boundary.method('startBuilding'),
      _Boundary.method('startUnitProduction'),
      _Boundary.method('startWonder'),
      _Boundary.method('rushProduction'),
    ],
  ),
  _Target(
    path:
        'packages/aonw_core/lib/game/domain/technology/persistent_research_command_resolver.dart',
    owner: 'PersistentResearchCommandResolver',
    boundaries: [_Boundary.method('selectTechnology', nullable: true)],
  ),
];

void main() {
  test('migrated persistent boundaries declare canonical WorldMap APIs', () {
    for (final target in _targets) {
      expect(
        _violations(File(target.path).readAsStringSync(), target),
        isEmpty,
        reason: target.path,
      );
    }
  });

  test(
    'guard rejects MapData at a method boundary despite an unrelated WorldMap',
    () {
      const target = _Target(
        path: 'lib/persistent_combat_command_resolver.dart',
        owner: 'PersistentCombatCommandResolver',
        boundaries: [_Boundary.method('resolve')],
      );

      final violations = _violations('''
class PersistentCombatCommandResolver {
  final WorldMap cachedWorldMap;

  void resolve({required MapData worldMap}) {}
}
''', target);

      expect(
        violations,
        containsAll([
          'PersistentCombatCommandResolver.resolve.worldMap must have type '
              'WorldMap; found MapData',
          'PersistentCombatCommandResolver.resolve must not expose MapData '
              'through parameter worldMap',
        ]),
      );
    },
  );

  test('guard rejects MapData in a public request field', () {
    const target = _Target(
      path: 'lib/persistent_turn_pipeline.dart',
      owner: 'PersistentTurnPipelineRequest',
      boundaries: [_Boundary.constructor('simultaneousFinalize')],
    );

    final violations = _violations('''
final class PersistentTurnPipelineRequest {
  PersistentTurnPipelineRequest.simultaneousFinalize({
    required this.worldMap,
  });

  final MapData worldMap;
  final WorldMap cachedWorldMap;
}
''', target);

    expect(
      violations,
      containsAll([
        'PersistentTurnPipelineRequest.simultaneousFinalize.worldMap must '
            'have type WorldMap; found MapData',
        'PersistentTurnPipelineRequest.worldMap field must have type '
            'WorldMap; found MapData',
        'PersistentTurnPipelineRequest.worldMap field must not expose MapData',
      ]),
    );
  });

  test('guard rejects a legacy MapDefinition signature', () {
    const target = _Target(
      path: 'lib/persistent_turn_combat_resolver.dart',
      owner: 'PersistentTurnCombatResolver',
      boundaries: [_Boundary.method('resolve', nullable: true)],
    );
    final violations = _violations('''
import 'package:aonw_core/domain/map_definition.dart';

abstract final class PersistentTurnCombatResolver {
  static void resolve({required MapDefinition mapDefinition}) {}
}
''', target);

    expect(
      violations,
      containsAll([
        'PersistentTurnCombatResolver.resolve must declare a worldMap '
            'parameter',
        'must not reference MapDefinition',
        'must not import map_definition.dart',
      ]),
    );
  });
}

List<String> _violations(String source, _Target target) {
  final unit = parseString(content: source, path: target.path).unit;
  final owner = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) => declaration.namePart.typeName.lexeme == target.owner,
  );
  final violations = <String>[];
  if (owner.length != 1) {
    return ['${target.owner} must declare exactly one class'];
  }

  for (final boundary in target.boundaries) {
    _checkBoundary(owner.single, boundary, violations);
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
  List<String> violations,
) {
  final member = _memberFor(owner, boundary);
  final memberLabel = '${owner.namePart.typeName.lexeme}.${boundary.name}';
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
    _checkWorldMapType(
      label: '$memberLabel.${boundary.parameter}',
      type: parameterType,
      nullable: boundary.nullable,
      violations: violations,
    );
  }

  for (final parameter in parameters.parameters) {
    final normalized = _unwrap(parameter);
    if (_isNamedType(_parameterType(normalized, owner), 'MapData')) {
      violations.add(
        '$memberLabel must not expose MapData through parameter '
        '${normalized.name?.lexeme ?? '<unnamed>'}',
      );
    }
  }

  if (boundary.kind == _BoundaryKind.constructor) {
    final field = _fieldFor(owner, boundary.parameter);
    final fieldLabel =
        '${owner.namePart.typeName.lexeme}.${boundary.parameter} field';
    if (field == null) {
      violations.add('$fieldLabel must be declared');
      return;
    }
    final fieldType = _fieldType(owner, boundary.parameter);
    _checkWorldMapType(
      label: fieldLabel,
      type: fieldType,
      nullable: boundary.nullable,
      violations: violations,
    );
    if (_isNamedType(fieldType, 'MapData')) {
      violations.add('$fieldLabel must not expose MapData');
    }
  }
}

AstNode? _memberFor(ClassDeclaration owner, _Boundary boundary) {
  for (final member in owner.body.members) {
    if (boundary.kind == _BoundaryKind.method &&
        member is MethodDeclaration &&
        member.name.lexeme == boundary.name) {
      return member;
    }
    if (boundary.kind == _BoundaryKind.constructor &&
        member is ConstructorDeclaration &&
        member.name?.lexeme == boundary.name) {
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

void _checkWorldMapType({
  required String label,
  required TypeAnnotation? type,
  required bool nullable,
  required List<String> violations,
}) {
  final expected = nullable ? 'WorldMap?' : 'WorldMap';
  if (!_isExpectedWorldMap(type, nullable)) {
    violations.add('$label must have type $expected; found ${_typeName(type)}');
  }
}

bool _isExpectedWorldMap(TypeAnnotation? type, bool nullable) {
  return _isNamedType(type, 'WorldMap') && (type?.question != null) == nullable;
}

bool _isNamedType(TypeAnnotation? type, String name) {
  return type is NamedType &&
      type.name.lexeme == name &&
      type.typeArguments == null;
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
  const _Boundary.method(this.name, {this.nullable = false})
    : kind = _BoundaryKind.method;

  const _Boundary.constructor(this.name)
    : kind = _BoundaryKind.constructor,
      nullable = false;

  final _BoundaryKind kind;
  final String name;
  final bool nullable;
  String get parameter => 'worldMap';
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
