import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import 'resolved_dart_workspace.dart';

typedef ResearchDiplomacyPatternSignature = ({int occurrences, int digest});

const researchDiplomacyFamilyCommandTypes = {
  'DiplomaticCommand',
  'SelectTechnologyCommand',
  'SendDiplomaticProposalCommand',
  'RespondDiplomaticProposalCommand',
  'DeclareWarCommand',
  'SendGoldGiftCommand',
  'SendDiplomaticMessageCommand',
  'RespondDiplomaticMessageCommand',
};

const _canonicalResearchDiplomacyExecutorMembers = {
  'ResearchEngineHandler.apply',
  'DiplomacyEngineHandler.apply',
  'DomainResearchCommandResolver.selectTechnology',
  'DomainDiplomacyCommandResolver.resolve',
  'SelectTechnologyResolver.selectTechnology',
  'ResearchOverflowRules.applyToSelectedTechnology',
  'ResearchSelectionPendingActionPolicy.afterAcceptedSelection',
  'DiplomacyCommandResolver.resolve',
  'DiplomacyProposalCommandHandler.resolve',
  'DiplomacyProposalResponseCommandHandler.resolve',
  'DiplomacyWarAndGiftCommandHandler.declareWar',
  'DiplomacyWarAndGiftCommandHandler.sendGoldGift',
  'DiplomacyMessageCommandHandler.sendMessage',
  'DiplomacyMessageCommandHandler.respondMessage',
};

const reviewedResearchDiplomacyFamilyPatternSignatures =
    <String, ResearchDiplomacyPatternSignature>{
      'lib/game/analysis/human_trace_analysis.dart': (
        occurrences: 2,
        digest: -688480779725267505,
      ),
      'lib/game/application/services/'
          'accepted_engine_command_interaction_source.dart': (
        occurrences: 1,
        digest: 6728238861306824402,
      ),
      'lib/game/application/services/ai_turn_command_executor.dart': (
        occurrences: 7,
        digest: 8693179505763133849,
      ),
      'lib/game/application/services/'
          'local_research_diplomacy_command_resolver.dart': (
        occurrences: 2,
        digest: 8017902511319485261,
      ),
      'lib/game/application/services/replay_service.dart': (
        occurrences: 7,
        digest: -2476462167450391537,
      ),
      'lib/game/presentation/audio/game_sound_cue_mapper.dart': (
        occurrences: 2,
        digest: 6069370054574359381,
      ),
      'lib/game/presentation/widgets/diplomacy/'
          'diplomacy_player_modal_actions.dart': (
        occurrences: 4,
        digest: -3401299362916956044,
      ),
      'lib/game/presentation/widgets/diplomacy/'
          'diplomacy_player_modal_conversation.dart': (
        occurrences: 1,
        digest: -2400207752553581003,
      ),
      'lib/game/presentation/widgets/diplomacy/'
          'diplomacy_player_modal_primitives.dart': (
        occurrences: 3,
        digest: -2420503857590387296,
      ),
      'lib/game/presentation/widgets/diplomacy/'
          'diplomatic_popup_presentation.dart': (
        occurrences: 2,
        digest: -5026820036386730781,
      ),
      'lib/game/presentation/widgets/hud/command/'
          'hud_command_dispatcher_city_research.dart': (
        occurrences: 1,
        digest: -8112916657560051160,
      ),
      'packages/aonw_core/lib/ai/diplomacy_ai_initiative.dart': (
        occurrences: 6,
        digest: 4315045777510882053,
      ),
      'packages/aonw_core/lib/ai/diplomacy_ai_policy.dart': (
        occurrences: 2,
        digest: 7779553504994028694,
      ),
      'packages/aonw_core/lib/ai/diplomacy_ai_responses.dart': (
        occurrences: 2,
        digest: 3177976813000832965,
      ),
      'packages/aonw_core/lib/ai/mcts/mcts_action_generator.dart': (
        occurrences: 1,
        digest: -325140652725839908,
      ),
      'packages/aonw_core/lib/ai/mcts/mcts_baseline_command_merger.dart': (
        occurrences: 3,
        digest: -1015564706876053629,
      ),
      'packages/aonw_core/lib/ai/mcts/mcts_evaluator.dart': (
        occurrences: 1,
        digest: -572535172026798523,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_economy_ranker.dart': (
        occurrences: 1,
        digest: 2170672272021234630,
      ),
      'packages/aonw_core/lib/ai/mcts/'
          'strategy_aware_economy_worker_ranker.dart': (
        occurrences: 1,
        digest: 866428937794019586,
      ),
      'packages/aonw_core/lib/ai/strategies/'
          'basic_strategy_research_planner.dart': (
        occurrences: 1,
        digest: -5089937929466334415,
      ),
      'packages/aonw_core/lib/game/application/engine/'
          'diplomacy_engine_handler.dart': (
        occurrences: 2,
        digest: -2401734842743364908,
      ),
      'packages/aonw_core/lib/game/application/engine/game_engine.dart': (
        occurrences: 4,
        digest: -8848840907978049475,
      ),
      'packages/aonw_core/lib/game/application/engine/'
          'research_engine_handler.dart': (
        occurrences: 3,
        digest: 8061731774214521170,
      ),
      'packages/aonw_core/lib/game/domain/command/'
          'diplomacy_commands.dart': (
        occurrences: 18,
        digest: -8620495630862599191,
      ),
      'packages/aonw_core/lib/game/domain/command/'
          'game_command_json_decoding.dart': (
        occurrences: 7,
        digest: 702406976783169100,
      ),
      'packages/aonw_core/lib/game/domain/command/'
          'game_command_json_encoding.dart': (
        occurrences: 7,
        digest: -3594974223192794904,
      ),
      'packages/aonw_core/lib/game/domain/command/research_commands.dart': (
        occurrences: 2,
        digest: -2980151966303067890,
      ),
      'packages/aonw_core/lib/game/domain/diplomacy/'
          'diplomacy_command_resolver.dart': (
        occurrences: 13,
        digest: 6174471586698132707,
      ),
      'packages/aonw_core/lib/game/domain/diplomacy/'
          'diplomacy_message_command_handler.dart': (
        occurrences: 4,
        digest: 6788195466236036609,
      ),
      'packages/aonw_core/lib/game/domain/diplomacy/'
          'diplomacy_proposal_command_handler.dart': (
        occurrences: 4,
        digest: -7570623534708453823,
      ),
      'packages/aonw_core/lib/game/domain/diplomacy/'
          'diplomacy_proposal_response_command_handler.dart': (
        occurrences: 1,
        digest: 1816739940215342413,
      ),
      'packages/aonw_core/lib/game/domain/diplomacy/'
          'diplomacy_war_and_gift_command_handler.dart': (
        occurrences: 5,
        digest: -2518713334791814773,
      ),
      'packages/aonw_core/lib/game/domain/diplomacy/'
          'domain_diplomacy_command_resolver.dart': (
        occurrences: 2,
        digest: -8524358295267975910,
      ),
      'packages/aonw_core/lib/game/domain/technology/'
          'domain_research_command_resolver.dart': (
        occurrences: 2,
        digest: 3289994162551816467,
      ),
      'packages/aonw_core/lib/game/domain/technology/'
          'select_technology_resolver.dart': (
        occurrences: 2,
        digest: 6473497038187237735,
      ),
      'tool/performance/ai_mcts_workload.dart': (
        occurrences: 2,
        digest: 4184325178705214729,
      ),
      'tool/performance/persistence_workload.dart': (
        occurrences: 1,
        digest: -1260836702068599836,
      ),
      'tool/performance/replay_workload.dart': (
        occurrences: 1,
        digest: 6950661906188346894,
      ),
      'tool/run_save_ai_benchmark/benchmark_command_diagnostics.dart': (
        occurrences: 1,
        digest: -5087755823673334499,
      ),
    };

