import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/diplomacy_kernel_import_graph_guard.dart';
import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _diplomacyLibrary = 'packages/aonw_core/lib/game/domain/diplomacy/';
const _kernelPath = '${_diplomacyLibrary}diplomacy_command_resolver.dart';
const _statePath = '${_diplomacyLibrary}diplomacy_command_state.dart';
const _resultPath = '${_diplomacyLibrary}diplomacy_command_result.dart';
const _supportPath = '${_diplomacyLibrary}diplomacy_command_support.dart';
const _proposalHandlerPath =
    '${_diplomacyLibrary}diplomacy_proposal_command_handler.dart';
const _proposalResponseHandlerPath =
    '${_diplomacyLibrary}diplomacy_proposal_response_command_handler.dart';
const _warAndGiftHandlerPath =
    '${_diplomacyLibrary}diplomacy_war_and_gift_command_handler.dart';
const _messageHandlerPath =
    '${_diplomacyLibrary}diplomacy_message_command_handler.dart';
const _persistentAdapterPath =
    '${_diplomacyLibrary}persistent_diplomacy_resolver.dart';
const _domainAdapterPath =
    '${_diplomacyLibrary}domain_diplomacy_command_resolver.dart';
const _routerPath = '${_diplomacyLibrary}diplomacy_command_router.dart';
const _localCallSite =
    'lib/game/domain/reducer/diplomacy/diplomacy_reducer.dart';
const _legacyLocalAdapter =
    'lib/game/domain/reducer/diplomacy/persistent_diplomacy_adapter.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_diplomacy.dart';
const _serverReducerPath =
    'server/lib/src/multiplayer/server_command_reducer.dart';
const _neutralKernelPaths = {
  _kernelPath,
  _statePath,
  _resultPath,
  _supportPath,
  _proposalHandlerPath,
  _proposalResponseHandlerPath,
  _warAndGiftHandlerPath,
  _messageHandlerPath,
};

void main() {
  _registerCallSiteBoundaryTest();
  _registerKernelShapeTest();
  _registerLocalBoundaryTest();
  _registerServerBoundaryTest();
  _registerStaticGuardTest();
  _registerAdversarialGuardTest();
}

void _registerCallSiteBoundaryTest() {
  test('diplomacy paths share one state-neutral command kernel', () {
    final sources = productionDartSources();

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'DiplomacyCommandResolver',
        'resolve',
      ),
      const {
        _persistentAdapterPath: 1,
        _domainAdapterPath: 1,
        _localCallSite: 1,
        _serverCallSite: 1,
      },
      reason: 'Unexpected DiplomacyCommandResolver.resolve call-sites.',
    );

    final adapterConsumerSources = Map<String, String>.of(sources)
      ..remove(_persistentAdapterPath)
      ..remove(_domainAdapterPath)
      ..remove(_routerPath);
    for (final adapter in const {
      'PersistentDiplomacyResolver',
      'DomainDiplomacyCommandResolver',
    }) {
      for (final member in const {
        'resolve',
        'sendProposal',
        'respondProposal',
        'declareWar',
        'sendGoldGift',
        'sendMessage',
        'respondMessage',
      }) {
        expect(
          staticMemberReferenceCountsByPath(
            adapterConsumerSources,
            adapter,
            member,
          ),
          isEmpty,
          reason: 'Production consumers must not call static adapter members.',
        );
        expect(
          instanceMemberReferenceCountsByPath(
            adapterConsumerSources,
            adapter,
            member,
          ),
          isEmpty,
          reason: 'Production consumers must call the neutral kernel directly.',
        );
      }
    }
  });
}

void _registerKernelShapeTest() {
  test('diplomacy kernel owns only bounded rule inputs and outputs', () {
    final sources = productionDartSources();
    final kernelSources = _neutralKernelSources(sources);
    expect(
      kernelSources.keys.toSet(),
      _neutralKernelPaths,
      reason:
          'The neutral kernel must keep its exact split into four handlers.',
    );

    final forbiddenTypes = typeNamesBackedBy(
      sources,
      diplomacyKernelForbiddenRootTypes,
    );
    final importGraph = diplomacyKernelImportGraph(
      sources,
      _neutralKernelPaths,
    );
    expect(
      diplomacyKernelImportGraphViolations(
        importGraph,
        expectedPaths: diplomacyKernelImportGraphPaths,
        forbiddenTypes: forbiddenTypes,
      ),
      isEmpty,
      reason:
          'The complete kernel import graph must remain closed and neutral.',
    );

    expect(_classFieldNames(sources[_statePath]!, 'DiplomacyCommandState'), {
      'playerColors',
      'playerCountries',
      'playerGold',
      'units',
      'cities',
      'fogOfWar',
      'diplomacy',
      'intendedAttacks',
      'resourceTradeAgreements',
    });
    expect(_classFieldNames(sources[_resultPath]!, 'DiplomacyCommandResult'), {
      'accepted',
      'reason',
      'playerGold',
      'diplomacy',
      'intendedAttacks',
      'resourceTradeAgreements',
      'events',
    });
  });
}

