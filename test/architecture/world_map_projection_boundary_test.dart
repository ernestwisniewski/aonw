import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/legacy_world_map_adapter_guard.dart';

part 'support/economy_simulation_map_view_guard.dart';
part 'support/economy_simulation_map_view_fixtures.dart';
part 'support/world_map_projection_boundary_fixtures.dart';
part 'support/world_map_read_view_boundary_guard.dart';

const _coreLib = 'packages/aonw_core/lib';
const _gameDomain = '$_coreLib/game/domain';
const _mapDataFreeMigrationPaths = {
  '$_gameDomain/city/persistent_city_expansion_resolver.dart',
  '$_gameDomain/city/persistent_city_founding_resolver.dart',
  '$_gameDomain/city/city_turn_processor.dart',
  '$_gameDomain/city/persistent_worker_command_resolver.dart',
  '$_gameDomain/combat/persistent_combat_command_resolver.dart',
  '$_gameDomain/fog/fog_of_war_service.dart',
  '$_gameDomain/fog/fog_reveal_calculator.dart',
  '$_gameDomain/movement/unit_movement_cost_rules.dart',
  '$_gameDomain/movement/persistent_move_unit_resolver.dart',
  '$_gameDomain/movement/persistent_merchant_trade_route_resolver.dart',
  '$_gameDomain/movement/persistent_unit_action_resolver.dart',
  '$_gameDomain/movement/merchant_trade_route_rules.dart',
  '$_gameDomain/movement/scout_auto_explore_planner.dart',
  '$_gameDomain/movement/unit_movement_pathfinder.dart',
  '$_gameDomain/outcome/domination_progress_calculator.dart',
  '$_gameDomain/outcome/game_outcome_detector.dart',
  '$_gameDomain/stability/persistent_stability_processor.dart',
  '$_gameDomain/stability/stability_input_builder.dart',
  '$_gameDomain/technology/research_turn_processor.dart',
  '$_gameDomain/technology/strategic_resource_discovery_rules.dart',
  '$_gameDomain/technology/persistent_research_command_resolver.dart',
  '$_gameDomain/terrain/tile_terrain_profile_rules.dart',
  '$_gameDomain/turn/persistent_turn_combat_resolver.dart',
  '$_gameDomain/turn/persistent_turn_economy_processor.dart',
  '$_gameDomain/turn/persistent_turn_movement_processor.dart',
  '$_gameDomain/turn/persistent_turn_pipeline.dart',
  '$_gameDomain/unit/unit_fortification_rules.dart',
  '$_gameDomain/unit/worker_turn_processor.dart',
  '$_gameDomain/unit/persistent_unit_detachment_resolver.dart',
  '$_gameDomain/unit/starting_units.dart',
  '$_coreLib/ai/simulation/economy_simulation_command_applier.dart',
  '$_coreLib/ai/simulation/economy_simulation_command_applier_production.dart',
  '$_coreLib/ai/simulation/economy_simulation_turn_row_factory.dart',
};
const _legacyWorldMapAdapterPath =
    '$_coreLib/map/persistence/legacy_world_map_adapter.dart';
const _persistentCityProductionResolverPath =
    '$_gameDomain/city/persistent_city_production_resolver.dart';
const _allowedFullMapConverterMethods = {'fromMapData', 'toMapData'};
const _allowedProductionProjectionSites = <String, int>{};
const _allowedProductionImportSites = <String, int>{
  'lib/editor/domain/map_draft.dart::class:MapDraft/method:freeze::call': 1,
  'server/lib/src/multiplayer/server_command_reducer_map_cache.dart::'
          'method:_loadServerMap::call':
      1,
};

