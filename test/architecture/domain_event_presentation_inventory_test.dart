import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:aonw/game/presentation/engine/domain_event_animation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/presentation_parity_events.dart';

const _eventDirectory = 'packages/aonw_core/lib/game/domain/event';
const _descriptorPath =
    'lib/game/application/services/game_event_descriptor.dart';
const _animationPolicyPath =
    'lib/game/presentation/engine/domain_event_animation_policy.dart';
const _projectorPath =
    'lib/game/presentation/engine/domain_event_presentation_projector.dart';

void main() {
  test(
    'every concrete GameEvent has one descriptor and animation policy',
    _verifyPresentationInventory,
  );

  test(
    'domain projector depends on events and facts, never commands or diffs',
    () {
      final source = File(_projectorPath).readAsStringSync();
      final unit = parseString(
        content: source,
        path: _projectorPath,
        throwIfDiagnostics: false,
      ).unit;
      final imports = unit.directives
          .whereType<ImportDirective>()
          .map((directive) => directive.uri.stringValue ?? '')
          .toList();

      expect(imports.where((uri) => uri.contains('/command')), isEmpty);
      expect(source, isNot(contains('GameCommand')));
      expect(source, isNot(contains('fromUnitDelta')));
      expect(source, isNot(contains('state.units.length')));
    },
  );

  test(
    'authoritative projection uses typed batches through production renderer',
    () {
      const productionPaths = [
        'lib/game/presentation/engine/command_dispatch_presentation_projector.dart',
        'lib/game/presentation/providers/game/game_state_provider_effects.dart',
        'lib/game/presentation/replay/replay_renderer_effect_planner.dart',
        'lib/game/presentation/services/hidden_ai_renderer_playback.dart',
      ];
      for (final path in productionPaths) {
        final source = File(path).readAsStringSync();
        expect(source, contains('projectObservedBatch('), reason: path);
        expect(source, isNot(contains('projectObserved(')), reason: path);
      }

      final viewModel = File(
        'lib/game/presentation/engine/renderer_view_model.dart',
      ).readAsStringSync();
      final renderer = [
        'lib/game/presentation/engine/game_renderer.dart',
        'lib/game/presentation/engine/game_renderer_projected_effects.dart',
      ].map((path) => File(path).readAsStringSync()).join('\n');
      expect(viewModel, contains('production.applyAuthoritativeProjection('));
      expect(renderer, contains('_projectedEffectCursor.consumeBatch('));
      expect(renderer, contains('applyProjectedTransition('));
    },
  );
}

void _verifyPresentationInventory() {
  final declarations = _eventDeclarations();
  final concreteEvents = _concreteEvents(declarations);
  final descriptorCases = _descriptorCases();
  final policyCases = _animationPolicyCases();
  final fixtureTypes = presentationGameEvents
      .map((event) => '${event.runtimeType}')
      .toList(growable: false);

  expect(_expandedDescriptorCases(descriptorCases), concreteEvents);
  expect(descriptorCases.toSet(), hasLength(descriptorCases.length));
  expect(policyCases, concreteEvents);
  expect(policyCases, hasLength(41));
  expect(fixtureTypes.toSet(), concreteEvents);
  expect(fixtureTypes.toSet(), hasLength(fixtureTypes.length));

  final policies = presentationGameEvents
      .map(DomainEventAnimationPolicy.forEvent)
      .toList(growable: false);
  expect(
    policies.every((policy) => policy.reviewReason.trim().isNotEmpty),
    isTrue,
  );
  expect(policies.any((policy) => policy.hasRendererEffects), isTrue);
  expect(policies.any((policy) => !policy.hasRendererEffects), isTrue);
}

Map<String, String?> _eventDeclarations() {
  final declarations = <String, String?>{};
  for (final entity in Directory(_eventDirectory).listSync()) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final unit = parseString(
      content: entity.readAsStringSync(),
      path: entity.path,
      throwIfDiagnostics: false,
    ).unit;
    for (final declaration in unit.declarations.whereType<ClassDeclaration>()) {
      declarations[declaration.namePart.typeName.lexeme] = declaration
          .extendsClause
          ?.superclass
          .toSource();
    }
  }
  return declarations;
}

Set<String> _concreteEvents(Map<String, String?> declarations) {
  return {
    for (final entry in declarations.entries)
      if (entry.key.endsWith('Event') &&
          _isGameEvent(entry.key, declarations) &&
          entry.key != 'DomainEvent' &&
          entry.key != 'GameEvent' &&
          entry.key != 'UnitPresentationEvent' &&
          entry.key != 'WorldEntityLifecycleEvent' &&
          entry.key != 'ArtifactLifecycleEvent')
        entry.key,
  };
}

List<String> _descriptorCases() =>
    RegExp(r'^\s{2,4}([A-Z][A-Za-z]+Event)\(', multiLine: true)
        .allMatches(File(_descriptorPath).readAsStringSync())
        .map((match) => match.group(1)!)
        .toList();

Set<String> _animationPolicyCases() =>
    RegExp(r'^\s*([A-Z][A-Za-z]+Event):\s*\.', multiLine: true)
        .allMatches(File(_animationPolicyPath).readAsStringSync())
        .map((match) => match.group(1)!)
        .toSet();

Set<String> _expandedDescriptorCases(Iterable<String> descriptorCases) => {
  for (final name in descriptorCases)
    if (name == 'ArtifactLifecycleEvent') ...const {
      'ArtifactExcavationStartedEvent',
      'ArtifactCarriedEvent',
      'ArtifactStoredEvent',
    } else if (name == 'UnitPresentationEvent') ...const {
      'UnitMovedEvent',
      'FortifiedUnitThreatenedEvent',
      'UnitGainedExperienceEvent',
    } else
      name,
};

bool _isGameEvent(
  String name,
  Map<String, String?> declarations, [
  Set<String>? ancestors,
]) {
  if (name == 'DomainEvent' || name == 'GameEvent') return true;
  final seen = ancestors ?? <String>{};
  if (!seen.add(name)) return false;
  final parent = declarations[name];
  return parent != null && _isGameEvent(parent, declarations, seen);
}
