import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

part 'support/world_foundation_boundary_guard.dart';

const _allowedAdapterPaths = {
  'packages/aonw_core/lib/game/domain/hex/legacy_hex_coord_adapter.dart',
};

void main() {
  group('world foundation boundaries', () {
    test('canonical world files have an exact dependency surface', () {
      const expectedImports = <String, Set<String>>{
        'packages/aonw_core/lib/domain/hex_coord.dart': {},
        'packages/aonw_core/lib/domain/map_objective_definition.dart': {
          'package:aonw_core/domain/hex_coord.dart',
        },
        'packages/aonw_core/lib/domain/world_map.dart': {
          'package:aonw_core/domain/hex_coord.dart',
          'package:aonw_core/domain/map_objective_definition.dart',
          'package:aonw_core/domain/world_map_invariants.dart',
          'package:aonw_core/map/domain/map_tile_view.dart',
          'package:aonw_core/map/domain/terrain_type.dart',
        },
      };

      for (final entry in expectedImports.entries) {
        final source = File(entry.key).readAsStringSync();
        expect(
          _directiveUris(source, entry.key),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('WorldMap tileAt remains a direct keyed lookup', () {
      const path = 'packages/aonw_core/lib/domain/world_map.dart';
      final unit = parseString(
        content: File(path).readAsStringSync(),
        path: path,
      ).unit;
      final worldMap = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (declaration) => declaration.namePart.typeName.lexeme == 'WorldMap',
          );
      final tileAt = worldMap.body.members
          .whereType<MethodDeclaration>()
          .singleWhere((method) => method.name.lexeme == 'tileAt');
      final body = tileAt.body as ExpressionFunctionBody;

      expect(body.expression, isA<IndexExpression>());
      expect(body.expression.toSource(), '_tilesByCoordinate[coordinate]');
    });

    test('production has no explicit converters outside named adapters', () {
      final sources = <String, String>{};
      for (final root in const [
        'packages/aonw_core/lib',
        'lib',
        'server/lib',
      ]) {
        for (final file in _dartFiles(root)) {
          sources[_relativePath(file.path)] = file.readAsStringSync();
        }
      }

      expect(
        _converterViolations(sources, allowedPaths: _allowedAdapterPaths),
        isEmpty,
      );
    });

    test(
      'editor crosses the persistence map boundary only through MapDraft',
      () {
        const allowedPaths = {'lib/editor/domain/map_draft.dart'};
        const persistenceIdentifiers = {'MapData'};
        final violations = <String>[];

        for (final file in _dartFiles('lib/editor')) {
          final path = _relativePath(file.path);
          if (allowedPaths.contains(path)) continue;
          final unit = parseString(
            content: file.readAsStringSync(),
            path: path,
          ).unit;
          final identifiers = <String>{};
          unit.accept(_IdentifierCollector(identifiers));
          for (final identifier in persistenceIdentifiers) {
            if (identifiers.contains(identifier)) {
              violations.add('$path: $identifier');
            }
          }
        }

        expect(violations, isEmpty);
      },
    );

    test(
      'MapDraft freezes directly through the canonical tile-view factory',
      () {
        const path = 'lib/editor/domain/map_draft.dart';
        expect(
          _mapDraftFreezeViolations(File(path).readAsStringSync(), path),
          isEmpty,
        );
      },
    );

    test('MapDraft remains owned by the editor in production', () {
      final violations = <String>[];

      for (final root in const [
        'packages/aonw_core/lib',
        'lib',
        'server/lib',
      ]) {
        for (final file in _dartFiles(root)) {
          final path = _relativePath(file.path);
          if (path.startsWith('lib/editor/')) continue;
          final unit = parseString(
            content: file.readAsStringSync(),
            path: path,
          ).unit;
          final identifiers = <String>{};
          unit.accept(_IdentifierCollector(identifiers));
          if (identifiers.contains('MapDraft')) violations.add(path);
        }
      }

      expect(violations, isEmpty);
    });

    test('guard rejects signature and inline point converters', () {
      final violations = _converterViolations({
        'lib/city_converter.dart': '''
HexCoord fromCity(CityHex value) =>
    HexCoord(col: value.col, row: value.row);
''',
        'lib/inline_converter.dart': '''
Object wrap(HexCoordinate value) =>
    HexCoord(col: value.col, row: value.row);
''',
        'lib/map_converter.dart': '''
WorldMap freeze(MapData value) =>
    WorldMap(cols: value.cols, rows: value.rows, tiles: const []);
''',
      }, allowedPaths: const {});

      expect(violations, hasLength(3));
      expect(violations.join('\n'), contains('city_converter.dart'));
      expect(violations.join('\n'), contains('inline_converter.dart'));
      expect(violations.join('\n'), contains('map_converter.dart'));
    });

    test('guard rejects MapDraft freeze through a persistence projection', () {
      final violations = _mapDraftFreezeViolations('''
final class MapDraft {
  WorldMap freeze() => LegacyWorldMapAdapter.fromMapData(toMapData());
}
''', 'fixture.dart');

      expect(violations, contains(contains('WorldMap.fromTileViews')));
      expect(violations, contains(contains('must not call toMapData')));
    });

    test('guard rejects a discarded tile-view factory result', () {
      final violations = _mapDraftFreezeViolations('''
final class MapDraft {
  WorldMap freeze() {
    WorldMap.fromTileViews(cols: 1, rows: 1, tiles: const []);
    return cachedWorld;
  }
}
''', 'fixture.dart');

      expect(violations, contains(contains('must return one')));
    });

    test('guard rejects constructor, factory, and captured converters', () {
      final violations = _converterViolations({
        'lib/constructor_converter.dart': '''
final class Projection {
  Projection(MapData value)
      : world = WorldMap(cols: value.cols, rows: value.rows, tiles: const []);
  final WorldMap world;
}
''',
        'lib/factory_converter.dart': '''
Object freeze(MapData value) => WorldMap.fromLegacy(value);
''',
        'lib/captured_converter.dart': '''
final class Holder {
  const Holder(this.legacy);
  final MapData legacy;
  WorldMap get world => WorldMap(
    cols: legacy.cols,
    rows: legacy.rows,
    tiles: const [],
  );
}
''',
        'lib/initializer_converter.dart': '''
MapData source = obtainMap();
final frozen = WorldMap(
  cols: source.cols,
  rows: source.rows,
  tiles: const [],
);
''',
        'lib/extension_converter.dart': '''
extension CityBridge on CityHex {
  HexCoord toCanonical() => HexCoord(col: col, row: row);
}
''',
      }, allowedPaths: const {});

      expect(violations, hasLength(5));
      expect(violations.join('\n'), contains('constructor_converter.dart'));
      expect(violations.join('\n'), contains('factory_converter.dart'));
      expect(violations.join('\n'), contains('captured_converter.dart'));
      expect(violations.join('\n'), contains('initializer_converter.dart'));
      expect(violations.join('\n'), contains('extension_converter.dart'));
    });

    test('guard allows raw construction and named adapters', () {
      final violations = _converterViolations({
        'lib/raw_coordinate.dart': '''
HexCoord coordinate(int col, int row) => HexCoord(col: col, row: row);
''',
        'packages/aonw_core/lib/game/domain/hex/legacy_hex_coord_adapter.dart':
            '''
HexCoord fromCity(CityHex value) =>
    HexCoord(col: value.col, row: value.row);
''',
      }, allowedPaths: _allowedAdapterPaths);

      expect(violations, isEmpty);
    });
  });
}

Set<String> _directiveUris(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  return {
    for (final directive in unit.directives.whereType<UriBasedDirective>())
      ?directive.uri.stringValue,
  };
}

Iterable<File> _dartFiles(String root) {
  return Directory(root)
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .where((file) => !file.path.endsWith('.g.dart'))
      .where((file) => !file.path.endsWith('.freezed.dart'));
}

String _relativePath(String path) {
  final prefix = '${Directory.current.path}${Platform.pathSeparator}';
  return path.startsWith(prefix) ? path.substring(prefix.length) : path;
}