void main() {
  test('production does not alias the legacy world-map adapter', () {
    expect(_adapterTypedefViolations(productionDartSources()), isEmpty);
  });

  test('production full-map projections match the shrinking allowlist', () {
    expect(
      _projectionRatchetViolations(
        productionDartSources(containing: 'toMapData'),
        allowedSites: _allowedProductionProjectionSites,
      ),
      isEmpty,
    );
  });

  test('production full-map imports match the shrinking allowlist', () {
    expect(
      _adapterMethodRatchetViolations(
        productionDartSources(containing: 'fromMapData'),
        methodName: 'fromMapData',
        allowedSites: _allowedProductionImportSites,
      ),
      isEmpty,
    );
  });

  test('production has no bounded legacy adapter calls', () {
    for (final methodName in _removedBoundedAdapterMethods) {
      expect(
        _adapterMethodRatchetViolations(
          productionDartSources(containing: methodName),
          methodName: methodName,
          allowedSites: const {},
        ),
        isEmpty,
        reason: methodName,
      );
    }
  });

  test('MCTS production depends only on canonical map read contracts', () {
    final mctsSources = productionDartSources().entries.where(
      (entry) => entry.key.startsWith('$_coreLib/ai/mcts/'),
    );
    for (final entry in mctsSources) {
      expect(
        _namedTypeViolations(entry.value, entry.key, forbiddenType: 'MapData'),
        isEmpty,
        reason: entry.key,
      );
      expect(
        _namedTypeViolations(entry.value, entry.key, forbiddenType: 'WorldMap'),
        isEmpty,
        reason: entry.key,
      );
      expect(
        entry.value,
        isNot(contains('LegacyWorldMapAdapter')),
        reason: entry.key,
      );
    }
  });

  test('economy simulation owns one shared indexed map view', () {
    expect(_economySimulationMapViewViolations(), isEmpty);
  });

  test('migrated map paths do not materialize legacy maps', () {
    for (final path in _mapDataFreeMigrationPaths) {
      expect(
        _legacyProjectionViolations(File(path).readAsStringSync(), path),
        isEmpty,
        reason: path,
      );
    }
  });

  test('migrated bounded rules do not depend on legacy tile DTOs', () {
    for (final path in _mapTileViewMigrationPaths) {
      expect(
        _namedTypeViolations(
          File(path).readAsStringSync(),
          path,
          forbiddenType: 'TileData',
        ),
        isEmpty,
        reason: path,
      );
    }
  });

  test('legacy adapter exposes only full-map conversion methods', () {
    final source = File(_legacyWorldMapAdapterPath).readAsStringSync();
    expect(
      _classProjectionViolations(
        source,
        _legacyWorldMapAdapterPath,
        className: 'LegacyWorldMapAdapter',
        allowedProjectionMethods: _allowedFullMapConverterMethods,
      ),
      isEmpty,
    );
    expect(
      _adapterApiDeclarationViolations(source, _legacyWorldMapAdapterPath),
      isEmpty,
    );
  });

  test('read contracts and WorldMap view remain zero-copy', () {
    expect(
      _mapTileLookupContractViolations(
        File(_mapReadViewPath).readAsStringSync(),
        _mapReadViewPath,
      ),
      isEmpty,
    );
    expect(
      _worldMapReadViewViolations(
        File(_worldMapReadViewPath).readAsStringSync(),
        _worldMapReadViewPath,
      ),
      isEmpty,
    );
  });

  test('bounded city production paths do not materialize legacy maps', () {
    expect(
      _classProjectionViolations(
        File(_persistentCityProductionResolverPath).readAsStringSync(),
        _persistentCityProductionResolverPath,
        className: 'PersistentCityProductionResolver',
        allowedProjectionMethods: const {},
      ),
      isEmpty,
    );
  });

  _registerWorldMapProjectionBoundaryFixtures();
  _registerEconomySimulationMapViewFixtures();
}

List<String> _adapterTypedefViolations(Map<String, String> sources) {
  final sites = legacyWorldMapAdapterTypedefSites(sources);
  final keys = sites.keys.toList()..sort();
  return [
    for (final key in keys)
      '$key must not alias LegacyWorldMapAdapter '
          'at lines ${sites[key] ?? const <int>[]}',
  ];
}

List<String> _projectionRatchetViolations(
  Map<String, String> sources, {
  required Map<String, int> allowedSites,
}) {
  return _adapterMethodRatchetViolations(
    sources,
    methodName: 'toMapData',
    allowedSites: allowedSites,
  );
}

