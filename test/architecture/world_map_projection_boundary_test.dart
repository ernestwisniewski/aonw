import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:flutter_test/flutter_test.dart';

const _boundedTileQueryResolvers = {
  'packages/aonw_core/lib/game/domain/city/'
      'persistent_city_expansion_resolver.dart',
  'packages/aonw_core/lib/game/domain/city/'
      'persistent_city_founding_resolver.dart',
  'packages/aonw_core/lib/game/domain/city/'
      'persistent_worker_command_resolver.dart',
  'packages/aonw_core/lib/game/domain/technology/'
      'persistent_research_command_resolver.dart',
};
const _legacyWorldMapAdapterPath =
    'packages/aonw_core/lib/map/persistence/legacy_world_map_adapter.dart';
const _persistentCityProductionResolverPath =
    'packages/aonw_core/lib/game/domain/city/'
    'persistent_city_production_resolver.dart';
const _allowedFullMapConverterMethods = {'fromMapData', 'toMapData'};
const _allowedProductionProjectionSites = <String, int>{
  'packages/aonw_core/lib/ai/simulation/'
          'economy_simulation_command_applier.dart::'
          'class:_EconomySimulationCommandApplier/method:apply::call':
      2,
  'packages/aonw_core/lib/game/domain/combat/'
          'persistent_combat_command_resolver.dart::'
          'class:PersistentCombatCommandResolver/'
          'method:_stateWithUpdatedVisibility::call':
      1,
  'packages/aonw_core/lib/game/domain/movement/'
          'persistent_move_unit_resolver.dart::'
          'class:PersistentMoveUnitResolver/method:resolve::call':
      1,
  'packages/aonw_core/lib/game/domain/movement/'
          'persistent_unit_action_resolver.dart::'
          'class:PersistentUnitActionResolver/method:autoExploreUnit::call':
      1,
  'packages/aonw_core/lib/game/domain/turn/'
          'persistent_turn_pipeline.dart::'
          'class:PersistentTurnPipeline/method:simultaneousFinalize::call':
      1,
  'packages/aonw_core/lib/game/domain/unit/'
          'persistent_unit_detachment_resolver.dart::'
          'class:PersistentUnitDetachmentResolver/method:detachTroop::call':
      1,
};

