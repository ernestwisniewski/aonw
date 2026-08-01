import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

part 'support/canonical_snapshot_conversion_guard.dart';

const _canonicalPipelinePath =
    'packages/aonw_core/lib/game/application/turn/'
    'canonical_turn_pipeline.dart';
const _saveSnapshotPath = 'lib/game/application/ports/save_snapshot.dart';
const _localCallSite =
    'lib/game/application/services/local_command_resolver.dart';
const _losslessSnapshotCodecPath =
    'server/lib/src/multiplayer/lossless_match_snapshot_codec.dart';
const _performanceCallSite = 'tool/performance/turn_finalization_workload.dart';
const _workedHexKernelPath =
    'packages/aonw_core/lib/game/domain/city/'
    'toggle_worked_hex_resolver.dart';
const _domainWorkedHexAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'domain_city_worked_hex_resolver.dart';
void main() {
  group('canonical turn pipeline boundary', () {
    test('worked-hex paths share one state-neutral kernel', () {
      final sources = productionDartSources();
      expect(
        staticMemberReferencePaths(
          sources,
          'ToggleWorkedHexResolver',
          'toggleWorkedHex',
        ),
        {_domainWorkedHexAdapterPath},
      );
      expect(
        instanceMemberReferencePaths(
          sources,
          'PersistentCityWorkedHexResolver',
          'toggleWorkedHex',
        ),
        isEmpty,
      );

      final collector = _NamedTypeCollector();
      _unitAt(_workedHexKernelPath).accept(collector);
      expect(
        collector.names.intersection(const {
          'PersistentGameState',
          'DomainState',
          'CanonicalGameSnapshot',
          'GameClientState',
        }),
        isEmpty,
      );
    });

    test('guard catches worked-hex instance calls and tear-offs', () {
      final sources = <String, String>{
        'constructor.dart': '''
void f() {
  const PersistentCityWorkedHexResolver().toggleWorkedHex();
}
''',
        'typed.dart': '''
void f(PersistentCityWorkedHexResolver parameter) {
  final PersistentCityWorkedHexResolver local = parameter;
  final inferred = const PersistentCityWorkedHexResolver();
  parameter.toggleWorkedHex();
  final tearOff = local.toggleWorkedHex;
  inferred.toggleWorkedHex();
}
''',
        'field.dart': '''
final class Holder {
  const Holder(this.adapter);
  final PersistentCityWorkedHexResolver adapter;
  void f() => adapter.toggleWorkedHex();
}
''',
        'getter.dart': '''
PersistentCityWorkedHexResolver get adapter =>
    const PersistentCityWorkedHexResolver();
void f() => adapter.toggleWorkedHex();
''',
        'alias.dart': '''
typedef WorkedHexAdapter = PersistentCityWorkedHexResolver;
void f(WorkedHexAdapter adapter) {
  adapter..toggleWorkedHex();
}
''',
        'clean.dart': 'void f(Object value) { value.toString(); }',
      };
      expect(
        instanceMemberReferencePaths(
          sources,
          'PersistentCityWorkedHexResolver',
          'toggleWorkedHex',
        ),
        {
          'constructor.dart',
          'typed.dart',
          'field.dart',
          'getter.dart',
          'alias.dart',
        },
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
        staticMemberReferencePaths(
          sources,
          'CanonicalTurnPipeline',
          'simultaneousFinalize',
        ),
        sources.keys.toSet(),
      );
    });

    test(
      'repo-wide snapshot conversion calls match the transition ratchet',
      () {
        final sources = productionDartSources();
        final counts = _snapshotConversionCounts(sources);
        expect(counts, _expectedSnapshotConversionCalls);
        expect(_adapterTypeReferencePaths(sources), _expectedAdapterTypePaths);
        expect(
          counts[_canonicalPipelinePath] ?? _zeroConversions,
          _zeroConversions,
        );
        expect(
          _adapterTypeReferencePaths(sources),
          isNot(contains(_canonicalPipelinePath)),
        );
        expect(counts[_localCallSite] ?? _zeroConversions, _zeroConversions);
        expect(
          _adapterTypeReferencePaths(sources),
          isNot(contains(_localCallSite)),
        );
        expect(
          counts.values.fold(
            _zeroConversions,
            (total, current) => (
              toCanonical: total.toCanonical + current.toCanonical,
              toLegacy: total.toLegacy + current.toLegacy,
            ),
          ),
          (toCanonical: 3, toLegacy: 3),
        );
      },
    );

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

final class _NamedTypeCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitNamedType(NamedType node) {
    names.add(node.name.lexeme);
    super.visitNamedType(node);
  }
}
