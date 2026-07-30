import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

const _eventDirectory = 'packages/aonw_core/lib/game/domain/event';
const _descriptorPath =
    'lib/game/application/services/game_event_descriptor.dart';
const _projectorPath =
    'lib/game/presentation/engine/domain_event_presentation_projector.dart';

const _presentationCatalog = <String, _PresentationDecision>{
  'ArtifactExcavationStartedEvent': _PresentationDecision.effect(
    'artifact excavation cue',
  ),
  'ArtifactCarriedEvent': _PresentationDecision.effect('artifact carried cue'),
  'ArtifactStoredEvent': _PresentationDecision.effect('artifact storage cue'),
  'CityFoundedEvent': _PresentationDecision.effect('city founding burst'),
  'CityBuiltBuildingEvent': _PresentationDecision.none(
    'persistent city state renders the building',
  ),
  'CityBuiltWonderEvent': _PresentationDecision.none(
    'persistent city state renders the wonder',
  ),
  'WonderProductionRefundedEvent': _PresentationDecision.none(
    'notification-only economy outcome',
  ),
  'CityProducedUnitEvent': _PresentationDecision.effect(
    'city production burst',
  ),
  'CityClaimedHexEvent': _PresentationDecision.effect('claimed-hex burst'),
  'UnitMovedEvent': _PresentationDecision.effect(
    'movement animation requires matching evidence',
  ),
  'FortifiedUnitThreatenedEvent': _PresentationDecision.effect(
    'camera focus and visible-enemy threat markers',
  ),
  'UnitGainedExperienceEvent': _PresentationDecision.none(
    'persistent unit state renders experience',
  ),
  'UnitAttackedEvent': _PresentationDecision.none(
    'CombatResolvedEvent owns the combat sequence',
  ),
  'CityAttackedEvent': _PresentationDecision.none(
    'CombatResolvedEvent owns the combat sequence',
  ),
  'CombatResolvedEvent': _PresentationDecision.effect(
    'combat, camera and result cues',
  ),
  'UnitKilledEvent': _PresentationDecision.effect('visible death cue'),
  'UnitRetreatedEvent': _PresentationDecision.effect(
    'visible retreat cue after combat',
  ),
  'CityCapturedEvent': _PresentationDecision.none(
    'persistent city state renders ownership',
  ),
  'CityDestroyedEvent': _PresentationDecision.none(
    'persistent world state removes the city',
  ),
  'TurnEndedEvent': _PresentationDecision.none(
    'turn lifecycle has no transient map effect',
  ),
  'WorkerCompletedJobEvent': _PresentationDecision.effect(
    'visible improvement completion cue',
  ),
  'DominationThresholdReachedEvent': _PresentationDecision.none(
    'notification-only victory progress',
  ),
  'StabilityBandChangedEvent': _PresentationDecision.none(
    'notification-only stability outcome',
  ),
  'ResearchPointsGainedEvent': _PresentationDecision.none(
    'persistent research state renders points',
  ),
  'TechnologyResearchedEvent': _PresentationDecision.effect(
    'visible research completion cue',
  ),
  'StrategicResourceDiscoveredEvent': _PresentationDecision.none(
    'notification and map-state update',
  ),
  'MapObjectiveSecuredEvent': _PresentationDecision.none(
    'notification and objective-state update',
  ),
  'CivilizationMetEvent': _PresentationDecision.none(
    'diplomacy popup and notification own the UI',
  ),
  'DiplomaticProposalSentEvent': _PresentationDecision.none(
    'diplomacy popup owns the UI',
  ),
  'DiplomaticProposalRespondedEvent': _PresentationDecision.none(
    'diplomacy popup owns the UI',
  ),
  'DiplomaticProposalExpiredEvent': _PresentationDecision.none(
    'notification-only expiry',
  ),
  'DiplomaticRelationChangedEvent': _PresentationDecision.none(
    'diplomacy state and notification',
  ),
  'DiplomaticMessageSentEvent': _PresentationDecision.none(
    'diplomacy popup owns the UI',
  ),
  'DiplomaticMessageRespondedEvent': _PresentationDecision.none(
    'diplomacy popup owns the UI',
  ),
  'DiplomaticScoreChangedEvent': _PresentationDecision.none(
    'persistent diplomacy state renders score',
  ),
  'DiplomaticPromiseBrokenEvent': _PresentationDecision.none(
    'notification-only diplomatic outcome',
  ),
  'CommandRejectedEvent': _PresentationDecision.none(
    'HUD feedback is interaction presentation',
  ),
  'AllPlayersSubmittedEvent': _PresentationDecision.none(
    'turn lifecycle status is state-driven',
  ),
  'PlayerTimedOutEvent': _PresentationDecision.none(
    'notification-only system outcome',
  ),
  'TurnAutoResolvedEvent': _PresentationDecision.none(
    'notification-only system outcome',
  ),
  'PlayerKickedEvent': _PresentationDecision.none(
    'lobby and notification state own the UI',
  ),
};

void main() {
  test(
    'every concrete GameEvent has one presentation descriptor branch',
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
        'lib/game/presentation/providers/game/game_state_provider_renderer_effects.dart',
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
      expect(renderer, contains('_projectedEffectCursor.consume('));
      expect(renderer, contains('applyProjectedTransition('));
    },
  );
}

void _verifyPresentationInventory() {
  final declarations = _eventDeclarations();
  final concreteEvents = _concreteEvents(declarations);
  final descriptorCases = _descriptorCases();
  _expectCompleteInventory(concreteEvents, descriptorCases);
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

void _expectCompleteInventory(
  Set<String> concreteEvents,
  List<String> descriptorCases,
) {
  final expandedDescriptorCases = {
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
  expect(expandedDescriptorCases, concreteEvents);
  expect(descriptorCases.toSet(), hasLength(descriptorCases.length));
  expect(concreteEvents, hasLength(41));
  expect(_presentationCatalog.keys.toSet(), concreteEvents);
  expect(
    _presentationCatalog.values.every(
      (decision) => decision.rationale.trim().isNotEmpty,
    ),
    isTrue,
  );
  expect(
    {
      for (final entry in _presentationCatalog.entries)
        if (entry.value.effectful) entry.key,
    },
    const {
      'CityFoundedEvent',
      'ArtifactExcavationStartedEvent',
      'ArtifactCarriedEvent',
      'ArtifactStoredEvent',
      'CityProducedUnitEvent',
      'CityClaimedHexEvent',
      'UnitMovedEvent',
      'FortifiedUnitThreatenedEvent',
      'CombatResolvedEvent',
      'UnitKilledEvent',
      'UnitRetreatedEvent',
      'WorkerCompletedJobEvent',
      'TechnologyResearchedEvent',
    },
  );
}

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

final class _PresentationDecision {
  const _PresentationDecision(this.effectful, this.rationale);
  const _PresentationDecision.effect(String rationale) : this(true, rationale);
  const _PresentationDecision.none(String rationale) : this(false, rationale);

  final bool effectful;
  final String rationale;
}
