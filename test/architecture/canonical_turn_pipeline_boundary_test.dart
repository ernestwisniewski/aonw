import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';

const _canonicalPipelinePath =
    'packages/aonw_core/lib/game/application/turn/'
    'canonical_turn_pipeline.dart';
const _localCallSite =
    'lib/game/application/services/local_command_resolver.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_turns.dart';
const _performanceCallSite = 'tool/performance/turn_finalization_workload.dart';

void main() {
  group('canonical turn pipeline boundary', () {
    test('runtime paths and workload share the canonical facade', () {
      final sources = productionDartSources();
      expect(
        _staticMemberReferencePaths(
          sources,
          'CanonicalTurnPipeline',
          'simultaneousFinalize',
        ),
        {_localCallSite, _serverCallSite, _performanceCallSite},
      );
    });

    test('persistent turn pipeline has no production consumers', () {
      final sources = productionDartSources();
      expect(
        _staticMemberReferencePaths(
          sources,
          'PersistentTurnPipeline',
          'simultaneousFinalize',
        ),
        isEmpty,
      );
      expect(
        _staticMemberReferencePaths(
          sources,
          'PersistentTurnPipeline',
          'simultaneousFinalizeAfterCombat',
        ),
        isEmpty,
      );
      expect(
        _staticMemberReferencePaths(
          sources,
          'PersistentTurnPipelineRequest',
          'simultaneousFinalize',
        ),
        isEmpty,
      );
    });

    test('guard catches prefixed, aliased, and tear-off bypasses', () {
      final sources = <String, String>{
        'direct.dart':
            'void f() { CanonicalTurnPipeline.simultaneousFinalize(r); }',
        'prefixed.dart':
            'void f() { core.CanonicalTurnPipeline.'
            'simultaneousFinalize(r); }',
        'alias.dart':
            'typedef PipelineAlias = CanonicalTurnPipeline; '
            'void f() { PipelineAlias.simultaneousFinalize(r); }',
        'tear_off.dart':
            'final f = CanonicalTurnPipeline.simultaneousFinalize;',
      };
      expect(
        _staticMemberReferencePaths(
          sources,
          'CanonicalTurnPipeline',
          'simultaneousFinalize',
        ),
        sources.keys.toSet(),
      );
      const kernelSources = {
        'kernel_tear_off.dart':
            'final f = legacy.PersistentTurnPipeline.simultaneousFinalize;',
        'tail_alias.dart':
            'typedef TailAlias = PersistentTurnPipeline; '
            'final f = TailAlias.simultaneousFinalizeAfterCombat;',
        'request_alias.dart':
            'typedef RequestAlias = PersistentTurnPipelineRequest; '
            'final f = RequestAlias.simultaneousFinalize;',
      };
      expect(
        _staticMemberReferencePaths(
          kernelSources,
          'PersistentTurnPipeline',
          'simultaneousFinalize',
        ),
        {'kernel_tear_off.dart'},
      );
      expect(
        _staticMemberReferencePaths(
          kernelSources,
          'PersistentTurnPipeline',
          'simultaneousFinalizeAfterCombat',
        ),
        {'tail_alias.dart'},
      );
      expect(
        _staticMemberReferencePaths(
          kernelSources,
          'PersistentTurnPipelineRequest',
          'simultaneousFinalize',
        ),
        {'request_alias.dart'},
      );
    });

    test('repo-wide ratchet limits each runtime path to two conversions', () {
      final sources = productionDartSources();
      final counts = _snapshotConversionCounts(sources);
      const allowedPaths = {
        _localCallSite,
        _serverCallSite,
        _performanceCallSite,
      };
      expect(counts.keys.toSet().difference(allowedPaths), isEmpty);
      expect(
        _adapterTypeReferencePaths(sources).difference(allowedPaths),
        isEmpty,
      );
      for (final entry in counts.entries) {
        expect(entry.value.toCanonical, lessThanOrEqualTo(1));
        expect(entry.value.toLegacy, lessThanOrEqualTo(1));
        expect(_total(entry.value), lessThanOrEqualTo(2));
      }
      expect(
        counts[_canonicalPipelinePath] ?? _zeroConversions,
        _zeroConversions,
      );
      expect(
        _adapterTypeReferencePaths(sources),
        isNot(contains(_canonicalPipelinePath)),
      );
    });

    test('conversion ratchet catches a helper outside the allowlist', () {
      const sources = {
        'helper.dart':
            'final class Helper { '
            'const Helper(this.adapter); '
            'final LegacyGameSnapshotAdapter adapter; '
            'Object convert(Object save, Object state) => '
            'adapter.toCanonical(save: save, state: state); '
            '}',
      };
      final counts = _snapshotConversionCounts(sources);

      expect(counts.keys, {'helper.dart'});
      expect(counts['helper.dart']?.toCanonical, 1);
      expect(_adapterTypeReferencePaths(sources), {'helper.dart'});
    });

    test('canonical request and result do not expose legacy state types', () {
      final unit = _unitAt(_canonicalPipelinePath);
      final forbidden = <String>{};
      for (final declaration
          in unit.declarations.whereType<ClassDeclaration>()) {
        if (!const {
          'CanonicalTurnPipelineRequest',
          'CanonicalTurnPipelineResult',
          'TurnMovementDelta',
        }.contains(declaration.namePart.typeName.lexeme)) {
          continue;
        }
        final collector = _NamedTypeCollector();
        declaration.accept(collector);
        forbidden.addAll(
          collector.names.where(
            (name) =>
                name == 'GameSave' ||
                name == 'PersistentGameState' ||
                name.startsWith('PersistentTurn') ||
                name.startsWith('Legacy'),
          ),
        );
      }

      expect(forbidden, isEmpty);
    });

    test('core domain never imports application or compatibility layers', () {
      final violations = <String>[];
      for (final entry in productionDartSources().entries) {
        if (!entry.key.startsWith('packages/aonw_core/lib/game/domain/')) {
          continue;
        }
        final unit = parseString(content: entry.value, path: entry.key).unit;
        for (final directive
            in unit.directives.whereType<UriBasedDirective>()) {
          final uri = directive.uri.stringValue;
          if (uri == null || !_isOuterGameLayerUri(uri)) continue;
          final line = unit.lineInfo.getLocation(directive.offset).lineNumber;
          violations.add('${entry.key}:$line imports $uri');
        }
      }

      expect(violations, isEmpty);
    });
  });
}

