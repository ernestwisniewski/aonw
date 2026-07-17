import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _projectorPath =
    'server/lib/src/multiplayer/player_match_view_projector.dart';
const _stateProjectorPath =
    'server/lib/src/multiplayer/player_view_state_projector.dart';
const _viewStatePath =
    'packages/aonw_core/lib/game/view/player_view_state.dart';

void main() {
  test('player projection returns and constructs only nominal view state', () {
    final sources = productionDartSources();
    final matchProjector = _classNamed(
      _unitAt(_projectorPath),
      'PlayerMatchViewProjector',
    );
    final stateFor = matchProjector.body.members
        .whereType<MethodDeclaration>()
        .singleWhere((member) => member.name.lexeme == '_stateFor');
    final stateProjector = _classNamed(
      _unitAt(_stateProjectorPath),
      'PlayerViewStateProjector',
    );
    final project = stateProjector.body.members
        .whereType<MethodDeclaration>()
        .singleWhere((member) => member.name.lexeme == 'project');

    expect(stateFor.returnType?.toSource(), 'PlayerViewState');
    expect(project.returnType?.toSource(), 'PlayerViewState');

    final outsideStateProjector = Map<String, String>.from(sources)
      ..remove(_stateProjectorPath);
    expect(
      constructedTypeViolations(outsideStateProjector, type: 'PlayerViewState'),
      isEmpty,
    );
  });

  test('canonical reducers, stores, AI, and replay reject player views', () {
    final violations = <String>[];
    for (final entry in productionDartSources().entries) {
      if (!_isCanonicalStateSubsystem(entry.key)) continue;
      violations.addAll(
        sourceSymbolReferenceViolations(
          entry.value,
          entry.key,
          symbol: 'PlayerViewState',
        ),
      );
    }

    expect(violations, isEmpty);
  });

  test(
    'player view exposes identity and wire encoding, not canonical state',
    () {
      final viewState = _classNamed(_unitAt(_viewStatePath), 'PlayerViewState');
      final violations = <String>[];
      for (final member in viewState.body.members) {
        switch (member) {
          case FieldDeclaration(:final fields):
            final exposesCanonicalState = _namedTypes(
              fields.type,
            ).any(const {'PersistentGameState', 'DomainState'}.contains);
            for (final variable in fields.variables) {
              if (!variable.name.lexeme.startsWith('_') &&
                  exposesCanonicalState) {
                violations.add(variable.name.lexeme);
              }
            }
          case MethodDeclaration(:final name, :final returnType):
            if (!name.lexeme.startsWith('_') &&
                _namedTypes(
                  returnType,
                ).any(const {'PersistentGameState', 'DomainState'}.contains)) {
              violations.add(name.lexeme);
            }
          default:
            break;
        }
      }

      expect(violations, isEmpty);
    },
  );
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

ClassDeclaration _classNamed(CompilationUnit unit, String name) {
  return unit.declarations.whereType<ClassDeclaration>().singleWhere(
    (declaration) => declaration.namePart.typeName.lexeme == name,
  );
}

bool _isCanonicalStateSubsystem(String path) {
  return path.startsWith('packages/aonw_core/lib/ai/') ||
      path.startsWith('lib/game/domain/ai/') ||
      path.startsWith('lib/game/domain/reducer/') ||
      path.startsWith('server/lib/src/multiplayer/multiplayer_match_store') ||
      path.startsWith('server/lib/src/multiplayer/server_command_reducer') ||
      path.contains('/replay/');
}

Set<String> _namedTypes(AstNode? node) {
  if (node == null) return const {};
  final types = <String>{};
  node.accept(_NamedTypeCollector(types));
  return types;
}

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  _NamedTypeCollector(this.types);

  final Set<String> types;

  @override
  void visitNamedType(NamedType node) {
    types.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
