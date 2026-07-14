import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _allowedAdapterPaths = {
  'packages/aonw_core/lib/game/domain/hex/legacy_hex_coord_adapter.dart',
  'packages/aonw_core/lib/map/persistence/legacy_world_map_adapter.dart',
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

    test('editor crosses the legacy map boundary only through MapDraft', () {
      const allowedPaths = {'lib/editor/domain/map_draft.dart'};
      const legacyIdentifiers = {'MapData', 'LegacyWorldMapAdapter'};
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
        for (final identifier in legacyIdentifiers) {
          if (identifiers.contains(identifier)) {
            violations.add('$path: $identifier');
          }
        }
      }

      expect(violations, isEmpty);
    });

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

List<String> _converterViolations(
  Map<String, String> sources, {
  required Set<String> allowedPaths,
}) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    if (allowedPaths.contains(entry.key)) continue;
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final declaredTypes = <String, String>{};
    unit
      ..accept(_DeclaredTypeCollector(declaredTypes))
      ..accept(_ConverterVisitor(entry.key, violations, declaredTypes));
  }
  return violations;
}

final class _DeclaredTypeCollector extends RecursiveAstVisitor<void> {
  _DeclaredTypeCollector(this.types);

  final Map<String, String> types;

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final declaration = node.parent;
    final owner = declaration?.parent;
    if (declaration is VariableDeclarationList &&
        (owner is TopLevelVariableDeclaration || owner is FieldDeclaration)) {
      final type = declaration.type?.toSource();
      if (type != null) types[node.name.lexeme] = type;
    }
    super.visitVariableDeclaration(node);
  }
}

final class _IdentifierCollector extends RecursiveAstVisitor<void> {
  _IdentifierCollector(this.names);

  final Set<String> names;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    names.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}

final class _ConverterVisitor extends RecursiveAstVisitor<void> {
  _ConverterVisitor(this.path, this.violations, this.declaredTypes);

  final String path;
  final List<String> violations;
  final Map<String, String> declaredTypes;

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkCallable(
      name: node.name.lexeme,
      returnType: node.returnType?.toSource() ?? '',
      parameters: node.functionExpression.parameters,
      nodes: [node.functionExpression.body],
      offset: node.offset,
    );
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkCallable(
      name: node.name.lexeme,
      returnType: node.returnType?.toSource() ?? '',
      parameters: node.parameters,
      receiverType: _extensionReceiverType(node),
      nodes: [node.body],
      offset: node.offset,
    );
    super.visitMethodDeclaration(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration &&
        node.parent is! MethodDeclaration) {
      _checkCallable(
        name: '<closure>',
        returnType: '',
        parameters: node.parameters,
        nodes: [node.body],
        offset: node.offset,
      );
    }
    super.visitFunctionExpression(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkCallable(
      name: node.name?.lexeme ?? '<unnamed>',
      returnType: '',
      parameters: node.parameters,
      nodes: [...node.initializers, node.body],
      offset: node.offset,
    );
    super.visitConstructorDeclaration(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final declaration = node.parent;
    final owner = declaration?.parent;
    final initializer = node.initializer;
    if (initializer != null &&
        declaration is VariableDeclarationList &&
        (owner is TopLevelVariableDeclaration || owner is FieldDeclaration)) {
      _checkCallable(
        name: node.name.lexeme,
        returnType: declaration.type?.toSource() ?? '',
        parameters: null,
        nodes: [initializer],
        offset: node.offset,
      );
    }
    super.visitVariableDeclaration(node);
  }

  void _checkCallable({
    required String name,
    required String returnType,
    required FormalParameterList? parameters,
    String receiverType = '',
    required Iterable<AstNode> nodes,
    required int offset,
  }) {
    final parameterTypes = '${parameters?.toSource() ?? ''} $receiverType';
    final createdTypes = <String>{};
    final referencedTypes = <String>{};
    final visitor = _TypeUsageVisitor(
      createdTypes: createdTypes,
      referencedTypes: referencedTypes,
      declaredTypes: declaredTypes,
    );
    for (final node in nodes) {
      node.accept(visitor);
    }
    if (_crossesBoundary(
      returnType,
      parameterTypes,
      createdTypes,
      referencedTypes,
    )) {
      violations.add('$path@$offset $name converts canonical and legacy data');
    }
  }
}

String _extensionReceiverType(AstNode node) {
  for (var parent = node.parent; parent != null; parent = parent.parent) {
    if (parent is ExtensionDeclaration) {
      return parent.onClause?.extendedType.toSource() ?? '';
    }
  }
  return '';
}

final class _TypeUsageVisitor extends RecursiveAstVisitor<void> {
  _TypeUsageVisitor({
    required this.createdTypes,
    required this.referencedTypes,
    required this.declaredTypes,
  });

  final Set<String> createdTypes;
  final Set<String> referencedTypes;
  final Map<String, String> declaredTypes;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    createdTypes.add(node.constructorName.type.toSource());
    super.visitInstanceCreationExpression(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    createdTypes.add(node.methodName.name);
    final target = node.realTarget?.toSource();
    if (target != null) referencedTypes.add(target);
    super.visitMethodInvocation(node);
  }

  @override
  void visitNamedType(NamedType node) {
    referencedTypes.add(node.toSource());
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final declaredType = declaredTypes[node.name];
    if (declaredType != null) referencedTypes.add(declaredType);
    super.visitSimpleIdentifier(node);
  }
}

bool _crossesBoundary(
  String returnType,
  String parameterTypes,
  Set<String> createdTypes,
  Set<String> referencedTypes,
) {
  return _crossesTypePair(
        canonical: 'HexCoord',
        legacy: const {'CityHex', 'HexCoordinate'},
        returnType: returnType,
        parameterTypes: parameterTypes,
        createdTypes: createdTypes,
        referencedTypes: referencedTypes,
      ) ||
      _crossesTypePair(
        canonical: 'WorldMap',
        legacy: const {'MapData', 'MapDefinition'},
        returnType: returnType,
        parameterTypes: parameterTypes,
        createdTypes: createdTypes,
        referencedTypes: referencedTypes,
      );
}

bool _crossesTypePair({
  required String canonical,
  required Set<String> legacy,
  required String returnType,
  required String parameterTypes,
  required Set<String> createdTypes,
  required Set<String> referencedTypes,
}) {
  final takesCanonical = _containsType(parameterTypes, canonical);
  final takesLegacy = legacy.any((type) => _containsType(parameterTypes, type));
  final referencesCanonical = referencedTypes.any(
    (type) => _containsType(type, canonical),
  );
  final referencesLegacy = referencedTypes.any(
    (reference) => legacy.any((type) => _containsType(reference, type)),
  );
  final returnsCanonical = _containsType(returnType, canonical);
  final returnsLegacy = legacy.any((type) => _containsType(returnType, type));
  final createsCanonical = createdTypes.any(
    (type) => _containsType(type, canonical),
  );
  final createsLegacy = createdTypes.any(
    (created) => legacy.any((type) => _containsType(created, type)),
  );
  return ((takesLegacy || referencesLegacy) &&
          (returnsCanonical || createsCanonical || referencesCanonical)) ||
      ((takesCanonical || referencesCanonical) &&
          (returnsLegacy || createsLegacy || referencesLegacy));
}

bool _containsType(String source, String type) {
  return RegExp(
    '(?:^|[^A-Za-z0-9_])${RegExp.escape(type)}(?:\$|[^A-Za-z0-9_])',
  ).hasMatch(source);
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
