import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('projected batches cannot bypass the exactly-once cursor', () {
    const batchPath = 'lib/game/presentation/engine/projected_game_effect.dart';
    final batchSource = File(batchPath).readAsStringSync();
    final batchUnit = parseString(
      content: batchSource,
      path: batchPath,
      throwIfDiagnostics: false,
    ).unit;
    final batch = batchUnit.declarations
        .whereType<ClassDeclaration>()
        .singleWhere(
          (declaration) =>
              declaration.namePart.typeName.lexeme ==
              'ProjectedGameEffectBatch',
        );
    final constructor = batch.body.members
        .whereType<ConstructorDeclaration>()
        .single;
    final parameterNames = constructor.parameters.parameters
        .map((parameter) => parameter.name?.lexeme)
        .toSet();

    expect(parameterNames, {
      'identity',
      'sequenceDirective',
      'projectedInteractionEffects',
      'animationPlans',
      'domainEffects',
    });
    expect(
      RegExp(r'SplayTreeMap<int,').allMatches(batchSource),
      hasLength(1),
      reason: 'Only the complete transition queue may buffer sequence gaps.',
    );

    for (final path in const [
      'lib/game/presentation/engine/game_renderer_projected_effects.dart',
      'lib/game/presentation/engine/renderer_view_model.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(
        source,
        contains('_projectedTransitionQueue.enqueue('),
        reason: path,
      );
      expect(
        source,
        contains('_projectedEffectCursor.consumeBatch('),
        reason: path,
      );
      expect(source, contains('transition.batch'), reason: path);
      expect(source, isNot(contains('batch.interactionEffects')), reason: path);
    }

    final productionHost = File(
      'lib/game/presentation/screens/game/game_screen.dart',
    ).readAsStringSync();
    expect(productionHost, contains('presentationClock:'));
    expect(
      productionHost,
      contains('session.gameMode == GameMode.multiplayer'),
    );
  });

  test('production renderer hosts explicitly activate one source', () {
    for (final path in const [
      'lib/game/presentation/screens/game/game_screen.dart',
      'lib/game/presentation/screens/replay/replay_renderer_host_lifecycle.dart',
    ]) {
      final visitor = _InvocationVisitor();
      _unit(path).accept(visitor);
      expect(
        visitor.members.where(
          (member) => member == 'activateProjectedEffectSource',
        ),
        hasLength(1),
        reason: path,
      );
    }
  });

  test('movement facts are associated before global event projection', () {
    const path =
        'lib/game/presentation/engine/domain_event_presentation_projector.dart';
    final visitor = _InvocationVisitor();
    _unit(path).accept(visitor);

    expect(visitor.members.where((member) => member == 'match'), hasLength(1));
    expect(
      visitor.members.where((member) => member == 'executionsForEventRange'),
      hasLength(1),
    );
    expect(
      visitor.members.where((member) => member == 'fromExecutions'),
      hasLength(1),
      reason: 'Observed projection is the only movement builder.',
    );
  });
}

CompilationUnit _unit(String path) => parseString(
  content: File(path).readAsStringSync(),
  path: path,
  throwIfDiagnostics: false,
).unit;

final class _InvocationVisitor extends RecursiveAstVisitor<void> {
  final List<String> members = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    members.add(node.methodName.name);
    super.visitMethodInvocation(node);
  }
}
