part of '../world_map_projection_boundary_test.dart';

const _mapTileViewMigrationPaths = {
  '$_coreLib/ai/simulation/economy_simulation_command_staleness.dart',
  '$_gameDomain/city/city_expansion_rules.dart',
  '$_gameDomain/city/city_expansion_selector.dart',
  '$_gameDomain/city/city_founding.dart',
  '$_gameDomain/city/city_site_rules.dart',
  '$_gameDomain/city/city_tile_yield_rules.dart',
  '$_gameDomain/city/city_unit_production_rules.dart',
  '$_gameDomain/city/field_improvement_definition.dart',
  '$_gameDomain/city/field_improvement_requirement.dart',
  '$_gameDomain/city/field_improvement_rules.dart',
  '$_gameDomain/city/worker_improvement_scoring.dart',
  '$_gameDomain/combat/combat_modifier_collector.dart',
  '$_gameDomain/combat/combat_retreat_resolver.dart',
  '$_gameDomain/fog/fog_visibility_query.dart',
  '$_gameDomain/hex/hex_coordinate.dart',
  '$_gameDomain/hex_assessment/hex_assessment_input.dart',
  '$_gameDomain/movement/persistent_move_unit_resolver.dart',
  '$_gameDomain/movement/scout_auto_explore_planner.dart',
  '$_gameDomain/movement/unit_movement_pathfinder.dart',
  '$_gameDomain/technology/technology_boost_evaluator.dart',
  '$_gameDomain/tile_yield/tile_yield_rules.dart',
};
const _mapReadViewPath = '$_coreLib/map/domain/map_read_view.dart';
const _worldMapReadViewPath = '$_coreLib/map/domain/world_map_read_view.dart';
const _removedBoundedAdapterMethods = {
  'tileDataAt',
  'asTileLookup',
  'asReadView',
  'asTraversalView',
};

List<String> _namedTypeViolations(
  String source,
  String path, {
  required String forbiddenType,
}) {
  final unit = parseString(content: source, path: path).unit;
  final visitor = _NamedTypePresenceVisitor(forbiddenType);
  unit.accept(visitor);
  return visitor.found
      ? ['$path must not reference legacy $forbiddenType']
      : const [];
}

List<String> _adapterApiDeclarationViolations(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  final declaration = _classDeclarationNamed(unit, 'LegacyWorldMapAdapter');
  if (declaration == null) return ['$path must declare LegacyWorldMapAdapter'];
  return [
    ..._adapterClassContractViolations(declaration, path),
    ..._adapterConverterContractViolations(declaration, path),
    ..._unexpectedAdapterMethodViolations(unit, declaration, path),
    ..._unexpectedAdapterFieldViolations(unit, declaration, path),
    ..._unexpectedAdapterConstructorViolations(unit, declaration, path),
  ];
}

List<String> _adapterClassContractViolations(
  ClassDeclaration declaration,
  String path,
) {
  final isClosedUtilityClass =
      declaration.abstractKeyword != null &&
      declaration.finalKeyword != null &&
      declaration.baseKeyword == null &&
      declaration.interfaceKeyword == null &&
      declaration.mixinKeyword == null &&
      declaration.sealedKeyword == null &&
      declaration.namePart.typeParameters == null &&
      declaration.extendsClause == null &&
      declaration.withClause == null &&
      declaration.implementsClause == null;
  return isClosedUtilityClass
      ? const []
      : [
          '$path LegacyWorldMapAdapter must remain a non-generic, unextended '
              'abstract final utility class',
        ];
}

List<String> _adapterConverterContractViolations(
  ClassDeclaration declaration,
  String path,
) {
  return [
    ..._adapterConverterMethodViolations(
      declaration,
      path,
      name: 'fromMapData',
      returnType: 'WorldMap',
      parameterType: 'MapData',
    ),
    ..._adapterConverterMethodViolations(
      declaration,
      path,
      name: 'toMapData',
      returnType: 'MapData',
      parameterType: 'WorldMap',
    ),
  ];
}

List<String> _adapterConverterMethodViolations(
  ClassDeclaration declaration,
  String path, {
  required String name,
  required String returnType,
  required String parameterType,
}) {
  final matches = declaration.body.members
      .whereType<MethodDeclaration>()
      .where((method) => method.name.lexeme == name)
      .toList();
  if (matches.length != 1) {
    return ['$path must declare exactly one $name converter'];
  }
  final method = matches.single;
  final hasExpectedSignature =
      method.isStatic &&
      method.typeParameters == null &&
      method.returnType?.toSource() == returnType &&
      _singleRequiredParameterType(method) == parameterType;
  return hasExpectedSignature
      ? const []
      : [
          '$path $name must be static $returnType '
              '$name($parameterType value)',
        ];
}

String? _singleRequiredParameterType(MethodDeclaration method) {
  final parameters = method.parameters?.parameters;
  if (parameters == null || parameters.length != 1) return null;
  final parameter = parameters.single;
  return parameter is SimpleFormalParameter ? parameter.type?.toSource() : null;
}