List<String> _adapterMethodRatchetViolations(
  Map<String, String> sources, {
  required String methodName,
  required Map<String, int> allowedSites,
}) {
  final sites = legacyWorldMapAdapterMethodSites(
    sources,
    methodName: methodName,
  );
  final keys = {...allowedSites.keys, ...sites.keys}.toList()..sort();
  return [
    for (final key in keys)
      if ((sites[key]?.length ?? 0) != (allowedSites[key] ?? 0))
        '$key expected ${allowedSites[key] ?? 0}, '
            'found ${sites[key]?.length ?? 0} '
            'at lines ${sites[key] ?? const <int>[]}',
  ];
}

List<String> _legacyProjectionViolations(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  final violations = <String>[];
  unit.accept(
    _LegacyProjectionVisitor(
      path: path,
      lineInfo: unit.lineInfo,
      violations: violations,
      legacyAdapterTypeNames: legacyWorldMapAdapterTypeNames(unit),
    ),
  );
  return violations.toSet().toList();
}

List<String> _classProjectionViolations(
  String source,
  String path, {
  required String className,
  required Set<String> allowedProjectionMethods,
}) {
  final unit = parseString(content: source, path: path).unit;
  final violations = <String>[];
  final qualifiedVisitor = _LegacyProjectionVisitor(
    path: path,
    lineInfo: unit.lineInfo,
    violations: violations,
    legacyAdapterTypeNames: legacyWorldMapAdapterTypeNames(unit),
    blockedAdapterMethods: _allowedFullMapConverterMethods,
  );
  final selfCallVisitor = _LegacyProjectionVisitor(
    path: path,
    lineInfo: unit.lineInfo,
    violations: violations,
    legacyAdapterTypeNames: legacyWorldMapAdapterTypeNames(unit),
    blockedAdapterMethods: _allowedFullMapConverterMethods,
    rejectUnqualifiedAdapterMethods: true,
  );
  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) {
      declaration.accept(qualifiedVisitor);
      continue;
    }
    final declarationClassName = declaration.namePart.typeName.lexeme;
    for (final member in declaration.body.members) {
      final isAllowedConverter =
          declarationClassName == className &&
          member is MethodDeclaration &&
          allowedProjectionMethods.contains(member.name.lexeme);
      if (isAllowedConverter) continue;
      final visitor =
          declarationClassName == className &&
              className == 'LegacyWorldMapAdapter'
          ? selfCallVisitor
          : qualifiedVisitor;
      member.accept(visitor);
    }
  }
  return violations.toSet().toList();
}

final class _LegacyProjectionVisitor extends RecursiveAstVisitor<void> {
  _LegacyProjectionVisitor({
    required this.path,
    required this.lineInfo,
    required this.violations,
    required this.legacyAdapterTypeNames,
    this.blockedAdapterMethods = const {
      'toMapData',
      'tileDataAt',
      'asTileLookup',
      'asReadView',
      'asTraversalView',
    },
    this.rejectUnqualifiedAdapterMethods = false,
  });

  final String path;
  final LineInfo lineInfo;
  final List<String> violations;
  final Set<String> legacyAdapterTypeNames;
  final Set<String> blockedAdapterMethods;
  final bool rejectUnqualifiedAdapterMethods;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    if (node.constructorName.type.name.lexeme == 'MapData') {
      _recordMapDataReference(node.offset);
    }
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (node.name.lexeme == 'MapData') {
      _recordMapDataReference(node.offset);
    }
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.parent is CommentReference) {
      super.visitSimpleIdentifier(node);
      return;
    }
    if (node.name == 'MapData') {
      _recordMapDataReference(node.offset);
    }
    final isBlockedAdapterReference =
        blockedAdapterMethods.contains(node.name) &&
        (isLegacyWorldMapAdapterMethodReference(
              node,
              methodName: node.name,
              adapterTypeNames: legacyAdapterTypeNames,
            ) ||
            (rejectUnqualifiedAdapterMethods &&
                isUnqualifiedMethodReference(node)));
    if (isBlockedAdapterReference) {
      violations.add(
        '$path:${lineInfo.getLocation(node.offset).lineNumber} '
        'must not call or capture LegacyWorldMapAdapter.${node.name}',
      );
    }
    super.visitSimpleIdentifier(node);
  }

  void _recordMapDataReference(int offset) {
    violations.add(
      '$path:${lineInfo.getLocation(offset).lineNumber} '
      'must not reference MapData',
    );
  }
}
