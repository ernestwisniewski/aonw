import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'movement_command_boundary_guard.dart';

List<String> movementVisibilityBoundaryViolations(Map<String, String> sources) {
  final declarations = _visibilityDeclarationCounts(sources);
  final directiveTargets = _visibilityDirectiveTargets(sources);
  final rules = _visibilityRules(sources[movementVisibilityPath]);
  return [
    if (declarations.length != 1 || declarations[movementVisibilityPath] != 1)
      'UnitMovementVisibilityRules must be declared exactly once in core',
    if (sources.containsKey(movementLegacyVisibilityPath))
      'the legacy root visibility rules file must be removed',
    if (directiveTargets.isNotEmpty)
      'all visibility-rule directives must resolve to the core rule: '
          '${directiveTargets.join(', ')}',
    ..._visibilityRuleShapeViolations(rules),
  ];
}

Map<String, int> _visibilityDeclarationCounts(Map<String, String> sources) {
  final declarations = <String, int>{};
  for (final entry in sources.entries) {
    final count = parseString(content: entry.value, path: entry.key)
        .unit
        .declarations
        .whereType<ClassDeclaration>()
        .where(_isVisibilityRules)
        .length;
    if (count > 0) declarations[entry.key] = count;
  }
  return declarations;
}

bool _isVisibilityRules(ClassDeclaration declaration) =>
    declaration.namePart.typeName.lexeme == 'UnitMovementVisibilityRules';

ClassDeclaration? _visibilityRules(String? source) {
  if (source == null) return null;
  final matches = parseString(
    content: source,
    path: movementVisibilityPath,
  ).unit.declarations.whereType<ClassDeclaration>().where(_isVisibilityRules);
  return matches.length == 1 ? matches.single : null;
}

List<String> _visibilityRuleShapeViolations(ClassDeclaration? rules) => [
  if (!_ownsExactVisibilityConstant(rules))
    'core visibility rules must own only static const hiddenPathingRange',
  if (!_hasExactVisibilityMethods(rules))
    'movement visibility rules must expose only the three reviewed contracts',
];

bool _ownsExactVisibilityConstant(ClassDeclaration? rules) {
  if (rules == null ||
      rules.abstractKeyword == null ||
      rules.finalKeyword == null) {
    return false;
  }
  final fields = rules.body.members.whereType<FieldDeclaration>().toList();
  if (fields.length != 1) return false;
  final field = fields.single;
  final variables = field.fields.variables;
  if (variables.length != 1) return false;
  final variable = variables.single;
  final inferredInt =
      field.fields.type?.toSource() == 'int' ||
      variable.initializer is IntegerLiteral;
  return field.isStatic &&
      field.fields.isConst &&
      variable.name.lexeme == 'hiddenPathingRange' &&
      inferredInt;
}

bool _hasExactVisibilityMethods(ClassDeclaration? rules) {
  if (rules == null) return false;
  final publicMethods = rules.body.members
      .whereType<MethodDeclaration>()
      .where((method) => !method.name.lexeme.startsWith('_'))
      .toList();
  if (publicMethods.length != 3) return false;
  final byName = {
    for (final method in publicMethods) method.name.lexeme: method,
  };
  if (byName.length != 3) return false;
  return _hasExactActorVisibilityMethod(byName['visibilityForActor']) &&
      _hasExactPlanningUnitsMethod(byName['planningUnitsForActor']) &&
      _hasExactCanPlanMethod(byName['canPlanThroughTile']);
}

bool _hasExactActorVisibilityMethod(MethodDeclaration? method) {
  if (method == null ||
      !method.isStatic ||
      method.returnType?.toSource() != 'FogVisibilityQuery') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 3) return false;
  return _isRequiredNamed(parameters[0], 'fogOfWar', 'FogOfWarState') &&
      _isRequiredNamed(parameters[1], 'actorPlayerId', 'String') &&
      _isOptionalNamed(
        parameters[2],
        'ignoreDynamicFog',
        'bool',
        defaultValue: 'false',
      );
}

bool _hasExactPlanningUnitsMethod(MethodDeclaration? method) {
  if (method == null ||
      !method.isStatic ||
      method.returnType?.toSource() != 'Iterable<GameUnit>') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 4) return false;
  return _isRequiredNamed(parameters[0], 'units', 'Iterable<GameUnit>') &&
      _isRequiredNamed(parameters[1], 'movingUnit', 'GameUnit') &&
      _isRequiredNamed(parameters[2], 'actorPlayerId', 'String') &&
      _isRequiredNamed(parameters[3], 'visibility', 'FogVisibilityQuery');
}

bool _hasExactCanPlanMethod(MethodDeclaration? method) {
  if (method == null ||
      !method.isStatic ||
      method.returnType?.toSource() != 'bool') {
    return false;
  }
  final parameters = method.parameters?.parameters ?? const <FormalParameter>[];
  if (parameters.length != 3) return false;
  return _isRequiredNamed(parameters[0], 'unit', 'GameUnit') &&
      _isRequiredNamed(parameters[1], 'tile', 'MapTileView') &&
      _isRequiredNamed(parameters[2], 'visibility', 'FogVisibilityQuery');
}

bool _isRequiredNamed(FormalParameter parameter, String name, String type) {
  if (parameter is! DefaultFormalParameter || !parameter.isNamed) return false;
  final normalized = parameter.parameter;
  return normalized is SimpleFormalParameter &&
      normalized.name?.lexeme == name &&
      normalized.type?.toSource() == type &&
      normalized.requiredKeyword != null &&
      parameter.defaultValue == null;
}

bool _isOptionalNamed(
  FormalParameter parameter,
  String name,
  String type, {
  required String defaultValue,
}) {
  if (parameter is! DefaultFormalParameter || !parameter.isNamed) return false;
  final normalized = parameter.parameter;
  return normalized is SimpleFormalParameter &&
      normalized.name?.lexeme == name &&
      normalized.type?.toSource() == type &&
      normalized.requiredKeyword == null &&
      parameter.defaultValue?.toSource() == defaultValue;
}

List<String> _visibilityDirectiveTargets(Map<String, String> sources) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    for (final directive in unit.directives.whereType<UriBasedDirective>()) {
      final uri = directive.uri.stringValue;
      if (!_isVisibilityRulesUri(uri)) continue;
      if (_workspacePathForUri(entry.key, uri!) != movementVisibilityPath) {
        violations.add('${entry.key} -> $uri');
      }
    }
  }
  return violations..sort();
}

bool _isVisibilityRulesUri(String? uri) =>
    uri?.endsWith('unit_movement_visibility_rules.dart') ?? false;

String? _workspacePathForUri(String importerPath, String uri) {
  const corePrefix = 'package:aonw_core/';
  if (uri.startsWith(corePrefix)) {
    return 'packages/aonw_core/lib/${uri.substring(corePrefix.length)}';
  }
  const rootPrefix = 'package:aonw/';
  if (uri.startsWith(rootPrefix)) {
    return 'lib/${uri.substring(rootPrefix.length)}';
  }
  if (Uri.parse(uri).hasScheme) return null;
  return Uri.parse(importerPath).resolve(uri).path;
}
