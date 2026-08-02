import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _multiplayerRoot = 'server/lib/src/multiplayer/';

void main() {
  test('server multiplayer facades compose explicit capability services', () {
    const expectedCapabilities = <String, Set<String>>{
      '${_multiplayerRoot}server_command_reducer.dart': {
        'ServerMapCache',
        'ServerTurnPolicy',
        'ServerCommandDispatcher',
        'ServerCommandOutcomeProjector',
      },
      '${_multiplayerRoot}multiplayer_match_store.dart': {
        'MultiplayerMatchQueryStore',
        'MultiplayerMatchPersistenceStore',
        'MultiplayerMatchSnapshotStore',
      },
      '${_multiplayerRoot}player_match_view_projector.dart': {
        'PlayerMatchIdentityProjector',
        'PlayerMatchSnapshotProjector',
        'PlayerMatchEventProjector',
      },
      '${_multiplayerRoot}player_view_state_projector.dart': {
        'PlayerWorldStateProjector',
        'PlayerLifecycleStateProjector',
      },
    };

    for (final entry in expectedCapabilities.entries) {
      final unit = _unitAt(entry.key);
      expect(
        unit.directives.whereType<PartDirective>(),
        isEmpty,
        reason: '${entry.key} must compose services instead of parts.',
      );
      expect(
        _namedTypes(unit),
        containsAll(entry.value),
        reason: '${entry.key} must retain every reviewed capability.',
      );
    }
  });

  test('obsolete reducer and store responsibility parts stay removed', () {
    for (final path in const {
      '${_multiplayerRoot}multiplayer_match_store_creation.dart',
      '${_multiplayerRoot}server_command_reducer_map_cache.dart',
      '${_multiplayerRoot}server_command_reducer_outcome.dart',
      '${_multiplayerRoot}server_command_reducer_turns.dart',
      '${_multiplayerRoot}server_command_reducer_unit_action.dart',
    }) {
      expect(File(path).existsSync(), isFalse, reason: '$path must stay gone.');
    }
  });
}

CompilationUnit _unitAt(String path) =>
    parseString(content: File(path).readAsStringSync(), path: path).unit;

Set<String> _namedTypes(AstNode node) {
  final visitor = _NamedTypeVisitor();
  node.accept(visitor);
  return visitor.names;
}

final class _NamedTypeVisitor extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
