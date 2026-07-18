import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _canonicalPipelinePath =
    'packages/aonw_core/lib/game/application/turn/'
    'canonical_turn_pipeline.dart';
const _persistentPipelinePath =
    'packages/aonw_core/lib/game/domain/turn/persistent_turn_pipeline.dart';
const _localCallSite =
    'lib/game/application/services/local_command_resolver.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_turns.dart';
const _performanceCallSite = 'tool/performance/turn_finalization_workload.dart';
const _workedHexKernelPath =
    'packages/aonw_core/lib/game/domain/city/'
    'toggle_worked_hex_resolver.dart';
const _persistentWorkedHexAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'persistent_city_worked_hex_resolver.dart';
const _domainWorkedHexAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'domain_city_worked_hex_resolver.dart';
const _localWorkedHexCallSite =
    'lib/game/domain/reducer/city/city_worked_hex_reducer.dart';
const _serverWorkedHexCallSite =
    'server/lib/src/multiplayer/server_command_reducer_city.dart';
const _retiredPersistentTurnTypes = {
  'PersistentTurnMovementDelta',
  'PersistentTurnPipelineRequest',
  'PersistentTurnPipelineResult',
};
const _retiredPersistentTurnMethods = {
  'simultaneousFinalize',
  '_simultaneousFinalizeAfterCombat',
};

void main() {
  group('canonical turn pipeline boundary', () {
    test('runtime paths and workload share the canonical facade', () {
      final sources = productionDartSources();
      expect(
        staticMemberReferencePaths(
          sources,
          'CanonicalTurnPipeline',
          'simultaneousFinalize',
        ),
        {_localCallSite, _serverCallSite, _performanceCallSite},
      );
    });

    test('persistent turn pipeline keeps only the single-player seam', () {
      expect(_persistentTurnApiViolations(productionDartSources()), isEmpty);
    });

    test('persistent turn API ratchet catches every retired declaration', () {
      const sources = {
        _persistentPipelinePath: '''
final class PersistentTurnMovementDelta {}
typedef PersistentTurnPipelineRequest = Object;
enum PersistentTurnPipelineResult { value }

abstract final class PersistentTurnPipeline {
  static void simultaneousFinalize() {}
  static void _simultaneousFinalizeAfterCombat() {}
  static void finalizeAllPlayers() {}
}
''',
      };

      expect(
        _persistentTurnApiViolations(sources),
        containsAll([
          'must not declare retired type PersistentTurnMovementDelta',
          'must not declare retired type PersistentTurnPipelineRequest',
          'must not declare retired type PersistentTurnPipelineResult',
          'PersistentTurnPipeline must not declare simultaneousFinalize',
          'PersistentTurnPipeline must not declare '
              '_simultaneousFinalizeAfterCombat',
          'PersistentTurnPipeline must not declare public method '
              'finalizeAllPlayers',
          'PersistentTurnPipeline must declare exactly one static '
              'advancePlayer method',
        ]),
      );
    });

    test('worked-hex paths share one state-neutral kernel', () {
      final sources = productionDartSources();
      expect(
        staticMemberReferencePaths(
          sources,
          'ToggleWorkedHexResolver',
          'toggleWorkedHex',
        ),
        {
          _persistentWorkedHexAdapterPath,
          _domainWorkedHexAdapterPath,
          _localWorkedHexCallSite,
          _serverWorkedHexCallSite,
        },
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
          'GameState',
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

List<String> _persistentTurnApiViolations(Map<String, String> sources) {
  final violations = <String>[];
  for (final entry in sources.entries) {
    final collector = _DeclaredTypeNameCollector();
    parseString(content: entry.value, path: entry.key).unit.accept(collector);
    for (final typeName in collector.names.intersection(
      _retiredPersistentTurnTypes,
    )) {
      violations.add('must not declare retired type $typeName');
    }
  }

  final source = sources[_persistentPipelinePath];
  if (source == null) {
    violations.add('PersistentTurnPipeline source must exist');
    return violations;
  }
  final unit = parseString(content: source, path: _persistentPipelinePath).unit;
  final pipelines = unit.declarations.whereType<ClassDeclaration>().where(
    (declaration) =>
        declaration.namePart.typeName.lexeme == 'PersistentTurnPipeline',
  );
  if (pipelines.length != 1) {
    violations.add('PersistentTurnPipeline must declare exactly one class');
    return violations;
  }

  final methods = pipelines.single.body.members.whereType<MethodDeclaration>();
  final methodNames = methods.map((method) => method.name.lexeme).toSet();
  for (final methodName in methodNames.intersection(
    _retiredPersistentTurnMethods,
  )) {
    violations.add('PersistentTurnPipeline must not declare $methodName');
  }
  for (final methodName in methodNames.where(
    (name) => !name.startsWith('_') && name != 'advancePlayer',
  )) {
    violations.add(
      'PersistentTurnPipeline must not declare public method $methodName',
    );
  }
  final advancePlayerMethods = methods.where(
    (method) => method.name.lexeme == 'advancePlayer' && method.isStatic,
  );
  if (advancePlayerMethods.length != 1) {
    violations.add(
      'PersistentTurnPipeline must declare exactly one static '
      'advancePlayer method',
    );
  }
  return violations;
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

final class _DeclaredTypeNameCollector extends RecursiveAstVisitor<void> {
  final Set<String> names = {};

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    names.add(node.namePart.typeName.lexeme);
    super.visitClassDeclaration(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    names.add(node.namePart.typeName.lexeme);
    super.visitEnumDeclaration(node);
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    names.add(node.primaryConstructor.typeName.lexeme);
    super.visitExtensionTypeDeclaration(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    names.add(node.name.lexeme);
    super.visitGenericTypeAlias(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    names.add(node.name.lexeme);
    super.visitMixinDeclaration(node);
  }
}
