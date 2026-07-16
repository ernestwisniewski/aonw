part of '../world_map_projection_boundary_test.dart';

const _mapTileViewMigrationPaths = {
  ..._mapDataBarrelFreeMigrationPaths,
  'lib/game/domain/reducer/movement/movement_reducer.dart',
  'lib/game/presentation/widgets/hud/selection/'
      'hud_selection_action_rules.dart',
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
  return sourceSymbolReferenceViolations(
    declaration.toSource(),
    path,
    symbol: 'TileData',
  );
}
