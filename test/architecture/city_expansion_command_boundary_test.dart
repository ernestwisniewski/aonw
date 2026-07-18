import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/city/'
    'city_expansion_command_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'persistent_city_expansion_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/city/'
    'domain_city_expansion_resolver.dart';
const _localCallSite =
    'lib/game/domain/reducer/city/city_expansion_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_city_expansion.dart';

void main() {
  test('city expansion paths share one state-neutral kernel', () {
    final sources = productionDartSources();
    const kernelCallSites = {
      _persistentAdapterPath,
      _domainAdapterPath,
      _localCallSite,
      _serverCallSite,
    };

    expect(
      staticMemberReferencePaths(
        sources,
        'CityExpansionCommandResolver',
        'selectExpansionHex',
      ),
      kernelCallSites,
      reason:
          'Unexpected CityExpansionCommandResolver.selectExpansionHex '
          'call-sites.',
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'PersistentCityExpansionResolver',
        'selectExpansionHex',
      ),
      isEmpty,
      reason: 'Production must call the state-neutral expansion kernel.',
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'DomainCityExpansionResolver',
        'selectExpansionHex',
      ),
      isEmpty,
      reason: 'Production must call the state-neutral expansion kernel.',
    );

    final kernelSource = sources[_kernelPath];
    expect(
      kernelSource,
      isNotNull,
      reason: 'The state-neutral city expansion kernel must exist.',
    );
    final kernelTypes = namedTypeReferencesInSource(
      kernelSource!,
      path: _kernelPath,
    );
    final forbiddenTypes = typeNamesBackedBy(sources, const {
      'PersistentGameState',
      'DomainState',
      'CanonicalGameSnapshot',
      'GameState',
      'GameRuntimeState',
      'PersistedInteractionState',
      'GameInteractionState',
      'PendingPlayerAction',
      'GameSelection',
      'PersistentCityExpansionResult',
      'PersistentCityExpansionResolver',
      'DomainCityExpansionResult',
      'DomainCityExpansionResolver',
      'MapData',
      'FogOfWarState',
      'FogOfWarService',
      'FogVisibilityQuery',
      'GameEvent',
      'GameStateTransition',
      'UiEffect',
    });
    expect(kernelTypes.intersection(forbiddenTypes), isEmpty);
  });

  test('static guard catches aliases, prefixes, and member tear-offs', () {
    final sources = <String, String>{
      'kernel.dart': '''
abstract final class CityExpansionCommandResolver {
  static void selectExpansionHex() {}
}
''',
      'alias.dart': '''
typedef ExpansionKernel = CityExpansionCommandResolver;
void apply() => ExpansionKernel.selectExpansionHex();
''',
      'prefixed.dart': '''
void apply() => core.CityExpansionCommandResolver.selectExpansionHex();
''',
      'tear_off.dart': '''
final applyExpansion = CityExpansionCommandResolver.selectExpansionHex;
''',
      'unrelated.dart': '''
abstract final class LegacyCityExpansionCommandResolver {
  static void selectExpansionHex() {}
}
void apply() => LegacyCityExpansionCommandResolver.selectExpansionHex();
''',
    };

    expect(
      staticMemberReferencePaths(
        sources,
        'CityExpansionCommandResolver',
        'selectExpansionHex',
      ),
      {'alias.dart', 'prefixed.dart', 'tear_off.dart'},
    );
  });
}