void _registerLocalBoundaryTest() {
  test('local diplomacy does not restore a full-state bridge', () {
    final sources = productionDartSources();
    final localSource = sources[_localCallSite]!;
    final localTypes = namedTypeReferencesInSource(
      localSource,
      path: _localCallSite,
    );
    expect(
      localTypes.intersection(const {
        'PersistentGameState',
        'PersistentDiplomacyResolver',
        'PersistentDiplomacyResult',
        'DomainState',
        'DomainDiplomacyCommandResolver',
        'DomainDiplomacyCommandResult',
        'DiplomacyCommandRouter',
      }),
      isEmpty,
    );
    expect(_memberReferenceCount(localSource, 'toPersistentState'), 0);
    expect(
      removedProductionSymbolViolations(
        sources,
        symbol: 'PersistentDiplomacyAdapter',
        uriSuffix: '/persistent_diplomacy_adapter.dart',
      ),
      isEmpty,
      reason: 'The removed local persistence bridge must not return.',
    );
    expect(sources, isNot(contains(_legacyLocalAdapter)));
  });
}

void _registerServerBoundaryTest() {
  test('server diplomacy bypasses the generic persistent-result bridge', () {
    final sources = productionDartSources();
    final serverReducer = sources[_serverReducerPath]!;
    final serverCallSite = sources[_serverCallSite]!;

    expect(
      namedTypeReferencesInSource(
        serverReducer,
        path: _serverReducerPath,
      ).intersection(const {
        'PersistentDiplomacyResult',
        'DiplomacyCommandRouter',
      }),
      isEmpty,
    );
    expect(
      namedTypeReferencesInSource(
        serverCallSite,
        path: _serverCallSite,
      ).intersection(const {
        'PersistentDiplomacyResult',
        'PersistentDiplomacyResolver',
        'DomainDiplomacyCommandResolver',
        'DiplomacyCommandRouter',
      }),
      isEmpty,
    );
    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'DiplomacyCommandRouter',
        'route',
      ),
      isEmpty,
      reason: 'The compatibility router must have no static call-sites.',
    );
    expect(
      instanceMemberReferenceCountsByPath(
        sources,
        'DiplomacyCommandRouter',
        'route',
      ),
      isEmpty,
      reason: 'The compatibility router must have no production call-sites.',
    );
  });
}

void _registerStaticGuardTest() {
  test('static kernel guard catches aliases, prefixes, and duplicates', () {
    final sources = <String, String>{
      'kernel.dart': '''
abstract final class DiplomacyCommandResolver {
  static void resolve() {}
}
''',
      'alias.dart': '''
typedef DiplomacyKernel = DiplomacyCommandResolver;
void apply() => DiplomacyKernel.resolve();
''',
      'prefixed.dart': '''
void apply() => core.DiplomacyCommandResolver.resolve();
''',
      'tear_off.dart': '''
final applyDiplomacy = DiplomacyCommandResolver.resolve;
''',
      'duplicate.dart': '''
void applyOnce() => DiplomacyCommandResolver.resolve();
final applyAgain = DiplomacyCommandResolver.resolve;
''',
      'unrelated.dart': '''
abstract final class LegacyDiplomacyCommandResolver {
  static void resolve() {}
}
void apply() => LegacyDiplomacyCommandResolver.resolve();
''',
    };

    expect(
      staticMemberReferenceCountsByPath(
        sources,
        'DiplomacyCommandResolver',
        'resolve',
      ),
      {
        'alias.dart': 1,
        'prefixed.dart': 1,
        'tear_off.dart': 1,
        'duplicate.dart': 2,
      },
    );
  });
}

void _registerAdversarialGuardTest() {
  _registerTypeAndInstanceGuardFixture();
  _registerStaticAdapterGuardFixture();
  _registerKernelImportGraphGuardFixture();
}