Map<String, String> researchDiplomacyRuntimeSources(
  Map<String, String> sources,
) => Map.unmodifiable({
  for (final entry in sources.entries)
    if (!entry.key.startsWith('packages/aonw_server_client/') &&
        !entry.key.startsWith('server/lib/src/generated/'))
      entry.key: entry.value,
});

Future<Map<String, ResearchDiplomacyPatternSignature>>
researchDiplomacyFamilyPatternSignaturesByPath(
  Map<String, String> sources,
) async {
  final occurrences = await _occurrencesByPath(sources);
  return {
    for (final entry in occurrences.entries)
      entry.key: (
        occurrences: entry.value.values.fold(0, (sum, count) => sum + count),
        digest: _patternDigest(entry.value),
      ),
  };
}

Future<Set<String>> unreviewedResearchDiplomacyFamilyPatternPaths(
  Map<String, String> sources,
) async {
  final actual = await researchDiplomacyFamilyPatternSignaturesByPath(sources);
  return {
    for (final path in {
      ...actual.keys,
      ...reviewedResearchDiplomacyFamilyPatternSignatures.keys,
    })
      if (actual[path] !=
          reviewedResearchDiplomacyFamilyPatternSignatures[path])
        path,
  };
}

Future<Map<String, Map<String, int>>> _occurrencesByPath(
  Map<String, String> sources,
) async {
  final occurrences = <String, Map<String, int>>{};
  final paths = sources.keys.toList()..sort();
  final workspace = ResolvedDartWorkspace(
    rootPath: Directory.current.path,
    sourceOverrides: {for (final path in paths) path: sources[path]!},
  );
  try {
    final resolvedUnits = await workspace.resolveAll(paths);
    for (final path in paths) {
      final visitor = _ResearchDiplomacyFamilyPatternVisitor();
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

final class _ResearchDiplomacyFamilyPatternVisitor
    extends RecursiveAstVisitor<void> {
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
        _canonicalResearchDiplomacyExecutorMembers.contains(memberKey)) {
      _record('executor:$memberKey');
    }
  }

  void _record(String type) {
    if (!type.startsWith('executor:') &&
        !researchDiplomacyFamilyCommandTypes.contains(type)) {
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
