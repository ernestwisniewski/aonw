import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

part 'support/resource_trade_server_map_boundary_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/trade/'
    'resource_trade_command_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/trade/'
    'persistent_resource_trade_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/trade/'
    'domain_resource_trade_command_resolver.dart';
const _localCallSite =
    'lib/game/domain/reducer/diplomacy/resource_trade_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_resource_trade.dart';
const _serverReducerPath =
    'server/lib/src/multiplayer/server_command_reducer.dart';

void main() {
  test('resource trade paths share one state-neutral command kernel', () {
    final sources = productionDartSources();
    const expectedKernelCallSites = {
      _persistentAdapterPath: 1,
      _domainAdapterPath: 1,
      _localCallSite: 1,
      _serverCallSite: 1,
    };

    for (final memberName in const {
      'openGoldForResourceTrade',
      'openResourceForResourceTrade',
    }) {
      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'ResourceTradeCommandResolver',
          memberName,
        ),
        expectedKernelCallSites,
        reason:
            'Unexpected ResourceTradeCommandResolver.$memberName '
            'call-sites.',
      );
      expect(
        instanceMemberReferenceCountsByPath(
          sources,
          'PersistentResourceTradeResolver',
          memberName,
        ),
        isEmpty,
        reason: 'Production must call the state-neutral trade kernel.',
      );
      expect(
        instanceMemberReferenceCountsByPath(
          sources,
          'DomainResourceTradeCommandResolver',
          memberName,
        ),
        isEmpty,
        reason: 'Production must call the state-neutral trade kernel.',
      );
    }
  });

  test('resource trade kernel exposes only agreement mutations', () {
    final sources = productionDartSources();
    final kernelSource = sources[_kernelPath];
    expect(kernelSource, isNotNull);

    final kernelTypes = namedTypeReferencesInSource(
      kernelSource!,
      path: _kernelPath,
    );
    final forbiddenTypes = typeNamesBackedBy(sources, const {
      'PersistentGameState',
      'PersistentResourceTradeResolver',
      'PersistentResourceTradeResult',
      'DomainState',
      'DomainResourceTradeCommandResolver',
      'DomainResourceTradeCommandResult',
      'CanonicalGameSnapshot',
      'GameState',
      'GameRuntimeState',
      'GameSave',
      'GameRuleset',
      'MapData',
      'MapDefinition',
      'MapReadView',
      'MapTraversalView',
      'MapTileCatalog',
      'MapTileView',
      'MapSurvey',
      'WorldMap',
      'WorldMapReadView',
      'FogOfWarState',
      'GameEvent',
      'GameStateTransition',
      'UiEffect',
    });
    expect(kernelTypes.intersection(forbiddenTypes), isEmpty);

    final unit = parseString(content: kernelSource, path: _kernelPath).unit;
    final resultClass = unit.declarations
        .whereType<ClassDeclaration>()
        .singleWhere(
          (declaration) =>
              declaration.namePart.typeName.lexeme ==
              'ResourceTradeCommandResult',
        );
    expect(_fieldNames(resultClass), {
      'accepted',
      'reason',
      'resourceTradeAgreements',
    });
  });

  test('local and server roots do not restore full-state trade bridges', () {
    final sources = productionDartSources();
    final localTypes = namedTypeReferencesInSource(
      sources[_localCallSite]!,
      path: _localCallSite,
    );
    expect(
      localTypes.intersection(const {
        'PersistentGameState',
        'PersistentResourceTradeResolver',
        'PersistentResourceTradeResult',
        'DomainState',
        'DomainResourceTradeCommandResolver',
        'DomainResourceTradeCommandResult',
      }),
      isEmpty,
    );
    expect(
      _memberReferenceCount(sources[_localCallSite]!, 'toPersistentState'),
      0,
      reason: 'The local trade reducer must not rebuild a persistent state.',
    );

    final serverTypes = namedTypeReferencesInSource(
      sources[_serverReducerPath]!,
      path: _serverReducerPath,
    );
    expect(
      serverTypes.intersection(const {
        'PersistentResourceTradeResult',
        'PersistentCityProductionResult',
      }),
      isEmpty,
      reason:
          'Migrated trade and production results must not return to the '
          'generic persistent-result bridge.',
    );
  });

  test('server trade extension exposes exactly one bounded map lookup', () {
    final sources = productionDartSources();

    expect(_serverExtensionMapBoundaryViolations(sources), isEmpty);
  });

  test('server extension map guard rejects broad, aliased, and extra maps', () {
    expect(
      _serverExtensionMapBoundaryViolations({
        'server.dart': _serverExtensionFixture(),
      }, path: 'server.dart'),
      isEmpty,
    );

    final broad = _serverExtensionMapBoundaryViolations({
      'server.dart': _serverExtensionFixture(mapType: 'MapReadView'),
    }, path: 'server.dart');
    expect(broad.join('\n'), contains('mapTiles must be MapTileLookup'));

    final aliased = _serverExtensionMapBoundaryViolations({
      'aliases.dart': 'typedef Tiles = MapTileLookup;',
      'server.dart': _serverExtensionFixture(mapType: 'Tiles'),
    }, path: 'server.dart');
    expect(aliased.join('\n'), contains('mapTiles must be MapTileLookup'));

    final extra = _serverExtensionMapBoundaryViolations({
      'server.dart': _serverExtensionFixture(
        extraParameter: ', required MapReadView extraMap',
      ),
    }, path: 'server.dart');
    expect(
      extra.join('\n'),
      contains('must expose exactly one map-backed parameter'),
    );

    final positional = _serverExtensionMapBoundaryViolations({
      'server.dart': _serverExtensionFixture(requiredNamed: false),
    }, path: 'server.dart');
    expect(
      positional.join('\n'),
      contains('mapTiles must be a required named parameter'),
    );

    final mapReturn = _serverExtensionMapBoundaryViolations({
      'server.dart': _serverExtensionFixture(returnType: 'MapReadView'),
    }, path: 'server.dart');
    expect(mapReturn.join('\n'), contains('must not return a map-backed type'));
  });

  test('full-state bridge guard catches calls and tear-offs', () {
    const source = '''
void convert(dynamic state, dynamic legacy) {
  state.toPersistentState();
  final convertState = state.toPersistentState;
  legacy.toPersistentState();
}
''';

    expect(_memberReferenceCount(source, 'toPersistentState'), 3);
    expect(
      _memberReferenceCount('void keep(dynamic state) {}', 'toPersistentState'),
      0,
    );
  });

  test('static guard catches aliases, prefixes, tear-offs, and duplicates', () {
    for (final memberName in const {
      'openGoldForResourceTrade',
      'openResourceForResourceTrade',
    }) {
      final sources = <String, String>{
        'kernel.dart':
            '''
abstract final class ResourceTradeCommandResolver {
  static void $memberName() {}
}
''',
        'alias.dart':
            '''
typedef TradeKernel = ResourceTradeCommandResolver;
void apply() => TradeKernel.$memberName();
''',
        'prefixed.dart':
            '''
void apply() => core.ResourceTradeCommandResolver.$memberName();
''',
        'tear_off.dart':
            '''
final applyTrade = ResourceTradeCommandResolver.$memberName;
''',
        'duplicate.dart':
            '''
void applyOnce() => ResourceTradeCommandResolver.$memberName();
final applyAgain = ResourceTradeCommandResolver.$memberName;
''',
        'unrelated.dart':
            '''
abstract final class LegacyResourceTradeCommandResolver {
  static void $memberName() {}
}
void apply() => LegacyResourceTradeCommandResolver.$memberName();
''',
      };

      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'ResourceTradeCommandResolver',
          memberName,
        ),
        {
          'alias.dart': 1,
          'prefixed.dart': 1,
          'tear_off.dart': 1,
          'duplicate.dart': 2,
        },
      );
    }
  });

  test(
    'adapter guard catches aliases, prefixes, and constructor tear-offs',
    () {
      final sources = <String, String>{
        'direct.dart': '''
void apply() => const PersistentResourceTradeResolver()
    .openGoldForResourceTrade();
''',
        'alias.dart': '''
typedef TradeAdapter = PersistentResourceTradeResolver;
final make = TradeAdapter.new;
void apply() => make().openGoldForResourceTrade();
''',
        'prefixed.dart': '''
final make = core.PersistentResourceTradeResolver.new;
void apply() => make().openGoldForResourceTrade();
''',
        'tear_off.dart': '''
final make = PersistentResourceTradeResolver.new;
final resolver = make();
final openTrade = resolver.openGoldForResourceTrade;
''',
        'unrelated.dart': 'void apply(Object value) => value.toString();',
      };

      expect(
        instanceMemberReferenceCountsByPath(
          sources,
          'PersistentResourceTradeResolver',
          'openGoldForResourceTrade',
        ),
        {
          'direct.dart': 1,
          'alias.dart': 1,
          'prefixed.dart': 1,
          'tear_off.dart': 1,
        },
      );
    },
  );
}

Set<String> _fieldNames(ClassDeclaration declaration) {
  return {
    for (final field in declaration.body.members.whereType<FieldDeclaration>())
      for (final variable in field.fields.variables) variable.name.lexeme,
  };
}

int _memberReferenceCount(String source, String memberName) {
  final collector = _NamedMemberReferenceCollector(memberName);
  parseString(content: source).unit.accept(collector);
  return collector.count;
}

final class _NamedMemberReferenceCollector extends RecursiveAstVisitor<void> {
  _NamedMemberReferenceCollector(this.memberName);

  final String memberName;
  int count = 0;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == memberName) count++;
    super.visitMethodInvocation(node);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.identifier.name == memberName) count++;
    super.visitPrefixedIdentifier(node);
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == memberName) count++;
    super.visitPropertyAccess(node);
  }
}
