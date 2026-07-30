import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'resolved_dart_workspace.dart';

typedef CityEconomyPatternSignature = ({int occurrences, int digest});

const cityEconomyFamilyCommandTypes = {
  'FoundCityCommand',
  'ToggleWorkedHexCommand',
  'SelectCityExpansionHexCommand',
  'StartBuildingCommand',
  'StartUnitProductionCommand',
  'StartCityProjectCommand',
  'StartWonderCommand',
  'SetCitySpecializationCommand',
  'RushProductionCommand',
  'SelectWorkerImprovementCommand',
  'ConfirmWorkerImprovementCommand',
  'CancelWorkerJobCommand',
  'AssignWorkerToHexCommand',
  'CancelWorkerAssignmentCommand',
  'StartArtifactExcavationCommand',
  'StoreArtifactInCityCommand',
  'TradeArtifactCommand',
  'OpenResourceTradeCommand',
  'OpenResourceExchangeCommand',
};

const _canonicalCityEconomyExecutorMembers = {
  'CityEngineHandler.apply',
  'ProductionEngineHandler.apply',
  'WorkerEngineHandler.apply',
  'ArtifactTradeEngineHandler.apply',
  'DomainCityFoundingResolver.foundCity',
  'DomainCityWorkedHexResolver.toggleWorkedHex',
  'DomainCityExpansionResolver.selectExpansionHex',
  'DomainCityProductionResolver.startBuilding',
  'DomainCityProductionResolver.startUnitProduction',
  'DomainCityProductionResolver.startCityProject',
  'DomainCityProductionResolver.startWonder',
  'DomainCityProductionResolver.setCitySpecialization',
  'DomainCityProductionResolver.rushProduction',
  'DomainWorkerCommandResolver.selectWorkerImprovement',
  'DomainWorkerCommandResolver.confirmWorkerImprovement',
  'DomainWorkerCommandResolver.cancelWorkerJob',
  'DomainWorkerCommandResolver.assignWorkerToHex',
  'DomainWorkerCommandResolver.cancelWorkerAssignment',
  'DomainArtifactCommandResolver.startExcavation',
  'DomainArtifactCommandResolver.storeInCity',
  'DomainArtifactCommandResolver.tradeArtifact',
  'DomainResourceTradeCommandResolver.openGoldForResourceTrade',
  'DomainResourceTradeCommandResolver.openResourceForResourceTrade',
};