Set<String> _staticMemberReferencePaths(
  Map<String, String> sources,
  String targetType,
  String memberName,
) {
  final paths = <String>{};
  final targetTypes = typeNamesBackedBy(sources, {targetType});
  for (final entry in sources.entries) {
    final unit = parseString(content: entry.value, path: entry.key).unit;
    final collector = _StaticMemberReferenceCollector(targetTypes, memberName);
    unit.accept(collector);
    if (collector.found) paths.add(entry.key);
  }
  return paths;
}

Map<String, _ConversionCounts> _snapshotConversionCounts(
  Map<String, String> sources,
) {
  final result = <String, _ConversionCounts>{};
  for (final entry in sources.entries) {
    final collector = _SnapshotConversionCollector();
    parseString(content: entry.value, path: entry.key).unit.accept(collector);
    final counts = (
      toCanonical: collector.toCanonical,
      toLegacy: collector.toLegacy,
    );
    if (_total(counts) > 0) result[entry.key] = counts;
  }
  return result;
}

Set<String> _adapterTypeReferencePaths(Map<String, String> sources) {
  final adapterTypes = typeNamesBackedBy(sources, const {
    'LegacyGameSnapshotAdapter',
  });
  final paths = <String>{};
  for (final entry in sources.entries) {
    final collector = _NamedTypeCollector();
    parseString(content: entry.value, path: entry.key).unit.accept(collector);
    if (collector.names.any(adapterTypes.contains)) paths.add(entry.key);
  }
  return paths;
}

CompilationUnit _unitAt(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}

bool _isOuterGameLayerUri(String uri) {
  final normalized = uri.toLowerCase();
  return normalized.contains('/game/application/') ||
      normalized.endsWith('/application.dart') ||
      normalized.contains('/game/compatibility/') ||
      normalized.endsWith('/compatibility.dart');
}

final class _StaticMemberReferenceCollector extends RecursiveAstVisitor<void> {
  _StaticMemberReferenceCollector(this.targetTypes, this.memberName);

  final Set<String> targetTypes;
  final String memberName;
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName && _isTarget(node.target)) {
      found = true;
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName && _isTarget(node.prefix)) {
      found = true;
    }
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName && _isTarget(node.target)) {
      found = true;
    }
    super.visitPropertyAccess(node);
  }

  bool _isTarget(AstNode? target) {
    final source = target?.toSource();
    if (source == null) return false;
    return targetTypes.any(
      (type) => source == type || source.endsWith('.$type'),
    );
  }
}

final class _SnapshotConversionCollector extends RecursiveAstVisitor<void> {
  int toCanonical = 0;
  int toLegacy = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _record(node.methodName.name);
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    _record(node.identifier.name);
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    _record(node.propertyName.name);
    super.visitPropertyAccess(node);
  }

  void _record(String name) {
    switch (name) {
      case 'toCanonical':
        toCanonical++;
      case 'toLegacy':
        toLegacy++;
    }
  }
}

typedef _ConversionCounts = ({int toCanonical, int toLegacy});

int _total(_ConversionCounts counts) => counts.toCanonical + counts.toLegacy;

const _zeroConversions = (toCanonical: 0, toLegacy: 0);

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