List<String> _unexpectedAdapterMethodViolations(
  CompilationUnit unit,
  ClassDeclaration declaration,
  String path,
) {
  return [
    for (final method
        in declaration.body.members.whereType<MethodDeclaration>())
      if (!method.name.lexeme.startsWith('_') &&
          !_allowedFullMapConverterMethods.contains(method.name.lexeme))
        '$path:${unit.lineInfo.getLocation(method.offset).lineNumber} '
            'declares unexpected public method ${method.name.lexeme}',
  ];
}

List<String> _unexpectedAdapterFieldViolations(
  CompilationUnit unit,
  ClassDeclaration declaration,
  String path,
) {
  return [
    for (final field in declaration.body.members.whereType<FieldDeclaration>())
      for (final variable in field.fields.variables)
        if (!variable.name.lexeme.startsWith('_'))
          '$path:${unit.lineInfo.getLocation(variable.offset).lineNumber} '
              'declares unexpected public field ${variable.name.lexeme}',
  ];
}

List<String> _unexpectedAdapterConstructorViolations(
  CompilationUnit unit,
  ClassDeclaration declaration,
  String path,
) {
  return [
    for (final constructor
        in declaration.body.members.whereType<ConstructorDeclaration>())
      if (constructor.name?.lexeme.startsWith('_') != true)
        '$path:${unit.lineInfo.getLocation(constructor.offset).lineNumber} '
            'declares unexpected public constructor',
  ];
}

List<String> _mapTileLookupContractViolations(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
    if (declaration.namePart.typeName.lexeme != 'MapTileLookup') continue;
    for (final method
        in declaration.body.members.whereType<MethodDeclaration>()) {
      if (method.name.lexeme != 'tileAt') continue;
      if (method.returnType?.toSource() == 'MapTileView?') return const [];
      return [
        '$path MapTileLookup.tileAt must return MapTileView?, found '
            '${method.returnType?.toSource()}',
      ];
    }
  }
  return ['$path must declare MapTileLookup.tileAt'];
}

List<String> _worldMapReadViewViolations(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  final declaration = _classDeclarationNamed(unit, 'WorldMapReadView');
  if (declaration == null) return ['$path must declare WorldMapReadView'];
  return [
    ..._worldMapReadViewTopLevelViolations(unit, declaration, path),
    ..._worldMapReadViewModifierViolations(declaration, path),
    ..._worldMapReadViewFieldViolations(declaration, path),
    ..._worldMapReadViewTileAtViolations(declaration, path),
    ..._worldMapReadViewTileDataViolations(declaration, path),
  ];
}

List<String> _worldMapReadViewTopLevelViolations(
  CompilationUnit unit,
  ClassDeclaration worldMapReadView,
  String path,
) {
  return [
    for (final declaration in unit.declarations)
      if (!identical(declaration, worldMapReadView))
        '$path must not declare top-level state or helpers beside '
            'WorldMapReadView',
  ];
}

ClassDeclaration? _classDeclarationNamed(CompilationUnit unit, String name) {
  for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
    if (declaration.namePart.typeName.lexeme == name) return declaration;
  }
  return null;
}

List<String> _worldMapReadViewModifierViolations(
  ClassDeclaration declaration,
  String path,
) {
  return declaration.toSource().startsWith('final class WorldMapReadView')
      ? const []
      : ['$path WorldMapReadView must remain final'];
}

List<String> _worldMapReadViewFieldViolations(
  ClassDeclaration declaration,
  String path,
) {
  final fields = declaration.body.members
      .whereType<FieldDeclaration>()
      .map((field) => field.toSource())
      .toList();
  return fields.length == 1 && fields.single == 'final WorldMap _worldMap;'
      ? const []
      : ['$path must declare exactly final WorldMap _worldMap; found $fields'];
}

List<String> _worldMapReadViewTileAtViolations(
  ClassDeclaration declaration,
  String path,
) {
  final method = _methodNamed(declaration, 'tileAt');
  if (method == null) return ['$path must declare WorldMapReadView.tileAt'];
  final returnType = method.returnType?.toSource();
  return returnType == 'WorldTile?'
      ? const []
      : [
          '$path WorldMapReadView.tileAt must return WorldTile?, found '
              '$returnType',
        ];
}

MethodDeclaration? _methodNamed(ClassDeclaration declaration, String name) {
  for (final method
      in declaration.body.members.whereType<MethodDeclaration>()) {
    if (method.name.lexeme == name) return method;
  }
  return null;
}

List<String> _worldMapReadViewTileDataViolations(
  ClassDeclaration declaration,
  String path,
) {
  final visitor = _NamedTypePresenceVisitor('TileData');
  declaration.accept(visitor);
  return visitor.found ? ['$path must not reference TileData'] : const [];
}

final class _NamedTypePresenceVisitor extends RecursiveAstVisitor<void> {
  _NamedTypePresenceVisitor(this.name);

  final String name;
  bool found = false;

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == name) found = true;
    super.visitNamedType(node);
  }
}
