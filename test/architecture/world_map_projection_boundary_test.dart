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
const _productionMethodsPendingMigration = {'startUnitProduction'};

void main() {
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
        allowedProjectionMethods: _productionMethodsPendingMigration,
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
