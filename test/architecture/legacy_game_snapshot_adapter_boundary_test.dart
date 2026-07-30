import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _adapterPath =
    'packages/aonw_core/lib/game/compatibility/'
    'legacy_game_snapshot_adapter.dart';
const _canonicalStateDirectory = 'packages/aonw_core/lib/game/domain/state/';
const _canonicalStateBarrel = 'packages/aonw_core/lib/game/domain/state.dart';

void main() {
  group('legacy game snapshot compatibility boundary', () {
    test(
      'production declares exactly one adapter at the compatibility path',
      () {
        final declarations = <({String path, ClassDeclaration declaration})>[];
        for (final entry in productionDartSources(
          containing: 'LegacyGameSnapshotAdapter',
        ).entries) {
          final unit = parseString(content: entry.value, path: entry.key).unit;
          for (final declaration
              in unit.declarations.whereType<ClassDeclaration>()) {
            if (declaration.namePart.typeName.lexeme ==
                'LegacyGameSnapshotAdapter') {
              declarations.add((path: entry.key, declaration: declaration));
            }
          }
        }

        expect(declarations.map((entry) => entry.path).toList(), [
          _adapterPath,
        ]);
        expect(declarations.single.declaration.finalKeyword, isNotNull);
      },
    );

    test('adapter does not depend on views, maps, wire, or protocol types', () {
      final unit = _unitAt(_adapterPath);
      final typeNames = <String>{};
      unit.accept(_NamedTypeCollector(typeNames));
      final forbiddenTypes = typeNames.where((name) {
        final normalized = name.toLowerCase();
        return name == 'PlayerViewState' ||
            name == 'MapData' ||
            normalized.contains('wire') ||
            normalized.contains('protocol');
      }).toSet();
      final forbiddenImports = unit.directives
          .whereType<UriBasedDirective>()
          .map((directive) => directive.uri.stringValue)
          .whereType<String>()
          .where(_isViewMapWireOrProtocolUri)
          .toSet();

      expect(forbiddenTypes, isEmpty);
      expect(forbiddenImports, isEmpty);
    });

    test('canonical state files never import compatibility', () {
      final violations = <String>[];
      for (final entry in productionDartSources().entries) {
        if (entry.key != _canonicalStateBarrel &&
            !entry.key.startsWith(_canonicalStateDirectory)) {
          continue;
        }
        final unit = parseString(content: entry.value, path: entry.key).unit;
        for (final directive
            in unit.directives.whereType<UriBasedDirective>()) {
          final uri = directive.uri.stringValue;
          if (uri == null || !_isCompatibilityUri(uri)) continue;
          final line = unit.lineInfo.getLocation(directive.offset).lineNumber;
          violations.add('${entry.key}:$line imports $uri');
        }
      }

      expect(violations, isEmpty);
    });

    test('performance workload legacy adapter debt stays bounded', () {
      final paths = {
        for (final entry in productionDartSources().entries)
          if (entry.key.startsWith('tool/performance/') &&
              sourceSymbolReferenceViolations(
                entry.value,
                entry.key,
                symbol: 'LegacyGameSnapshotAdapter',
              ).isNotEmpty)
            entry.key,
      };

      expect(paths, {
        'tool/performance/ai_strategy_workload.dart',
        'tool/performance/turn_finalization_workload.dart',
      });
    });
  });
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

bool _isViewMapWireOrProtocolUri(String uri) {
  final normalized = uri.toLowerCase();
  return normalized.contains('/view/') ||
      normalized.endsWith('/view.dart') ||
      normalized.endsWith('/map_data.dart') ||
      normalized.contains('/wire/') ||
      normalized.endsWith('/wire.dart') ||
      normalized.contains('/protocol/') ||
      normalized.endsWith('/protocol.dart');
}

bool _isCompatibilityUri(String uri) {
  final normalized = uri.toLowerCase();
  return normalized.contains('/compatibility/') ||
      normalized.endsWith('/compatibility.dart');
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  _NamedTypeCollector(this.names);

  final Set<String> names;

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
