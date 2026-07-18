import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/artifact/'
    'artifact_command_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/artifact/'
    'persistent_artifact_command_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/artifact/'
    'domain_artifact_command_resolver.dart';
const _localCallSite = 'lib/game/domain/reducer/artifact/artifact_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_artifact.dart';

void main() {
  test('artifact paths share one state-neutral kernel', () {
    final sources = productionDartSources();
    const expectedKernelCallSites = {
      _persistentAdapterPath,
      _domainAdapterPath,
      _localCallSite,
      _serverCallSite,
    };

    for (final method in const [
      'startExcavation',
      'storeInCity',
      'tradeArtifact',
    ]) {
      expect(
        staticMemberReferencePaths(sources, 'ArtifactCommandResolver', method),
        expectedKernelCallSites,
        reason: 'Unexpected ArtifactCommandResolver.$method call-sites.',
      );
      expect(
        instanceMemberReferencePaths(
          sources,
          'PersistentArtifactCommandResolver',
          method,
        ),
        isEmpty,
        reason: 'Production must call the state-neutral $method kernel.',
      );
    }

    final kernelTypes = namedTypeReferencesInSource(
      sources[_kernelPath]!,
      path: _kernelPath,
    );
    expect(
      kernelTypes.intersection(const {
        'PersistentGameState',
        'DomainState',
        'CanonicalGameSnapshot',
        'GameState',
        'GameRuntimeState',
        'PendingPlayerAction',
        'GameInteractionState',
        'GameSelection',
        'MapData',
        'MapReadView',
        'MapTileLookup',
        'WorldMap',
      }),
      isEmpty,
    );

    final localTypes = namedTypeReferencesInSource(
      sources[_localCallSite]!,
      path: _localCallSite,
    );
    expect(
      localTypes.intersection(const {
        'PersistentGameState',
        'PersistentArtifactCommandResolver',
        'PersistentArtifactCommandResult',
      }),
      isEmpty,
    );
  });

  test('instance guard catches constructor tear-off factory chains', () {
    final sources = <String, String>{
      'direct.dart': '''
final make = PersistentArtifactCommandResolver.new;
void apply() {
  final resolver = make();
  resolver.tradeArtifact();
}
''',
      'alias.dart': '''
typedef ArtifactAdapter = PersistentArtifactCommandResolver;
final make = ArtifactAdapter.new;
final copiedFactory = make;
void apply() {
  final resolver = copiedFactory();
  resolver.tradeArtifact();
}
''',
      'prefixed.dart': '''
final make = core.PersistentArtifactCommandResolver.new;
void apply() => make().tradeArtifact();
''',
      'function.dart': '''
PersistentArtifactCommandResolver make() =>
    const PersistentArtifactCommandResolver();
void apply() => make().tradeArtifact();
''',
      'clean.dart': 'void apply(Object value) { value.toString(); }',
    };

    expect(
      instanceMemberReferencePaths(
        sources,
        'PersistentArtifactCommandResolver',
        'tradeArtifact',
      ),
      {'direct.dart', 'alias.dart', 'prefixed.dart', 'function.dart'},
    );
  });
}
