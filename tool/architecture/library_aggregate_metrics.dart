import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import 'dart_metrics.dart';
import 'failure.dart';
import 'git_repository.dart';
import 'policy.dart';
import 'source_census.dart';

final class LibraryAggregateMeasurer {
  const LibraryAggregateMeasurer({
    required this.repository,
    required this.policy,
    required this.census,
  });

  final GitRepository repository;
  final ArchitecturePolicy policy;
  final SourceCensus census;

  Map<String, Map<String, LibraryAggregateMetric>> measure() {
    census.validateRepositoryCoverage();
    return {
      for (final entry in policy.scopes.entries)
        entry.key: _measureScope(entry.key, entry.value),
    };
  }

  Map<String, LibraryAggregateMetric> _measureScope(
    String scopeName,
    ScopePolicy scope,
  ) {
    final paths = census.handwrittenFiles(scopeName).toSet();
    final sources = <String, _LibrarySource>{};
    for (final path in paths) {
      final contents = File(repository.resolve(path)).readAsStringSync();
      sources[path] = _LibrarySource(
        owner: resolveLibraryOwner(path, contents),
        metrics: measureDartSource(path, contents),
      );
    }
    final grouped = <String, List<DartSourceMetrics>>{};
    for (final entry in sources.entries) {
      final owner = entry.value.owner;
      if (!paths.contains(owner)) {
        throw ArchitectureFailure(
          '${entry.key} resolves to library owner outside $scopeName: $owner',
        );
      }
      final ownerRole = scope.roleFor(owner).name;
      final sourceRole = scope.roleFor(entry.key).name;
      if (ownerRole != sourceRole) {
        throw ArchitectureFailure(
          '${entry.key} ($sourceRole) cannot join $owner ($ownerRole).',
        );
      }
      grouped.putIfAbsent(owner, () => []).add(entry.value.metrics);
    }
    return Map.unmodifiable({
      for (final owner in grouped.keys.toList()..sort())
        owner: LibraryAggregateMetric.fromSources(grouped[owner]!),
    });
  }
}

String resolveLibraryOwner(String path, String contents) {
  final unit = parseString(
    content: contents,
    path: path,
    throwIfDiagnostics: false,
  ).unit;
  final partOf = unit.directives.whereType<PartOfDirective>().toList();
  if (partOf.isEmpty) return path;
  if (partOf.length != 1 || partOf.single.uri?.stringValue == null) {
    throw ArchitectureFailure(
      '$path must use one URI-based part-of directive.',
    );
  }
  return resolveRepositoryUri(path, partOf.single.uri!.stringValue!);
}

String resolveRepositoryUri(String path, String uri) {
  final parsed = Uri.parse(uri);
  if (parsed.hasScheme ||
      parsed.hasAuthority ||
      parsed.hasQuery ||
      parsed.hasFragment) {
    throw ArchitectureFailure('$path has a non-local part-of URI: $uri');
  }
  final segments = path.split('/')..removeLast();
  for (final segment in parsed.pathSegments) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') {
      if (segments.isEmpty) {
        throw ArchitectureFailure(
          '$path part-of URI escapes the repository: $uri',
        );
      }
      segments.removeLast();
    } else {
      segments.add(segment);
    }
  }
  final resolved = segments.join('/');
  if (!resolved.endsWith('.dart')) {
    throw ArchitectureFailure('$path has a non-Dart part-of URI: $uri');
  }
  return resolved;
}

final class LibraryAggregateMetric {
  const LibraryAggregateMetric({
    required this.sourceLines,
    required this.callableCount,
    required this.callableLines,
    required this.cyclomaticComplexity,
    required this.cognitiveComplexity,
  });

  factory LibraryAggregateMetric.fromSources(
    Iterable<DartSourceMetrics> sources,
  ) {
    var sourceLines = 0;
    var callableCount = 0;
    var callableLines = 0;
    var cyclomaticComplexity = 0;
    var cognitiveComplexity = 0;
    for (final source in sources) {
      sourceLines += source.fileLines;
      callableCount += source.callables.length;
      for (final callable in source.callables) {
        callableLines += callable.lines;
        cyclomaticComplexity += callable.cyclomaticComplexity;
        cognitiveComplexity += callable.cognitiveComplexity;
      }
    }
    return LibraryAggregateMetric(
      sourceLines: sourceLines,
      callableCount: callableCount,
      callableLines: callableLines,
      cyclomaticComplexity: cyclomaticComplexity,
      cognitiveComplexity: cognitiveComplexity,
    );
  }

  final int sourceLines;
  final int callableCount;
  final int callableLines;
  final int cyclomaticComplexity;
  final int cognitiveComplexity;
}

final class _LibrarySource {
  const _LibrarySource({required this.owner, required this.metrics});

  final String owner;
  final DartSourceMetrics metrics;
}
