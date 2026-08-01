import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _systemPath =
    'packages/aonw_core/lib/game/application/engine/'
    'system_command.dart';
const _allowedReferences = <String>{
  'packages/aonw_core/lib/game/application/engine/game_engine.dart',
  'packages/aonw_core/lib/game/application/engine/turn_engine_handler.dart',
  'server/lib/src/multiplayer/server_command_reducer.dart',
  'server/lib/src/multiplayer/match_command_service_event.dart',
  'server/lib/src/multiplayer/match_lifecycle_service.dart',
  'server/lib/src/multiplayer/match_lifecycle_service_resignation.dart',
};
const _systemDeclarations = <String>{
  'SystemCommand',
  'SystemCommandCodec',
  'RecordedSystemCommand',
  'FinalizeTimedOutTurn',
  'KickParticipant',
};
const _systemTypes = <String>{
  'SystemCommand',
  'FinalizeTimedOutTurn',
  'KickParticipant',
};
const _removedLifecycleTypes = <String>{
  'LocalLifecycleCommand',
  'SetActivePlayerCommand',
  'ResetUnitMovementCommand',
};
const _canonicalPipelinePath =
    'packages/aonw_core/lib/game/application/turn/'
    'canonical_turn_pipeline.dart';
const _turnHandlerPath =
    'packages/aonw_core/lib/game/application/engine/'
    'turn_engine_handler.dart';

void main() {
  test('server system commands form a closed non-player boundary', () {
    final sources = productionDartSources();
    final systemSource = sources[_systemPath]!;
    final systemUnit = parseString(
      content: systemSource,
      path: _systemPath,
    ).unit;
    final declarations = {
      for (final declaration
          in systemUnit.declarations.whereType<ClassDeclaration>())
        declaration.namePart.typeName.lexeme: declaration,
    };

    expect(declarations.keys, _systemDeclarations);
    expect(declarations['SystemCommand']!.sealedKeyword, isNotNull);
    expect(
      declarations['SystemCommand']!.extendsClause,
      isNull,
      reason: 'Trusted server commands must not be player GameCommands.',
    );

    final unexpected = <String>[];
    for (final entry in sources.entries) {
      if (entry.key == _systemPath || _allowedReferences.contains(entry.key)) {
        continue;
      }
      final references = <String>{};
      parseString(
        content: entry.value,
        path: entry.key,
      ).unit.accept(_SystemReferenceCollector(references));
      final forbidden = references.intersection(_systemTypes);
      if (forbidden.isNotEmpty) {
        unexpected.add('${entry.key}: ${forbidden.toList()..sort()}');
      }
    }
    expect(
      unexpected,
      isEmpty,
      reason:
          'Client, serializer, replay and tool code cannot construct or '
          'reference trusted server commands.',
    );
  });

  test('legacy lifecycle commands and direct turn paths stay removed', () {
    final sources = productionDartSources();
    expect(
      sources.keys,
      isNot(
        anyOf(
          contains('advance_turn_snapshot.dart'),
          contains('submit_turn_reducer.dart'),
        ),
      ),
    );

    final legacyReferences = <String>[];
    final directPipelineReferences = <String>[];
    for (final entry in sources.entries) {
      final references = <String>{};
      parseString(
        content: entry.value,
        path: entry.key,
      ).unit.accept(_SystemReferenceCollector(references));
      final forbidden = references.intersection(_removedLifecycleTypes);
      if (forbidden.isNotEmpty) {
        legacyReferences.add('${entry.key}: ${forbidden.toList()..sort()}');
      }
      if (entry.key != _canonicalPipelinePath &&
          entry.key != _turnHandlerPath &&
          references.contains('CanonicalTurnPipeline')) {
        directPipelineReferences.add(entry.key);
      }
    }

    expect(
      legacyReferences,
      isEmpty,
      reason:
          'Removed presentation/reset lifecycle must not return as '
          'command-shaped runtime dispatch.',
    );
    expect(
      directPipelineReferences,
      isEmpty,
      reason:
          'Turn finalization must enter through GameEngine; only the '
          'closed turn handler may invoke CanonicalTurnPipeline.',
    );
  });
}

final class _SystemReferenceCollector extends RecursiveAstVisitor<void> {
  _SystemReferenceCollector(this.references);

  final Set<String> references;

  @override
  void visitNamedType(NamedType node) {
    references.add(node.name.lexeme);
    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    references.add(node.name);
    super.visitSimpleIdentifier(node);
  }
}