const reviewedCityEconomyFamilyPatternSignatures =
    <String, CityEconomyPatternSignature>{
      'lib/game/analysis/human_trace_analyzer.dart': (
        occurrences: 10,
        digest: -6490144808525609761,
      ),
      'lib/game/analysis/human_trace_benchmark.dart': (
        occurrences: 1,
        digest: 6973065674861887521,
      ),
      'lib/game/application/services/'
          'accepted_engine_command_interaction_source.dart': (
        occurrences: 7,
        digest: 2164426491002170519,
      ),
      'lib/game/application/services/ai_turn_command_executor.dart': (
        occurrences: 19,
        digest: 1602138930146431912,
      ),
      'lib/game/application/services/authoritative_command_policy.dart': (
        occurrences: 24,
        digest: 5437926357238653160,
      ),
      'lib/game/application/services/game_intent_resolver.dart': (
        occurrences: 2,
        digest: 3281745417229852721,
      ),
      'lib/game/application/services/'
          'local_city_economy_command_resolver.dart': (
        occurrences: 3,
        digest: -1175467929627583722,
      ),
      'lib/game/application/services/'
          'local_city_economy_engine_projection.dart': (
        occurrences: 17,
        digest: -4199011773204335367,
      ),
      'lib/game/application/services/replay_service.dart': (
        occurrences: 19,
        digest: -8963395515821012448,
      ),
      'lib/game/domain/reducer/interaction/interaction_reducer.dart': (
        occurrences: 1,
        digest: -869746894041255394,
      ),
      'lib/game/presentation/audio/game_sound_cue_mapper.dart': (
        occurrences: 19,
        digest: -2757472282667144838,
      ),
      'lib/game/presentation/engine/game_renderer_tile_interactions.dart': (
        occurrences: 3,
        digest: -466922330534588617,
      ),
      'lib/game/presentation/widgets/diplomacy/'
          'diplomacy_player_modal_resource_trade.dart': (
        occurrences: 2,
        digest: 4006332364167670248,
      ),
      'lib/game/presentation/widgets/hud/city/'
          'hud_city_production_commands.dart': (
        occurrences: 6,
        digest: -5026013672559009755,
      ),
      'lib/game/presentation/widgets/hud/command/'
          'hud_command_dispatcher_selection.dart': (
        occurrences: 3,
        digest: -7589536156123265190,
      ),
      'lib/game/presentation/widgets/hud/selection/'
          'hud_selection_commands.dart': (
        occurrences: 3,
        digest: 4211285491768265953,
      ),
      'packages/aonw_core/lib/ai/mcts/mcts_baseline_command_merger.dart': (
        occurrences: 14,
        digest: 7103214852195880750,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'mcts_baseline_unit_command_policy.dart': (
        occurrences: 5,
        digest: 2119333732399357462,
      ),
      'packages/aonw_core/lib/ai/mcts/mcts_command_candidate_guard.dart': (
        occurrences: 3,
        digest: -6685554122981474006,
      ),
      'packages/aonw_core/lib/ai/mcts/mcts_command_production_scorer.dart': (
        occurrences: 1,
        digest: 60198737860560334,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'mcts_command_production_situation.dart': (
        occurrences: 1,
        digest: -797520559701036068,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'mcts_command_reconciliation_rules.dart': (
        occurrences: 5,
        digest: 529879481410210096,
      ),
      'packages/aonw_core/lib/ai/mcts/mcts_evaluator.dart': (
        occurrences: 10,
        digest: -4988507995828004633,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'mcts_founding_candidate_collector.dart': (
        occurrences: 1,
        digest: 531276455656515751,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'mcts_production_candidate_collector.dart': (
        occurrences: 3,
        digest: -3779747031801985062,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'mcts_worker_candidate_collector.dart': (
        occurrences: 2,
        digest: -5113967158501478700,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'settler_founding_stability_policy.dart': (
        occurrences: 1,
        digest: -189975145300646642,
      ),
      'packages/aonw_core/lib/ai/mcts/strategy_aware_action_generator.dart': (
        occurrences: 3,
        digest: 8369132987444023314,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_defense_early_ranker.dart': (
        occurrences: 4,
        digest: -398460280685429150,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_defense_general_ranker.dart': (
        occurrences: 4,
        digest: 2127882398197295186,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_defense_reserve_ranker.dart': (
        occurrences: 2,
        digest: -2007649061569774048,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_economy_production_ranker.dart': (
        occurrences: 2,
        digest: -4710714687669738789,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_economy_queue_ranker.dart': (
        occurrences: 2,
        digest: 4039804072226495396,
      ),
      'packages/aonw_core/lib/ai/mcts/strategy_aware_economy_ranker.dart': (
        occurrences: 5,
        digest: 6706291055254837820,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_economy_settler_production.dart': (
        occurrences: 2,
        digest: 4900184161290549480,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_economy_worker_ranker.dart': (
        occurrences: 2,
        digest: 8934562972088243795,
      ),
      'packages/aonw_core/lib/ai/mcts/strategy_aware_opening_ranker.dart': (
        occurrences: 2,
        digest: 5965492587030803564,
      ),
      'packages/aonw_core/lib/ai/mcts/strategy_aware_ranking_queries.dart': (
        occurrences: 3,
        digest: 640663020641648195,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_settler_move_ranker.dart': (
        occurrences: 2,
        digest: -13409445788220083,
      ),
      'packages/aonw_core/lib/ai/simulation/'
          'economy_simulation_command_stats.dart': (
        occurrences: 20,
        digest: 8550293528218054525,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_artifact_logistics_planner.dart': (
        occurrences: 2,
        digest: 7847464883070056778,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_city_specialization_planner.dart': (
        occurrences: 2,
        digest: -924610373205056015,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_founding_planner.dart': (
        occurrences: 5,
        digest: 4234080831130438685,
      ),
      'packages/aonw_core/lib/ai/strategies/basic_strategy_pipeline.dart': (
        occurrences: 1,
        digest: 8621105540158645398,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_planning_session.dart': (
        occurrences: 5,
        digest: -8391234929180754003,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_production_planner.dart': (
        occurrences: 4,
        digest: -6349717869821624977,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_resource_trade_planner.dart': (
        occurrences: 2,
        digest: -5630996025981291380,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_worker_planner.dart': (
        occurrences: 4,
        digest: 6695705971934485808,
      ),
      'server/lib/src/multiplayer/server_command_reducer.dart': (
        occurrences: 19,
        digest: -9108413536824560433,
      ),
    };

Future<Map<String, CityEconomyPatternSignature>>
cityEconomyFamilyPatternSignaturesByPath(Map<String, String> sources) async {
  final occurrences = await _cityEconomyFamilyPatternOccurrencesByPath(sources);
  return {
    for (final entry in occurrences.entries)
      entry.key: (
        occurrences: entry.value.values.fold(0, (sum, count) => sum + count),
        digest: _patternDigest(entry.value),
      ),
  };
}

Future<Map<String, Map<String, int>>> cityEconomyFamilyPatternOccurrencesByPath(
  Map<String, String> sources,
) => _cityEconomyFamilyPatternOccurrencesByPath(sources);

Future<Set<String>> unreviewedCityEconomyFamilyPatternPaths(
  Map<String, String> sources,
) async {
  final actual = await cityEconomyFamilyPatternSignaturesByPath(sources);
  return {
    for (final path in {
      ...actual.keys,
      ...reviewedCityEconomyFamilyPatternSignatures.keys,
    })
      if (actual[path] != reviewedCityEconomyFamilyPatternSignatures[path])
        path,
  };
}

Future<Map<String, Map<String, int>>>
_cityEconomyFamilyPatternOccurrencesByPath(Map<String, String> sources) async {
  final occurrences = <String, Map<String, int>>{};
  final paths = [
    for (final entry in sources.entries)
      if (_couldContainCityEconomyReference(entry.value)) entry.key,
  ]..sort();
  final workspace = ResolvedDartWorkspace(
    rootPath: Directory.current.path,
    sourceOverrides: {for (final path in paths) path: sources[path]!},
  );
  try {
    final resolvedUnits = await workspace.resolveAll(paths);
    for (final path in paths) {
      final visitor = _CityEconomyFamilyPatternVisitor();
      resolvedUnits[path]!.unit.accept(visitor);
      if (visitor.occurrences.isNotEmpty) {
        occurrences[path] = visitor.sortedOccurrences();
      }
    }
  } finally {
    await workspace.dispose();
  }
  return occurrences;
}

bool _couldContainCityEconomyReference(String source) {
  return cityEconomyFamilyCommandTypes.any(source.contains) ||
      _canonicalCityEconomyExecutorMembers.any((member) {
        final separator = member.indexOf('.');
        return source.contains(member.substring(0, separator)) &&
            source.contains(member.substring(separator + 1));
      });
}

int _patternDigest(Map<String, int> occurrences) {
  const offsetBasis = 0xcbf29ce484222325;
  const prime = 0x100000001b3;
  const mask = 0xffffffffffffffff;
  var digest = offsetBasis;
  for (final entry in occurrences.entries) {
    final token = '${entry.key}=${entry.value}\n';
    for (final codeUnit in token.codeUnits) {
      digest ^= codeUnit;
      digest = (digest * prime) & mask;
    }
  }
  return digest;
}

final class _CityEconomyFamilyPatternVisitor extends RecursiveAstVisitor<void> {
  final Map<String, int> occurrences = {};
  final List<String> _roles = ['compilation-unit'];

  Map<String, int> sortedOccurrences() {
    final keys = occurrences.keys.toList()..sort();
    return {for (final key in keys) key: occurrences[key]!};
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _visitRole(
      'class:${node.namePart.typeName.lexeme}',
      () => super.visitClassDeclaration(node),
    );
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _visitRole(
      'mixin:${node.name.lexeme}',
      () => super.visitMixinDeclaration(node),
    );
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _visitRole(
      'extension:${node.name?.lexeme ?? '<unnamed>'}',
      () => super.visitExtensionDeclaration(node),
    );
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _visitRole(
      'enum:${node.namePart.typeName.lexeme}',
      () => super.visitEnumDeclaration(node),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _visitNestedRole(
      'function:${node.name.lexeme}',
      () => super.visitFunctionDeclaration(node),
    );
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _visitNestedRole(
      '${node.isGetter ? 'getter' : 'method'}:${node.name.lexeme}',
      () => super.visitMethodDeclaration(node),
    );
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _visitNestedRole(
      'constructor:${node.name?.lexeme ?? 'new'}',
      () => super.visitConstructorDeclaration(node),
    );
  }

  @override
  void visitNamedType(NamedType node) {
    final element = node.element?.baseElement;
    if (element is InterfaceElement &&
        element.library.uri.toString() ==
            'package:aonw_core/game/domain/command/game_command.dart') {
      _record(element.displayName);
    }
    super.visitNamedType(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _recordExecutorMember(node.methodName.element);
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _recordExecutorMember(node.identifier.element);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _recordExecutorMember(node.propertyName.element);
    super.visitPropertyAccess(node);
  }

  void _recordExecutorMember(Element? element) {
    final memberKey = _elementMemberKey(element);
    if (memberKey != null &&
        _canonicalCityEconomyExecutorMembers.contains(memberKey)) {
      _record('executor:$memberKey');
    }
  }

  void _record(String type) {
    if (!type.startsWith('executor:') &&
        !cityEconomyFamilyCommandTypes.contains(type)) {
      return;
    }
    final key = '${_roles.last}::$type';
    occurrences[key] = (occurrences[key] ?? 0) + 1;
  }

  void _visitNestedRole(String role, void Function() visit) {
    final parent = _roles.last;
    _visitRole(parent == 'compilation-unit' ? role : '$parent/$role', visit);
  }

  void _visitRole(String role, void Function() visit) {
    _roles.add(role);
    visit();
    _roles.removeLast();
  }
}

String? _elementMemberKey(Element? element) {
  final base = element?.baseElement;
  if (base == null) return null;
  final enclosing = base.enclosingElement;
  if (enclosing is! InterfaceElement) return null;
  return '${enclosing.displayName}.${base.displayName}';
}