void _registerTypeAndInstanceGuardFixture() {
  test('boundary fixtures fail closed around aliases and bridge tear-offs', () {
    final sources = {
      'state.dart': 'class PersistentGameState {}',
      'alias.dart': 'typedef LegacyState = PersistentGameState;',
    };
    final forbidden = typeNamesBackedBy(sources, const {'PersistentGameState'});
    expect(
      namedTypeReferencesInSource(
        'void resolve(LegacyState state) {}',
      ).intersection(forbidden),
      {'LegacyState'},
    );

    const bridgeSource = '''
void convert(dynamic state) {
  state.toPersistentState();
  final convertState = state.toPersistentState;
}
''';
    expect(_memberReferenceCount(bridgeSource, 'toPersistentState'), 2);

    final adapterSources = <String, String>{
      'direct.dart': '''
void apply() => const PersistentDiplomacyResolver().resolve();
''',
      'alias.dart': '''
typedef LegacyAdapter = PersistentDiplomacyResolver;
final make = LegacyAdapter.new;
void apply() => make().resolve();
''',
      'tear_off.dart': '''
final make = PersistentDiplomacyResolver.new;
final adapter = make();
final applyDiplomacy = adapter.resolve;
''',
    };
    expect(
      instanceMemberReferenceCountsByPath(
        adapterSources,
        'PersistentDiplomacyResolver',
        'resolve',
      ),
      {'direct.dart': 1, 'alias.dart': 1, 'tear_off.dart': 1},
    );
  });
}

void _registerStaticAdapterGuardFixture() {
  test(
    'adapter guard catches static calls and tear-offs for both adapters',
    () {
      final sources = <String, String>{
        'persistent_direct.dart': '''
void apply() => PersistentDiplomacyResolver.resolve();
''',
        'persistent_alias.dart': '''
typedef LegacyAdapter = PersistentDiplomacyResolver;
final apply = LegacyAdapter.resolve;
''',
        'domain_prefixed.dart': '''
void apply() => core.DomainDiplomacyCommandResolver.resolve();
''',
        'domain_tear_off.dart': '''
final apply = DomainDiplomacyCommandResolver.resolve;
''',
        'router_static.dart': '''
void apply() => DiplomacyCommandRouter.route();
''',
      };

      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'PersistentDiplomacyResolver',
          'resolve',
        ),
        {'persistent_direct.dart': 1, 'persistent_alias.dart': 1},
      );
      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'DomainDiplomacyCommandResolver',
          'resolve',
        ),
        {'domain_prefixed.dart': 1, 'domain_tear_off.dart': 1},
      );
      expect(
        staticMemberReferenceCountsByPath(
          sources,
          'DiplomacyCommandRouter',
          'route',
        ),
        {'router_static.dart': 1},
      );
    },
  );
}

void _registerKernelImportGraphGuardFixture() {
  test('kernel graph catches an arbitrarily named stateful helper', () {
    const root = '${_diplomacyLibrary}fixture_resolver.dart';
    const helper = '${_diplomacyLibrary}stealth_rules.dart';
    final sources = <String, String>{
      root: '''
import 'package:aonw_core/game/domain/diplomacy/stealth_rules.dart';
import 'package:aonw_core/game/domain/city.dart';
''',
      helper: '''
PersistentGameState leak(PersistentGameState state) => state;
''',
    };
    final graph = diplomacyKernelImportGraph(sources, const {root});
    final violations = diplomacyKernelImportGraphViolations(
      graph,
      expectedPaths: const {root},
      forbiddenTypes: const {'PersistentGameState'},
    );

    expect(graph.keys.toSet(), {root, helper});
    expect(
      violations.join('\n'),
      allOf(
        contains('unexpected graph path'),
        contains('PersistentGameState'),
        contains(
          'unapproved dependency package:aonw_core/game/domain/city.dart',
        ),
      ),
    );
  });
}

Map<String, String> _neutralKernelSources(Map<String, String> sources) {
  return {
    for (final entry in sources.entries)
      if (entry.key.startsWith(_diplomacyLibrary) &&
          entry.key.contains('command_') &&
          !entry.key.endsWith('diplomacy_command_router.dart') &&
          !entry.key.endsWith('persistent_diplomacy_resolver.dart') &&
          !entry.key.endsWith('domain_diplomacy_command_resolver.dart'))
        entry.key: entry.value,
  };
}

Set<String> _classFieldNames(String source, String className) {
  final unit = parseString(content: source).unit;
  final declaration = unit.declarations
      .whereType<ClassDeclaration>()
      .singleWhere(
        (candidate) => candidate.namePart.typeName.lexeme == className,
      );
  return {
    for (final field in declaration.body.members.whereType<FieldDeclaration>())
      for (final variable in field.fields.variables) variable.name.lexeme,
  };
}

int _memberReferenceCount(String source, String memberName) {
  final visitor = _NamedMemberReferenceCollector(memberName);
  parseString(content: source).unit.accept(visitor);
  return visitor.count;
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
