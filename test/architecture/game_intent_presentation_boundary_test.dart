import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

const _interactionReducer =
    'lib/game/domain/reducer/game_state/game_state_reducer.dart';
const _intentResolver =
    'lib/game/application/services/game_intent_resolver.dart';
const _localCommandResolver =
    'lib/game/application/services/local_command_resolver.dart';
const _expectedConcreteIntents = <String>{
  'CancelAttackTargetingCommand',
  'CancelCityExpansionSelectionCommand',
  'CancelCityFoundingCommand',
  'CancelCityWorkedHexSelectionCommand',
  'CancelCommanderMergeSelectionCommand',
  'CancelMerchantMoveToCitySelectionCommand',
  'CancelMerchantTradeRouteSelectionCommand',
  'CancelResearchSelectionCommand',
  'CancelWorkerActionSelectionCommand',
  'ChooseWorkerImprovementIntent',
  'CityTappedCommand',
  'ConfirmWorkerImprovementIntent',
  'FocusNextPendingActionCommand',
  'FocusTurnStartActionCommand',
  'SelectCityCommand',
  'SelectTileCommand',
  'SelectUnitCommand',
  'StartAttackTargetingCommand',
  'StartCityExpansionSelectionCommand',
  'StartCityFoundingCommand',
  'StartCityWorkedHexSelectionCommand',
  'StartCommanderMergeSelectionCommand',
  'StartMerchantMoveToCitySelectionCommand',
  'StartMerchantTradeRouteSelectionCommand',
  'StartWorkerActionSelectionCommand',
  'TileTappedCommand',
  'ToggleMoveTargetingCommand',
};
const _ruleTypes = {
  'TurnReducer',
  'CityFoundingRules',
  'WorkerImprovementRules',
  'CombatResolver',
  'CombatRetreatResolver',
};
const _allowedPresentationRuleReads = <String, List<String>>{
  'lib/game/presentation/widgets/hud/overlay/hud_overlay_frame.dart': [
    'TurnReducer.pendingTurnActionCount',
    'TurnReducer.currentPendingTurnActionIndex',
    'CityFoundingRules.startFailure',
  ],
  'lib/game/presentation/widgets/hud/selection/hud_selection_action_rules.dart':
      ['CityFoundingRules.startFailure'],
  'lib/game/presentation/widgets/hud/combat/hud_combat_preview_resolver.dart': [
    'CombatResolver.resolve',
    'CombatRetreatResolver.destination',
  ],
  'lib/game/presentation/widgets/hud/turn/turn_action_hint.dart': [
    'TurnReducer.pendingTurnActionTargets',
  ],
  'lib/game/presentation/widgets/hud/city/hud_city_founding_availability.dart':
      ['CityFoundingRules.canStart'],
  'lib/game/presentation/screens/game/game_primary_action_controller.dart': [
    'TurnReducer.pendingTurnActionCount',
    'TurnReducer.pendingTurnActionCount',
  ],
  'lib/game/presentation/widgets/bottom_toolbar/view_models/worker_improvement_options_view_model_factory.dart':
      ['WorkerImprovementRules.evaluate', 'WorkerImprovementRules.evaluate'],
  'lib/game/presentation/engine/game_planning_marker_coordinator.dart': [
    'WorkerImprovementRules.availabilityForTile',
    'WorkerImprovementRules.cityForImprovementHex',
    'CityFoundingRules.isCenterFarEnoughFromCities',
  ],
  'lib/game/presentation/engine/recommended_city_site_planner.dart': [
    'CityFoundingRules.isControlledHexCandidate',
    'CityFoundingRules.isCenterFarEnoughFromCities',
  ],
  'lib/game/presentation/engine/rendering_layers/city/city_founding_preview_layer.dart':
      ['CityFoundingRules.isControlledHexCandidate'],
  'lib/game/presentation/widgets/selection/view_models/selection_resource_value_card_factory.dart':
      ['WorkerImprovementRules.cityForImprovementHex'],
  'lib/game/presentation/engine/rendering_layers/city/city_management_overlay_layer.dart':
      ['WorkerImprovementRules.evaluate'],
  'lib/game/presentation/widgets/selection/view_models/tile_selection_view_model_factory.dart':
      ['WorkerImprovementRules.cityForImprovementHex'],
};

void main() {
  test('the intent resolver exclusively owns GameIntent dispatch', () {
    final interactionReducer = File(_interactionReducer).readAsStringSync();
    final resolver = File(_intentResolver).readAsStringSync();
    final localCommandResolver = File(_localCommandResolver).readAsStringSync();
    final intentNames = _gameIntentNames();

    expect(intentNames.toSet(), _expectedConcreteIntents);
    expect(
      [
        for (final name in intentNames)
          if (interactionReducer.contains('$name()')) name,
      ],
      isEmpty,
      reason: 'GameStateReducer may not retain presentation intent branches.',
    );
    final handlerCounts = {
      for (final name in intentNames)
        name: RegExp('\\b$name\\(\\)').allMatches(resolver).length,
    };
    expect(
      handlerCounts,
      {for (final name in intentNames) name: 1},
      reason:
          'Every concrete GameIntent must have exactly one resolver branch.',
    );
    expect(localCommandResolver, isNot(contains('GameIntent')));
    expect(localCommandResolver, isNot(contains('game_intent_resolver.dart')));
  });

  test('presentation imports no authoritative command resolver', () {
    final offenders = <String>[];
    for (final entity in Directory(
      'lib/game/presentation',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceFirst('${Directory.current.path}/', '');
      if (!path.contains('/engine/') && !path.contains('/widgets/hud/')) {
        continue;
      }
      final unit = parseString(
        content: entity.readAsStringSync(),
        path: path,
        throwIfDiagnostics: false,
      ).unit;
      for (final directive in unit.directives.whereType<ImportDirective>()) {
        final uri = directive.uri.stringValue ?? '';
        if (uri.contains('command_resolver') ||
            uri.contains('engine_handler')) {
          offenders.add('$path -> $uri');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('presentation rule reads match the explicit planning allowlist', () {
    final actual = <String, List<String>>{};
    for (final entity in Directory(
      'lib/game/presentation',
    ).listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceFirst('${Directory.current.path}/', '');
      final unit = parseString(
        content: entity.readAsStringSync(),
        path: path,
        throwIfDiagnostics: false,
      ).unit;
      final visitor = _PresentationRuleReadVisitor();
      unit.accept(visitor);
      if (visitor.reads.isNotEmpty) actual[path] = visitor.reads;
    }
    expect(actual, _allowedPresentationRuleReads);
  });
}

final class _PresentationRuleReadVisitor extends RecursiveAstVisitor<void> {
  final List<String> reads = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final target = node.target?.toSource();
    if (target != null && _ruleTypes.contains(target)) {
      reads.add('$target.${node.methodName.name}');
    }
    super.visitMethodInvocation(node);
  }
}

List<String> _gameIntentNames() {
  final declarations = <String, String?>{};
  for (final entity in Directory(
    'packages/aonw_core/lib/game/domain/command',
  ).listSync()) {
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

  bool isIntent(String name, Set<String> seen) {
    if (name == 'GameIntent') return true;
    if (!seen.add(name)) return false;
    final parent = declarations[name];
    return parent != null && isIntent(parent, seen);
  }

  return [
    for (final entry in declarations.entries)
      if (entry.key != 'GameIntent' &&
          isIntent(entry.key, <String>{}) &&
          !entry.key.endsWith('InteractionCommand'))
        entry.key,
  ]..sort();
}
