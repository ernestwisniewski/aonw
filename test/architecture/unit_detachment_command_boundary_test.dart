import 'package:flutter_test/flutter_test.dart';

import 'support/map_boundary_source_guard.dart';
import 'support/static_member_reference_guard.dart';

const _kernelPath =
    'packages/aonw_core/lib/game/domain/unit/detach_troop_resolver.dart';
const _persistentAdapterPath =
    'packages/aonw_core/lib/game/domain/unit/'
    'persistent_unit_detachment_resolver.dart';
const _domainAdapterPath =
    'packages/aonw_core/lib/game/domain/unit/'
    'domain_unit_detachment_resolver.dart';
const _localCallSite =
    'lib/game/domain/reducer/unit/unit_attachment_reducer.dart';
const _serverCallSite =
    'server/lib/src/multiplayer/server_command_reducer_detachment.dart';
const _simulationPersistentCallSite =
    'packages/aonw_core/lib/ai/simulation/'
    'economy_simulation_command_applier.dart';

void main() {
  test('detachment paths share one state-neutral kernel', () {
    final sources = productionDartSources();
    expect(
      staticMemberReferencePaths(sources, 'DetachTroopResolver', 'detachTroop'),
      {
        _persistentAdapterPath,
        _domainAdapterPath,
        _localCallSite,
        _serverCallSite,
      },
    );
    expect(
      instanceMemberReferencePaths(
        sources,
        'PersistentUnitDetachmentResolver',
        'detachTroop',
      ),
      {_simulationPersistentCallSite},
    );
    expect(
      staticMemberReferencePaths(sources, 'UnitDetachmentRules', 'detachTroop'),
      {_kernelPath},
    );

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
        'GameSelection',
        'MapData',
        'WorldMap',
      }),
      isEmpty,
    );
  });
}
