import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonical world boundary', () {
    test('legacy map representations and adapters are removed', () {
      for (final path in const [
        'packages/aonw_core/lib/map/domain/map_data.dart',
        'lib/map/domain/map_data.dart',
        'packages/aonw_core/lib/map/domain/world_map_read_view.dart',
      ]) {
        expect(File(path).existsSync(), isFalse, reason: path);
      }

      expect(_legacyMapReferences(), isEmpty);
    });

    test('WorldMap is the immutable indexed map root', () {
      const path = 'packages/aonw_core/lib/domain/world_map.dart';
      final unit = parseString(
        content: File(path).readAsStringSync(),
        path: path,
      ).unit;
      final declaration = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (candidate) => candidate.namePart.typeName.lexeme == 'WorldMap',
          );
      final fields = {
        for (final field
            in declaration.body.members.whereType<FieldDeclaration>())
          for (final variable in field.fields.variables)
            variable.name.lexeme: field,
      };

      expect(declaration.finalKeyword, isNotNull);
      expect(declaration.implementsClause?.toSource(), contains('MapReadView'));
      expect(
        declaration.implementsClause?.toSource(),
        contains('MapTileSource<WorldTile>'),
      );
      for (final name in const [
        'cols',
        'rows',
        'tiles',
        'objectives',
        'mapName',
        'defaultZoom',
        '_tilesByCoordinate',
      ]) {
        expect(fields[name]?.fields.isFinal, isTrue, reason: name);
      }
      final tileAt = declaration.body.members
          .whereType<MethodDeclaration>()
          .singleWhere((method) => method.name.lexeme == 'tileAt');
      expect(tileAt.toSource(), contains('_tilesByCoordinate[HexCoord('));
      final coordinateLookup = declaration.body.members
          .whereType<MethodDeclaration>()
          .singleWhere((method) => method.name.lexeme == 'tileAtHex');
      expect(
        coordinateLookup.toSource(),
        contains('_tilesByCoordinate[coordinate]'),
      );
    });

    test('MapDraft remains editor-only and freezes directly to WorldMap', () {
      const draftPath = 'lib/editor/domain/map_draft.dart';
      final draft = File(draftPath).readAsStringSync();
      expect(draft, contains('WorldMap freeze('));
      expect(draft, contains('WorldMap.fromTileViews('));

      final violations = <String>[];
      for (final entry in _productionSources().entries) {
        if (entry.key.startsWith('lib/editor/')) continue;
        if (RegExp(r'\bMapDraft\b').hasMatch(entry.value)) {
          violations.add(entry.key);
        }
      }
      expect(violations, isEmpty);
    });
  });
}

List<String> _legacyMapReferences() {
  final violations = <String>[];
  for (final entry in _productionSources().entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final guard = _LegacyMapAstGuard()..visitCompilationUnit(unit);
    if (guard.foundForbiddenReference) {
      violations.add(entry.key);
    }
  }
  return violations;
}

Map<String, String> _productionSources() {
  final result = <String, String>{};
  for (final root in const [
    'lib',
    'packages/aonw_core/lib',
    'server/lib',
    'tool',
  ]) {
    for (final entity in Directory(root).listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        result[entity.path] = entity.readAsStringSync();
      }
    }
  }
  return result;
}

final class _LegacyMapAstGuard extends RecursiveAstVisitor<void> {
  static const _forbiddenTypes = {'MapData', 'TileData', 'WorldMapReadView'};
  static final _forbiddenImport = RegExp(
    r'/(map_data|world_map_read_view)\.dart$',
  );

  bool foundForbiddenReference = false;

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_forbiddenTypes.contains(node.namePart.typeName.lexeme)) {
      foundForbiddenReference = true;
    }
    super.visitClassDeclaration(node);
  }

  @override
  void visitNamedType(NamedType node) {
    if (_forbiddenTypes.contains(node.name.lexeme)) {
      foundForbiddenReference = true;
    }
    super.visitNamedType(node);
  }

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri != null && _forbiddenImport.hasMatch(uri)) {
      foundForbiddenReference = true;
    }
    super.visitImportDirective(node);
  }
}