void main() {
  test('production full-map projections match the shrinking allowlist', () {
    expect(
      _projectionRatchetViolations(
        _productionSources(),
        allowedSites: _allowedProductionProjectionSites,
      ),
      isEmpty,
    );
  });

  test('bounded tile-query resolvers do not materialize legacy maps', () {
    for (final path in _boundedTileQueryResolvers) {
      expect(
        _legacyProjectionViolations(File(path).readAsStringSync(), path),
        isEmpty,
        reason: path,
      );
    }
  });

  test('bounded adapter helpers do not materialize legacy maps', () {
    expect(
      _classProjectionViolations(
        File(_legacyWorldMapAdapterPath).readAsStringSync(),
        _legacyWorldMapAdapterPath,
        className: 'LegacyWorldMapAdapter',
        allowedProjectionMethods: _allowedFullMapConverterMethods,
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

  test('guard rejects direct, prefixed, tear-off, and manual projections', () {
    final violations = _legacyProjectionViolations('''
typedef Adapter = LegacyWorldMapAdapter;

void direct(WorldMap worldMap) {
  final first = LegacyWorldMapAdapter.toMapData(worldMap);
  final second = legacy.LegacyWorldMapAdapter.toMapData(worldMap);
  final projection = LegacyWorldMapAdapter.toMapData;
  final prefixedProjection = legacy.LegacyWorldMapAdapter.toMapData;
  final aliasedProjection = Adapter.toMapData(worldMap);
  final manual = MapData(cols: worldMap.cols, rows: worldMap.rows, tiles: []);
}
''', 'fixture.dart');

    expect(
      violations.where((violation) => violation.contains('toMapData')),
      hasLength(5),
    );
    expect(violations, contains(contains('must not reference MapData')));
  });

  test('guard allows single-tile adapters and unrelated toMapData methods', () {
    final violations = _legacyProjectionViolations('''
TileData? projectOne(WorldMap worldMap) =>
    LegacyWorldMapAdapter.tileDataAt(worldMap, 0, 0);
Object saveDraft(MapDraft draft) => draft.toMapData();
''', 'fixture.dart');

    expect(violations, isEmpty);
  });

  test('adapter guard rejects full projections hidden behind helpers', () {
    final violations = _classProjectionViolations(
      '''
abstract final class LegacyWorldMapAdapter {
  static MapData toMapData(WorldMap worldMap) => throw UnimplementedError();

  static Object asTileLookup(WorldMap worldMap) => _hidden(worldMap);

  static Object _hidden(WorldMap worldMap) => toMapData(worldMap);
}
''',
      'fixture.dart',
      className: 'LegacyWorldMapAdapter',
      allowedProjectionMethods: _allowedFullMapConverterMethods,
    );

    expect(violations, contains(contains('toMapData')));
  });

  test('class guard permits projections only in named migration methods', () {
    final violations = _classProjectionViolations(
      '''
class PersistentCityProductionResolver {
  Object pending(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);

  Object migratedDirectly(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);

  Object migratedViaHelper(WorldMap worldMap) => _hidden(worldMap);

  Object _hidden(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);
}
''',
      'fixture.dart',
      className: 'PersistentCityProductionResolver',
      allowedProjectionMethods: const {'pending'},
    );

    expect(violations, contains(contains('toMapData')));
    expect(violations, hasLength(2));
  });

  test('ratchet binds projections to path, owner, and reference kind', () {
    const allowedKey = 'lib/allowed.dart::class:Allowed/method:pending::call';
    final violations = _projectionRatchetViolations(
      {
        'lib/allowed.dart': '''
class Allowed {
  Object pending(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);
}
''',
        'lib/helper.dart': '''
class Helper {
  Object hidden(WorldMap worldMap) =>
      LegacyWorldMapAdapter.toMapData(worldMap);
}
''',
        'lib/tear_off.dart': '''
final projection = LegacyWorldMapAdapter.toMapData;
''',
      },
      allowedSites: const {allowedKey: 1},
    );

    expect(violations, hasLength(2));
    expect(violations, contains(contains('lib/helper.dart')));
    expect(violations, contains(contains('lib/tear_off.dart')));
    expect(violations, contains(contains('tearOff')));
  });

  test('ratchet rejects another projection in an allowed member', () {
    const key = 'lib/allowed.dart::class:Allowed/method:pending::call';
    final violations = _projectionRatchetViolations(
      {
        'lib/allowed.dart': '''
class Allowed {
  void pending(WorldMap worldMap) {
    LegacyWorldMapAdapter.toMapData(worldMap);
    LegacyWorldMapAdapter.toMapData(worldMap);
  }
}
''',
      },
      allowedSites: const {key: 1},
    );

    expect(violations, contains(contains('expected 1, found 2')));
  });
}

Map<String, String> _productionSources() {
  final sources = <String, String>{};
  for (final root in const ['packages/aonw_core/lib', 'lib', 'server/lib']) {
    for (final entry in Directory(root).listSync(recursive: true)) {
      if (entry is! File ||
          !entry.path.endsWith('.dart') ||
          entry.path.endsWith('.g.dart') ||
          entry.path.endsWith('.freezed.dart')) {
        continue;
      }
      final path = _relativePath(entry.path);
      if (path == _legacyWorldMapAdapterPath) continue;
      final source = entry.readAsStringSync();
      if (source.contains('toMapData')) sources[path] = source;
    }
  }
  return sources;
}

String _relativePath(String path) {
  final prefix = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(prefix) ? path.substring(prefix.length) : path;
}

List<String> _projectionRatchetViolations(
  Map<String, String> sources, {
  required Map<String, int> allowedSites,
}) {
  final sites = <String, List<int>>{};
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    unit.accept(
      _ProjectionSiteVisitor(
        path: entry.key,
        lineInfo: unit.lineInfo,
        sites: sites,
        legacyAdapterTypeNames: _legacyAdapterTypeNames(unit),
      ),
    );
  }
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
      legacyAdapterTypeNames: _legacyAdapterTypeNames(unit),
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
  final visitor = _LegacyProjectionVisitor(
    path: path,
    lineInfo: unit.lineInfo,
    violations: violations,
    legacyAdapterTypeNames: _legacyAdapterTypeNames(unit),
    rejectAnyToMapData: true,
  );
  for (final declaration in unit.declarations) {
    if (declaration is! ClassDeclaration) {
      declaration.accept(visitor);
      continue;
    }
    final declarationClassName = declaration.namePart.typeName.lexeme;
    for (final member in declaration.body.members) {
      final isAllowedConverter =
          declarationClassName == className &&
          member is MethodDeclaration &&
          allowedProjectionMethods.contains(member.name.lexeme);
      if (!isAllowedConverter) member.accept(visitor);
    }
  }
  return violations.toSet().toList();
}

Set<String> _legacyAdapterTypeNames(CompilationUnit unit) {
  final names = <String>{'LegacyWorldMapAdapter'};
  var changed = true;
  while (changed) {
    changed = false;
    for (final alias in unit.declarations.whereType<GenericTypeAlias>()) {
      final type = alias.type;
      if (type is NamedType &&
          names.contains(type.name.lexeme) &&
          names.add(alias.name.lexeme)) {
        changed = true;
      }
    }
  }
  return names;
}

final class _ProjectionSiteVisitor extends RecursiveAstVisitor<void> {
  _ProjectionSiteVisitor({
    required this.path,
    required this.lineInfo,
    required this.sites,
    required this.legacyAdapterTypeNames,
  });

  final String path;
  final LineInfo lineInfo;
  final Map<String, List<int>> sites;
  final Set<String> legacyAdapterTypeNames;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (_isLegacyToMapDataReference(
      node,
      legacyAdapterTypeNames: legacyAdapterTypeNames,
      rejectAnyTarget: false,
    )) {
      final kind = node.parent is MethodInvocation ? 'call' : 'tearOff';
      final key = '$path::${_declarationOwner(node)}::$kind';
      sites
          .putIfAbsent(key, () => [])
          .add(lineInfo.getLocation(node.offset).lineNumber);
    }
    super.visitSimpleIdentifier(node);
  }
}

String _declarationOwner(AstNode node) {
  String? className;
  String? member;
  for (var parent = node.parent; parent != null; parent = parent.parent) {
    member ??= switch (parent) {
      MethodDeclaration(:final name) => 'method:${name.lexeme}',
      ConstructorDeclaration(:final name) =>
        'constructor:${name?.lexeme ?? '<unnamed>'}',
      FunctionDeclaration(:final name) => 'function:${name.lexeme}',
      VariableDeclaration(:final name) when _isOwnerVariable(parent) =>
        'field:${name.lexeme}',
      _ => null,
    };
    if (parent is ClassDeclaration) {
      className = parent.namePart.typeName.lexeme;
      break;
    }
  }
  return '${className == null ? '' : 'class:$className/'}'
      '${member ?? '<unit>'}';
}

bool _isOwnerVariable(VariableDeclaration node) {
  final declaration = node.parent;
  if (declaration is! VariableDeclarationList) return false;
  return declaration.parent is FieldDeclaration ||
      declaration.parent is TopLevelVariableDeclaration;
}

final class _LegacyProjectionVisitor extends RecursiveAstVisitor<void> {
  _LegacyProjectionVisitor({
    required this.path,
    required this.lineInfo,
    required this.violations,
    required this.legacyAdapterTypeNames,
    this.rejectAnyToMapData = false,
  });

  final String path;
  final LineInfo lineInfo;
  final List<String> violations;
  final Set<String> legacyAdapterTypeNames;
  final bool rejectAnyToMapData;

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
    if (_isLegacyToMapDataReference(
      node,
      legacyAdapterTypeNames: legacyAdapterTypeNames,
      rejectAnyTarget: rejectAnyToMapData,
    )) {
      violations.add(
        '$path:${lineInfo.getLocation(node.offset).lineNumber} '
        'must not call or capture LegacyWorldMapAdapter.toMapData',
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

bool _isLegacyToMapDataReference(
  SimpleIdentifier node, {
  required Set<String> legacyAdapterTypeNames,
  required bool rejectAnyTarget,
}) {
  if (node.name != 'toMapData') return false;
  if (rejectAnyTarget) return true;
  final parent = node.parent;
  final target = switch (parent) {
    MethodInvocation(:final methodName, :final realTarget)
        when identical(methodName, node) =>
      realTarget?.toSource(),
    PrefixedIdentifier(:final identifier, :final prefix)
        when identical(identifier, node) =>
      prefix.toSource(),
    PropertyAccess(:final propertyName, :final realTarget)
        when identical(propertyName, node) =>
      realTarget.toSource(),
    _ => null,
  };
  final targetType = target?.split('.').last;
  return targetType != null && legacyAdapterTypeNames.contains(targetType);
}
