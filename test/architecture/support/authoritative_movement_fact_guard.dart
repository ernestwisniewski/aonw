import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import 'resolved_dart_workspace.dart';

const movementFactProjectorPath =
    'lib/game/presentation/engine/domain_event_presentation_projector.dart';
const movementFactGameActionsPath =
    'lib/game/presentation/engine/command_dispatch_presentation_projector.dart';
const movementFactExternalPath =
    'lib/game/presentation/providers/game/game_state_provider_effects.dart';
const movementFactHiddenAiPath =
    'lib/game/presentation/services/hidden_ai_renderer_playback.dart';
const movementFactReplayPath =
    'lib/game/presentation/replay/replay_renderer_effect_planner.dart';

const _paths = {
  movementFactProjectorPath,
  movementFactGameActionsPath,
  movementFactExternalPath,
  movementFactHiddenAiPath,
  movementFactReplayPath,
  'lib/game/application/services/queued_movement_effect_builder.dart',
  'lib/game/application/services/local_command_resolver.dart',
  'lib/game/application/ports/command_transport.dart',
  'lib/game/application/use_cases/dispatch_command_use_case.dart',
  'lib/game/application/services/game_handoff.dart',
  'lib/game/application/services/replay_service.dart',
};

final class MovementFactAudit {
  const MovementFactAudit(this.violations);

  final List<String> violations;
}

Future<MovementFactAudit> auditMovementFactGraph({
  Map<String, String> sourceOverrides = const {},
}) async {
  final workspace = ResolvedDartWorkspace(
    rootPath: '.',
    sourceOverrides: sourceOverrides,
  );
  try {
    final units = await workspace.resolveAll(_paths);
    final projectorCalls = <String, int>{};
    final effectBuilderCalls = <String, int>{};
    final invalidFactArguments = <String>[];
    for (final entry in units.entries) {
      final visitor = _MovementFactVisitor(
        path: entry.key,
        projectorCalls: projectorCalls,
        effectBuilderCalls: effectBuilderCalls,
        invalidFactArguments: invalidFactArguments,
      );
      entry.value.unit.accept(visitor);
    }
    final violations = <String>[
      if (!_sameCounts(projectorCalls, const {
        movementFactGameActionsPath: 1,
        movementFactExternalPath: 1,
        movementFactHiddenAiPath: 1,
        movementFactReplayPath: 1,
      }))
        'projectObservedBatch callsites changed: $projectorCalls',
      if (!_sameCounts(effectBuilderCalls, const {
        movementFactProjectorPath: 1,
      }))
        'movement effects must only be created by the projector: '
            '$effectBuilderCalls',
      ...invalidFactArguments,
    ];
    return MovementFactAudit(List.unmodifiable(violations));
  } finally {
    await workspace.dispose();
  }
}

bool _sameCounts(Map<String, int> actual, Map<String, int> expected) {
  return actual.length == expected.length &&
      expected.entries.every((entry) => actual[entry.key] == entry.value);
}

final class _MovementFactVisitor extends RecursiveAstVisitor<void> {
  _MovementFactVisitor({
    required this.path,
    required this.projectorCalls,
    required this.effectBuilderCalls,
    required this.invalidFactArguments,
  });

  final String path;
  final Map<String, int> projectorCalls;
  final Map<String, int> effectBuilderCalls;
  final List<String> invalidFactArguments;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.methodName.element?.enclosingElement?.displayName;
    final member = node.methodName.name;
    if (target == 'DomainEventPresentationProjector' &&
        member == 'projectObservedBatch') {
      projectorCalls.update(path, (count) => count + 1, ifAbsent: () => 1);
      final facts = node.argumentList.arguments
          .whereType<NamedExpression>()
          .where(
            (argument) =>
                argument.name.label.name == 'visibleMovementExecutions',
          )
          .toList();
      if (facts.length != 1 ||
          !_isForwardedMovementFacts(facts.single.expression)) {
        invalidFactArguments.add(
          '$path must forward typed movementExecutions to projectObservedBatch.',
        );
      }
    }
    if (target == 'QueuedMovementEffectBuilder' && member == 'fromExecutions') {
      effectBuilderCalls.update(path, (count) => count + 1, ifAbsent: () => 1);
    }
    super.visitMethodInvocation(node);
  }
}

bool _isForwardedMovementFacts(Expression expression) {
  final element = switch (expression) {
    PrefixedIdentifier(:final identifier) => identifier.element,
    PropertyAccess(:final propertyName) => propertyName.element,
    SimpleIdentifier(:final element) => element,
    _ => null,
  };
  return element != null && element.displayName == 'movementExecutions';
}
