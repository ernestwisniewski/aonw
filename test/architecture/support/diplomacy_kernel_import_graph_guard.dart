import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'map_boundary_source_guard.dart';

const diplomacyKernelLibraryPath =
    'packages/aonw_core/lib/game/domain/diplomacy/';

const diplomacyKernelImportGraphPaths = {
  '${diplomacyKernelLibraryPath}diplomacy_command_resolver.dart',
  '${diplomacyKernelLibraryPath}diplomacy_command_result.dart',
  '${diplomacyKernelLibraryPath}diplomacy_command_state.dart',
  '${diplomacyKernelLibraryPath}diplomacy_command_support.dart',
  '${diplomacyKernelLibraryPath}diplomacy_contact_pairs.dart',
  '${diplomacyKernelLibraryPath}diplomacy_json_helpers.dart',
  '${diplomacyKernelLibraryPath}diplomacy_message_command_handler.dart',
  '${diplomacyKernelLibraryPath}diplomacy_proposal_command_handler.dart',
  '${diplomacyKernelLibraryPath}diplomacy_proposal_response_command_handler.dart',
  '${diplomacyKernelLibraryPath}diplomacy_state.dart',
  '${diplomacyKernelLibraryPath}diplomacy_state_immutability.dart',
  '${diplomacyKernelLibraryPath}diplomacy_state_model.dart',
  '${diplomacyKernelLibraryPath}diplomacy_state_serialization_helpers.dart',
  '${diplomacyKernelLibraryPath}diplomacy_war_and_gift_command_handler.dart',
  '${diplomacyKernelLibraryPath}diplomatic_action_guard.dart',
  '${diplomacyKernelLibraryPath}diplomatic_contact.dart',
  '${diplomacyKernelLibraryPath}diplomatic_gold_gift_rules.dart',
  '${diplomacyKernelLibraryPath}diplomatic_message.dart',
  '${diplomacyKernelLibraryPath}diplomatic_message_effects.dart',
  '${diplomacyKernelLibraryPath}diplomatic_proposal.dart',
  '${diplomacyKernelLibraryPath}diplomatic_proposal_forecast.dart',
  '${diplomacyKernelLibraryPath}diplomatic_relation.dart',
  '${diplomacyKernelLibraryPath}diplomatic_score_adjustment.dart',
  '${diplomacyKernelLibraryPath}diplomatic_score_entry.dart',
  '${diplomacyKernelLibraryPath}diplomatic_score_reason.dart',
  '${diplomacyKernelLibraryPath}diplomatic_shared_war.dart',
  '${diplomacyKernelLibraryPath}diplomatic_warmonger_reputation.dart',
  '${diplomacyKernelLibraryPath}gold_amount.dart',
  '${diplomacyKernelLibraryPath}proposal_acceptance_policy.dart',
};

const diplomacyKernelForbiddenRootTypes = {
  'PersistentGameState',
  'PersistentDiplomacyResolver',
  'PersistentDiplomacyResult',
  'DomainState',
  'DomainDiplomacyCommandResolver',
  'DomainDiplomacyCommandResult',
  'CanonicalGameSnapshot',
  'MatchSessionState',
  'GameState',
  'GameRuntimeState',
  'GameSave',
  'WireMatch',
  'WireSnapshot',
  'WireCommand',
  'MapData',
  'MapDefinition',
  'MapReadView',
  'MapTraversalView',
  'MapTileLookup',
  'MapTileCatalog',
  'MapTileView',
  'MapSurvey',
  'WorldMap',
  'WorldMapReadView',
  'GameStateTransition',
  'UiEffect',
};

const _leafDependencyUris = {
  'package:aonw_core/domain/intended_attack.dart',
  'package:aonw_core/game/domain/city/game_city.dart',
  'package:aonw_core/game/domain/command.dart',
  'package:aonw_core/game/domain/event.dart',
  'package:aonw_core/game/domain/fog/fog_of_war_state.dart',
  'package:aonw_core/game/domain/hex/hex_coordinate.dart',
  'package:aonw_core/game/domain/player.dart',
  'package:aonw_core/game/domain/trade/resource_trade_agreement.dart',
  'package:aonw_core/game/domain/unit/game_unit.dart',
  'package:aonw_core/util/collection_equality.dart',
  'package:aonw_core/util/wire_json.dart',
  'package:freezed_annotation/freezed_annotation.dart',
  'diplomacy_state.freezed.dart',
};

Map<String, String> diplomacyKernelImportGraph(
  Map<String, String> sources,
  Set<String> roots,
) {
  final paths = _reachablePaths(sources, roots);
  return {for (final path in paths) path: sources[path]!};
}

List<String> diplomacyKernelImportGraphViolations(
  Map<String, String> graph, {
  required Set<String> expectedPaths,
  required Set<String> forbiddenTypes,
}) {
  final violations = <String>[];
  final actualPaths = graph.keys.toSet();
  for (final path in actualPaths.difference(expectedPaths)) {
    violations.add('$path is an unexpected graph path');
  }
  for (final path in expectedPaths.difference(actualPaths)) {
    violations.add('$path is missing from the kernel graph');
  }
  for (final entry in graph.entries) {
    violations.addAll(_sourceViolations(entry, graph, forbiddenTypes));
  }
  return violations..sort();
}

Set<String> _reachablePaths(Map<String, String> sources, Set<String> roots) {
  final reached = <String>{};
  final pending = roots.toList();
  while (pending.isNotEmpty) {
    final path = pending.removeLast();
    final source = sources[path];
    if (source == null) throw StateError('Missing kernel source: $path');
    if (!reached.add(path)) continue;
    for (final uri in _directiveUris(source, path)) {
      final dependency = _diplomacyPathForUri(path, uri);
      if (dependency != null &&
          sources.containsKey(dependency) &&
          !reached.contains(dependency)) {
        pending.add(dependency);
      }
    }
  }
  return reached;
}

List<String> _sourceViolations(
  MapEntry<String, String> entry,
  Map<String, String> graph,
  Set<String> forbiddenTypes,
) {
  final violations = <String>[];
  final types = namedTypeReferencesInSource(entry.value, path: entry.key);
  for (final type in types.intersection(forbiddenTypes)) {
    violations.add('${entry.key} references forbidden $type');
  }
  for (final uri in _directiveUris(entry.value, entry.key)) {
    final dependency = _diplomacyPathForUri(entry.key, uri);
    if (_leafDependencyUris.contains(uri) ||
        (dependency != null && graph.containsKey(dependency))) {
      continue;
    }
    violations.add('${entry.key} imports unapproved dependency $uri');
  }
  return violations;
}

Set<String> _directiveUris(String source, String path) {
  final unit = parseString(content: source, path: path).unit;
  return {
    for (final directive in unit.directives.whereType<UriBasedDirective>())
      ?directive.uri.stringValue,
  };
}

String? _diplomacyPathForUri(String importerPath, String uri) {
  const packagePrefix = 'package:aonw_core/game/domain/diplomacy/';
  if (uri.startsWith(packagePrefix)) {
    return '$diplomacyKernelLibraryPath${uri.substring(packagePrefix.length)}';
  }
  if (Uri.parse(uri).hasScheme) return null;
  final resolved = Uri.parse(importerPath).resolve(uri).path;
  return resolved.startsWith(diplomacyKernelLibraryPath) ? resolved : null;
}
